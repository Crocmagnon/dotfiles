# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

chezmoi source directory for Gabriel's dotfiles. One repo, four machines:

| Machine | OS | `work` | `headless` |
|---|---|---|---|
| Work laptop | Ubuntu 24.04 | true | false |
| Work server | Debian 12 | true | true |
| Personal laptop (Framework) | Arch | false | false |
| Personal desktop | Arch | false | false |

`.chezmoi.toml.tmpl` stores both in `~/.config/chezmoi/chezmoi.toml`: `work` is asked once (`promptBoolOnce`); `headless` is derived from `hostnamectl chassis` (`vm`, `server`, `container`) on the first init, asked only without systemd, and a stored value wins, so fix a wrong guess there. Arch-specific bits test `.chezmoi.osRelease.id "arch"`; per-host bits (Plasma) test `.chezmoi.hostname`.

## Commands

- `chezmoi diff` / `chezmoi status` (fish alias `dotstatus`): what `apply` would change here. Fish prints "dotfiles drift" at startup when status is non-empty.
- `chezmoi apply [target]`: deploy. Don't run it: it writes to `$HOME` and runs the `run_onchange_*` scripts. Edit versioned files and run read-only commands freely, but anything outside the repo (`chezmoi apply`, `host.config`, keys, YubiKey) is the user's to run: give them the command.
- `chezmoi cat ~/path/to/target`: render one file for this machine.
- Render for another profile: `chezmoi --override-data '{"work":false,"headless":false}' cat ~/.config/mise/config.toml`. This only overrides `work`/`headless`; Arch/hostname branches still follow the current machine.
- `chezmoi execute-template < file.tmpl`: render an arbitrary template snippet.
- `chezmoi managed` / `chezmoi ignored`: check a target is (not) deployed on this machine.

No build, lint or tests: verification is rendering the affected targets for each profile they touch.

## How machine differences are handled

Two mechanisms, pick the right one:

- **Whole file per machine** → `.chezmoiignore` (itself a template). Work-only files (company hosts, k8s helpers, `.netrc`, `.ovh.conf`, jira/stash MCP credentials), personal-only files, desktop-only files (fonts, autostart, `environment.d`) are gated there by target path. A new work-only file needs a line there, not a template guard.
- **Part of a file** → `{{ if get . "work" }}` inside a `.tmpl`. Use `get .` rather than `.work`: templates run with `missingkey=error`, and machines that have not re-run `chezmoi init` lack the key.

Work renders must stay byte-identical when adding personal-only content: use `{{-`/`-}}` trimming so no blank lines or empty directories appear on work machines. Check with `chezmoi diff` on the current (work) machine.

## Template gotchas

- **`{{-` also eats the newline before the tag, gluing headings together.** Put tags on their own line with `-}}` only.
- **chezmoi skips only truly empty renders:** a lone `\n` still creates the file.
- **Never template a file that already contains `{{`** (kitty.conf has some in its comments). Include a small templated file instead (`shell.conf`).
- **Test renders without touching `$HOME`:** `chezmoi --config <tmp.toml> --source . --destination <tmp> execute-template` or `managed`. `--promptBool` matches the prompt *text*, not the key.

## Secrets and encryption

