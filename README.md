# myconf

My dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap a new machine

1. Install chezmoi, then:

```sh
chezmoi init --apply git@github.com:rbgarga/myconf.git
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

`.chezmoiignore` uses the profile and OS to decide which files are
installed (e.g. sway/i3status/wallpapers only on desktop hosts,
XCompose/login_conf only on FreeBSD).

## Toolchain

`chezmoi apply` installs the LazyVim toolchain automatically (hashed
`run_onchange` scripts — they run only when the package list changes):

- **macOS**: Homebrew (`brew install` from `.brew-packages`). Errors with
  instructions if brew or the Xcode CLT are missing.
- **FreeBSD**: `pkg install` from `.pkg-packages`. Adjust `php84` to the PHP
  version you target. `hadolint` is not available (not in ports; Mason
  prebuilt binaries are Linux/macOS-only) — everything else is covered by
  system packages.
- **Ubuntu/Debian**: `apt-get` (`.apt-packages`) plus `bob`, the nvim version
  manager, since distro nvim (noble: 0.9.x, trixie: 0.10.x) is too old for
  current LazyVim. bob lives in `~/bin` and `bob use stable` leaves the
  active nvim shim in `~/bin`, ahead of `/usr/bin` in PATH (prezto zprofile).
  An existing node installation (e.g. NodeSource, which bundles npm and
  conflicts with the distro `npm` package) is detected and respected.
- **Chimera Linux**: `apk add` (`.apk-packages`) via `doas` (falls back to
  `sudo`). Chimera is musl-based — Mason's glibc prebuilt binaries mostly
  won't run, so expect degraded LSP/formatter coverage and rely on system
  packages where the ports carry them.

Mason handles per-language tools (stylua, shfmt, formatters, LSPs) inside
nvim; system packages provide the toolchains they need (go, node, python,
php).

Terminal notes: nvim mouse selection requires mouse reporting enabled in the
terminal (iTerm2 enables it by default; make sure "Disable session-initiated
mouse reporting" is off, and that "Automatically Enable Alternate Mouse
Scroll" isn't intercepting wheel events). The Ghostty config is deployed on
desktop hosts via `~/.config/ghostty/config`.

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
- `dot_bin/` — helper scripts; `hook_ctags.sh` is kept but no longer
  wired into git template hooks
- `.chezmoiscripts/` — onetime/onchange system tweaks (polkit rules and the
  poudriere nginx config on FreeBSD; the nginx config is templated with each
  host's FQDN)
- `pkg_list` — reference file, not installed
