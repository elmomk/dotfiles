-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = LazyVim.safe_keymap_set

map("i", "jk", "<ESC>", { desc = "Easy escape from insert mode", silent = true })
map(
  "n",
  "<leader>W",
  "<cmd>lua vim.diagnostic.config({ virtual_text = false })<cr>",
  { desc = "Toggle diagnostic virtual text", silent = false }
)
