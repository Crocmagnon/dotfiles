function ll --wraps=ls --wraps=eza
    set bin exa
    if type -q eza
        set bin eza
    end

    $bin --long --all --header --group --git $argv
end
