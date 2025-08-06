#!/bin/bash -xe

TIME=360

echo "Delete: $(/usr/bin/find $HOME/.cache/cliphist/thumbs/ -type f -mmin +$TIME)"
cliphist list

/usr/bin/find $HOME/.cache/cliphist/thumbs/ -type f -mmin +$TIME -delete

cliphist wipe

echo 'After cleanup:'
ls -halt $HOME/.cache/cliphist/thumbs/
cliphist list
