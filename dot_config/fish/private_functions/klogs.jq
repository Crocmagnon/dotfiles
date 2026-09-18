def c(code): if $color then "[" + code + "m" + . + "[0m" else . end;
def rpad(n): . + ((" " * (n - length)) // "");
def lvlname: {"0":"EMERG","1":"ALERT","2":"CRIT","3":"ERROR","4":"WARN","5":"NOTICE","6":"INFO","7":"DEBUG"}[tostring] // "L\(.)";
def lvlcolor: if . <= 2 then "1;35" elif . == 3 then "1;31" elif . == 4 then "33" elif . == 5 then "36" elif . == 7 then "2" else "32" end;
def hidden: ["version","host","timestamp","level","short_message","full_message","_pid","_file","_line","_app_env","_app_name","_app_region","_app_version","_caller","_source_file","_source_line_int"];

.message as $msg
| ((.containerName + "·" + (.podName | split("-") | last)) | .[0:26] | rpad(26) | c("36")) as $who
| (($msg | fromjson?) // null) as $j
| if ($j | type) == "object" and ($j.short_message? | type) == "string" then
    ($j.level // 6) as $l
  | ($j.timestamp | if type == "number" then
        (floor | strflocaltime("%H:%M:%S")) + "." + (("00" + ($j.timestamp * 1000 | floor % 1000 | tostring)) | .[-3:])
      else "            " end) as $ts
  | ($j
      | to_entries
      | map(select((.key | IN(hidden[])) | not))
      | map(select(.value as $v | .key != "_app_error" or ($j.short_message | contains($v | tostring) | not)))
      | map((.key | ltrimstr("_") | ltrimstr("app_")) + "=" + (.value | tostring))
      | join(" ")) as $extra
  | (($j._app_region // "?") | rpad(6) | c("2")) as $region
  | (($j._app_version // "?") | .[0:20] | rpad(20) | c("2")) as $ver
  | ($ts | c("2")) + " " + ($l | lvlname | rpad(6) | c($l | lvlcolor)) + " " + $region + " " + $ver + " " + $who + " " + $j.short_message
    + (if $extra == "" then "" else " " + ($extra | c("2")) end)
  else
    ("            " | c("2")) + " " + ("raw   " | c("2")) + " " + (" " * 28) + $who + " " + ($msg | c("2"))
  end
