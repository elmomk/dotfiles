-- local colorscheme = "tokyonight"
-- require("tokyonight").setup({
--   style = "night",
--   transparent = false,
-- })
require("kanagawa").setup({
  transparent = false,
})

local colorscheme = "kanagawa"

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  return
end
