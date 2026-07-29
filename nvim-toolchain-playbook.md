# Neovim Toolchain Playbook (post-Mason)

Bootstrap checklist for a new machine running `github.com/mplilly/nvim`.

Since this config dropped the Mason trio, **nothing installs itself**. `init.lua`
calls external binaries and expects them on `$PATH`. If a binary is missing the
failure is usually silent: `vim.lsp.enable` just never attaches, and
`conform.nvim` skips the formatter and falls through to the LSP.

Two distro families are covered. Commands are identical within each family.

- **openSUSE Tumbleweed** — `zypper`
- **Debian / Ubuntu** — `apt`

---

## 0. Prerequisites

| Requirement | Check | Notes |
|---|---|---|
| Neovim 0.12+ | `nvim --version` | Config uses `vim.pack`, `vim.lsp.config`, `vim.lsp.enable`, `vim.o.autocomplete` — all 0.12 APIs. Distro packages often lag; use the official tarball or AppImage if so. |
| `git` | `git --version` | Needed by `vim.pack` itself, not just for cloning. |
| `~/.local/bin` on `$PATH` | `echo $path` | Add under `$ZDOTDIR`, not a bare `~/.zshrc`. |
| CPU arch | `uname -m` | `x86_64` vs `aarch64` decides which prebuilt binary to grab in §5. |

If you are already inside a tmux session when you change `$PATH`, run
`tmux kill-server` afterward so new panes inherit it. Re-sourcing `.zshrc` in one
pane will not fix the others.

---

## 1. Clone the config

Clone rather than hand-copying, so the committed `nvim-pack-lock.json` comes with
it and this machine installs the same plugin revisions as pine:

```bash
git clone git@github.com:mplilly/nvim ~/.config/nvim
```

Do not launch `nvim` yet — plugin installation in §7 wants the compiler from §2
already present.

---

## 2. Build toolchain

Compiles treesitter parsers, the orgmode grammar, and `telescope-fzf-native`.
Skipping this produces confusing parser-compile errors on first launch.

**openSUSE:**
```bash
sudo zypper install -t pattern devel_C_C++
```

**Debian / Ubuntu:**
```bash
sudo apt update
sudo apt install build-essential
```

---

## 3. Search backends

Telescope's `live_grep` and `grep_string` shell out to ripgrep. `find_files` uses
`fd` when present and falls back to `find` otherwise, so `fd` is optional — but
if you install it, Telescope looks for the name `fd`.

**openSUSE** — binary is already named `fd`, nothing further to do:
```bash
sudo zypper in ripgrep fd git
```

**Debian / Ubuntu** — packaged as `fd-find`, binary is `fdfind`, needs a symlink:
```bash
sudo apt install ripgrep fd-find git
ln -s "$(which fdfind)" ~/.local/bin/fd
```

> On a minimal Ubuntu server image these may live in `universe`. If apt can't
> find a package: `sudo add-apt-repository universe && sudo apt update`.

---

## 4. Clipboard

Decide by whether the machine has a display.

**Desktop / Wayland** (the pine case) — `unnamedplus` needs a real clipboard tool:
```bash
sudo zypper in wl-clipboard        # openSUSE
sudo apt install wl-clipboard      # Debian/Ubuntu
```

**Headless server** (the aidev case) — **install nothing.** Neovim 0.10+
auto-enables its OSC 52 provider when `$SSH_TTY` is set and no clipboard tool is
found, so yanks propagate to the clipboard of whatever machine you're sitting at.
The one thing to configure is tmux passthrough:

```tmux
set -g set-clipboard on
```

kitty and Blink Shell both do OSC 52 by default, so no terminal-side work.

Installing `xclip` on a headless box actively breaks this — Neovim finds it,
prefers it over OSC 52, and then it fails for lack of a display.

---

## 5. Python tooling — via pipx

Both distro families enforce PEP 668 (externally-managed environments), so this
is `pipx`, never `pip install`.

**openSUSE:**
```bash
sudo zypper in python3-pipx
```

**Debian / Ubuntu:**
```bash
sudo apt install pipx
```

Then, identically on both:
```bash
pipx ensurepath          # adds ~/.local/bin to PATH — open a fresh shell after
pipx install ruff        # linter-LSP AND formatter (ruff_format, ruff_organize_imports)
pipx install pyright     # types + hover
pipx install pylatexenc  # optional: LaTeX rendering in render-markdown.nvim
```

Notes:

- `ruff` wears two hats here — it's the LSP *and* what conform invokes. One
  install covers both; there's no separate formatter binary.
