function kjsonlogs
klogs $argv -o raw | jq -r -R 'fromjson? | select(type == "object") | "\(.time) \(.levelname) \(.message)"'
end
