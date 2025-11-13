#!/bin/bash

clear

if [[ -z "$1" ]]; then
    echo "❌ Usage: $0 path-to-directory"
    exit 1
fi

TARGET_DIR="$1"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "❌ Directory '$TARGET_DIR' does not exist."
    exit 1
fi

FIRST_FILE=$(ls "$TARGET_DIR"/*.mkv 2>/dev/null | head -n 1)
if [[ -z "$FIRST_FILE" ]]; then
    echo "❌ No MKV files found in '$TARGET_DIR'."
    exit 1
fi

echo "🎬 Inspecting first file: $(basename "$FIRST_FILE")"
echo "------------------------------------------------------------"
ffprobe -v error -show_entries stream=index,codec_type,codec_name:stream_tags=language,title \
    -of csv=p=0 "$FIRST_FILE" | nl -v 0
echo "------------------------------------------------------------"

read -p "🎯 Enter the track number you want to remove from ALL files: " TRACK_NUM
if [[ -z "$TRACK_NUM" ]]; then
    echo "❌ No track number entered. Exiting."
    exit 1
fi

shopt -s nullglob
COUNT=0
FILES=("$TARGET_DIR"/*.mkv)
TOTAL=${#FILES[@]}

for FILE in "${FILES[@]}"; do
    ((COUNT++))
    TMP_FILE="${FILE%.mkv}_tmp.mkv"

    echo "🔄 [$COUNT/$TOTAL] Processing '$(basename "$FILE")'... removing track $TRACK_NUM"

    # Get total stream count
    STREAM_COUNT=$(ffprobe -v error -show_entries stream=index -of csv=p=0 "$FILE" | wc -l)

    # Build -map arguments (include all except the chosen one)
    MAP_ARGS=()
    for i in $(seq 0 $((STREAM_COUNT-1))); do
        if [[ "$i" -ne "$TRACK_NUM" ]]; then
            MAP_ARGS+=("-map" "0:$i")
        fi
    done

    ffmpeg -hide_banner -loglevel warning -y -i "$FILE" "${MAP_ARGS[@]}" -c copy "$TMP_FILE"
    if [[ $? -eq 0 ]]; then
        mv "$TMP_FILE" "$FILE"
        echo "✅ Successfully updated '$(basename "$FILE")'"
    else
        echo "⚠️ Failed to process '$(basename "$FILE")'. Temporary file left as '$TMP_FILE'."
    fi
done

echo
echo "🎉 All done! Processed $COUNT files."
