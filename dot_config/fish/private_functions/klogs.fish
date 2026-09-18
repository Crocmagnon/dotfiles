function klogs --wraps=stern --description 'stern with GELF json logs rendered human-readable (--raw for plain stern)'
    if contains -- --raw $argv
        stern --tail=50 (string match -v -- --raw $argv)
        return
    end

    set -l color false
    isatty stdout; and set color true

    stern --tail=50 -o json $argv \
        | TZ=Europe/Paris jq -r --unbuffered --argjson color $color -f (functions --details klogs | path dirname)/klogs.jq
end
