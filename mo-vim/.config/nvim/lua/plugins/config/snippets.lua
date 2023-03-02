require("luasnip").filetype_extend("bash", { "shell" })
require("luasnip").filetype_extend("markdown", { "markdown" })
require("luasnip").filetype_extend("golang", { "go" })
require("luasnip").filetype_extend("python", { "python" })
require("luasnip").filetype_extend("rust", { "rust" })
require("luasnip").filetype_extend("yaml", { "kubernetes" })
require("luasnip").filetype_extend("html", { "html" })
require("luasnip").filetype_extend("make", { "make" })

require("luasnip").filetype_extend("yaml", { "docker-compose" }) -- not yet working
require("luasnip").filetype_extend("dockerfile", { "docker_file" }) -- not yet working

require("luasnip.loaders.from_vscode").load({ paths = { "./snippets" } })
-- require("luasnip.loaders.from_vscode").lazy_load({ paths = { "~/.config/nvim/snippets" } })

-- -- lua snippet example  https://sbulav.github.io/vim/neovim-setting-up-luasnip/
-- local ls = require("luasnip")
--
-- -- some shorthands...
-- local snip = ls.snippet
-- local node = ls.snippet_node
-- local text = ls.text_node
-- local insert = ls.insert_node
-- local func = ls.function_node
-- local choice = ls.choice_node
-- local dynamicn = ls.dynamic_node
--
-- local date = function() return {os.date('%Y-%m-%d')} end
--
-- ls.add_snippets(nil, {
--     all = {
--         snip({
--             trig = "mydate",
--             namr = "Date",
--             dscr = "Date in the form of YYYY-MM-DD",
--         }, {
--             func(date, {}),
--         }),
--     },
-- })
