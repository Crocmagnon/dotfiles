# Defined interactively
function kdjango --description 'Pop into the shell of django pod of the current namespace'
    argparse -X 1 -x "h,b,s,m,o,d" "h/help" "b/bash" "s/sh" "m/manage" "o/original-shell" "d/db-shell" -- $argv; or return
    if set -q _flag_h
        echo "Exec into the django pod of the current namespace..."
        echo -e "kdjango [-b]\t ...using bash (default if no option)"
        echo -e "kdjango -s\t ...using sh"
        echo -e "kdjango -m\t ...using manage.py shell_plus"
        echo -e "kdjango -o\t ...using manage.py shell"
        echo -e "kdjango -d\t ...using manage.py dbshell"
        echo -e "\nRequires kubens for namespace selection"
        return
    end
    if count $argv > /dev/null
        set pod $argv[1]
    else
        set pod (kubectl get pods -o name | grep "django" | grep -Ev "celery|migrations" | head -1)
    end
    set -l command /bin/bash
    if set -q _flag_b
        set command /bin/bash
    else if set -q _flag_s
        set command /bin/sh
    else if set -q _flag_m
        set command ./manage.py shell_plus
    else if set -q _flag_o
        set command ./manage.py shell
    else if set -q _flag_d
        if kubectl exec -it $pod -- which pgcli &> /dev/null
            set command sh -c 'pgcli $(./manage.py sqldsn --quiet --style=uri)'
        else
            set command ./manage.py dbshell
        end
    end
    echo "running $command in $pod"
    kubectl exec -it $pod -- $command
end
