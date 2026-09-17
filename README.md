# dotfiles

My dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap a new machine

On distros without a chezmoi package (e.g. Debian trixie), install the
binary first:

```sh
sudo sh -c 'curl -sfL https://get.chezmoi.io | sh -s -- -b /usr/local/bin'
# or, without sudo (~/bin is in PATH via prezto):
curl -sfL https://get.chezmoi.io | sh -s -- -b "$HOME/bin"
```

1. Install chezmoi, then:

```sh
chezmoi init --apply git@github.com:rbgarga/dotfiles.git
```

chezmoi clones prezto (`rbgarga/prezto`) into `~/.zprezto` and links the
runcoms (`zshrc`, `zshenv`, `zprofile`, `zpreztorc`, `zlogin`, `zlogout`)
into `$HOME`.

2. Open `nvim` once; `lazy.nvim` bootstraps itself and installs plugins.

## Profiles: desktop vs ssh

`.chezmoi.toml.tmpl` holds a central hostname → profile map
(`desktop` or `ssh`). Unknown hosts default to `ssh`, which gets the
minimal config. To add a machine, add its short hostname to the map:

```go
{{- $profiles := dict
      "m2" "desktop"
      "buildbox" "ssh"
-}}
```

The map also holds a `$poudriere` list with the hosts running the
poudriere nginx frontend — only those get `/usr/local/etc/nginx/nginx.conf`.

**After editing the map, run `chezmoi init` once on the affected hosts** —
the config template only renders at init; `chezmoi update` alone will not
re-evaluate it.

`.chezmoiignore` uses the profile and OS to decide which files are
installed (e.g. sway/i3status only on FreeBSD desktop hosts,
XCompose/login_conf only on FreeBSD).

**Shell handoff**: machines whose login shell is managed by IT's
saltstack (reset to bash) load zsh automatically via `~/.bash_profile`
— interactive login shells `exec zsh -l`; non-interactive sessions
(scp, rsync, `ssh <command>`, salt runs) stay in bash.

## Toolchain

`chezmoi apply` installs the LazyVim toolchain automatically (hashed
`run_onchange` scripts — they run only when the package list changes):

- **macOS**: Homebrew (`brew install` from `.brew-packages`). Errors with
  instructions if brew or the Xcode CLT are missing.
- **FreeBSD**: `pkg install` from `.pkg-packages`. `hadolint` is not
  available (not in ports; Mason prebuilt binaries are Linux/macOS-only).
  `gmake` is required to build `telescope-fzf-native.nvim` (the stock
  `make` is bmake, which cannot parse GNU Makefiles); `tree-sitter-cli` is
  required by nvim-treesitter `main`; `gopls`, `lua-language-server`,
  `terraform-ls` and `ruff` provide the LSPs/formatters Mason cannot install
  here.
- **Ubuntu/Debian**: `apt-get` (`.apt-packages`) plus `bob`, the nvim version
  manager, since distro nvim (noble: 0.9.x, trixie: 0.10.x) is too old for
  current LazyVim. bob lives in `~/bin` and `bob use stable` leaves the
  active nvim shim in `~/bin`, ahead of `/usr/bin` in PATH (prezto zprofile).
  An existing node installation (e.g. NodeSource, which bundles npm and
  conflicts with the distro `npm` package) is detected and respected.
- **Chimera Linux**: `apk add` (`.apk-packages`) via `doas` (falls back to
  `sudo`). Chimera is musl-based — Mason's glibc prebuilt binaries mostly
  won't run, so LSPs/formatters come from system packages (`gopls`, `ruff`,
  `tree-sitter-cli`). Not packaged upstream: `shellcheck`,
  `lua-language-server` and a separate `npm` (it is bundled with `nodejs`).

Mason handles per-language tools where binaries exist; system packages
provide the toolchains and the LSPs/formatters Mason cannot install on
FreeBSD/Chimera only — on macOS, Ubuntu/Debian everything comes through
Mason. PHP support is macOS/FreeBSD only.

Terminal notes: nvim mouse selection requires mouse reporting enabled in the
terminal (iTerm2 enables it by default; make sure "Disable session-initiated
mouse reporting" is off, and that "Automatically Enable Alternate Mouse
Scroll" isn't intercepting wheel events). The Ghostty config is deployed on
desktop hosts via `~/.config/ghostty/config`. Inside tmux, clicking a URL
requires `shift+cmd+click`: the shift keeps ghostty from forwarding the
mouse event to tmux, letting it detect and open the link on the mac. For
URLs wrapped across lines inside tmux, use the URL picker (`prefix+u` or
`M-u`): it lists every URL in the pane scrollback and copies the picked
one to the mac clipboard via OSC 52.

## Updating

```sh
chezmoi update     # pull repo + apply
chezmoi edit       # edit a file in the source repo
chezmoi cd         # jump to the source repo
chezmoi diff       # preview pending changes
```

## Layout notes

- `dot_config/nvim/` — LazyVim config (extras in `lazyvim.json`)
- `dot_vimrc`, `dot_vim/` — legacy vim fallback, still deployed everywhere
- `bin/` — helper scripts, deployed to `~/bin` as executables
  (`executable_*` sources); `hook_ctags.sh` is kept but no longer wired
  into git template hooks
- `.chezmoiscripts/` — hashed package installers per OS, the daily tmux
  config reload, and FreeBSD desktop system tweaks (polkit rules and the
  poudriere nginx config, templated with each host's FQDN and gated on the
  `poudriere` flag)
- `pkg_list` — reference file, not installed
