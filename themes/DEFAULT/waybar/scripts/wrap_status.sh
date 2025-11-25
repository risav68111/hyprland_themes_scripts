#!/bin/bash

status=$(warp-cli status | grep -i 'Status' | awk '{print $2}')

if [[ "$status" == "Connected" ]]; then
    echo '{"text": "WARP", "tooltip": "Cloudflare WARP Connected", "class": "on"}'
else
    echo '{"text": "NO VPN", "tooltip": "VPN Disconnected", "class": "off"}'
fi

