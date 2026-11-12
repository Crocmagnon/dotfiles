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
- `chezmoi apply [target]`: deploy (writes to `$HOME`, runs the `run_onchange_*` scripts). Run it yourself once a change is done, after `chezmoi diff` shows only the expected change; then make it take effect without asking (Krohnkite: reload it as described under Krohnkite below). Other things outside the repo (`host.config`, keys, YubiKey) stay the user's to run: give them the command.
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
- `.chezmoidata/*.yaml`: data driving scripts — Plasma `kwriteconfig` keys (only changed keys, optionally `hosts:`-restricted), pinned Rotatrix version.
- Plasma settings (`plasma.yaml`) are written by `~/.local/bin/plasma-settings` at every login, before KWin (`plasma-settings.service`, wanted by `plasma-kwin_wayland.service`), and by `run_onchange_after_plasma.sh` when they change (it holds the script's hash). kglobalaccel, inside KWin, reads `kglobalshortcutsrc` when it starts and rewrites the whole file from memory at logout, so a shortcut written during a session was lost (laptop, 01/11/2026): a shortcut change takes effect at the next login. A versioned key changed in the GUI comes back at the next login.
- `.chezmoitemplates/starship.toml`: shared starship config, rendered twice with a palette (`starship.toml.tmpl` light, `starship-mocha.toml.tmpl` dark); `conf.d/theme-auto.fish` switches between them.
- `.chezmoiremove` (absent when empty): targets to delete from `$HOME` on apply. When removing a file from the repo, add its target here so it disappears from machines too, then drop the entry once every machine has applied: a stale entry deletes any file later recreated at that path.
- `dot_claude/`: Claude Code settings and personal rules, templated per work/personal (work: company API proxy, Stash rules; personal: French, curl/wget denied). Runtime state under `~/.claude` is listed in `.chezmoiignore`. User-scope MCP servers can't live in `~/.claude.json`, so they're registered by `run_onchange_after_claude-mcp.sh.tmpl`. Project-scoped ones live in that project's `.mcp.json` and read their token from a chezmoi-managed file (`~/.config/paperless-mcp/token` for `~/pCloudSync/paperless`, personal machines only). Home Assistant too, since 2026-11-12: `home-assistant` in `~/pCloudSync/Home Assistant` (`~/.config/ha-mcp/token`) and `ha-parents` in `~/pCloudSync/Home Assistant parents` (`token-parents`), so neither HA is reachable elsewhere; `run_onchange_after_claude-mcp.sh.tmpl` now only removes the former user-scope `home-assistant`.
- Tools come from mise (`dot_config/mise/config.toml.tmpl`), split into common/work/personal. On Arch, some come from pacman instead, declared in the `arch-config` repo (decman), which owns everything outside `$HOME` on the Arch desktops; its `CLAUDE.md` lists which and why. On the work machines, tools not listed here come from apt (laptop) or a local mise config (server).
- On the personal Arch desktops, Claude Code talks to the API through a local Caddy (`claude-proxy.service`, `~/.config/caddy/claude-proxy.Caddyfile`, `127.0.0.1`/`::1` port 13862; caddy declared in arch-config): an `ANTHROPIC_BASE_URL` other than Anthropic's stops it downloading the company's remote settings, which follow the account onto personal machines. The admins gave this workaround.
- Claude Code comes from its native installer (`run_once_after_claude-install.sh`, every machine) into `~/.local/bin`, and updates itself. User units that call it must not rely on the PATH Plasma imports: `ranger-impressions-3d.service` sets its own.
- SolidCraft (personal desktops) is an AppImage downloaded once into `~/Applications` by `run_once_after_solidcraft-install.sh.tmpl`, then updated by its own in-app updater (stable releases, about one a day: too often for the AUR). Its AppRun writes the menu entry, icons and (after 0.22) `~/.local/bin/solidcraft-cli` on each launch: don't manage those here, and don't use `.chezmoiexternal` for it (it would fight the updater). Since 0.22.1 the app adds itself as an MCP server to Claude Code at each launch (`~/.claude.json`, entry `solidcraft`), so it is not declared here. It uses the CLI next to its own binary: from the AppImage, a `/tmp/.mount_…` path gone once it closes. `environment.d/60-solidcraft.conf` sets `SOLIDCRAFT_CLI` to the wrapper instead; it takes effect at the next login.
- `ranger-impressions-3d` (`dot_local/bin`, user `.path`/`.service`, enabled by its `run_onchange` script; personal Arch desktops only): sorts `~/pCloudSync/Projets/Impressions 3D/_Inbox` by asking `claude -p` for a JSON plan. Every machine runs it on the same pCloud folder, so it takes a per-host lock file in the inbox; the inbox must always end empty, or the `.path` unit retriggers in a loop.
- `docs/` is git-ignored and chezmoi-ignored: scratch space.
- niri (with Dux Shell) was the main session on the Arch desktops from 30/10 to 01/11/2026, then dropped for Karousel, then Krohnkite, on Plasma. Its config and the workarounds it needed (portals, `environment.d` KDE variables, Nautilus kept away, light/dark relay) are in git history (`git log -i --grep=niri`).
- Krohnkite (every Plasma machine; `.chezmoiexternal.toml`, `.chezmoidata/plasma.yaml`, `dot_local/share/applications/kitty-simple.desktop.tmpl`): dwm-style automatic tiling as a KWin script (master + stack, Tile layout first), with the `kwin4_effect_geometry_change` effect animating moves. It replaced Karousel (scrollable tiling) on 09/11/2026 to get one model on Plasma 5 and 6; Karousel's config and its screen-change reload unit are in git history. The Arch desktops get the maintained fork, Plasma 6 only, from Codeberg (`anametologin/Krohnkite`, its `releases/download/latest/krohnkite.kwinscript` URL rechecked weekly; the GitHub repo and krohnkite.com are not it); the effect still comes from its latest GitHub release (`gitHubLatestRelease`). The work laptop (Plasma 5.27) gets the original project's last release, esjeon v0.8.1 (2022, unmaintained), and the effect 1.1, both pinned. A `.kwinscript` is a zip with no top folder (`format = "zip"`, no `stripComponents`). Under Wayland, KWin 5.27 windows have no `basicUnit` nor `windowId`, and no window has `clientSize` any more (an XWayland window with a resize step, like Webex, reached it): 0.8.1 threw a `TypeError` on every placement, swallowed it, and tiled nothing (windows stacked on top of each other, 09-10/11/2026). Its `script.js` is therefore a separate `file` external, extracted from the same archive and patched by `.patches/krohnkite-0.8.1-wayland.py` (a dot-dir, ignored by chezmoi, run as `filter.command`), which asserts each replaced line still exists. KWin caches a script's code for the whole session (disabling and re-enabling it, or `reconfigure`, rerun the old code): to test a change without logging out, do what upstream's `tools/reload-script.py` does, copy the script to a fresh directory, then `qdbus org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript krohnkite`, `loadDeclarativeScript <copy>/contents/ui/main.qml krohnkite`, `start` (verified on 0.8.1, 09/11/2026). The two versions name their shortcut actions differently (0.8.1 `Krohnkite: <label>`, 0.9 `KrohnkiteXxx`, from `contents/ui/shortcuts.qml`) and their settings too (0.8.1 `floatingClass`, `directionalKeyDwm` on by default; 0.9 `floatConfig`), so `plasma.yaml` has one set per version, same keys: `arch_desktop` for 0.9 and Arch, `work_desktop` for 0.8.1 and Plasma 5 (application shortcuts in Plasma 5's format). Krohnkite's own defaults (vim keys, Meta+T/M/F/D/I/./,) collide with ours and are all reassigned. It cannot send a window to another desktop: KWin's "Window One Desktop Up/Down" and "Window to Desktop N" do, and it retiles the window there. Its wiki (Tips) rules out the Squash minimize effect: Magic Lamp is enabled instead (`kwin4_effect_squash` on Plasma 5, `squash` on Plasma 6). Plasma 6 keeps application shortcuts (KRunner, the emoji picker, a `.desktop` launcher) under `[services][<app>.desktop]`; Plasma 5 under `[<app>.desktop]`, with the full `active,default,label` value, and the screen reader under `[kaccess]`. `gitHubLatestRelease` calls the API on every chezmoi command, and fails offline once its cache is older than `github.refreshPeriod` (1 min by default): `.chezmoi.toml.tmpl` sets it to a week on Arch (verified offline 01/11/2026). Shortcuts and settings are `plasma.yaml` entries; they follow niri's Ergo-L convention (OSEN, Ctrl moves, Alt resizes). KWin stores a shifted symbol without Shift (Mod+Shift+& is `Meta+1`, Mod+Shift+; is `Meta+.`), and a comma is written `Meta+\,`. An action with two keys separates them with a tab; `quote` renders it `\t`, so the script turns that back into a tab with `$tab`. Shortcuts apply at the next login (see `plasma-settings` above), and a KWin script reads its config only when it loads: log out and back in after a change. `kitty-simple.desktop` uses kitty's absolute path (`lookPath`): at work kitty lives in `~/.local/bin`, which the session's `PATH` may not include.

## gpg-agent and SSH

- **gpg-agent is the SSH agent, and GnuPG stays in `~/.gnupg`.** Arch does not export `SSH_AUTH_SOCK` for it: `environment.d/50-gpg-agent.conf.tmpl` sets it for the Arch graphical session, `config.fish` for every fish, except over `ssh -A`, where the forwarded agent is kept.
- **gpg-agent starts about 1 s before the Plasma session, without a display.** SSH requests carry no display, so pinentry needs `updatestartuptty`, run by `autostart/gpg-agent-display.desktop` and by every interactive fish. Never run `updatestartuptty` from a display-less ssh command (VM tests): it wipes the display.
- **On the Arch desktops, pinentry-qt keeps passphrases in KWallet** (`PINENTRY_KDE_USE_WALLET`), which PAM unlocks at autologin. The PAM side and how to check the wallet live in arch-config.
- **Two git identities.** Work (default on work machines) signs with GPG, the primary of the one RSA key set as `user.signingkey` (with `!`) in `host.config`: CDS only knows primary key IDs (ovh/cds#7891), so the per-machine signing subkeys stay unused until it does. Personal (`git/perso.config`: everywhere on personal machines, GitHub/Codeberg remotes on work machines via `includeIf hasconfig:remote.*.url`) signs with the machine's SSH key. A new machine's SSH key goes in `git/allowed_signers` and as a signing key on GitHub and Codeberg.

## Conventions

- Comments inside the files are written in French; commit messages in English, one short line.
- Private files use chezmoi's `private_` prefix (0600/0700), executables `executable_`, symlinks `symlink_`.
- Top-level repo files that aren't dotfiles (README, LICENSE, this file) must be listed in `.chezmoiignore`.
