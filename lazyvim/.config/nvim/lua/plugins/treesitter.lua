return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

      parser_config.kcl = {
        install_info = {
          url = "https://github.com/kcl-lang/tree-sitter-kcl",
          files = { "src/parser.c" },
          branch = "main",
          -- 👇 ADD THESE TWO LINES 👇
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
        filetype = "kcl",
      }

      if type(opts.ensure_installed) == "table" then
        table.insert(opts.ensure_installed, "kcl")
      end
    end,
  },
}
