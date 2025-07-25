#!/bin/bash

# Define the directory where cliphist-wofi-img *would* put thumbnails,
# or where you'll put them if you create them manually.
# cliphist-wofi-img generally puts them in ~/.cache/cliphist/thumbs/
THUMBS_DIR="$HOME/.cache/cliphist/thumbs"

# Ensure the thumbnails directory exists
mkdir -p "$THUMBS_DIR"

# Loop through each line of input from stdin (which will be `cliphist list` output)
while IFS= read -r line; do
  # Try to extract the ID from the beginning of the line
  # This assumes the ID is the first numeric string at the start of the line.
  id=$(echo "$line" | grep -oP '^\d+' | head -n 1)

  # Check if an ID was found and if it's an image line
  if [[ -n "$id" && "$line" =~ "[[ binary data" ]]; then
    # This is an image line.
    # The description is everything after the ID, stripped of leading/trailing whitespace.
    description=$(echo "$line" | sed -E "s/^[0-9]+[[:space:]]*//")

    # Construct the expected thumbnail path.
    # cliphist-wofi-img saves thumbnails as ID.png
    thumbnail_file="$THUMBS_DIR/$id.png"

    # Check if the thumbnail file actually exists.
    # This is the tricky part: if cliphist-wofi-img isn't working,
    # these thumbnails might not be getting generated.
    # You might need to manually run cliphist decode to get the image
    # and then use 'convert' from ImageMagick to create a thumbnail.
    # This script assumes a thumbnail *already exists* at that path.

    if [[ -f "$thumbnail_file" ]]; then
      # If thumbnail exists, output the Wofi image format
      echo "img:$thumbnail_file:text:$description"
    else
      # If no thumbnail found, just output the text description
      echo "$description (No preview)"
    fi
  else
    # Not an image line, or no ID found, just output the line as text
    echo "$line"
  fi
done
