# Defined interactively
function kdjango --description 'Pop into the shell of django pod of the current namespace'
    argparse -x "h,b,s,m" "h/help" "b/bash" "s/sh" "m/manage" -- $argv; or return
    if set -q _flag_h
        echo "Exec into the django pod of the current namespace..."
        echo -e "kdjango [-b]\t ...using bash (default if no option)"
        echo -e "kdjango -s\t ...using sh"
        echo -e "kdjango -m\t ...using manage.py shell"
        echo -e "\nRequires kubens for namespace selection"
        return
    end
    set -l command /bin/bash
    if set -q _flag_b
        set command /bin/bash
    else if set -q _flag_s
        set command /bin/sh
    else if set -q _flag_m
        set command ./manage.py shell
    end
    set pod (kubectl get pods -o name | grep "django" | grep -Ev "celery|migrations" | head -1)
    echo "running $command in $pod"
    kubectl exec -it $pod -- $command
end
