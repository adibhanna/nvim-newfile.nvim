-- Utility functions for nvim-newfile
local M = {}

local config = require("nvim-newfile.config")

-- Get file extension from file path
function M.get_file_extension(file_path)
    local extension = vim.fn.fnamemodify(file_path, ":e")
    return extension:lower()
end

-- Get relative path for display purposes
function M.get_relative_path(current_dir)
    local home = vim.fn.expand("~")
    if current_dir:find(home, 1, true) == 1 then
        return "~" .. current_dir:sub(#home + 1)
    end
    return current_dir
end

-- Find project root by looking for specific patterns
function M.find_project_root(start_path)
    local patterns = config.get_project_root_patterns()
    local current_path = start_path

    while current_path ~= "/" and current_path ~= "" do
        for _, pattern in ipairs(patterns) do
            local test_path = current_path .. "/" .. pattern
            if vim.fn.isdirectory(test_path) == 1 or vim.fn.filereadable(test_path) == 1 then
                return current_path
            end
        end

        local parent = vim.fn.fnamemodify(current_path, ":h")
        if parent == current_path then
            break -- Reached root
        end
        current_path = parent
    end

    return nil
end

-- Get relative path from project root
function M.get_relative_path_from_root(dir_path, project_root)
    if not project_root or project_root == "" then
        return vim.fn.fnamemodify(dir_path, ":t")
    end

    local relative = dir_path:sub(#project_root + 1)
    -- Remove leading slash
    if relative:sub(1, 1) == "/" then
        relative = relative:sub(2)
    end

    return relative
end

-- Normalize path separators to forward slashes
function M.normalize_path(path)
    return path:gsub("\\", "/")
end

-- Split path into components
function M.split_path(path)
    local normalized = M.normalize_path(path)
    local parts = {}
    for part in normalized:gmatch("[^/]+") do
        if part ~= "" then
            table.insert(parts, part)
        end
    end
    return parts
end

-- Join path components
function M.join_path(...)
    local parts = { ... }
    local path = table.concat(parts, "/")
    return M.normalize_path(path)
end

-- Check if path exists
function M.path_exists(path)
    return vim.fn.isdirectory(path) == 1 or vim.fn.filereadable(path) == 1
end

-- Get parent directory
function M.get_parent_dir(path)
    return vim.fn.fnamemodify(path, ":h")
end

-- Get directory name (last component)
function M.get_dir_name(path)
    return vim.fn.fnamemodify(path, ":t")
end

-- Convert string to proper case (capitalize first letter)
function M.to_proper_case(str)
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end

-- Convert string to camelCase
function M.to_camel_case(str)
    local result = str:gsub("[-_](%w)", function(c) return c:upper() end)
    return result:sub(1, 1):lower() .. result:sub(2)
end

-- Convert string to PascalCase
function M.to_pascal_case(str)
    local result = str:gsub("[-_](%w)", function(c) return c:upper() end)
    return result:sub(1, 1):upper() .. result:sub(2)
end

-- Get filename without extension
function M.get_filename_without_ext(path)
    return vim.fn.fnamemodify(path, ":t:r")
end

-- Get filename with extension
function M.get_filename(path)
    return vim.fn.fnamemodify(path, ":t")
end

-- Escape path for shell usage
function M.escape_path(path)
    return vim.fn.shellescape(path)
end

-- Check if directory is empty
function M.is_dir_empty(path)
    if vim.fn.isdirectory(path) == 0 then
        return false
    end

    local files = vim.fn.glob(path .. "/*", false, true)
    local hidden_files = vim.fn.glob(path .. "/.*", false, true)

    -- Filter out . and .. entries
    hidden_files = vim.tbl_filter(function(file)
        local name = M.get_filename(file)
        return name ~= "." and name ~= ".."
    end, hidden_files)

    return #files == 0 and #hidden_files == 0
end

-- Get unique filename if file already exists
function M.get_unique_filename(base_path)
    if vim.fn.filereadable(base_path) == 0 then
        return base_path
    end

    local dir = M.get_parent_dir(base_path)
    local name = M.get_filename_without_ext(base_path)
    local ext = M.get_file_extension(base_path)

    local counter = 1
    local new_path

    repeat
        local new_name = string.format("%s_%d", name, counter)
        if ext ~= "" then
            new_path = M.join_path(dir, new_name .. "." .. ext)
        else
            new_path = M.join_path(dir, new_name)
        end
        counter = counter + 1
    until vim.fn.filereadable(new_path) == 0

    return new_path
end

-- Validate filename (check for invalid characters)
function M.is_valid_filename(filename)
    -- Check for invalid characters in filename
    local invalid_chars = { "<", ">", ":", '"', "|", "?", "*" }
    for _, char in ipairs(invalid_chars) do
        if filename:find(char, 1, true) then
            return false, "Filename contains invalid character: " .. char
        end
    end

    -- Check for reserved names on Windows
    local reserved_names = {
        "CON", "PRN", "AUX", "NUL",
        "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
        "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
    }

    local base_name = M.get_filename_without_ext(filename):upper()
    for _, reserved in ipairs(reserved_names) do
        if base_name == reserved then
            return false, "Filename is a reserved system name: " .. reserved
        end
    end

    return true, nil
end

-- Get directory completions for the given input text
function M.get_directory_completions(input_text, current_dir)
    current_dir = current_dir or vim.fn.getcwd()

    if not input_text or input_text == "" then
        -- If no input, return directories in current directory
        return M._get_directories_in_path(current_dir)
    end

    -- Parse the input to determine the directory to search and prefix to match
    local last_slash = input_text:find("/[^/]*$")
    local search_dir, prefix

    if last_slash then
        -- Input contains path separators, extract directory part and prefix
        local dir_part = input_text:sub(1, last_slash - 1)
        prefix = input_text:sub(last_slash + 1)

        -- Convert relative path to absolute
        if dir_part:sub(1, 1) == "/" then
            search_dir = dir_part
        elseif dir_part:sub(1, 2) == "~/" then
            search_dir = vim.fn.expand("~") .. dir_part:sub(2)
        else
            search_dir = current_dir .. "/" .. dir_part
        end
    else
        -- No path separators, search in current directory
        search_dir = current_dir
        prefix = input_text
    end

    -- Get directories that match the prefix
    local directories = M._get_directories_in_path(search_dir)
    local completions = {}

    for _, dir in ipairs(directories) do
        if dir:sub(1, #prefix) == prefix then
            local full_completion
            if last_slash then
                full_completion = input_text:sub(1, last_slash) .. dir
            else
                full_completion = dir
            end
            table.insert(completions, full_completion)
        end
    end

    return completions
end

-- Get all directories in the given path (helper function)
function M._get_directories_in_path(path)
    if vim.fn.isdirectory(path) == 0 then
        return {}
    end

    local directories = {}
    local handle = vim.loop.fs_scandir(path)

    if handle then
        while true do
            local name, type = vim.loop.fs_scandir_next(handle)
            if not name then break end

            if type == "directory" and name ~= "." and name ~= ".." then
                -- Skip hidden directories unless they are commonly used development directories
                if name:sub(1, 1) ~= "." or name == ".git" or name == ".github" or name == ".vscode" then
                    table.insert(directories, name)
                end
            end
        end
    end

    table.sort(directories)
    return directories
end

-- Get the longest common prefix of a list of strings
function M.get_common_prefix(strings)
    if #strings == 0 then
        return ""
    end

    if #strings == 1 then
        return strings[1]
    end

    local prefix = strings[1]
    for i = 2, #strings do
        local j = 1
        while j <= #prefix and j <= #strings[i] and prefix:sub(j, j) == strings[i]:sub(j, j) do
            j = j + 1
        end
        prefix = prefix:sub(1, j - 1)

        if prefix == "" then
            break
        end
    end

    return prefix
end

return M
