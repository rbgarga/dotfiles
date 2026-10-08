# dotfiles

My dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap a new machine

On distros without a chezmoi package (e.g. Debian trixie), install the
binary first:

```sh
sudo sh -c 'curl -sfL https://get.chezmoi.io | sh -s -- -b /usr/local/bin'
# or, without sudo (~/.local/bin is in PATH via prezto):
curl -sfL https://get.chezmoi.io | sh -s -- -b "$HOME/.local/bin"
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
minimal config. To add a machine, add its short hostname to the map
(on macOS the key is the Bonjour `LocalHostName`, not the DHCP-assigned
hostname, which changes with the network):

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

**Auto tmux on ssh**: `~/.zlogin` (managed here; it sources prezto's
`zlogin` first) runs `tmux new-session -A -s main` on interactive ssh
logins, so every login creates or re-attaches the `main` session, and
detaching ends the ssh connection. It is skipped inside tmux, without a
tty (scp, rsync, `ssh <command>`) and when tmux is missing or fails to
start. To get a plain shell, run
`ssh -t <host> 'NO_SSH_TMUX=1 zsh -l'`.

For a second, independent session on the same host, `ssh-tmux <session>
[ssh options] <host>` (in `~/.local/bin`) attaches to the tmux session
named `<session>` instead of `main` — e.g. `ssh-tmux vnc -L5901:localhost:5929
<host>`. It works by setting `SSH_TMUX_SESSION` for the remote `~/.zlogin`.

**SSH agent forwarding**: enabled — remote hosts use the mac's agent to
clone from gitlab.netgate.com, so every ssh-profile host gets
`ForwardAgent yes` via `~/.ssh/agent_forward` (private keys live only on
desktop-profile hosts, m2 and e14), plus the non-chezmoi hosts listed in
`forward_extra` (e.g. the `tnsr-build-*` builders). The mac's unmanaged
`~/.ssh/config` includes the generated file with a single
`Include ~/.ssh/agent_forward` line. A forwarded agent lets root on the
remote host sign with the mac's keys while connected; set
`forward_agent = false` in `.chezmoi.toml.tmpl` and run `chezmoi init` to
turn it off. Narrower alternatives: `ProxyJump`, or destination-constrained
keys (`ssh-add -h`).

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
  current LazyVim. bob lives in `~/.local/bin` and `bob use stable` leaves the
  active nvim shim in `~/.local/bin`, ahead of `/usr/bin` in PATH (prezto zprofile).
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

`dot_config/nvim/lazy-lock.json` is versioned so every machine
converges on the same plugin commits and fresh installs check out
exact revisions (immune to upstream tag/branch churn and to GitHub
API rate limits). After an intentional `:Lazy sync` in nvim, run
`chezmoi add ~/.config/nvim/lazy-lock.json` and commit the lock.

## Layout notes

- `dot_config/nvim/` — LazyVim config (extras in `lazyvim.json`)
- `dot_vimrc`, `dot_vim/` — legacy vim fallback, still deployed everywhere
- `dot_local/bin/` — helper scripts, deployed to `~/.local/bin` as executables
  (`~/bin` is no longer in PATH); `hook_ctags.sh` is kept but no longer wired
  into git template hooks
- `.chezmoiscripts/` — hashed package installers per OS, the daily tmux
  config reload, and FreeBSD desktop system tweaks (polkit rules and the
  poudriere nginx config, templated with each host's FQDN and gated on the
  `poudriere` flag)
- `pkg_list` — reference file, not installed
