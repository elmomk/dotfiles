local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
	return
end

local shengri = {
[[                                                        *          ]],
[[                                                                   ]],
[[          .             OO           *                  .          ]],
[[                *       OO                  .     /|               ]],
[[                  OO    OO      .               /  |               ]],
[[                  OOOOOOOOOOOOO          .     |    \              ]],
[[                  OOOOOOOOOOOOO               . \    |             ]],
[[                 OO     OO                  *    |  /     *        ]],
[[                OO      OO      .        :       |/        .       ]],
[[                O       OO                    OOOOOOOOOOOO   . .   ]],
[[                        OO             .     OOOOOOOOOOOOO         ]],
[[              ..  OOOOOOOOOOOOO     .        OO         OO         ]],
[[               .        OO   OO     *        OO         OO    .   *]],
[[       *                OO                   OO         OO         ]],
[[             .  .       OO    .         .    OO.         O  .      ]],
[[                        OO                   OOOOOOOOOOOOO         ]],
[[                        OO                   OOOOOOOOOOOOO     .   ]],
[[                        OO                   OOOOOOOOOOOOO     .   ]],
[[              OOOOOOOOOOOOOOOOOOOOOOO        OO         OO         ]],
[[              OO                OOOO         OO         OO         ]],
[[                                    .        OO         OO         ]],
[[                  .     OO                   OO         OO     .   ]],
[[                        OO   OO    OO   .    OOOOOOOOOOOOO  .      ]],
[[                        OO   OO    OO   .    OOOOOOOOOOOO    .     ]],
[[                     OO OO   OO    OO                       O      ]],
[[                     OO OO   OO OOOOOOOOO                  OO      ]],
[[                     OO OO   OO OO OO  OO    .      O      OO    OO   ]],
[[                     OO OO  OO     OO  OO  *      OOOO  OOOOOO  OOOO  ]],
[[               .     OO OO  O      OO  OO    .   OO  OO OO  OO OO  OO ]],
[[                     OO OO O       O   OO  .     OO  OO O    O  OOOO  ]],
[[                      OOOO O  OOOOOOOOOOOOOOO      OOO  OOOOOO   OOO  ]],
[[                        OOOO      OO     OOOO     OO OO OO   O  OO OO ]],
[[                        OOOO .    O..       .    OO  OO OO   O OO  OO ]],
[[                        OO       OO OOO           OOOOO OOOOOO  OOOO  ]],
[[                    .   OO      OO   OOO                  O      .    ]],
[[                        OO .   OO      OO      .          OO          ]],
[[                        OO    OOO       OO      OOOOOOOOOOOOOOOOOOOO  ]],
[[              .         OO    O          OO    OOOO  .    OO     OOOOOO ]],
[[                        OO           .                 O  OO  O     OO  ]],
[[                                                     OOO  OO  OO        ]],
[[                                                   OOOO   OO   OOO      ]],
[[                                         *        OOO     OO    OOO     ]],
[[                                                   O      OO      O     ]],
[[                                                               .        ]],
[[                                                       * -jurcy         ]],
}

local long = {
[[                         xxxxxx       xxxx                              ]],
[[                           xxx        xxxx                              ]],
[[                            x         xxxx                              ]],
[[                 xxxxxxxxxxxxxxxxxxxx xxxxxxxxxxxxxxxxxxx              x]],
[[                      xxxx    xxxx    xxxx                        x     ]],
[[               xxx    xxx     xxxxxxxxxxxxxxx         x                 ]],
[[                        xx    xx                 xxxx      x            ]],
[[    x      xxxxxxxxxxxxxxxxxxxxxxxxxx xxxxxxxxxxxxxxx     x             ]],
[[        x             xxxxxxxxxxxx    xxxx                 x            ]],
[[          x           xxxx    xxxx    xxxxxxxxxxxxx          x          ]],
[[           x          xxxxxxxxxxxx    xxxx                x             ]],
[[          x           xxxx    xxxx    xxxxxxxxxxxxx                x    ]],
[[       x              xxxxxxxxxxxx    xxxx                           xx ]],
[[     xx               xxxx    xxxx    xxxxxxxxxxxxx                  xxx]],
[[    xxx              xxxx  x  xxxx    xxxx                         xxxxx]],
[[     xxxx          xxxx     xxxxx      xxxx                     xxxxxx  ]],
[[       xxxxxxxxxxxxx         xxx         xxxxxxxxxxxxxxxxxxxxxxxxx      ]],
}

