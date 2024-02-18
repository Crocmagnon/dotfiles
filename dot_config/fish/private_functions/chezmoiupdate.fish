function chezmoiupdate
  set -x NODE_OPTIONS "--no-deprecation"
  bwunlock
  chezmoi update
end
