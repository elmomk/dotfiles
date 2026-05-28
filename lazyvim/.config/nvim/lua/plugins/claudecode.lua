return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude - toggle terminal" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = { "n", "v" }, desc = "Claude - send selection/file" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude - focus terminal" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude - accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude - reject diff" },
    { "<leader>at", "<cmd>ClaudeCodeTreeAdd<cr>", mode = { "n", "v" }, desc = "Claude - add tree file" },
  },
  opts = {
    terminal = {
      split_side = "right",
      split_width_percentage = 0.35,
      provider = "snacks",
    },
    track_selection = true,
  },
}
