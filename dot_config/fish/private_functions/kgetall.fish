function kgetall
for i in (kubectl api-resources --verbs=list --namespaced -o name | grep -v "events.events.k8s.io" | grep -v "events" | sort | uniq)
echo -e "\nResource:" $i
kubectl get $i
end
end
