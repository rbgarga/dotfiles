-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local set = vim.keymap.set

-- Navigate through buffers
set("n", "<M-Right>", "<cmd>bn<CR>", { desc = "Next Buffer" })
set("n", "<M-Left>", "<cmd>bp<CR>", { desc = "Previous Buffer" })

-- Delete current buffer and switch to previous one
set("n", "<C-x>", "<cmd>bp | bd #<CR>", { desc = "Delete Current Buffer and Switch" })

-- Insert "CRubicon Communications, LLC ("Netgate")" using <leader>is (Insert Sponsor)
set("n", "<leader>is", 'iRubicon Communications, LLC ("Netgate")<ESC>', { desc = "Insert Netgate Sponsor Text" })
