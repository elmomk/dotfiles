-- Shorten function name
local keymap = vim.keymap.set
-- Silent keymap option
-- local opts = { silent = true }

-- dap
keymap("n", "<leader>dc", ":lua require('dap').continue()<CR>", { silent = true })
keymap("n", "<leader>dr", ":lua require('dap').run_to_cursor()<cr>")
keymap("n", "<leader>de", ":lua require('dapui').eval(vim.fn.input '[Expression] > ')<cr>")
keymap("n", "<leader>db", ":lua require('dap').set_breakpoint(vim.fn.input '[Condition] > ')<cr>")
keymap("n", "<leader>dt", ":lua require('dapui').toggle()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').step_back()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').continue()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').disconnect()<cr>")
-- keymap("n", "<leader>d", ":lua require('dapui').eval()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').session()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap.ui.widgets').hover()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap.ui.widgets').scopes()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').step_into()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').step_over()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').pause.toggle()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').close()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').repl.toggle()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').continue()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').toggle_breakpoint()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').terminate()<cr>")
-- keymap("n", "<leader>d", ":lua require('dap').step_out()<cr>")
