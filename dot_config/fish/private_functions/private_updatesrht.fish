function updatesrht
set newremote (git remote get-url origin | sed "s#git@git.sr.ht:~crocmagnon#ssh://git@git.augendre.info:23730/gaugendre#"); and git remote set-url origin $newremote;
end
