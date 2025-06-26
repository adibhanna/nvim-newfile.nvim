-- nvim-newfile plugin
-- Main plugin entry point

if vim.fn.has("nvim-0.5") == 0 then
    vim.api.nvim_err_writeln("nvim-newfile requires at least nvim-0.5")
    return
end

-- Avoid loading twice
if vim.g.loaded_nvim_newfile == 1 then
    return
end
vim.g.loaded_nvim_newfile = 1

-- Create user commands
vim.api.nvim_create_user_command("NewFile", function(opts)
    require("nvim-newfile").create_file(opts.args)
end, {
    nargs = "?",
    desc = "Create a new file with automatic package/namespace declaration",
})

vim.api.nvim_create_user_command("NewFileHere", function()
    require("nvim-newfile").create_file_here()
end, {
    desc = "Create a new file in the current directory with automatic package/namespace declaration",
})