- `pyright` from pipx provides `pyright-langserver`, which is the binary name
  `vim.lsp.config('pyright', ...)` expects. It quietly downloads its own Node
  runtime on first run, so the very first attach lags a second or two. Don't
  mistake that for a broken install.

---

## 6. Lua tooling

Needed only if you'll edit the nvim config *on this machine*. If it's a box where
you only edit Python, skip the section entirely — `lua_ls` simply won't attach.

### openSUSE — both are packaged

```bash
sudo zypper in lua-language-server
```

For stylua, prefer the prebuilt binary (below) over `cargo install`. The
openSUSE-packaged rustup skips the profile-editing step the upstream installer
does, so `~/.cargo/bin` never lands on `$PATH` — a snag already hit once on pine.

### Debian / Ubuntu — neither is packaged, use prebuilt binaries

`lua-language-server` from <https://github.com/LuaLS/lua-language-server/releases>
(match your `uname -m` — `linux-x64` or `linux-arm64`):

```bash
mkdir -p ~/.local/share/lua-language-server
tar -xzf lua-language-server-*-linux-x64.tar.gz -C ~/.local/share/lua-language-server
ln -s ~/.local/share/lua-language-server/bin/lua-language-server ~/.local/bin/lua-language-server
```

The symlink matters: the binary resolves its `main.lua` relative to its real
location, so moving just the binary out of the extracted tree breaks it.

`stylua` from <https://github.com/JohnnyMorganz/StyLua/releases>:

```bash
unzip stylua-linux-x86_64.zip -d ~/.local/bin && chmod +x ~/.local/bin/stylua
```

### stylua config

`format_on_save` is enabled for lua, so stylua rewrites `init.lua` on every
write. Make sure `stylua.toml` is committed at the repo root, or this machine's
stylua defaults will fight pine's formatting and generate diff noise:

```toml
column_width = 120
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "Always"
```

---

## 7. rust_analyzer — usually skip

Only if you write Rust on this box. `vim.lsp.enable` starts a server only for
matching filetypes, so an absent `rust_analyzer` is harmless — it never attaches.

```bash
rustup component add rust-analyzer
# no rustup yet?  sudo zypper in rustup && rustup default stable
#                 (Debian/Ubuntu: use the upstream rustup-init script)
```

Going through rustup keeps it tracking your toolchain version.

---

## 8. First launch, inside Neovim

Order matters a little — treesitter parsers need §2 done, and the org grammar is
a separate command from the parser list.

1. `nvim` — `vim.pack` clones plugins at the locked revisions. Let it finish.
2. Restart, then `:checkhealth` and skim for red.
3. `:TSInstall latex yaml html` — the render-markdown.nvim extras, if not already
   in `ensure_installed`.
4. `:Org install_treesitter_grammar` — orgmode.nvim ships its own org parser.
   This is deliberately *not* in nvim-treesitter's `ensure_installed`; putting
   `'org'` there installs a conflicting grammar.
5. `telescope-fzf-native` builds on first load. If it errors, §2 didn't take.

---

## 9. Verification

From the shell nvim launches from (not a different pane with a stale `$PATH`):

```bash
which rg fd ruff pyright-langserver lua-language-server stylua
```

Then inside Neovim:

| Check | Expect |
|---|---|
| `:checkhealth nvim-treesitter` | parsers present, compiler found |
| open a `.py`, `:checkhealth vim.lsp` | `pyright` and `ruff` both attached |
| open a `.lua`, `:checkhealth vim.lsp` | `lua_ls` attached |
| `:ConformInfo` | `ruff_*` for python, `stylua` for lua, all resolved |
| `<leader>sg` | live_grep returns results (ripgrep wired up) |
| yank a line, paste locally | OSC 52 working, if headless |

---

## 10. Troubleshooting

| Symptom | Likely cause |
|---|---|
| LSP silently never attaches | binary not on `$PATH` in nvim's environment; check `:echo $PATH` inside nvim, not just the shell |
| Works in a new pane, not the old one | tmux inherited the pre-`ensurepath` `$PATH`; `tmux kill-server` |
| Telescope `find_files` works, `live_grep` doesn't | ripgrep missing |
| `fd` not found, Debian/Ubuntu | the `fdfind` symlink from §3 |
| Parser compile failures | build toolchain from §2 |
| Org files unhighlighted | `:Org install_treesitter_grammar` not run |
| First pyright attach hangs briefly | it's downloading its Node runtime; expected once |
| `.lua` files reformat unexpectedly | stylua via `format_on_save`; see §6 |
| Quotes flip style between machines | `stylua.toml` not committed |
