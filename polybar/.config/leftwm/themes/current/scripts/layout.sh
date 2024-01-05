#!/bin/bash

if [[ $(leftwm-state -q | jq '.workspaces[0].tags[].focused' | grep true 2>/dev/null) ]]; then
    leftwm-state -w 0 -s "{{ workspace.layout }}"
else
    leftwm-state -w 1 -s "{{ workspace.layout }}"
fi
