#!/usr/bin/env bash
# Claude Code statusline: model | repo[worktree]:branch*ahead/behind | ctx bar | cost
# Avec LC_NUMERIC=fr_FR, printf '%.2f' rejette « 1.2345 » et affiche 0 : le coût sortait à $0,00.
# C stabilise aussi la sortie de git.
export LC_ALL=C

input=$(cat)

IFS=$'\t' read -r model dir used cost < <(jq -r '[
  .model.display_name // "?",
  (.workspace.current_dir // .cwd // "."),
  (.context_window.used_percentage // -1),
  (.cost.total_cost_usd // 0)
] | @tsv' <<<"$input")

R=$'\e[0m' DIM=$'\e[2m' REPO=$'\e[1;34m' BRANCH=$'\e[35m' PR=$'\e[36m'
# Bar colors as backgrounds: kitty draws shade glyphs as its own dither, so the
# bar is built from blank cells. Track is the accent at 25% over the Latte base.
RED=$'\e[48;2;210;15;57m'  RED_T=$'\e[48;2;232;185;198m'
YEL=$'\e[48;2;223;142;29m' YEL_T=$'\e[48;2;235;216;191m'
GRN=$'\e[48;2;64;160;43m'  GRN_T=$'\e[48;2;195;221;195m'
LINK=$'\e]8;;' LINKMID=$'\e\\' LINKEND=$'\e]8;;\e\\'
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

  if pr=$(pr_id) && [ -n "$pr" ]; then
    # ssh://git@host:7999/project/repo.git -> https://host/projects/PROJECT/repos/repo
    url=$(git -C "$dir" remote get-url origin 2>/dev/null |
      sed -E 's#^[a-z+]+://##; s#^[^/@]*@##; s#\.git$##; s#:[0-9]+/#/#; s#^([^/]+)/(.*)/([^/]+)$#https://\1/projects/\U\2\E/repos/\3#')
    case "$url" in
      https://*) loc="$loc ${LINK}${url}/pull-requests/${pr}${LINKMID}${PR}#$pr${R}${LINKEND}" ;;
      *) loc="$loc ${PR}#$pr${R}" ;;
    esac
  fi
  out="$out$SEP$loc"
else
  out="$out$SEP${REPO}$(basename "$dir")${R}"
fi

# Context bar fills as the window is consumed.
if [ "$used" -ge 0 ] 2>/dev/null; then
  width=10
  filled=$(( (used * width + 50) / 100 ))
  if   [ "$used" -ge 85 ]; then c=$RED t=$RED_T
  elif [ "$used" -ge 60 ]; then c=$YEL t=$YEL_T
  else                         c=$GRN t=$GRN_T
  fi
  printf -v bar '%*s' "$filled" ''
  printf -v rest '%*s' "$((width - filled))" ''
  out="$out$SEP${c}${bar}${t}${rest}${R}"
fi

printf '%s%s%s$%.2f%s' "$out" "$SEP" "$DIM" "$cost" "$R"
