#!/usr/bin/env bash
set -e

APK_NAME="base.apk"
DECODE_DIR="decoded_gxb"
OUTPUT_APK="gxb_plaintext_standalone.apk"
UBER_SIGNER="/usr/local/bin/uber-apk-signer.jar"

echo "==> [1/3] Decompiling $APK_NAME..."
rm -rf "$DECODE_DIR"
apktool d "$APK_NAME" -o "$DECODE_DIR" -f

echo "==> [2/3] Handing over to decompiler and patching logic..."
# Ensure the secondary script is executable before running
chmod +x decompile_and_patch.sh
./decompile_and_patch.sh

echo "==> [3/3] Repacking and Signing APK..."
apktool b "$DECODE_DIR" -o "unsigned_$OUTPUT_APK"
java -jar "$UBER_SIGNER" -a "unsigned_$OUTPUT_APK"

echo "=========================================================="
echo "✅ Build Complete: unsigned_${OUTPUT_APK%.apk}-aligned-signed.apk"
echo "=========================================================="
