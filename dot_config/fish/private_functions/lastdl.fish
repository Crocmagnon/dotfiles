function lastdl --description 'Print the path of the most recently modified file in ~/Downloads'
    eza -1 -s modified --absolute=on ~/Downloads | tail -1
end