local jiayou = {
[[                 .;.                     .               .;.           ]],
[[                ;;;;;                   ;;;             ;;;;;          ]],
[[                ;;;;;                   ;;;;            ;;;;;          ]],
[[                ;;;;;                    ;;;            ;;;;;          ]],
[[                ;;;;;                    ;;;            ;;;;;          ]],
[[                ;;;;    ..                ;;            ;;;;       ;;. ]],
[[       ;;;;;;;;;;;;;;;;;;;,                       ;;;;;;;;;;;;;;;;;;;;.]],
[[       .;;;;;;;;;;;;;;;;;.                   ;    .;;;;;;;;;;;;;;;;;;;.]],
[[              .;;;;   ;;;  .      .         ;;     ;;   ;;;;      ;;;. ]],
[[              .;;;;   ;;.  ;;;;;;;;.      ;;;.     ;;   ;;;;      ;;;  ]],
[[              .;;;    ;;   ;;    ;;      ;;;;      ;;   ;;;.      ;;;  ]],
[[              ,;;;    ;;   ;;    ;;      .;;       ;;   ;;;       ;;;  ]],
[[              ;;;     ;;   ;;   `;;           ;    ;;;;;;;;;;;;;;;;;;  ]],
[[             ;;;      ;;   ;;;;;;.          ;;;    ;;;;;;;;;;;;;;`;;;  ]],
[[            ;;;       ;;                   ;;;;    ;;   ;;        ;;.  ]],
[[           ;;         ;;                  ;;;;.    .;   ;;        ;;   ]],
[[          ;;        ` ;;                 ;;;;.      ;   ;;      `;;;   ]],
[[         ;.          ;;;                ;;;;;       ;;;;;;;;;;;;;;     ]],
[[        ;             ;.                .;;.        .;;;;;;;;;;;;.     ]],
[[                                                                       ]],
[[                                                           liza 4.19.94]],
}

