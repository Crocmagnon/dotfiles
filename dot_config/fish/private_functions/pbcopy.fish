function pbcopy
    set cmd command pbcopy
    if type -q "xclip"
        set cmd xclip -sel clipboard
    end
    $cmd
end
