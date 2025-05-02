function setup-mise
    if test -f .mise.toml; echo "mise is already setup"; return 1; end
    set cfg_file (find cmd -name config.yml)
    if test -z "$cfg_file"; echo "config file not found"; return 1; end
    echo "found config file: '$cfg_file'"
    echo "creating .mise.toml file..."
    echo -e "[env]\nCONFIGURATION_FROM=\"file:{{config_root}}/$cfg_file\"" >> .mise.toml
    mise trust -q
end
