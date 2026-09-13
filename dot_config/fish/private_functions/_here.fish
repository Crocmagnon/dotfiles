function _here
    $argv[1] . > /dev/null 2>&1 &; disown
end
