local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
  return
end

local dashboard = require "alpha.themes.dashboard"
dashboard.section.header.val = {

[[ _____ ______   ________          ___      ___ ___  _____ ______       ]],
[[ |\   _ \  _   \|\   __  \        |\  \    /  /|\  \|\   _ \  _   \    ]],
[[ \ \  \\\__\ \  \ \  \|\  \       \ \  \  /  / | \  \ \  \\\__\ \  \   ]],
[[  \ \  \\|__| \  \ \  \\\  \       \ \  \/  / / \ \  \ \  \\|__| \  \  ]],
[[   \ \  \    \ \  \ \  \\\  \       \ \    / /   \ \  \ \  \    \ \  \ ]],
[[    \ \__\    \ \__\ \_______\       \ \__/ /     \ \__\ \__\    \ \__\]],
[[     \|__|     \|__|\|_______|        \|__|/       \|__|\|__|     \|__|]],
[[                                                                       ]],
[[                                                                       ]],
[[                                                                       ]],
-- [[          .         .                                                                              .         .            ]],
-- [[         ,8.       ,8.           ,o888888o.               `8.`888b           ,8'  8 8888          ,8.       ,8.           ]],
-- [[        ,888.     ,888.       . 8888     `88.              `8.`888b         ,8'   8 8888         ,888.     ,888.          ]],
-- [[       .`8888.   .`8888.     ,8 8888       `8b              `8.`888b       ,8'    8 8888        .`8888.   .`8888.         ]],
-- [[      ,8.`8888. ,8.`8888.    88 8888        `8b              `8.`888b     ,8'     8 8888       ,8.`8888. ,8.`8888.        ]],
-- [[     ,8'8.`8888,8^8.`8888.   88 8888         88               `8.`888b   ,8'      8 8888      ,8'8.`8888,8^8.`8888.       ]],
-- [[    ,8' `8.`8888' `8.`8888.  88 8888         88                `8.`888b ,8'       8 8888     ,8' `8.`8888' `8.`8888.      ]],
-- [[   ,8'   `8.`88'   `8.`8888. 88 8888        ,8P                 `8.`888b8'        8 8888    ,8'   `8.`88'   `8.`8888.     ]],
-- [[  ,8'     `8.`'     `8.`8888.`8 8888       ,8P                   `8.`888'         8 8888   ,8'     `8.`'     `8.`8888.    ]],
-- [[ ,8'       `8        `8.`8888.` 8888     ,88'                     `8.`8'          8 8888  ,8'       `8        `8.`8888.   ]],
-- [[,8'         `         `8.`8888.  `8888888P'                        `8.`           8 8888 ,8'         `         `8.`8888.  ]],
  -- [[                             __                ]],
  -- [[  ___ ___      ___   __  __ /\_\    ___ ___    ]],
  -- [[ / __` __`\   / __`\/\ \/\ \\/\ \  / __` __`\  ]],
  -- [[/\ \/\ \/\ \ /\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
  -- [[\ \_\ \_\ \_\\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
  -- [[ \/_/\/_/\/_/ \/___/  \/__/    \/_/\/_/\/_/\/_/]],
  -- [[                                               ]],
  -- [[                                               ]],
  -- [[                                               ]],
}
dashboard.section.buttons.val = {
  dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
  dashboard.button("e", " " .. " New file", ":ene <BAR> startinsert <CR>"),
  dashboard.button("p", " " .. " Find project", ":lua require('telescope').extensions.projects.projects()<CR>"),
  dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
  dashboard.button("t", " " .. " Find text", ":Telescope live_grep <CR>"),
  dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
  dashboard.button("u", " " .. " Plugins", ":PackerStatus <CR>"),
  dashboard.button("a", " " .. " See Planets", ":Telescope planets<CR>"),
  dashboard.button("m", " " .. " Mason", ":Mason <CR>"),
  dashboard.button("q", " " .. " Quit", ":qa<CR>"),
}
local function footer()
  return "Based on chrisatmachine.com"
end

dashboard.section.footer.val = footer()

dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "Include"
dashboard.section.buttons.opts.hl = "Keyword"

dashboard.opts.opts.noautocmd = true
alpha.setup(dashboard.opts)
