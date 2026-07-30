-- Neovim entry point. Note this is entirely separate from ~/.vimrc: nvim does
-- not read it, and deliberately so - ~/.vimrc still bootstraps vim-plug into
-- ~/.vim/plugged, and letting nvim source it would have vim-plug and lazy.nvim
-- both managing plugins in the same session. The settings below mirror the
-- parts of ~/.vimrc worth keeping; the rest of that file is vim-specific.

--------------------------------------------------------------------------------
-- Leader
--------------------------------------------------------------------------------
-- Must be set BEFORE lazy.nvim loads. Plugin specs declare their keymaps at
-- load time, and <leader> is resolved to whatever mapleader holds at that
-- moment - set it afterwards and every plugin mapping is silently bound to the
-- default backslash instead. Comma matches ~/.vimrc.
vim.g.mapleader = ","
vim.g.maplocalleader = ","

--------------------------------------------------------------------------------
-- Nerd Font
--------------------------------------------------------------------------------
-- Fedora Sway Atomic ships no Nerd Font, and Ghostty here uses the default
-- font, so the private-use codepoints that file-type icons live in would render
-- as tofu boxes. False makes nvim-tree fall back to ASCII markers, which is
-- ugly but legible. To flip this on:
--
--   mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
--   curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
--   unzip -o JetBrainsMono.zip && rm JetBrainsMono.zip && fc-cache -f
--
-- then set `font-family = JetBrainsMono Nerd Font` in ~/.config/ghostty/config
-- and set this to true. A user-local install needs no rpm-ostree layering and
-- no reboot, which is the whole reason to prefer it on an atomic system.
vim.g.have_nerd_font = false

--------------------------------------------------------------------------------
-- netrw
--------------------------------------------------------------------------------
-- nvim-tree replaces netrw, and both want to own the "opened a directory"
-- event. Disabling netrw here - before any plugin loads - is what nvim-tree's
-- own docs require; skip it and `nvim .` races between the two.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

--------------------------------------------------------------------------------
-- Options (carried over from ~/.vimrc)
--------------------------------------------------------------------------------
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.scrolloff = 7
opt.signcolumn = "yes" -- always reserve the gutter, so text does not jump
                       -- sideways the moment a git or diagnostic sign appears

opt.ignorecase = true
opt.smartcase = true -- ignorecase alone makes /Foo match "foo"; smartcase says
                     -- "only ignore case while the pattern is all-lowercase"

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

opt.mouse = "a"
opt.termguicolors = true -- Ghostty is truecolor; without this nvim quantises
                         -- every highlight down to the 256-colour cube
opt.undofile = true      -- persistent undo in ~/.local/state/nvim/undo, which
                         -- is the reason the swap/backup files below are safe
                         -- to drop
opt.backup = false
opt.writebackup = false
opt.swapfile = false

opt.splitright = true
opt.splitbelow = true

-- Clear search highlight. ~/.vimrc binds <leader><cr>; keep it.
vim.keymap.set("n", "<leader><cr>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Window movement without the <C-w> prefix, as in ~/.vimrc.
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })

--------------------------------------------------------------------------------
-- lazy.nvim bootstrap
--------------------------------------------------------------------------------
-- Clones itself into ~/.local/share/nvim/lazy on first launch, so a fresh
-- machine needs nothing beyond `stow dotfiles` and a working git. Plugins live
-- under ~/.local/share/nvim (state, not config) and are therefore NOT in this
-- repo; lazy-lock.json is what pins their versions, and it does live here.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local out = vim.fn.system({
        "git", "clone", "--filter=blob:none", "--branch=stable",
        "https://github.com/folke/lazy.nvim.git", lazypath,
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Every file under lua/plugins/ returning a spec table is picked up
-- automatically, so adding a plugin means adding one file - no central list to
-- keep in sync.
require("lazy").setup({
    spec = { { import = "plugins" } },
    install = { colorscheme = { "habamax" } },
    checker = { enabled = false }, -- no background "updates available" polling;
                                   -- run :Lazy check by hand instead
    change_detection = { notify = false },
})
