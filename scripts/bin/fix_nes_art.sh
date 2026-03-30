#!/bin/bash

# ==============================================================================
# Script: fix_nes_art.sh
# Purpose: Clean, resize (640px), and move scraped NES images for Miyoo Mini Plus
# Usage: ./fix_nes_art.sh -s <source_dir> -d <rom_dir> [-t|--test]
# ==============================================================================

# Default values
SOURCE_DIR=""
ROM_DIR=""
DRY_RUN=false

# Help message
usage() {
    echo "Usage: $0 -s <source_images_dir> -d <nes_roms_dir> [-t|--test]"
    echo ""
    echo "Options:"
    echo "  -s, --source   Directory containing the scraped images"
    echo "  -d, --dest     Your NES/FC ROMs directory (e.g., /path/to/Roms/FC)"
    echo "  -t, --test     Dry run (preview changes without moving files)"
    echo "  -h, --help     Show this help message"
    exit 1
}

# Check for ImageMagick dependency
if ! command -v convert &> /dev/null && ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick is not installed."
    echo "Please install it using: sudo pacman -S imagemagick (Arch) or sudo apt install imagemagick (Debian/Ubuntu)"
    exit 1
fi

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--source) SOURCE_DIR="$2"; shift ;;
        -d|--dest) ROM_DIR="$2"; shift ;;
        -t|--test) DRY_RUN=true ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Validation
if [[ -z "$SOURCE_DIR" || -z "$ROM_DIR" ]]; then
    echo "Error: Source and Destination directories are required."
    usage
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

# Define Onion OS Images directory
IMG_DIR="$ROM_DIR/Imgs"

# Create destination if it doesn't exist (unless dry run)
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$IMG_DIR"
fi

echo "---------------------------------------------------"
echo "Processing NES Art..."
echo "Source: $SOURCE_DIR"
echo "Target: $IMG_DIR"
echo "Action: Rename + Resize to 640px width"
if [ "$DRY_RUN" = true ]; then echo "MODE: DRY RUN (No changes will be made)"; fi
echo "---------------------------------------------------"

count=0

# Loop through images (png, jpg, jpeg)
find "$SOURCE_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | while read -r filepath; do
    filename=$(basename "$filepath")
    extension="${filename##*.}"
    base_name="${filename%.*}"

    # CLEANUP LOGIC
    # Remove common scraper suffixes (-image, -thumb, -mix, _boxart)
    new_base_name=$(echo "$base_name" | sed -E 's/(-image|-thumb|-mix|_boxart|_image)$//')
    
    new_filename="${new_base_name}.${extension}"
    dest_path="$IMG_DIR/$new_filename"

    # Action
    if [ "$DRY_RUN" = true ]; then
        echo "[TEST] Would resize and save: '$filename' -> '$dest_path'"
    else
        # Use ImageMagick to convert/resize
        # -resize 640> means "resize to width 640 only if the image is larger than that"
        if command -v magick &> /dev/null; then
            magick "$filepath" -resize 640\> "$dest_path"
        else
            convert "$filepath" -resize 640\> "$dest_path"
        fi
        
        echo "Processed: $new_filename"
    fi
    ((count++))
done

echo "---------------------------------------------------"
if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete."
else
    echo "Done. Processed files."
    echo "Make sure to Refresh Roms in Onion OS (Select + Menu on main screen)."
fi
