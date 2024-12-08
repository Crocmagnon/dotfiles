function ansible-encrypt-to-clipboard
read -s val
ansible-vault encrypt_string -- "$val" | grep -v Encryption | pbcopy
end
