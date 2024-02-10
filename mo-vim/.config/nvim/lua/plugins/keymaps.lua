-- Shorten function name
local keymap = vim.keymap.set
-- Silent keymap option
local opts = { silent = true }

--Remap space as leader key
-- keymap("", "<Space>", "<Nop>", opts)
-- vim.g.mapleader = " "

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
keymap("n", "<leader>sv", "<C-w>v", { silent = true, desc = "vertical split" }) -- split window vertically
keymap("n", "<leader>sh", "<C-w>s", { silent = true, desc = "horizontal split" }) -- split window horizontally
keymap("n", "<leader>se", "<C-w>=", { silent = true, desc = "equal windows out" }) -- split window equal width
keymap("n", "<leader>sx", ":close<CR>", { silent = true, desc = "close window" }) -- split window equal width
-- git worktree
keymap("n", "<leader>sc", "::lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>", opts)
keymap("n", "<leader>sd", "::lua require('telescope').extensions.git_worktree.git_worktrees()<CR>", opts)
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

-- portal
keymap("n", "<leader>p", ":Portal jumplist<CR>", opts)
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
-- Move Lines
keymap("n", "<A-j>", ":m .+1<cr>==", { silent = true, desc = "Move down" })
keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { silent = true, desc = "Move down" })
keymap("i", "<A-j>", "<Esc>:m .+1<cr>==gi", { silent = true, desc = "Move down" })
keymap("n", "<A-k>", ":m .-2<cr>==", { silent = true, desc = "Move up" })
keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { silent = true, desc = "Move up" })
keymap("i", "<A-k>", "<Esc>:m .-2<cr>==gi", { silent = true, desc = "Move up" })

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)
keymap("n", "<leader>w", "<cmd>w<cr><esc>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Plugins --

-- theprimeagen setup
keymap("n", "<leader>u", ":UndotreeToggle<CR> :UndotreeFocus<CR>", opts)
-- keymap("n", "gd", ":lua vim.lsp.buf.definition()<CR>", opts) -- already mapped in lsp/handlers.lua
--
-- Shorten function name
-- local keymap = vim.keymap.set
-- harpoon setup
keymap("n", "<leader>a", require("harpoon.mark").add_file, { silent = false, desc = "add file to harpoon" })
keymap(
	"n",
	"<leader>q",
	require("harpoon.ui").toggle_quick_menu,
	{ silent = false, desc = "toggle harpoon quick menu" }
)
keymap("n", "<leader><leader>q", ":Telescope harpoon marks<CR>", { silent = false, desc = "toggle harpoon quick menu" })

-- more then 5 seems a bit over the top
keymap("n", "<leader>1", function()
	require("harpoon.ui").nav_file(1)
end, { silent = false, desc = "nav to file 1" })
keymap("n", "<leader>2", function()
	require("harpoon.ui").nav_file(2)
end, { silent = false, desc = "nav to file 2" })
keymap("n", "<leader>3", function()
	require("harpoon.ui").nav_file(3)
end, { silent = false, desc = "nav to file 3" })
keymap("n", "<leader>4", function()
	require("harpoon.ui").nav_file(4)
end, { silent = false, desc = "nav to file 4" })
keymap("n", "<leader>5", function()
	require("harpoon.ui").nav_file(5)
end, { silent = false, desc = "nav to file 5" })

-- zenmode
keymap("n", "<leader>zz", ":ZenMode<CR>", opts)

-- NvimTrNeoTreeShowToggleee
keymap("n", "<leader>e", ":Neotree float toggle<CR>", { silent = true, desc = "toggle neotree" })

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
keymap("n", "<leader>fh", ":Telescope help_tags<CR>", opts)
keymap("n", "<leader>r", ":Telescope registers<CR>", opts)
-- bufferline
keymap("n", "<leader>b", ":BufferLinePick<CR>", opts)
keymap("n", "<leader>B", ":BufferLinePickClose<CR>", opts)
-- use gt and gT to jump between recent buffers
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
---- floating terminal
--keymap("n", "<leader>ft", function() Util.float_term(nil, { cwd = Util.get_root() }) end, { desc = "Terminal (ro
--keymap("n", "<leader>fT", function() Util.float_term() end, { desc = "Terminal (cwd)" })
--keymap("t", "<esc><esc>", "<c-\\><c-n>", {desc = "Enter Normal Mode"})

keymap("n", "<leader>ds", ":!wrapcli ls<CR>", { silent = true, desc = "List stacks" })
keymap("n", "<leader>dp", ":!wrapcli plan -e prd -s stack -t tenant ", { silent = false, desc = "plan" })
keymap("n", "<leader>da", ":!wrapcli apply -e prd -s stack -t tenant", { silent = false, desc = "apply" })
-- trivy config ./ -s HIGH
-- keymap("n", "<leader>tv", ":!trivy image --exit-code 1 --severity HIGH --no-progress --format table --ignore-unfixed --ignore-policy --ignorefile .trivyignore .<CR>", { silent = false, desc = "trivy" })

keymap("n", "<leader>gpd", ":lua require('goto-preview').goto_preview_definition()<cr>", { silent = true })
keymap("n", "<leader>gpt", ":lua require('goto-preview').goto_preview_type_definition()<CR>", { silent = true })
keymap("n", "<leader>gpi", ":lua require('goto-preview').goto_preview_implementation()<CR>", { silent = true })
keymap("n", "<leader>gp", ":lua require('goto-preview').close_all_win()<cr>", { silent = true })
keymap("n", "<leader>gpr", ":lua require('goto-preview').goto_preview_references()<cr>", { silent = true })
