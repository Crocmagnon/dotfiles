function chezmoiapply
  set -x NODE_OPTIONS "--no-deprecation"
  bwunlock
  chezmoi apply
end
