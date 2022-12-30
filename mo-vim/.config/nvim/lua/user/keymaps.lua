-- Shorten function name
local keymap = vim.keymap.set
-- Silent keymap option
local opts = { silent = true }

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)
-- window splitting
keymap("n", "<leader>sv", "<C-w>v", opts) -- split window vertically
keymap("n", "<leader>sh", "<C-w>s", opts) -- split window horizontally
keymap("n", "<leader>se", "<C-w>=", opts) -- split window equal width
keymap("n", "<leader>sx", ":close<CR>", opts) -- split window equal width
-- tabs
-- keymap("n", "<leader>to", ":tabnew<CR>", opts) -- open new tab
-- keymap("n", "<leader>tx", ":tabclose<CR>", opts) -- close current tab
-- keymap("n", "<leader>tn", ":tabn<CR>", opts) -- go to next tab
-- keymap("n", "<leader>tp", ":tabp<CR>", opts) -- go to previous tab
-- Trouble
keymap("n", "<leader>t", ":TroubleToggle<CR>", opts) -- go to previous tab

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Clear highlights
keymap("n", "<leader>h", "<cmd>nohlsearch<CR>", opts)

-- Close buffers
keymap("n", "<S-q>", "<cmd>Bdelete!<CR>", opts)

-- Better paste
keymap("v", "p", '"_dP', opts)
-- move selected line / block of text in visual mode
keymap("v", "J", ":m '>+1<CR>gv=gv'", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv'", opts)

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)
keymap("n", "<leader>w", ":w<CR>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Plugins --

-- theprimeagen setup
keymap("n", "<leader>u", ":UndotreeToggle<CR> :UndotreeFocus<CR>", opts)
-- keymap("n", "gd", ":lua vim.lsp.buf.definition()<CR>", opts) -- already mapped in lsp/handlers.lua

-- harpoon setup
keymap("n", "<leader>a", require("harpoon.mark").add_file)
keymap("n", "<leader>q", require("harpoon.ui").toggle_quick_menu)

-- more then 5 seems a bit over the top
keymap("n", "<leader>1", function()
	require("harpoon.ui").nav_file(1)
end)
keymap("n", "<leader>2", function()
	require("harpoon.ui").nav_file(2)
end)
keymap("n", "<leader>3", function()
	require("harpoon.ui").nav_file(3)
end)
keymap("n", "<leader>4", function()
	require("harpoon.ui").nav_file(4)
end)
keymap("n", "<leader>5", function()
	require("harpoon.ui").nav_file(5)
end)

-- zenmode
keymap("n", "<leader>zz", ":ZenMode<CR>", opts)

-- NvimTree
keymap("n", "<leader>e", ":NvimTreeToggle<CR>", opts)

-- Telescope
keymap("n", "<leader>fo", ":Telescope oldfiles<CR>", opts)
keymap("n", "<leader>ff", ":Telescope find_files<CR>", opts)
keymap("n", "<leader>fv", ":Telescope git_files<CR>", opts)
keymap("n", "<leader>fg", ":Telescope live_grep<CR>", opts)
keymap("n", "<leader>fs", ":Telescope grep_string<CR>", opts)
keymap("n", "<leader>fp", ":Telescope projects<CR>", opts)
keymap("n", "<leader>fb", ":Telescope buffers<CR>", opts)
keymap("n", "<leader>fr", ":Telescope lsp_references<CR>", opts)
keymap("n", "<leader>fj", ":Telescope jumplist<CR>", opts)
keymap("n", "<leader>fm", ":Telescope <CR>", opts)
keymap("n", "<leader><leader>", ":Telescope keymaps<CR>", opts)
-- Glow
keymap("n", "<leader>g", ":Glow<CR>", opts)

-- Git
keymap("n", "<leader>lg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", opts)

-- Comment
keymap("n", "<leader>/", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", opts)
keymap("x", "<leader>/", '<ESC><CMD>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>')

-- Lsp
keymap("n", "<leader>lf", "<cmd>lua vim.lsp.buf.format{ async = true }<cr>", opts)
-- keymap("n", "<leader>lc", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts) -- already mapped in lsp/handlers.lua
