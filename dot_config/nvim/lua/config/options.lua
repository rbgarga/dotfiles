-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.autoformat = false
vim.opt.background = "dark"
vim.opt.colorcolumn = "80"
vim.opt.cursorline = true
vim.opt.expandtab = false
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.incsearch = true
vim.opt.modeline = true
vim.opt.mouse = "a"
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.shiftwidth = 8
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.softtabstop = 8
vim.opt.tabstop = 8
vim.opt.undofile = true

-- Copy yanked lines to clipboard, even through SSH
local sysname = vim.uv.os_uname().sysname:lower() or ""

if sysname ~= "darwin" then
  vim.o.clipboard = "unnamedplus"
  vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
      -- vim.highlight.on_yank()
      local copy_to_unnamedplus = require("vim.ui.clipboard.osc52").copy("+")
      copy_to_unnamedplus(vim.v.event.regcontents)
      local copy_to_unnamed = require("vim.ui.clipboard.osc52").copy("*")
      copy_to_unnamed(vim.v.event.regcontents)
    end,
  })
end
