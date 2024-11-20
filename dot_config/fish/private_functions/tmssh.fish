function tmssh --wraps=ssh --description 'start ssh with tmux'
ssh -t $argv 'tmux -CC new -A -s tmssh'
end
