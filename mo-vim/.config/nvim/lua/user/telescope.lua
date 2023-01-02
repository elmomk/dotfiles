local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local actions = require "telescope.actions"

-- pcall(require('telescope').load_extension, 'fzf')

pcall(require('telescope').load_extension, 'git_worktree')
telescope.setup {
  defaults = {

    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "smart" },

    file_ignore_patterns = { ".git/", "node_modules", "venv" },
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        mirror = false,
      },
      vertical = {
        mirror = false,
      },
    },

    mappings = {
      i = {
        ["<Down>"] = actions.cycle_history_next,
        ["<Up>"] = actions.cycle_history_prev,
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    },
    project = {
      base_dirs = {
        {"~/Documents/git", max_depth = 4},
        "~/Documents",
      },
      hidden_files = true,
      theme = "dropdown",
      order_by = "asc",
      sync_with_nvim_tree = true,
    }
  },
}
-- pcall(require("telescope").load_extension, 'harpoon')
-- require'telescope'.extensions.project.project{}
