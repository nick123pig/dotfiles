-- nvim-tree: the sidebar file explorer that replaces netrw.
--
-- nvim-web-devicons is listed as a dependency even when have_nerd_font is
-- false. It costs nothing when the icons are switched off below, and it means
-- flipping the toggle in init.lua takes effect on the next launch rather than
-- needing a :Lazy sync first.

local nerd = vim.g.have_nerd_font

return {
    "nvim-tree/nvim-tree.lua",
    version = "*", -- track tagged releases rather than master
    lazy = false,  -- must load at startup: hijack_directories only works if the
                   -- plugin is already there when `nvim .` opens the directory
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
        { "<leader>f", "<cmd>NvimTreeFindFile<cr>", desc = "Reveal current file in explorer" },
    },
    opts = {
        hijack_cursor = true, -- keep the cursor on the filename rather than at
                              -- column 0, so the highlighted row reads properly
        sync_root_with_cwd = true,   -- :cd moves the tree root too
        respect_buf_cwd = true,
        update_focused_file = {
            enable = true,           -- highlight the buffer you are editing
            update_root = false,     -- ...but never silently re-root the tree
                                     -- because you opened a file elsewhere
        },
        view = {
            width = 34,
            preserve_window_proportions = true, -- opening the tree does not
                                                -- resize your other splits
        },
        renderer = {
            group_empty = true,      -- collapse a/b/c chains into one row
            highlight_git = true,
            indent_markers = { enable = true },
            icons = {
                show = {
                    file = nerd,
                    folder = nerd,
                    folder_arrow = nerd,
                    git = true,      -- the git glyphs below are plain
                                     -- punctuation, so they render in any font
                },
                glyphs = {
                    git = nerd and {} or {
                        unstaged = "~", staged = "+", unmerged = "!",
                        renamed = ">", untracked = "?", deleted = "-",
                        ignored = ".",
                    },
                },
            },
        },
        filters = {
            dotfiles = false,        -- this is a dotfiles repo; hiding them
                                     -- would defeat the point
            git_ignored = false,
        },
        git = { enable = true },
        actions = {
            open_file = {
                quit_on_open = false,
                window_picker = { enable = true }, -- with 2+ splits open, prompt
                                                   -- for the target instead of
                                                   -- guessing
            },
        },
        diagnostics = { enable = true },
    },
}
