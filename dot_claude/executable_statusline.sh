#!/usr/bin/env bash
# Claude Code statusline: model | repo[worktree]:branch*ahead/behind | ctx bar | cost
input=$(cat)

IFS=$'\t' read -r model dir used cost < <(jq -r '[
  .model.display_name // "?",
  (.workspace.current_dir // .cwd // "."),
  (.context_window.used_percentage // -1),
  (.cost.total_cost_usd // 0)
] | @tsv' <<<"$input")

R=$'\e[0m' DIM=$'\e[2m' REPO=$'\e[1;34m' BRANCH=$'\e[35m' PR=$'\e[36m'
RED=$'\e[31m' YEL=$'\e[33m' GRN=$'\e[32m'
SEP="${DIM} | ${R}"

# Bitbucket/Stash publishes refs/pull-requests/<id>/from; the ref whose tip is the pushed
# branch tip is this branch's PR. Refreshed in the background so a render never waits on it.
pr_id() {
  local sha cache file
  sha=$(git -C "$dir" rev-parse --verify --quiet '@{upstream}') || return
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
  file="$cache/$(printf '%s' "$root" | cksum | cut -d' ' -f1)"
  mkdir -p "$cache"
  if [ ! -s "$file" ] || [ -n "$(find "$file" -mmin +5 2>/dev/null)" ]; then
    (git -C "$dir" ls-remote origin 'refs/pull-requests/*/from' >"$file.tmp" 2>/dev/null &&
      mv "$file.tmp" "$file") >/dev/null 2>&1 &
    disown 2>/dev/null
  fi
  awk -v s="$sha" '$1 == s { split($2, p, "/"); print p[3]; exit }' "$file" 2>/dev/null
}

out="${DIM}${model}${R}"

if root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
  # In a linked worktree the common dir is the main clone's .git, so the two names differ.
  repo=$(basename "$(dirname "$(cd "$dir" && git rev-parse --path-format=absolute --git-common-dir)")")
  wt=$(basename "$root")
  loc="${REPO}${repo}${R}"
  [ "$wt" != "$repo" ] && loc="$loc${DIM}[${R}${REPO}${wt}${R}${DIM}]${R}"

  branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "$branch" ] && loc="$loc${DIM}:${R}${BRANCH}${branch}${R}"
  [ -n "$(git -C "$dir" status --porcelain --untracked-files=no 2>/dev/null | head -1)" ] && loc="$loc${RED}*${R}"

  if counts=$(git -C "$dir" rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null); then
    behind=${counts%%[[:space:]]*} ahead=${counts##*[[:space:]]}
    [ "$ahead" -gt 0 ] 2>/dev/null && loc="$loc ${YEL}↑$ahead${R}"
    [ "$behind" -gt 0 ] 2>/dev/null && loc="$loc ${YEL}↓$behind${R}"
  fi

  pr=$(pr_id) && [ -n "$pr" ] && loc="$loc ${PR}#$pr${R}"
  out="$out$SEP$loc"
else
  out="$out$SEP${REPO}$(basename "$dir")${R}"
fi

# Context bar fills as the window is consumed.
if [ "$used" -ge 0 ] 2>/dev/null; then
  width=10
  filled=$(( (used * width + 50) / 100 ))
  if   [ "$used" -ge 85 ]; then c=$RED
  elif [ "$used" -ge 60 ]; then c=$YEL
  else                         c=$GRN
  fi
  bar=""
  for ((i = 0; i < width; i++)); do
    if [ "$i" -lt "$filled" ]; then bar+="█"; else bar+="░"; fi
  done
  out="$out$SEP${c}${bar}${R}"
fi

printf '%s%s%s$%.2f%s' "$out" "$SEP" "$DIM" "$cost" "$R"
