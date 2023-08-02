function lastdl
echo "$HOME/Downloads/$(exa -1 -s modified ~/Downloads | tail -1)"
end
