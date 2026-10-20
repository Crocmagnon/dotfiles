#!/bin/sh
# Claude Code par l'installeur natif (~/.local/bin/claude), qui se met à jour seul. Toutes les
# machines ; sur Arch, il remplace le paquet AUR claude-code.
[ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash
