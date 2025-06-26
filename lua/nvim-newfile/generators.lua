-- Content generators for different languages
local M = {}

local config = require("nvim-newfile.config")
local utils = require("nvim-newfile.utils")

-- Generate content for a new file based on language and location
function M.generate_content(file_path, dir_path)
    -- Check for special file types that shouldn't have namespace/package declarations
    if M.is_blade_template(file_path) then
        return "" -- Blade templates should be empty by default
    end

    local extension = utils.get_file_extension(file_path)
    local language = M.detect_language(extension)

    if not language then
        return "" -- No specific language detected, return empty content
    end

    local lang_config = config.get_language_config(language)
    if not lang_config or not lang_config.enabled then
        return ""
    end

    local package_name = M.generate_package_name(language, dir_path, file_path)
    if not package_name or package_name == "" then
        return ""
    end

    return string.format(lang_config.package_format, package_name) .. "\n\n"
end

-- Check if file is a Laravel Blade template
function M.is_blade_template(file_path)
    local filename = vim.fn.fnamemodify(file_path, ":t")
    return filename:match("%.blade%.php$") ~= nil
end

-- Detect language from file extension
function M.detect_language(extension)
    for lang, lang_config in pairs(config.options.languages) do
        if lang_config.enabled then
            for _, ext in ipairs(lang_config.file_extensions) do
                if ext == extension then
                    return lang
                end
            end
        end
    end
    return nil
end

-- Generate package/namespace name based on directory structure
function M.generate_package_name(language, dir_path, file_path)
    local lang_config = config.get_language_config(language)
    if not lang_config then
        return nil
    end

    if lang_config.use_directory_name then
        -- For languages like Go that use just the directory name
        if language == "go" then
            -- Special handling for Go: check if directory should use "main" package
            local package_name = M.determine_go_package_name(dir_path, file_path)
            return package_name
        else
            local dir_name = vim.fn.fnamemodify(dir_path, ":t")
            local transform_fn = config.get_directory_transform(language)
            return transform_fn(dir_name)
        end
    else
        -- For languages that use full namespace path (Java, PHP, etc.)
        return M.generate_namespace_path(language, dir_path, file_path)
    end
end

-- Determine the correct package name for Go files
function M.determine_go_package_name(dir_path, file_path)
    -- Check if there's already a main.go file in the directory
    local main_go_path = dir_path .. "/main.go"
    if vim.fn.filereadable(main_go_path) == 1 then
        return "main"
    end

    -- Check if the current file being created is main.go
    local filename = vim.fn.fnamemodify(file_path, ":t")
    if filename == "main.go" then
        return "main"
    end

    -- Check if any existing .go files in the directory use "package main"
    local go_files = vim.fn.glob(dir_path .. "/*.go", false, true)
    for _, go_file in ipairs(go_files) do
        if vim.fn.filereadable(go_file) == 1 then
            local first_lines = vim.fn.readfile(go_file, "", 10) -- Read first 10 lines
            for _, line in ipairs(first_lines) do
                local trimmed = line:match("^%s*(.-)%s*$")       -- Trim whitespace
                if trimmed:match("^package%s+main%s*$") then
                    return "main"
                end
                -- Stop at first non-comment, non-blank line that starts with "package"
                if trimmed:match("^package%s+") then
                    break
                end
            end
        end
    end

    -- Default to directory name if no main package found
    local dir_name = vim.fn.fnamemodify(dir_path, ":t")
    local transform_fn = config.get_directory_transform("go")
    return transform_fn(dir_name)
end

-- Generate full namespace path for languages that need it
function M.generate_namespace_path(language, dir_path, file_path)
    local project_root = utils.find_project_root(dir_path)
    if not project_root then
        -- Fallback to directory name
        local dir_name = vim.fn.fnamemodify(dir_path, ":t")
        local transform_fn = config.get_directory_transform(language)
        return transform_fn(dir_name)
    end

    local relative_path = utils.get_relative_path_from_root(dir_path, project_root)

    -- Language-specific namespace generation
    if language == "java" or language == "kotlin" or language == "scala" then
        return M.generate_java_like_package(relative_path, project_root)
    elseif language == "php" then
        return M.generate_php_namespace(relative_path, project_root)
    elseif language == "csharp" then
        return M.generate_csharp_namespace(relative_path, project_root)
    end

    return relative_path:gsub("/", ".")
end

-- Generate Java-like package names (java, kotlin, scala)
function M.generate_java_like_package(relative_path, project_root)
    -- Look for src/main/java or src/main/kotlin patterns
    local package_path = relative_path

    -- Remove common source directory prefixes
    package_path = package_path:gsub("^src/main/java/", "")
    package_path = package_path:gsub("^src/main/kotlin/", "")
    package_path = package_path:gsub("^src/main/scala/", "")
    package_path = package_path:gsub("^src/", "")
    package_path = package_path:gsub("^main/", "")

    -- Convert path separators to dots
    package_path = package_path:gsub("/", ".")

    -- Remove leading/trailing dots
    package_path = package_path:gsub("^%.", ""):gsub("%.$", "")

    return package_path
end

-- Generate PHP namespace
function M.generate_php_namespace(relative_path, project_root)
    local namespace = relative_path

    -- Remove common PHP source directory prefixes
    namespace = namespace:gsub("^src/", "")
    namespace = namespace:gsub("^lib/", "")
    namespace = namespace:gsub("^app/", "")

    -- Convert path separators to backslashes for PHP
    namespace = namespace:gsub("/", "\\")

    -- Capitalize first letter of each part
    namespace = namespace:gsub("([^\\]+)", function(part)
        return part:sub(1, 1):upper() .. part:sub(2)
    end)

    -- Remove leading/trailing backslashes
    namespace = namespace:gsub("^\\", ""):gsub("\\$", "")

    return namespace
end

-- Generate C# namespace
function M.generate_csharp_namespace(relative_path, project_root)
    local namespace = relative_path

    -- Remove common C# source directory prefixes
    namespace = namespace:gsub("^src/", "")
    namespace = namespace:gsub("^Source/", "")

    -- Convert path separators to dots
    namespace = namespace:gsub("/", ".")

    -- Capitalize first letter of each part
    namespace = namespace:gsub("([^%.]+)", function(part)
        return part:sub(1, 1):upper() .. part:sub(2)
    end)

    -- Remove leading/trailing dots
    namespace = namespace:gsub("^%.", ""):gsub("%.$", "")

    return namespace
end

-- Generate template-based content
function M.generate_template_content(language, template_type, package_name, class_name)
    local template = config.get_template(language, template_type)
    if not template then
        return nil
    end

    if class_name then
        return string.format(template, package_name, class_name)
    else
        return string.format(template, package_name)
    end
end

-- Check if file should use a specific template
function M.should_use_template(file_path)
    local filename = vim.fn.fnamemodify(file_path, ":t:r")
    local extension = utils.get_file_extension(file_path)
    local language = M.detect_language(extension)

    if not language then
        return nil, nil
    end

    -- Check for main files
    if filename:lower() == "main" and language == "go" then
        return language, "main"
    end

    -- Check for class files (files starting with uppercase)
    if filename:match("^[A-Z]") then
        if language == "java" or language == "php" or language == "csharp" then
            return language, "class"
        end
    end

    return nil, nil
end

return M