local chunjie = {
	[[             ?                       ?           ]],
	[[           #####                   #####         ]],
	[[          (SPRING)               ( FESTIVAL )    ]],
	[[       ###       ###           ###       ###     ]],
	[[     #      ||       #       #    ||   ||    #   ]],
	[[   #    ==========     #    #   ===========    # ]],
	[[  #       ==||==        # #       ||   ||       #]],
	[[  #    ============     # #    ==============   #]],
	[[  #       //  \\        # #          ||    ||   #]],
	[[  #     //|====|\\      # #          ||    ||   #]],
	[[   #  // ||====|| \\   #   #         ||   ==   # ]],
	[[    #    ||====||     #     #        ||       #  ]],
	[[       ###       ###           ###       ###     ]],
	[[         #########               #########       ]],
	[[           |||||                   |||||         ]],
	[[           |||||                   |||||         ]],
	[[          /////                   /////          ]],
	[[         /////                   /////           ]],
	[[                                                                          ]],
}
local ren = {
	[[          ____________________________________________________________  ]],
	[[         / o                                                        o \ ]],
	[[         |                                                            | ]],
	[[         |                          _ap@@@@@@b                        | ]],
	[[         |                     _ap@@@@@@@@@@@@@b                      | ]],
	[[         |                  @@@@@@P@@@P     ~@@@i                     | ]],
	[[         |                   ~~~~   @@@      @@@I                     | ]],
	[[         |                   ,qq,   @@@      @@@I                     | ]],
	[[         |                   ~~P@b,d@@      d@@@                      | ]],
	[[         |                       .d@@    ._d@@@                       | ]],
	[[         |                     .aPP       ~@@P                        | ]],
	[[         |                  .       ,_          .__                   | ]],
	[[         |                dP   @     @@b   _,     ~P@be.              | ]],
	[[         |               @@   I@      P@@@@@~   e_  ~P@@b             | ]],
	[[         |              @@@    @@b     `~~'     I@b   @@@             | ]],
	[[         |              `@P     @@@@eeeeeeeeeee@@@'   P~              | ]],
	[[         |                        ~~~PPPPPPPPPPP~                     | ]],
	[[         |                                                            | ]],
	[[         |                                                            | ]],
	[[         |         P  .  A  .  T  .  I  .  E  .  N  .  C  .  E        | ]],
	[[         |                                                            | ]],
	[[         | o                                                        o | ]],
	[[         \____________________________________________________________/ ]],
	[[                                                                        ]],
}

local meng = {
	[[                                                            ]],
	[[                   The key to happiness is ha               ]],
	[[                   h                        v               ]],
	[[                   e        |      |        i               ]],
	[[                      ------|------|------  n               ]],
	[[                   k     ___|______|___     g               ]],
	[[                   e     |   |    |   |                     ]],
	[[                   y     |___|____|___|     d               ]],
	[[                       /-----------------/  r               ]],
	[[                   t  /     /________   /   e               ]],
	[[                   o      _/        /       a               ]],
	[[                             \     /        m               ]],
	[[                   s           \ /          s               ]],
	[[                   u           /            .               ]],
	[[                   c     ____/              e               ]],
	[[                   c                        u               ]],
	[[                   ess is making them come tr        Dvd '94]],
	[[                                                            ]],
}

local movim = {
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
}

local movim1 = {
	[[         ,8.       ,8.           ,o888888o.               `8.`888b           ,8'  8 8888          ,8.       ,8.           ]],
	[[        ,888.     ,888.       . 8888     `88.              `8.`888b         ,8'   8 8888         ,888.     ,888.          ]],
	[[       .`8888.   .`8888.     ,8 8888       `8b              `8.`888b       ,8'    8 8888        .`8888.   .`8888.         ]],
	[[      ,8.`8888. ,8.`8888.    88 8888        `8b              `8.`888b     ,8'     8 8888       ,8.`8888. ,8.`8888.        ]],
	[[     ,8'8.`8888,8^8.`8888.   88 8888         88               `8.`888b   ,8'      8 8888      ,8'8.`8888,8^8.`8888.       ]],
	[[    ,8' `8.`8888' `8.`8888.  88 8888         88                `8.`888b ,8'       8 8888     ,8' `8.`8888' `8.`8888.      ]],
	[[   ,8'   `8.`88'   `8.`8888. 88 8888        ,8P                 `8.`888b8'        8 8888    ,8'   `8.`88'   `8.`8888.     ]],
	[[  ,8'     `8.`'     `8.`8888.`8 8888       ,8P                   `8.`888'         8 8888   ,8'     `8.`'     `8.`8888.    ]],
	[[ ,8'       `8        `8.`8888.` 8888     ,88'                     `8.`8'          8 8888  ,8'       `8        `8.`8888.   ]],
	[[,8'         `         `8.`8888.  `8888888P'                        `8.`           8 8888 ,8'         `         `8.`8888.  ]],
}

-- local dashboard = require("alpha.themes.dashboard")
-- local function switch_ascii_art()
-- 	local ascii_arts = { chunjie, ren, meng, movim, movim1 }
-- 	dashboard.section.header.val = ascii_arts[random_index]
-- end
require("os")
require("math")

local dashboard = require("alpha.themes.dashboard")
local function switch_ascii_art()
	local ascii_arts = { ren, meng, movim, movim1, jiayou, long }
  local current_month = tonumber(os.date("%m"))
  if current_month == 1 then
    dashboard.section.header.val = chunjie
  elseif current_month == 12 then
    dashboard.section.header.val = shengri
  else
	  local asciiarts_index = math.random(#ascii_arts)
    dashboard.section.header.val = ascii_arts[asciiarts_index]
  end
  end
-- dashboard.section.header.val = ren
switch_ascii_art()
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
