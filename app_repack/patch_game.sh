#!/usr/bin/env bash
set -e

# Dynamically determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Safely check for APKs in the app/ directory
shopt -s nullglob
APK_FILES=("$SCRIPT_DIR/app/"*.apk)
shopt -u nullglob

# Enforce exactly one APK rule
if [ ${#APK_FILES[@]} -eq 0 ]; then
    echo "[-] Error: No APK file found in $SCRIPT_DIR/app/."
    echo "    Please place your target APK inside the app/ folder."
    exit 1
elif [ ${#APK_FILES[@]} -gt 1 ]; then
    echo "[-] Error: Multiple APK files found in $SCRIPT_DIR/app/."
    for apk in "${APK_FILES[@]}"; do
        echo "      - $(basename "$apk")"
    done
    echo "    Please ensure there is exactly ONE APK file in the app/ folder."
    exit 1
fi

APK_PATH="${APK_FILES[0]}"
DECODE_DIR="$SCRIPT_DIR/decoded_gxb"
OUTPUT_APK="gxb_plaintext_standalone.apk"
UBER_SIGNER="/usr/local/bin/uber-apk-signer.jar"

echo "==> [1/3] Decompiling $(basename "$APK_PATH") into $DECODE_DIR..."
rm -rf "$DECODE_DIR"
apktool d "$APK_PATH" -o "$DECODE_DIR" -f

echo "==> [2/3] Handing over to decompiler and patching logic..."
chmod +x "$SCRIPT_DIR/decompile_and_patch.sh"
"$SCRIPT_DIR/decompile_and_patch.sh"

echo "==> [3/3] Repacking and Signing APK..."
apktool b "$DECODE_DIR" -o "$SCRIPT_DIR/unsigned_$OUTPUT_APK"
java -jar "$UBER_SIGNER" -a "$SCRIPT_DIR/unsigned_$OUTPUT_APK"

echo "=========================================================="
echo "✅ Build Complete: $SCRIPT_DIR/unsigned_${OUTPUT_APK%.apk}-aligned-signed.apk"
echo "=========================================================="
