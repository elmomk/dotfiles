vim.notify = require("notify")
-- notify when writing to a buffer as done by the vim.api 
-- vim.cmd [[ autocmd BufWritePre * lua vim.notify("Saved " .. vim.fn.expand("%:t"), vim.log.levels.INFO, { title = "Neovim" }) ]]

