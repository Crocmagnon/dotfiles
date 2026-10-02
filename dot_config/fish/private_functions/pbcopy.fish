function pbcopy
    # Headless (e.g. over SSH): OSC 52 asks the local terminal to set the clipboard.
    if not set -q DISPLAY; and not set -q WAYLAND_DISPLAY
        base64 -w0 | read -z b64
        printf '\e]52;c;%s\a' $b64 >/dev/tty
        return
    end
    if type -q wl-copy
        wl-copy
    else
        xclip -sel clipboard
    end
end
