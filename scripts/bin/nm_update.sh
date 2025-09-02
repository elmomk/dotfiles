#!/bin/bash -xe

WORD="$(cat ~/bin/.pass | base64 -d)"

nmcli c mod DynaOne-5G 802-1x.password "$WORD"
