function zoxide-scan --description 'Add every git repo root under a directory to zoxide'
    set -l root (test -n "$argv[1]" && echo $argv[1] || pwd)
    fd --hidden --no-ignore --type d --max-depth 6 '^\.git$' $root | while read -l gitdir
        zoxide add (path dirname $gitdir)
    end
end
