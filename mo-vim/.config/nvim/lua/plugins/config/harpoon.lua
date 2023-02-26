-- Shorten function name
local keymap = vim.keymap.set
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
