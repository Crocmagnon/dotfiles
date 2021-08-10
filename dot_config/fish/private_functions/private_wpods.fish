# Defined interactively
function wpods
watch -n 2 kubectl get pods $argv
end
