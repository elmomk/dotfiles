local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
  return
end

-- Check below link for more info on which languages are by default supported:
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics
local code_actions = null_ls.builtins.code_actions

-- https://github.com/prettier-solidity/prettier-plugin-solidity
null_ls.setup {
  debug = false,
  sources = {
    formatting.prettier.with {
      extra_filetypes = { "toml" },
      extra_args = { "--no-semi", "--single-quote", "--jsx-single-quote" },
    },
    -- python
    formatting.black.with { extra_args = { "--fast" } },
    formatting.isort,
    formatting.autoflake,
    diagnostics.flake8,
    diagnostics.yamllint,
    diagnostics.jsonlint,
    -- diagnostics.mypy,
    -- diagnostics.pylint,
    -- lua
    formatting.stylua,
    -- java
    -- formatting.google_java_format,
    -- rust
    formatting.rustfmt,
    -- golang
    formatting.gofmt,
    formatting.gofumpt,
    formatting.goimports,
    formatting.goimports_reviser,
    diagnostics.staticcheck,
    -- terraform
    formatting.terraform_fmt,
    -- shell
    formatting.shfmt,
    formatting.beautysh,
    diagnostics.shellcheck,
    --  opa
    diagnostics.opacheck,
    -- formatting.codespell,
    -- null_ls.builtins.completion.spell.with { filetypes = { "markdown", "text" } },
    code_actions.shellcheck,
    code_actions.gomodifytags,
  },
}
