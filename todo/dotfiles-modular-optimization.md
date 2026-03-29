# Dotfiles Modular Optimization — 2026-03-27

Active stack: Hyprland + ZSH + mo-vim. Many machines. Archived packages (i3, leftwm, regolith2, sxhkdrc, fish, lazyvim) left as-is.

---

## P0 — Security & Bugs

- [ ] Remove/vault hardcoded credentials in `scripts/bin/easy.sh` (base64 password)
- [ ] Remove/vault hardcoded credentials in `scripts/bin/scraper_nginx.sh` (HTTP auth)
- [ ] Remove/vault hardcoded credentials in `scripts/bin/nm_update.sh` (password file)
- [ ] Fix `/home/salomo/` → `%h` in `hyprland/.config/systemd/user/cliphist-thumbs-cleanup.service`
- [ ] Fix `/home/sbartholomees/` in `i3/.config/i3/config` (if ever reused)
- [ ] Fix `prefferred` typo in `hyprland/.config/hypr/hyprland.conf:3`
- [ ] Fix `head 5` → `head -n 5` in `zsh/.config/zsh/zsh_aliases` (pscpu alias)
- [ ] Resolve HISTSIZE conflict: `.zshenv` sets 10000 + `$ZDOTDIR/.zhistory`, `.zshrc-zinit` overrides to 5000 + `~/.zsh_history`

## P1 — Create Shared Core Package

- [ ] Create `core/.config/shell/environment.sh` — XDG dirs, EDITOR, PATH (POSIX sh)
- [ ] Create `core/.config/shell/aliases.sh` — consolidated aliases from zsh_aliases, standardized on `eza`
- [ ] Create `core/.config/shell/functions.sh` — consolidated from zsh_functions, deduplicated
- [ ] Move scripts from `scripts/bin/` to `core/bin/` (except credential scripts)
- [ ] Update `zsh/.config/zsh/.zshrc` to source core shell files
- [ ] Delete `zsh/.config/zsh/zsh_aliases` (replaced by core)
- [ ] Delete `zsh/.config/zsh/zsh_functions` (replaced by core)
- [ ] Deduplicate `zsh-personal/.zshrc-fn` — remove functions that moved to core
- [ ] Remove HISTSIZE/HISTFILE overrides from `zsh-personal/.zshrc-zinit`
- [ ] Remove duplicate starship init from `zsh-personal/.zshrc-work`
- [ ] Add compinit caching to `.zshrc` (only regen .zcompdump if >24h old)

## P2 — Mo-vim Cleanup

- [ ] Delete `mo-vim/.config/nvim/lua/plugins/config/cmp.lua` (dead — blink.cmp is active)
- [ ] Rename `mo-vim/.config/nvim/lua/plugins/lsp/settings/sumneko_lua.lua` → `lua_ls.lua`
- [ ] Remove duplicate `cursorcolumn` in `mo-vim/.config/nvim/lua/core/options.lua`
- [ ] Fix claude-code plugin: use git URL instead of absolute local path

## P3 — Hyprland Fixes

- [ ] Re-enable `exec-once = hypridle` in `hyprland/.config/hypr/conf/startup.conf`
- [ ] Add missing deps to `hyprland/.config/hypr/install.sh`: brightnessctl, wireplumber, wofi, brave-beta, fcitx5, blueman, nm-applet, firefox, thunderbird
- [ ] Gitignore waybar `*.bak` files

## P4 — Machine Profiles

- [ ] Create `profiles/workstation.sh` — stow core zsh zsh-personal tmux gitconfig hyprland mo-vim udev
- [ ] Create `profiles/server.sh` — stow core zsh tmux gitconfig
- [ ] Create `profiles/minimal.sh` — stow core zsh gitconfig

## P5 — Future Optimizations

- [ ] Extract theme system from `hyprland/.config/themes/` to `core/` so standalone alacritty/dunst/tmux can reference it
- [ ] Integrate swaync styling into theme system (currently hardcoded Catppuccin)
- [ ] Profile mo-vim startup with `nvim --startuptime`
- [ ] Consider shorter Hyprland animation durations (borders: 5.39s, windows: 4.79s → ~1s)
- [ ] Remove auto-generated fish completions from git (tfctl.fish, kubectl-fish-abbr.fish) if fish is ever cleaned up

---

## Dead Code Reference (not blocking, clean up when touching these files)

| File | Issue |
|------|-------|
| `regolith2_i3/i3_config` | 827 lines, entirely commented |
| `i3/config` | 60% commented |
| `dunst/dunstrc` | 35% commented |
| `gitconfig/.gitconfig` | 60% commented SSH examples |
| `fish/alias.fish` | 628 lines, massive bloat |
| `fish/conf.d/git_abbr.fish` | 439 lines with unused uninstall function |
| `lazyvim/plugins/example.lua` | Entirely commented |
| `hyprland/windowrules.conf` | All rules commented |