- git-crypt (not chezmoi's age/gpg) encrypts every `encrypted_*` file (`.gitattributes`). chezmoi runs with `encryption = "transparent"`: it strips the `encrypted_` prefix but decrypts nothing. The repo must be `git-crypt unlock`ed for templates to render.
- Once unlocked, never print a rendered template that includes a secret: use `chezmoi apply` without `-v`, and `chezmoi status` for names only.
- Secret values live one per file in `.secrets/encrypted_*` (ignored by chezmoi as a dot-dir) and are pulled into templates with `{{ include ".secrets/encrypted_<name>" | trim }}`. Scripts needing a secret at runtime reference the source path (`joinPath .chezmoi.sourceDir ".secrets/..."`) rather than inlining it.
- Work material — company hostnames, URLs, credentials, keyservers — goes in `.secrets/` or an `encrypted_` file, never in plaintext templates. Whole binary files (fonts, credential JSONs) are encrypted in place with the `encrypted_` prefix.
- The agenix identity of the personal desktops (`~/.config/agenix/identity.txt`, see the nixos-config `CLAUDE.md`) is `dot_config/private_agenix/encrypted_private_identity.txt`, ignored on work machines.
- Per-host overrides (`host.config` included by `git/config` and `ssh/config`) are local per machine and not in this repo.

## Layout notes

- `run_onchange_after_*.sh.tmpl`: post-apply hooks, re-run when their rendered content changes. To re-trigger on another file's change, embed its hash in a comment (`{{ include "..." | sha256sum }}`, see `fisher-update`). Scripts guard with `command -v … || exit 0` because tools may not be installed yet, and put `{{ lookPath "…" }}` in a comment: chezmoi records the hash even when the guard exits, so without it the script would not run again once the tool appears. A script whose whole body is inside `{{ if }}` renders empty and is skipped on other machines.
- `.chezmoidata/*.yaml`: data driving scripts — Plasma `kwriteconfig` keys (only changed keys, optionally `hosts:`-restricted), pinned Rotatrix and nRF Connect versions (AppImages installed by their `run_onchange` scripts; bump the version to upgrade).
- `.chezmoitemplates/starship.toml`: shared starship config, rendered twice with a palette (`starship.toml.tmpl` light, `starship-mocha.toml.tmpl` dark); `conf.d/theme-auto.fish` switches between them.
- `.chezmoiremove` (absent when empty): targets to delete from `$HOME` on apply. When removing a file from the repo, add its target here so it disappears from machines too, then drop the entry once every machine has applied: a stale entry deletes any file later recreated at that path.
- `dot_claude/`: Claude Code settings and personal rules, templated per work/personal (work: company API proxy, Stash rules; personal: French, curl/wget denied). Runtime state under `~/.claude` is listed in `.chezmoiignore`. User-scope MCP servers can't live in `~/.claude.json`, so they're registered by `run_onchange_after_claude-mcp.sh.tmpl`.
- Tools come from mise (`dot_config/mise/config.toml.tmpl`), split into common/work/personal. On Arch, some come from pacman instead, declared in the `arch-config` repo (decman), which owns everything outside `$HOME` on the Arch desktops; its `CLAUDE.md` lists which and why. On the work machines, tools not listed here come from apt (laptop) or a local mise config (server).
- Claude Code comes from its native installer (`run_once_after_claude-install.sh`, every machine) into `~/.local/bin`, and updates itself. User units that call it must not rely on the PATH Plasma imports: `ranger-impressions-3d.service` sets its own.
- `ranger-impressions-3d` (`dot_local/bin`, user `.path`/`.service`, enabled by its `run_onchange` script; personal Arch desktops only): sorts `~/pCloudSync/Projets/Impressions 3D/_Inbox` by asking `claude -p` for a JSON plan. Every machine runs it on the same pCloud folder, so it takes a per-host lock file in the inbox; the inbox must always end empty, or the `.path` unit retriggers in a loop.
- `docs/` is git-ignored and chezmoi-ignored: scratch space.

## gpg-agent and SSH

- **gpg-agent is the SSH agent, and GnuPG stays in `~/.gnupg`.** Arch does not export `SSH_AUTH_SOCK` for it: `environment.d/50-gpg-agent.conf.tmpl` sets it for the Arch graphical session, `config.fish` for every fish, except over `ssh -A`, where the forwarded agent is kept.
- **gpg-agent starts about 1 s before the Plasma session, without a display.** SSH requests carry no display, so pinentry needs `updatestartuptty`, run by `autostart/gpg-agent-display.desktop` and by every interactive fish. Never run `updatestartuptty` from a display-less ssh command (VM tests): it wipes the display.
- **On the Arch desktops, pinentry-qt keeps passphrases in KWallet** (`PINENTRY_KDE_USE_WALLET`), which PAM unlocks at autologin. The PAM side and how to check the wallet live in arch-config.
- **Two git identities.** Work (default on work machines) signs with GPG, the primary of the one RSA key set as `user.signingkey` (with `!`) in `host.config`: CDS only knows primary key IDs (ovh/cds#7891), so the per-machine signing subkeys stay unused until it does. Personal (`git/perso.config`: everywhere on personal machines, GitHub/Codeberg remotes on work machines via `includeIf hasconfig:remote.*.url`) signs with the machine's SSH key. A new machine's SSH key goes in `git/allowed_signers` and as a signing key on GitHub and Codeberg.

## Conventions

- Comments inside the files are written in French; commit messages in English, one short line.
- Private files use chezmoi's `private_` prefix (0600/0700), executables `executable_`, symlinks `symlink_`.
- Top-level repo files that aren't dotfiles (README, LICENSE, this file) must be listed in `.chezmoiignore`.
