return {
  "elmomk/cc-watcher.nvim",
  event = { "BufReadPost", "BufNewFile" },
  cmd = {
    "ClaudeSidebar",
    "ClaudeDiff",
    "ClaudeSnacks",
    "ClaudeTrouble",
    "ClaudeDiffview",
  },
  keys = {
    { "<leader>cs", desc = "Claude - toggle sidebar" },
    { "<leader>cd", desc = "Claude - toggle inline diff" },
    { "<leader>ct", "<cmd>ClaudeSnacks<cr>", desc = "Claude - changed files" },
    { "<leader>ch", "<cmd>ClaudeSnacks hunks<cr>", desc = "Claude - hunks" },
    { "<leader>cx", "<cmd>ClaudeTrouble<cr>", desc = "Claude - trouble" },
    { "<leader>cv", "<cmd>ClaudeDiffview<cr>", desc = "Claude - diffview" },
  },
  opts = {
    integrations = {
      telescope = false,
      fzf_lua = false,
      snacks = true,
      trouble = true,
      diffview = true,
    },
  },
}
