function pbcopy
    set cmd command pbcopy
    if type -q xclip
        set cmd xclip -sel clipboard
    end
    if type -q wl-copy
        set cmd wl-copy
    end
    $cmd
end
