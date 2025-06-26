-- Example configuration for nvim-newfile plugin
-- Place this in your init.lua or in a separate config file

require("nvim-newfile").setup({
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
            use_directory_name = false,
            file_extensions = { "php" },
        },
        java = {
            enabled = true,
            package_format = "package %s;",
            use_directory_name = false,
            file_extensions = { "java" },
        },
        kotlin = {
            enabled = true,
            package_format = "package %s",
            use_directory_name = false,
            file_extensions = { "kt", "kts" },
        },
        csharp = {
            enabled = true,
            package_format = "namespace %s\n{",
            use_directory_name = false,
            file_extensions = { "cs" },
        },
        scala = {
            enabled = true,
            package_format = "package %s",
            use_directory_name = false,
            file_extensions = { "scala" },
        },

        -- Custom language examples
        rust = {
            enabled = true,
            package_format = "// Module: %s\n",
            use_directory_name = true,
            file_extensions = { "rs" },
        },
        python = {
            enabled = true,
            package_format = '"""Package: %s"""\n',
            use_directory_name = false,
            file_extensions = { "py" },
        },
        typescript = {
            enabled = true,
            package_format = "// Namespace: %s\n",
            use_directory_name = false,
            file_extensions = { "ts" },
        },
    },

    -- Project root detection patterns (in order of priority)
    project_root_patterns = {
        "go.mod",         -- Go modules
        "composer.json",  -- PHP Composer
        "pom.xml",        -- Java Maven
        "build.gradle",   -- Java/Kotlin Gradle
        "build.sbt",      -- Scala SBT
        "package.json",   -- Node.js/TypeScript
        ".git",           -- Git repository
        "Cargo.toml",     -- Rust
        "Makefile",       -- Make-based projects
        "pyproject.toml", -- Python projects
        "setup.py",       -- Python setuptools
    },

    -- Directory name transformations for different languages
    directory_transforms = {
        go = function(name)
            -- Convert kebab-case to snake_case for Go
            return name:gsub("%-", "_")
        end,
        java = function(name)
            -- Convert kebab-case to camelCase for Java packages
            return name:gsub("%-(%w)", function(c) return c:upper() end)
        end,
        kotlin = function(name)
            -- Same as Java
            return name:gsub("%-(%w)", function(c) return c:upper() end)
        end,
        php = function(name)
            -- Convert kebab-case to PascalCase for PHP namespaces
            return name:gsub("(%w)([%w]*)", function(first, rest)
                return first:upper() .. rest:lower()
            end):gsub("%-", "")
        end,
        csharp = function(name)
            -- Convert to PascalCase for C#
            return name:gsub("(%w)([%w]*)", function(first, rest)
                return first:upper() .. rest:lower()
            end):gsub("%-", "")
        end,
    },

    -- Additional content templates for specific file types
    templates = {
        go = {
            main = [[package main

import "fmt"

func main() {
	fmt.Println("Hello, World!")
}
]],
            test = [[package %s

import "testing"

func TestExample(t *testing.T) {
	// TODO: Add test implementation
}
]],
        },
        php = {
            class = [[<?php

namespace %s;

class %s
{
    // TODO: Implement class
}
]],
            interface = [[<?php

namespace %s;

interface %s
{
    // TODO: Define interface methods
}
]],
        },
        java = {
            class = [[package %s;

public class %s {
    // TODO: Implement class
}
]],
            interface = [[package %s;

public interface %s {
    // TODO: Define interface methods
}
]],
        },
        typescript = {
            class = [[// Namespace: %s

export class %s {
    // TODO: Implement class
}
]],
            interface = [[// Namespace: %s

export interface %s {
    // TODO: Define interface
}
]],
        },
    },

    -- UI customization
    ui = {
        border_style = "rounded", -- "single", "double", "rounded", "solid", "shadow"
        prompt_text = "📝 File name: ",
        width = 60,
        height = 1,
        -- You can also customize colors (optional)
        -- winhighlight = "Normal:Normal,FloatBorder:Special",
    },
})

-- Optional: Custom command for specific file types
vim.api.nvim_create_user_command("NewGoFile", function(opts)
    local filename = opts.args
    if not filename:match("%.go$") then
        filename = filename .. ".go"
    end
    require("nvim-newfile").create_file(filename)
end, {
    nargs = 1,
    desc = "Create a new Go file",
})

vim.api.nvim_create_user_command("NewPhpClass", function(opts)
    local classname = opts.args
    local filename = classname .. ".php"
    require("nvim-newfile").create_file(filename)
end, {
    nargs = 1,
    desc = "Create a new PHP class file",
})
