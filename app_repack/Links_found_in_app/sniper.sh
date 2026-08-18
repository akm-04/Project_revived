#!/bin/bash

INPUT_FILE="clean_urls.txt"
TARGET_FILE="sniper_urls.txt"

echo "Extracting publisher-specific URLs..."

# Explicitly INCLUDE only the Yotta/Carolgames network and Zrok dev tunnels
grep -Eo '(http|https)://[^"<>\\]+' "$INPUT_FILE" | \
sort -u > "$TARGET_FILE"

TOTAL_URLS=$(wc -l < "$TARGET_FILE")
echo "Found $TOTAL_URLS high-value targets. Starting probe..."
echo "------------------------------------------------"

while read -r url; do
    # Probe with a 3-second timeout
    STATUS=$(curl -I -m 3 -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$STATUS" -eq 000 ]; then
        echo "[DEAD]     $url"
    elif [ "$STATUS" -eq 200 ]; then
        echo "[200 OK]   $url"
    elif [ "$STATUS" -eq 403 ] || [ "$STATUS" -eq 401 ]; then
        echo "[$STATUS]      $url (Alive, but access denied/requires auth)"
    elif [ "$STATUS" -eq 404 ]; then
        echo "[$STATUS]      $url (Alive, but endpoint missing)"
    else
        echo "[$STATUS]      $url"
    fi

done < "$TARGET_FILE"

echo "------------------------------------------------"
echo "Probe complete."#!/bin/bash