local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
  return
end

local dashboard = require "alpha.themes.dashboard"
dashboard.section.header.val = {

[[8 888888888o.          ,o888888o.    8 888888888o   ]],
[[8 8888    `^888.      8888     `88.  8 8888    `88. ]],
[[8 8888        `88. ,8 8888       `8. 8 8888     `88 ]],
[[8 8888         `88 88 8888           8 8888     ,88 ]],
[[8 8888          88 88 8888           8 8888.   ,88' ]],
[[8 8888          88 88 8888           8 888888888P'  ]],
[[8 8888         ,88 88 8888           8 8888         ]],
[[8 8888        ,88' `8 8888       .8' 8 8888         ]],
[[8 8888    ,o88P'      8888     ,88'  8 8888         ]],
[[8 888888888P'          `8888888P'    8 8888         ]],

-- [[ _____     ______     ______   ]],
-- [[/\  __-.  /\  ___\   /\  == \  ]],
-- [[\ \ \/\ \ \ \ \____  \ \  _-/  ]],
-- [[ \ \____-  \ \_____\  \ \_\    ]],
-- [[  \/____/   \/_____/   \/_/    ]],

-- [[  ;                               ]],
-- [[  ED.                             ]],
-- [[  E#Wi               .,           ]],
-- [[  E###G.            ,Wt t         ]],
-- [[  E#fD#W;          i#D. ED.       ]],
-- [[  E#t t##L        f#f   E#K:      ]],
-- [[  E#t  .E#K,    .D#i    E##W;     ]],
-- [[  E#t    j##f  :KW,     E#E##t    ]],
-- [[  E#t    :E#K: t#f      E#ti##f   ]],
-- [[  E#t   t##L    ;#G     E#t ;##D. ]],
-- [[  E#t .D#W;      :KE.   E#ELLE##K:]],
-- [[  E#tiW#G.        .DW:  E#L;;;;;;,]],
-- [[  E#K##i            L#, E#t       ]],
-- [[  E##D.              jt E#t       ]],
-- [[  E#t                             ]],
-- [[  L:                              ]],

-- [[DDDDDDDDDDDDD                CCCCCCCCCCCCCPPPPPPPPPPPPPPPPP   ]],
-- [[D::::::::::::DDD          CCC::::::::::::CP::::::::::::::::P  ]],
-- [[D:::::::::::::::DD      CC:::::::::::::::CP::::::PPPPPP:::::P ]],
-- [[DDD:::::DDDDD:::::D    C:::::CCCCCCCC::::CPP:::::P     P:::::P]],
-- [[  D:::::D    D:::::D  C:::::C       CCCCCC  P::::P     P:::::P]],
-- [[  D:::::D     D:::::DC:::::C                P::::P     P:::::P]],
-- [[  D:::::D     D:::::DC:::::C                P::::PPPPPP:::::P ]],
-- [[  D:::::D     D:::::DC:::::C                P:::::::::::::PP  ]],
-- [[  D:::::D     D:::::DC:::::C                P::::PPPPPPPPP    ]],
-- [[  D:::::D     D:::::DC:::::C                P::::P            ]],
-- [[  D:::::D     D:::::DC:::::C                P::::P            ]],
-- [[  D:::::D    D:::::D  C:::::C       CCCCCC  P::::P            ]],
-- [[DDD:::::DDDDD:::::D    C:::::CCCCCCCC::::CPP::::::PP          ]],
-- [[D:::::::::::::::DD      CC:::::::::::::::CP::::::::P          ]],
-- [[D::::::::::::DDD          CCC::::::::::::CP::::::::P          ]],
-- [[DDDDDDDDDDDDD                CCCCCCCCCCCCCPPPPPPPPPP          ]],

-- [[__/\\\\\\\\\\\\___________/\\\\\\\\\__/\\\\\\\\\\\\\___        ]],
-- [[ _\/\\\////////\\\______/\\\////////__\/\\\/////////\\\_       ]],
-- [[  _\/\\\______\//\\\___/\\\/___________\/\\\_______\/\\\_      ]],
-- [[   _\/\\\_______\/\\\__/\\\_____________\/\\\\\\\\\\\\\/__     ]],
-- [[    _\/\\\_______\/\\\_\/\\\_____________\/\\\/////////____    ]],
-- [[     _\/\\\_______\/\\\_\//\\\____________\/\\\_____________   ]],
-- [[      _\/\\\_______/\\\___\///\\\__________\/\\\_____________  ]],
-- [[       _\/\\\\\\\\\\\\/______\////\\\\\\\\\_\/\\\_____________ ]],
-- [[        _\////////////___________\/////////__\///______________]],

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
  return "Created by Mo\nBased on chrisatmachine.com"
end

dashboard.section.footer.val = footer()

dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "Include"
dashboard.section.buttons.opts.hl = "Keyword"

dashboard.opts.opts.noautocmd = true
alpha.setup(dashboard.opts)
