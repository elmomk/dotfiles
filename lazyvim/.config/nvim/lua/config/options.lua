-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Clean diff filler (blank instead of diagonal hatches)
vim.opt.fillchars:append({ diff = " " })

-- Ensure mise-managed tools (terraform, helm, ansible, terragrunt, kubectl, etc.)
-- are available to LSP servers, linters, and formatters running inside nvim.
local shims = vim.fn.expand("~/.local/share/mise/shims")
if vim.fn.isdirectory(shims) == 1 and not vim.env.PATH:find(shims, 1, true) then
  vim.env.PATH = shims .. ":" .. vim.env.PATH
end
