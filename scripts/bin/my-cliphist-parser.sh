#!/bin/bash

THUMBS_DIR="$HOME/.cache/cliphist/thumbs"
mkdir -p "$THUMBS_DIR" # Ensure directory exists

# Debug log setup - ALL DEBUG LINES ARE UNCOMMENTED FOR MAXIMUM DETAIL
# DEBUG_LOG="$HOME/wofi_parser_debug_aggressive.log"
# printf " %s - START OF RUN \n" "$(date)" >"$DEBUG_LOG"

while IFS= read -r line; do
  cleaned_line=$(echo "$line" | sed 's/\xc2\xa0/ /g')

  # Use cleaned_line for all subsequent processing
  # printf "RAW INPUT: '%s'\nCLEANED INPUT: '%s'\n" "$line" "$cleaned_line" >>"$DEBUG_LOG" # Debug raw vs cleaned

  # Extract the first "word" (ID) from the cleaned line
  first_word=$(echo "$cleaned_line" | awk '{print $1}')

  # Check if the cleaned line is empty or if the first word is not purely numeric.
  if [[ -z "$cleaned_line" || ! "$first_word" =~ ^[0-9]+$ ]]; then
    # printf "SKIPPING NON-ID LINE: '%s'\n" "$cleaned_line" >>"$DEBUG_LOG" # Debug skipped lines
    echo "$line" # Output original line if not parsed
    continue
  fi

  id="$first_word"

  # The rest of the cleaned line is the description, stripped of the ID and leading whitespace.
  description=$(echo "$cleaned_line" | sed -E "s/^[0-9]+[[:space:]]*//")

  # REFINED IMAGE DETECTION:
  # Check if the description specifically matches the pattern of a binary image entry.
  # Now, with `sed` cleaning, the regex should match correctly formed strings.
  if [[ "$description" =~ ^\[\[[[:space:]]*binary[[:space:]]*data[[:space:]]*[0-9]+[[:space:]]*KiB[[:space:]]*[a-zA-Z]+[[:space:]]*[0-9]+x[0-9]+[[:space:]]*\]\]$ ]]; then
    # printf "REGEX MATCH: Description for ID %s matched image regex: '%s'\n" "$id" "$description" >>"$DEBUG_LOG"

    # Extract the specific image type (e.g., 'png', 'jpeg')
    image_type=$(echo "$description" | grep -oP 'KiB[[:space:]]+\K[a-zA-Z]+(?=[[:space:]]+[0-9]+x[0-9]+)')
    # printf "EXTRACTED IMAGE TYPE: '%s' for ID %s\n" "$image_type" "$id" >>"$DEBUG_LOG"

    case "$image_type" in
    png | jpeg | jpg | gif | webp | bmp) # List all supported image types here
      # printf "IMAGE TYPE SUPPORTED: '%s' for ID %s.\n" "$image_type" "$id" >>"$DEBUG_LOG"
      thumbnail_file="$THUMBS_DIR/$id.png" # Standardize to PNG for thumbnail storage

      # If thumbnail doesn't exist, try to generate it
      if [[ ! -f "$thumbnail_file" ]]; then
        # printf "GENERATING THUMBNAIL FOR ID: '%s'\n" "$id" >>"$DEBUG_LOG"
        # Attempt to decode and convert, redirecting stderr to null for silent errors
        if cliphist decode "$id" | convert - -thumbnail 100x100 "$thumbnail_file" 2>/dev/null; then
          # printf "THUMBNAIL GENERATED SUCCESSFULLY for ID: '%s'\n" "$id" >>"$DEBUG_LOG"
          echo "img:$thumbnail_file:text:$description"
        else
          # printf "FAILED TO GENERATE THUMBNAIL FOR ID: '%s'. Command failed.\n" "$id" >>"$DEBUG_LOG"
          echo "$description (Thumbnail failed)" # Provide clearer message to user if this happens
        fi
      else
        # printf "USING EXISTING THUMBNAIL FOR ID: '%s'\n" "$id" >>"$DEBUG_LOG"
        echo "img:$thumbnail_file:text:$description"
      fi
      ;;
    *)
      # printf "IMAGE TYPE NOT RECOGNIZED: '%s' for ID %s. Passing as text.\n" "$image_type" "$id" >>"$DEBUG_LOG"
      echo "$line"
      ;;
    esac
  else
    # printf "REGEX NO MATCH: Description for ID %s did NOT match image regex: '%s'\n" "$id" "$description" >>"$DEBUG_LOG"
    echo "$line"
  fi
done
# printf "%s - END OF RUN \n\n" "$(date)" >>"$DEBUG_LOG"
