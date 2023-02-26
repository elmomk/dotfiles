-- use this to disable/enable filetypes fot copilot
vim.g.copilot_filetypes = { xml = false}
vim.g.copilot_enabled = true


vim.cmd[[imap <silent><script><expr> <C-g> copilot#Accept("\<CR>")]]
vim.g.copilot_no_tab_map = true
-- vim.keymap.set.keymap("i", "<C-g>", ":copilot#Accept('\\<CR>')<CR>", {silent = true})



-- vim.cmd[[highlight CopilotSuggestion guifg=#555555 ctermfg=8]]
vim.cmd[[highlight CopilotSuggestionSelected guifg=#ffffff ctermfg=15 gui=bold cterm=bold]]
