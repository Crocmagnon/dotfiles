function showcert
openssl s_client -connect $argv[1]:443 -servername $argv[1] -showcerts < /dev/null
end
