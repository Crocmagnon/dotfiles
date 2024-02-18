function bwunlock
  set -x NODE_OPTIONS "--no-deprecation"

  if not bw login --check
    set -gx BW_SESSION (bw login --raw)
  end
  if not bw unlock --check
    set -gx BW_SESSION (bw unlock --raw)
  end
end
