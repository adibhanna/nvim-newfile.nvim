# nvim-newfile

A Neovim plugin that intelligently creates new files with automatic package/namespace declarations based on directory structure and language context.

Demo: https://x.com/Adib_Hanna/status/1938245952541954496

## Features

- 🎯 **Smart Package Detection**: Automatically generates correct package/namespace declarations based on directory structure
- 🌍 **Multi-Language Support**: Supports Go, PHP, Java, Kotlin, Scala, C#, and more
- 🎨 **Beautiful UI**: Uses [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for an elegant file creation interface
- 🔍 **Project Root Detection**: Intelligently finds project root using common patterns (`go.mod`, `composer.json`, `.git`, etc.)
- ⚙️ **Configurable**: Highly customizable with language-specific settings and templates
- 📁 **Directory Creation**: Automatically creates directories if they don't exist

## Requirements

- Neovim 0.5.0+
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "adibhanna/nvim-newfile.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim"
  },
  config = function()
    require("nvim-newfile").setup({
      -- Optional configuration
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "adibhanna/nvim-newfile.nvim",
  requires = {
    "MunifTanjim/nui.nvim"
  },
  config = function()
    require("nvim-newfile").setup({
      -- Optional configuration
    })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'MunifTanjim/nui.nvim'
Plug 'adibhanna/nvim-newfile.nvim'

" In your init.lua or after/plugin/nvim-newfile.lua
lua require("nvim-newfile").setup({})
```

## Usage

### Commands

- `:NewFile [filename]` - Create a new file with optional filename (relative to working directory)
- `:NewFileHere` - Create a new file in the same directory as the current buffer

### Features

- **Tab Completion**: Press `<Tab>` in the file input popup to autocomplete directory paths
- **Auto Extension Detection**: File extensions are automatically added based on project type
- **Smart Package Generation**: Automatically generates appropriate package/namespace declarations
- **Directory Creation**: Automatically creates directories if they don't exist
- **Laravel Blade Support**: Creates clean Blade templates without PHP tags or namespaces

### Examples

#### Auto Extension Detection
```bash
# In a Go project
:NewFile handler          → creates handler.go with "package main"
:NewFile utils/helper     → creates utils/helper.go with "package utils"

# In a PHP project  
:NewFile UserController   → creates UserController.php with namespace
:NewFile views/index      → creates views/index.blade.php (empty, no PHP tags)

# In a Java project
:NewFile StringUtils      → creates StringUtils.java with package declaration

# In a Rust project
:NewFile handler          → creates handler.rs (clean, no boilerplate)
```

#### Tab Completion
```bash
# Type partial path and press Tab to autocomplete directories
:NewFile src/<Tab>        → shows: components/, utils/, services/
:NewFile src/comp<Tab>    → completes to: src/components/
```

#### Working Directory vs Current File
```bash
# If you're editing /project/src/components/Button.tsx
:NewFile utils.ts         → creates /project/utils.ts (working directory)
:NewFileHere utils.ts     → creates /project/src/components/utils.ts (current file location)
```

#### Package/Namespace Examples
```bash
# Go project in /project/calculations/
:NewFile calculator       → creates calculator.go with "package calculations"

# PHP project in /project/src/Services/Payment/  
:NewFile Processor        → creates Processor.php with "namespace Services\\Payment;"

# Java project in /project/src/main/java/com/example/utils/
:NewFile StringHelper     → creates StringHelper.java with "package com.example.utils;"
```

## Language Support

### Supported Languages

| Language | Extensions    | Package Format                    | Example                        |
| -------- | ------------- | --------------------------------- | ------------------------------ |
| Go       | `.go`         | `package <directory>`             | `package calculations`         |
| PHP      | `.php`        | `<?php\n\nnamespace <namespace>;` | `namespace App\\Services;`     |
| Java     | `.java`       | `package <namespace>;`            | `package com.example.utils;`   |
| Kotlin   | `.kt`, `.kts` | `package <namespace>`             | `package com.example.utils`    |
| Scala    | `.scala`      | `package <namespace>`             | `package com.example.utils`    |
| C#       | `.cs`         | `namespace <namespace>\n{`        | `namespace MyProject.Services` |
| Rust     | `.rs`         | (no package declaration)          | Clean file, no boilerplate     |

### Package/Namespace Generation Rules

- **Go**: Uses the directory name as the package name
- **PHP**: Converts directory path to namespace with backslashes, capitalizes each part
- **Java/Kotlin/Scala**: Converts directory path to dot-separated package, removes common source prefixes
- **C#**: Similar to Java but with proper C# namespace formatting
- **Rust**: Creates clean files without package declarations (follows Rust module system conventions)

## Configuration

### Default Configuration

```lua
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
    -- ... more languages
  },
  
  -- Project root detection patterns
  project_root_patterns = {
    "go.mod", "composer.json", "pom.xml", "build.gradle",
    "build.sbt", "package.json", ".git", "Cargo.toml", "Makefile"
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
    enabled = true, -- Set to false to disable file creation notifications
  },
})
```

### Custom Language Support

You can add support for additional languages:

```lua
require("nvim-newfile").setup({
  languages = {
    rust = {
      enabled = true,
      package_format = "// Module: %s",
      use_directory_name = true,
      file_extensions = { "rs" },
    },
    python = {
      enabled = true,
      package_format = '"""Package: %s"""',
      use_directory_name = false,
      file_extensions = { "py" },
    },
  },
})
```

### Directory Transformations

Customize how directory names are transformed for different languages:

```lua
require("nvim-newfile").setup({
  directory_transforms = {
    go = function(name) return name:gsub("%-", "_") end,
    java = function(name) return name:gsub("%-", ".") end,
  },
})
```

### Notification Settings

Control whether to show notifications when files are created:

```lua
require("nvim-newfile").setup({
  notifications = {
    enabled = false, -- Disable file creation notifications
  },
})
```

By default, the plugin shows a notification like "Created file: example.go" when a file is successfully created. You can disable this by setting `notifications.enabled = false`.

## Key Mappings

The plugin doesn't define any default key mappings. You can add your own convenient key mappings:

```lua
-- Example key mappings (add to your init.lua)
vim.keymap.set("n", "<leader>nf", ":NewFile<CR>", { desc = "Create new file" })
vim.keymap.set("n", "<leader>nh", ":NewFileHere<CR>", { desc = "Create new file here" })
```

## Advanced Features

### Template Support

The plugin includes templates for common file types:

- **Go main files**: Automatically includes basic main function structure
- **Class files**: For PHP, Java, C# files starting with uppercase letters

### Project Root Detection

The plugin intelligently detects project roots by looking for:
- `go.mod` (Go modules)
- `composer.json` (PHP Composer)
- `pom.xml` (Java Maven)
- `build.gradle` (Gradle projects)
- `.git` (Git repositories)
- And more...

### Smart Namespace Generation

- Removes common source directory prefixes (`src/`, `main/`, etc.)
- Handles nested directory structures
- Respects language-specific conventions

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

### Adding Language Support

To add support for a new language:

1. Add language configuration to `lua/nvim-newfile/config.lua`
2. Implement any special namespace generation logic in `lua/nvim-newfile/generators.lua`
3. Add tests and documentation

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for the beautiful UI components
- Inspired by various IDE features for intelligent file creation # nvim-newfile.nvim
