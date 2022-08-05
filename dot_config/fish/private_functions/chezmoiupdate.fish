function chezmoiupdate
if not bw login --check
set -x BW_SESSION (bw login --raw)
end
if not bw unlock --check
set -x BW_SESSION (bw unlock --raw)
end
chezmoi update
end
