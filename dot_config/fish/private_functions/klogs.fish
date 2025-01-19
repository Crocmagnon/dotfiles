# Defined interactively
function klogs --wraps="kubectl stern"
kubectl stern --tail=50 $argv
end
