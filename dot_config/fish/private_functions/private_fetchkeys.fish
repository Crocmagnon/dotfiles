function fetchkeys
  set -x NODE_OPTIONS "--no-deprecation"
  bwunlock
  set key_item (bw list items --search "SSH Main" | jq ".[0]" --raw-output)
  set key_item_id (echo $key_item | jq ".id" --raw-output)
  set key1 (echo $key_item | jq ".attachments[0]" --raw-output)
  set key1_name (echo $key1 | jq ".fileName" --raw-output)
  set key1_id (echo $key1 | jq ".id" --raw-output)
  set key2 (echo $key_item | jq ".attachments[1]" --raw-output)
  set key2_name (echo $key2 | jq ".fileName" --raw-output)
  set key2_id (echo $key2 | jq ".id" --raw-output)
  bw get attachment $key1_id --output "./$key1_name" --itemid $key_item_id
  bw get attachment $key2_id --output "./$key2_name" --itemid $key_item_id
  if string match -q -- '*.pub' $key1_name
    chmod 600 $key2_name
  else
    chmod 600 $key1_name
  end
end
