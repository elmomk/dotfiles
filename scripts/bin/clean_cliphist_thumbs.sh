#!/bin/bash -xe

LOG_FILE="/tmp/cliphist-thumbs-cleanup-$(date +%Y-%m-%d).log"

echo "Starting cliphist thumbnail cleanup at $(date)" >>"$LOG_FILE"

/usr/bin/find $HOME/.cache/cliphist/thumbs/ -type f -mtime +1 -delete >>"$LOG_FILE" 2>&1
cliphist wipe >>"$LOG_FILE" 2>&1

echo "Finished cliphist thumbnail cleanup at $(date)" >>"$LOG_FILE"
