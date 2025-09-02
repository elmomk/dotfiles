#!/bin/bash

# This script takes a screenshot of a selected region and then decodes
# a QR code from it using zbarimg.
# Dependencies: grim, slurp, zbarimg, wl-copy, notify-send

# Take a screenshot of the selected area and pipe it to zbarimg for decoding.
# `slurp -d` is used to interactively select a region on the screen.
# The `-` in `grim` and `zbarimg` indicates reading from or writing to stdin/stdout.

# The `zbarimg -q --raw -` command:
# - `-q`: "quiet" mode, suppresses informational output.
# - `--raw`: only prints the decoded data, without the barcode type.
# - `-`: reads the image data from standard input.

# Check for necessary dependencies
if [ ! -x "$(command -v grim)" ]; then
  echo "Error: 'grim' is not installed or not in your PATH." >&2
  exit 1
fi

if [ ! -x "$(command -v slurp)" ]; then
  echo "Error: 'slurp' is not installed or not in your PATH." >&2
  exit 1
fi

if [ ! -x "$(command -v zbarimg)" ]; then
  echo "Error: 'zbarimg' is not installed or not in your PATH." >&2
  exit 1
fi

if [ ! -x "$(command -v wl-copy)" ]; then
  echo "Error: 'wl-copy' is not installed or not in your PATH." >&2
  exit 1
fi

if [ ! -x "$(command -v notify-send)" ]; then
  echo "Error: 'notify-send' is not installed or not in your PATH." >&2
  exit 1
fi

# Use `grim` to capture a region selected by `slurp`, and pipe the image data
# directly to `zbarimg` for decoding.
# The output is captured in a variable.
DECODED_TEXT=$(grim -g "$(slurp -d)" - | zbarimg -q --raw - || true)

# Check if any text was decoded. If so, copy it to the clipboard and send a notification.
if [ -n "$DECODED_TEXT" ]; then
  echo "$DECODED_TEXT" | wl-copy
  notify-send "QR Code Decoded" "$DECODED_TEXT"
else
  notify-send "QR Code Decoder" "No QR code found."
fi
