function upgrade --wraps=topgrade
    set -x NODE_OPTIONS "--no-deprecation"
    if not bw login --check
        set -x BW_SESSION (bw login --raw)
    end
    if not bw unlock --check
        set -x BW_SESSION (bw unlock --raw)
    end
    sudo ls >/dev/null
    topgrade $argv
end
