#!/usr/bin/env python3
# Hook PreToolUse : toute écriture dans l'auto-mémoire (~/.claude/projects/*/memory/) demande
# confirmation, pour que le savoir aille d'abord au niveau versionné adapté (voir la règle
# « Saving knowledge »).
import fnmatch
import json
import os
import sys

path = json.load(sys.stdin).get("tool_input", {}).get("file_path", "")
pattern = os.path.expanduser("~/.claude/projects/*/memory/*")
if fnmatch.fnmatch(os.path.abspath(os.path.expanduser(path)), pattern):
    json.dump({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": "Auto-memory is the last resort: repo docs, then sia-skills on work machines, "
        "then the chezmoi rules come first (rule \"Saving knowledge\"). Approve only for "
        "repo-only, unshareable knowledge.",
    }}, sys.stdout)
