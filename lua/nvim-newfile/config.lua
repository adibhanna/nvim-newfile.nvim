-- Configuration module for nvim-newfile
local M = {}

-- Default configuration
M.defaults = {
    -- Language-specific settings
    languages = {
        go = {
            enabled = true,
            package_format = "package %s",
            use_directory_name = true,
            file_extensions = { "go" },
        },
        php = {
            enabled = true,
            package_format = "<?php\n\nnamespace %s;",
            use_directory_name = false, -- PHP uses full namespace path
            file_extensions = { "php" },
        },
        java = {
            enabled = true,
            package_format = "package %s;",
            use_directory_name = false,
            file_extensions = { "java" },
        },
        csharp = {
            enabled = true,
            package_format = "namespace %s\n{",
            use_directory_name = false,
            file_extensions = { "cs" },
        },
        kotlin = {
            enabled = true,
            package_format = "package %s",
            use_directory_name = false,
            file_extensions = { "kt", "kts" },
        },
        scala = {
            enabled = true,
            package_format = "package %s",
            use_directory_name = false,
            file_extensions = { "scala" },
        },
        rust = {
            enabled = true,
            package_format = "", -- Rust doesn't typically use package declarations at file top
            use_directory_name = false,
            file_extensions = { "rs" },
        },
    },

    -- Project root detection patterns
    project_root_patterns = {
        "go.mod",        -- Go modules
        "composer.json", -- PHP Composer
        "pom.xml",       -- Java Maven
        "build.gradle",  -- Java/Kotlin Gradle
        "build.sbt",     -- Scala SBT
        "package.json",  -- Node.js
        ".git",          -- Git repository
        "Cargo.toml",    -- Rust
        "Makefile",      -- Make-based projects
    },

    -- Directory name transformations
    directory_transforms = {
        -- Convert kebab-case to camelCase for certain languages
        go = function(name) return name end,
        java = function(name) return name:gsub("%-", ".") end,
        kotlin = function(name) return name:gsub("%-", ".") end,
        php = function(name) return name:gsub("%-", "\\") end,
    },

    -- Additional content templates
    templates = {
        go = {
            main = "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello, World!\")\n}\n",
        },
        php = {
            class = "<?php\n\nnamespace %s;\n\nclass %s\n{\n\t// TODO: Implement class\n}\n",
        },
        java = {
            class = "package %s;\n\npublic class %s {\n\t// TODO: Implement class\n}\n",
        },
    },

    -- UI settings
    ui = {
        border_style = "rounded",
        prompt_text = "📝 File name: ",
        width = 60,
        height = 1,
    },

    -- Notification settings
    notifications = {
        enabled = true, -- Show notification when creating files
    },
}

-- Current configuration (starts with defaults)
M.options = vim.deepcopy(M.defaults)

-- Setup function to merge user config with defaults
function M.setup(user_config)
    user_config = user_config or {}
    M.options = vim.tbl_deep_extend("force", M.defaults, user_config)
end

-- Get configuration for a specific language
function M.get_language_config(language)
    return M.options.languages[language]
end

-- Get project root patterns
function M.get_project_root_patterns()
    return M.options.project_root_patterns
end

-- Get directory transform function for language
function M.get_directory_transform(language)
    return M.options.directory_transforms[language] or function(name) return name end
end

-- Get template for language and type
function M.get_template(language, template_type)
    local lang_templates = M.options.templates[language]
    if lang_templates then
        return lang_templates[template_type]
    end
    return nil
end

-- Get UI configuration
function M.get_ui_config()
    return M.options.ui
end

-- Get notification configuration
function M.get_notification_config()
    return M.options.notifications
end

return M
