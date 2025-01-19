function kjsonlogs
klogs $argv -o raw | jq -r -R 'fromjson? | select(type == "object") | "\(.timestamp) \(.level) \(.short_message)"'
end
