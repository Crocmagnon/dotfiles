function klogs --wraps=stern
    stern --tail=50 $argv
end
