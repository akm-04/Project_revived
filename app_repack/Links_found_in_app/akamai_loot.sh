#!/bin/bash

# Extract all 8-digit IDs starting with 1, 4, 5, or 6 from your res_id list
grep -Eo '\b[1456][0-9]{7}\b' res_id.txt | sort -u > target_ids.txt

TOTAL=$(wc -l < target_ids.txt)
echo "[*] Found $TOTAL exact Yotta IDs to probe."
echo "[*] Disguising wget to bypass AkamaiGHost WAF..."

mkdir -p akamai_loot

while read id; do
    URL="http://mhome.carolgames.com/assets/img/mobile_img/share_girls/${id}.png"
    FILE="akamai_loot/${id}.png"

    # wget disguised as an Android Samsung Galaxy S20
    wget -q \
         --user-agent="Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.162 Mobile Safari/537.36" \
         --header="Referer: http://mhome.carolgames.com/" \
         --header="Accept: image/webp,image/apng,image/*,*/*;q=0.8" \
         -O "$FILE" "$URL"

    # Akamai might return a 403 HTML page instead of an image.
    # We check if the downloaded file is actually a PNG/JPG.
    if ! file "$FILE" | grep -qE "PNG|JPEG|image data"; then
        rm "$FILE" # Delete the fake/error file
    else
        echo "[SUCCESS] Found and saved NPC/Asset: ${id}.png"
    fi

    # Sleep for 0.2 seconds to avoid triggering Akamai's rate limiter
    sleep 0.2

done < target_ids.txt

echo "------------------------------------------------"
echo "[*] Probe complete. Check the 'akamai_loot' folder."#!/bin/bash