return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_x, 1, {
      function()
        return require("cc-watcher").statusline()
      end,
      cond = function()
        local ok, watcher = pcall(require, "cc-watcher.watcher")
        return ok and vim.tbl_count(watcher.get_changed_files()) > 0
      end,
    })
  end,
}
