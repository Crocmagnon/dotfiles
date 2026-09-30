# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

chezmoi source directory for Gabriel's dotfiles. One repo, four machines:

| Machine | OS | `work` | `headless` |
|---|---|---|---|
| Work laptop | Ubuntu 24.04 | true | false |
| Work server | Debian 12 | true | true |
| Personal laptop (Framework) | Arch | false | false |
| Personal desktop | Arch | false | false |

`work` and `headless` are asked once by `.chezmoi.toml.tmpl` (`promptBoolOnce`) and stored in `~/.config/chezmoi/chezmoi.toml`. Arch-specific bits test `.chezmoi.osRelease.id "arch"`; per-host bits (Plasma) test `.chezmoi.hostname`.

## Commands

- `chezmoi diff` / `chezmoi status` (fish alias `dotstatus`): what `apply` would change here. Fish prints "dotfiles drift" at startup when status is non-empty.
- `chezmoi apply [target]`: deploy. Ask before running it — it writes to `$HOME` and runs the `run_onchange_*` scripts.
- `chezmoi cat ~/path/to/target`: render one file for this machine.
- Render for another profile: `chezmoi --override-data '{"work":false,"headless":false}' cat ~/.config/mise/config.toml`. This only overrides `work`/`headless`; Arch/hostname branches still follow the current machine.
- `chezmoi execute-template < file.tmpl`: render an arbitrary template snippet.
- `chezmoi managed` / `chezmoi ignored`: check a target is (not) deployed on this machine.

No build, lint or tests: verification is rendering the affected targets for each profile they touch.

## How machine differences are handled

Two mechanisms, pick the right one:

- **Whole file per machine** → `.chezmoiignore` (itself a template). Work-only files (company hosts, k8s helpers, `.netrc`, `.ovh.conf`, jira/stash MCP credentials), personal-only files, desktop-only files (fonts, autostart, `environment.d`) are gated there by target path. A new work-only file needs a line there, not a template guard.
- **Part of a file** → `{{ if get . "work" }}` inside a `.tmpl`. Use `get .` rather than `.work` so a missing key doesn't error.

Work renders must stay byte-identical when adding personal-only content: use `{{-`/`-}}` trimming so no blank lines or empty directories appear on work machines. Check with `chezmoi diff` on the current (work) machine.

## Secrets and encryption

- git-crypt (not chezmoi's age/gpg) encrypts every `encrypted_*` file (`.gitattributes`). chezmoi runs with `encryption = "transparent"`: it strips the `encrypted_` prefix but decrypts nothing. The repo must be `git-crypt unlock`ed for templates to render.
- Secret values live one per file in `.secrets/encrypted_*` (ignored by chezmoi as a dot-dir) and are pulled into templates with `{{ include ".secrets/encrypted_<name>" | trim }}`. Scripts needing a secret at runtime reference the source path (`joinPath .chezmoi.sourceDir ".secrets/..."`) rather than inlining it.
- Work material — company hostnames, URLs, credentials, keyservers — goes in `.secrets/` or an `encrypted_` file, never in plaintext templates. Whole binary files (fonts, credential JSONs) are encrypted in place with the `encrypted_` prefix.
- Per-host overrides (`host.config` included by `git/config` and `ssh/config`) are local per machine and not in this repo.

## Layout notes

- `run_onchange_after_*.sh.tmpl`: post-apply hooks, re-run when their rendered content changes. To re-trigger on another file's change, embed its hash in a comment (`{{ include "..." | sha256sum }}`, see `bat-cache` and `fisher-update`). Scripts guard with `command -v … || exit 0` because tools may not be installed yet (mise installs most of them). A script whose whole body is inside `{{ if }}` renders empty and is skipped on other machines.
- `.chezmoidata/*.yaml`: data driving scripts — Plasma `kwriteconfig` keys (only changed keys, optionally `hosts:`-restricted), pinned Rotatrix version.
- `.chezmoitemplates/starship.toml`: shared starship config, rendered twice with a palette (`starship.toml.tmpl` light, `starship-mocha.toml.tmpl` dark); `conf.d/theme-auto.fish` switches between them.
- `.chezmoiremove`: targets to delete from `$HOME` on apply. Add a file's target here when removing it from the repo, so it disappears from machines too.
- `dot_claude/`: Claude Code settings and personal rules, templated per work/personal (work: company API proxy, Stash rules; personal: French, curl/wget denied). Runtime state under `~/.claude` is listed in `.chezmoiignore`. User-scope MCP servers can't live in `~/.claude.json`, so they're registered by `run_onchange_after_claude-mcp.sh.tmpl`.
- Tools come from mise (`dot_config/mise/config.toml.tmpl`), split into common/work/personal. On Arch, some come from pacman instead (fisher, luarocks).
- `docs/` is git-ignored and chezmoi-ignored: scratch space.

## Conventions

- Comments inside the files are written in French; commit messages in English, one short line.
- Private files use chezmoi's `private_` prefix (0600/0700), executables `executable_`, symlinks `symlink_`.
- Top-level repo files that aren't dotfiles (README, LICENSE, this file) must be listed in `.chezmoiignore`.
