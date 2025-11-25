#!/bin/bash

status=$(warp-cli status 2>/dev/null | grep 'Status update:' | awk '{print $3}')

# echo $status
if [[ "$status" == "Connected" ]]; then
  echo ''
elif [[ "$status" == "Connecting" ]]; then
  echo '󱌒'
else
  echo ''
fi

#           󱦄     
