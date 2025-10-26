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

read -p "🎯 Which track number do you want to remove? " TRACK_NUM

if [[ -z "$TRACK_NUM" ]]; then
    echo "❌ No track number entered. Exiting."
    exit 1
fi

shopt -s nullglob
COUNT=0
TOTAL=$(ls "$TARGET_DIR"/*.mkv 2>/dev/null | wc -l)

for FILE in "$TARGET_DIR"/*.mkv; do
    ((COUNT++))
    TMP_FILE="${FILE%.mkv}_tmp.mkv"

    echo "🔄 [$COUNT/$TOTAL] Processing '$FILE'... removing track $TRACK_NUM"

    # Build map options: include all streams except the one to remove
    MAP_ARGS=()
    STREAM_COUNT=$(ffprobe -v error -select_streams a:v:s -show_entries stream=index -of csv=p=0 "$FILE" | wc -l)
    
    for i in $(seq 0 $((STREAM_COUNT-1))); do
        if [[ "$i" -ne "$TRACK_NUM" ]]; then
            MAP_ARGS+=("-map" "0:$i")
        fi
    done

    # Copy all streams without re-encoding
    ffmpeg -y -i "$FILE" "${MAP_ARGS[@]}" -c copy "$TMP_FILE"

    if [[ $? -eq 0 ]]; then
        mv "$TMP_FILE" "$FILE"
        echo "✅ Successfully updated '$FILE'"
    else
        echo "⚠️ Failed to process '$FILE'. Temporary file left as '$TMP_FILE'."
    fi
done

echo "🎉 All done! Processed $COUNT files."
