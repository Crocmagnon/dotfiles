function pbcopy
    # Headless (e.g. over SSH): OSC 52 asks the local terminal to set the clipboard.
    if test (uname) != Darwin; and not set -q DISPLAY; and not set -q WAYLAND_DISPLAY
        base64 -w0 | read -z b64
        printf '\e]52;c;%s\a' $b64 >/dev/tty
        return
    end
    set cmd command pbcopy
    if type -q xclip
        set cmd xclip -sel clipboard
    end
    if type -q wl-copy
        set cmd wl-copy
    end
    $cmd
end
