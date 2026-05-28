-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- ~/.config/nvim/lua/config/autocmds.lua
vim.filetype.add({
  extension = {
    k = "kcl",
    kcl = "kcl",
  },
  -- Terragrunt: detect terragrunt.hcl and *.hcl in dirs with terragrunt.hcl
  filename = {
    ["terragrunt.hcl"] = "hcl",
  },
})

-- Auto-reload buffers when files are changed externally (e.g. by Claude Code)
-- LazyVim already handles FocusGained/TermClose/TermLeave; this adds BufEnter
-- and CursorHold so changes are picked up even without a focus event.
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("claude_autoreload", { clear = true }),
  callback = function()
    if vim.o.buftype == "" then
      vim.cmd("checktime")
    end
  end,
})
