-- Main module for nvim-newfile
local M = {}

local Input = require("nui.input")
local event = require("nui.utils.autocmd").event
local config = require("nvim-newfile.config")
local generators = require("nvim-newfile.generators")
local utils = require("nvim-newfile.utils")

-- Create a new file with package/namespace declaration
function M.create_file(filename)
    if filename and filename ~= "" then
        M._create_file_with_name(filename)
    else
        M._show_input_dialog()
    end
end

-- Create a file in the current directory
function M.create_file_here()
    -- Get the directory of the current buffer, fallback to working directory
    local current_file = vim.fn.expand("%:p")
    local target_dir
    if current_file and current_file ~= "" then
        target_dir = vim.fn.fnamemodify(current_file, ":h")
    else
        target_dir = vim.fn.getcwd()
    end
    M._show_input_dialog(target_dir)
end

-- Show input dialog using nui.nvim
function M._show_input_dialog(target_dir)
    local current_dir = target_dir or vim.fn.getcwd()
    local relative_dir = utils.get_relative_path(current_dir)
    local ui_config = config.get_ui_config()

    local input = Input({
        position = "50%",
        size = {
            width = ui_config.width,
            height = ui_config.height,
        },
        border = {
            style = ui_config.border_style,
            text = {
                top = string.format("[New File in %s]", relative_dir),
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = ui_config.winhighlight or "Normal:Normal,FloatBorder:Normal",
        },
    }, {
        prompt = ui_config.prompt_text,
        default_value = "",
        on_close = function()
            -- Do nothing on close
        end,
        on_submit = function(value)
            if value and value ~= "" then
                -- Validate filename
                local is_valid, error_msg = utils.is_valid_filename(value)
                if not is_valid then
                    vim.notify("Invalid filename: " .. error_msg, vim.log.levels.ERROR)
                    return
                end
                -- Schedule the file creation to happen after the input dialog is closed
                vim.schedule(function()
                    -- Add a small delay to ensure the input dialog is fully unmounted
                    vim.defer_fn(function()
                        M._create_file_with_name(value, current_dir)
                    end, 10)
                end)
            end
        end,
    })

    -- Mount the input dialog
    input:mount()

    -- Add tab completion functionality
    input:map("i", "<Tab>", function()
        -- Get current text from the input buffer
        local current_text = vim.api.nvim_buf_get_lines(input.bufnr, 0, 1, false)[1] or ""
        -- Remove the prompt prefix if it exists
        local prompt_len = #(ui_config.prompt_text or "")
        if prompt_len > 0 and current_text:sub(1, prompt_len) == ui_config.prompt_text then
            current_text = current_text:sub(prompt_len + 1)
        end

        local completions = utils.get_directory_completions(current_text, current_dir)

        if #completions == 0 then
            return -- No completions available
        elseif #completions == 1 then
            -- Single completion, replace current text
            local completion = completions[1]
            -- Add trailing slash if it's a directory path
            if not completion:match("%.%w+$") then
                completion = completion .. "/"
            end
            local new_line = ui_config.prompt_text .. completion
            vim.api.nvim_buf_set_lines(input.bufnr, 0, 1, false, { new_line })
            vim.api.nvim_win_set_cursor(input.winid, { 1, #new_line })
        else
            -- Multiple completions, find common prefix
            local common_prefix = utils.get_common_prefix(completions)
            if #common_prefix > #current_text then
                -- Replace with common prefix
                local new_line = ui_config.prompt_text .. common_prefix
                vim.api.nvim_buf_set_lines(input.bufnr, 0, 1, false, { new_line })
                vim.api.nvim_win_set_cursor(input.winid, { 1, #new_line })
            else
                -- Show completions in a notification or echo
                local completion_list = table.concat(completions, ", ")
                vim.notify("Available completions: " .. completion_list, vim.log.levels.INFO)
            end
        end
    end, { noremap = true })

    -- Unmount when leaving buffer
    input:on(event.BufLeave, function()
        input:unmount()
    end)
end

-- Auto-detect and append file extension based on project type
function M._auto_detect_extension(filename, current_dir)
    -- Extract just the filename part (in case the input includes a path)
    local path_part = ""
    local name_part = filename

    local last_slash = filename:find("/[^/]*$")
    if last_slash then
        path_part = filename:sub(1, last_slash - 1) .. "/"
        name_part = filename:sub(last_slash + 1)
    end

    -- Return as-is if the filename part already has an extension
    if name_part:match("%.%w+$") then
        return filename
    end

    -- For extension detection, use the target directory (where the file will be created)
    local target_dir = current_dir
    if path_part ~= "" then
        target_dir = vim.fn.fnamemodify(current_dir .. "/" .. path_part, ":p")
    end

    -- Detect project type based on directory structure and project files
    local project_type = M._detect_project_type(target_dir)

    if project_type then
        local lang_config = config.get_language_config(project_type)
        if lang_config and lang_config.file_extensions and #lang_config.file_extensions > 0 then
            -- Special handling for Laravel Blade templates
            if project_type == "php" and M._is_likely_blade_file(name_part, target_dir) then
                return path_part .. name_part .. ".blade.php"
            end

            -- Use the first (primary) extension for the detected language
            local extension = lang_config.file_extensions[1]
            return path_part .. name_part .. "." .. extension
        end
    end

    -- No extension detected, return as-is
    return filename
end

-- Detect project type based on current directory and project structure
function M._detect_project_type(current_dir)
    -- First, try to detect by project root files
    local project_root = utils.find_project_root(current_dir)
    if project_root then
        -- Check for Go project
        if vim.fn.filereadable(project_root .. "/go.mod") == 1 then
            return "go"
        end
        -- Check for PHP project
        if vim.fn.filereadable(project_root .. "/composer.json") == 1 then
            return "php"
        end
        -- Check for Java project (Maven)
        if vim.fn.filereadable(project_root .. "/pom.xml") == 1 then
            return "java"
        end
        -- Check for Java/Kotlin project (Gradle)
        if vim.fn.filereadable(project_root .. "/build.gradle") == 1 or
            vim.fn.filereadable(project_root .. "/build.gradle.kts") == 1 then
            -- Check for Kotlin-specific indicators
            if vim.fn.glob(project_root .. "/**/*.kt", false, true)[1] or
                vim.fn.filereadable(project_root .. "/build.gradle.kts") == 1 then
                return "kotlin"
            else
                return "java"
            end
        end
        -- Check for Scala project
        if vim.fn.filereadable(project_root .. "/build.sbt") == 1 then
            return "scala"
        end
        -- Check for C# project
        if vim.fn.glob(project_root .. "/**/*.csproj", false, true)[1] or
            vim.fn.glob(project_root .. "/**/*.sln", false, true)[1] then
            return "csharp"
        end
    end

    -- If no project root detected, check current directory for existing files
    local file_types = {}
    local files = vim.fn.glob(current_dir .. "/*", false, true)

    for _, file in ipairs(files) do
        if vim.fn.isdirectory(file) == 0 then -- Only check files, not directories
            local ext = utils.get_file_extension(file)
            if ext ~= "" then
                local detected_lang = generators.detect_language(ext)
                if detected_lang then
                    file_types[detected_lang] = (file_types[detected_lang] or 0) + 1
                end
            end
        end
    end

    -- Return the most common language in the directory
    local max_count = 0
    local detected_type = nil
    for lang, count in pairs(file_types) do
        if count > max_count then
            max_count = count
            detected_type = lang
        end
    end

    return detected_type
end

-- Check if a filename is likely intended to be a Blade template
function M._is_likely_blade_file(filename, target_dir)
    -- Check if we're in a Laravel project structure
    local is_laravel = M._is_laravel_project(target_dir)
    if not is_laravel then
        return false
    end

    -- Check if we're in a views directory (common Laravel pattern)
    local normalized_path = target_dir:lower()
    if normalized_path:match("/views?/") or
        normalized_path:match("/resources/views") or
        normalized_path:match("\\views?\\") or
        normalized_path:match("\\resources\\views") then
        return true
    end

    -- Check if filename suggests it's a view (common patterns)
    local lower_name = filename:lower()
    if lower_name:match("^index$") or
        lower_name:match("^create$") or
        lower_name:match("^edit$") or
        lower_name:match("^show$") or
        lower_name:match("^layout$") or
        lower_name:match("^master$") or
        lower_name:match("^app$") or
        lower_name:match("%-view$") or
        lower_name:match("_view$") then
        return true
    end

    return false
end

-- Check if the current directory is part of a Laravel project
function M._is_laravel_project(target_dir)
    local project_root = utils.find_project_root(target_dir)
    if not project_root then
        return false
    end

    -- Check for Laravel-specific files/directories
    return vim.fn.filereadable(project_root .. "/artisan") == 1 or
        vim.fn.isdirectory(project_root .. "/app") == 1 and
        vim.fn.filereadable(project_root .. "/composer.json") == 1
end

-- Create file with the given name
function M._create_file_with_name(filename, target_dir)
    local current_dir = target_dir or vim.fn.getcwd()

    -- Auto-detect and append file extension if none provided
    filename = M._auto_detect_extension(filename, current_dir)

    local full_path = vim.fn.fnamemodify(current_dir .. "/" .. filename, ":p")
    local dir_path = vim.fn.fnamemodify(full_path, ":h")

    -- Create directory if it doesn't exist
    if vim.fn.isdirectory(dir_path) == 0 then
        vim.fn.mkdir(dir_path, "p")
    end

    -- Check if file already exists
    if vim.fn.filereadable(full_path) == 1 then
        local choice = vim.fn.confirm(
            string.format("File '%s' already exists. Overwrite?", filename),
            "&Yes\n&No\n&Open existing",
            3
        )

        if choice == 1 then
            -- Continue with creation (overwrite)
        elseif choice == 3 then
            -- Open existing file
            vim.schedule(function()
                vim.cmd("edit " .. vim.fn.fnameescape(full_path))
            end)
            return
        else
            -- Cancel
            return
        end
    end

    -- Check if we should use a template
    local language, template_type = generators.should_use_template(full_path)
    local content = ""

    if language and template_type then
        local package_name = generators.generate_package_name(language, dir_path, full_path)
        local class_name = utils.get_filename_without_ext(full_path)
        content = generators.generate_template_content(language, template_type, package_name, class_name)
    end

    -- If no template content, generate regular package declaration
    if not content or content == "" then
        content = generators.generate_content(full_path, dir_path)
    end

    -- Write content to file
    local lines = vim.split(content, "\n")
    vim.fn.writefile(lines, full_path)

    -- Open the file in Neovim (ensure we're in a clean state)
    vim.schedule(function()
        vim.cmd("edit " .. vim.fn.fnameescape(full_path))

        -- Position cursor appropriately
        if #lines > 1 then
            -- Move to end of file for content addition
            vim.cmd("normal! G")
            if content:match("\n\n$") then
                vim.cmd("normal! o")
            end
        end
    end)

    vim.notify(string.format("Created file: %s", filename), vim.log.levels.INFO)
end

-- Setup function for configuration
function M.setup(opts)
    config.setup(opts)
end

return M
