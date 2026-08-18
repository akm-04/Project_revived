#!/usr/bin/env bash
set -e

# Dynamically determine the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DECODE_DIR="$SCRIPT_DIR/decoded_gxb"

# FIX: Point OUTPUT_DIR to where the .exe actually generates the files
OUTPUT_DIR="$SCRIPT_DIR/tools/output"

# Zrok endpoints
ZROK_SDK_URL="https://gxbsdk.shares.zrok.io/"
ZROK_SDK_HOST="gxbsdk.shares.zrok.io"
ZROK_ENGINE_CENTER="https://gxbengine.shares.zrok.io/center/v1"
ZROK_ENGINE_API="https://gxbengine.shares.zrok.io/api/v1"

echo "  -> [A] Running LuaJIT Decompiler via Wine..."
rm -rf "$OUTPUT_DIR"
wine "$SCRIPT_DIR/tools/luajit-decompiler-v2.exe" "$DECODE_DIR" -e lua -s

echo "  -> [B] Merging ALL decompiled plaintext Lua over bytecode..."
cp -rv "$OUTPUT_DIR/assets/"* "$DECODE_DIR/assets/"

echo "  -> [C] Patching Java Smali..."
# 1. Patch Constant.smali (SDK Base URL)
CONSTANT_FILE="$DECODE_DIR/smali/com/xyd/platform/android/Constant.smali"
if [ -f "$CONSTANT_FILE" ]; then
    sed -i "s|https://mhome.carolgames.com/|$ZROK_SDK_URL|g" "$CONSTANT_FILE"
    echo "    [+] Patched Constant.smali"
else
    echo "    [!] Constant.smali not found!"
fi

# 2. Patch XinydUtils.smali (DNS Bypass)
XINYD_FILE="$DECODE_DIR/smali/com/xyd/platform/android/utility/XinydUtils.smali"
if [ -f "$XINYD_FILE" ]; then
    python3 -c "
import sys
filepath = sys.argv[1]
host = sys.argv[2]
with open(filepath, 'r') as f:
    content = f.read()

target = '.method public static getGoogleDNS('
if target in content:
    parts = content.split(target)
    rest = parts[1].split('.end method', 1)
    
    new_method = (
        ')Ljava/lang/String;\n'
        '    .registers 1\n\n'
        f'    const-string v0, \"{host}\"\n\n'
        '    return-object v0\n'
    )
    
    with open(filepath, 'w') as f:
        f.write(parts[0] + target + new_method + '.end method' + rest[1])
    print('    [+] Patched XinydUtils.smali (getGoogleDNS)')
" "$XINYD_FILE" "$ZROK_SDK_HOST"
else
    echo "    [!] XinydUtils.smali not found!"
fi

echo "  -> [D] Executing URL string patches on specific plaintext files..."
FILES_TO_PATCH=(
    "$DECODE_DIR/assets/src_32/UpdateScene.lua"
    "$DECODE_DIR/assets/src_32/UpdateScene_64.lua"
    "$DECODE_DIR/assets/src_64/UpdateScene.lua"
    "$DECODE_DIR/assets/src_64/UpdateScene_64.lua"
    "$DECODE_DIR/assets/src_32/data/tables/misc.lua"
    "$DECODE_DIR/assets/src_32/data/tables/misc1.lua"
    "$DECODE_DIR/assets/src_64/data/tables/misc.lua"
    "$DECODE_DIR/assets/src_64/data/tables/misc1.lua"
)

for file in "${FILES_TO_PATCH[@]}"; do
    if [ -f "$file" ]; then
        # 1. Nuke the primary domain
        sed -i 's|http://xuemeien.carolgames.com:9000|https://gxbengine.shares.zrok.io|g' "$file"
        
        # 2. Nuke the UpdateScene hardcoded IP
        sed -i 's|http://119.81.215.217:9000|https://gxbengine.shares.zrok.io|g' "$file"
        
        # 3. Nuke the misc table hardcoded IP
        sed -i 's|http://203.74.199.17:9000|https://gxbengine.shares.zrok.io|g' "$file"
        
        # 4. Nuke the newly discovered CDN domains
        sed -i 's|http://www.game168.tw|https://gxbengine.shares.zrok.io|g' "$file"
        sed -i 's|https://girls.game168.com.tw|https://gxbengine.shares.zrok.io|g' "$file"
        
        echo "    [+] Patched URLs in $(basename "$file")"
    fi
done

echo "  -> [E-Sub] Injecting AssetDownload Probe..."
PROBE_SCRIPT="$SCRIPT_DIR/patch_decoded_assetdownload_probe.py"
if [ -f "$PROBE_SCRIPT" ]; then
    python3 "$PROBE_SCRIPT" "$DECODE_DIR"
else
    echo "    [!] Probe script not found at $PROBE_SCRIPT, skipping..."
fi

# Cleanup raw output workspace
rm -rf "$OUTPUT_DIR"
echo "  -> [E] Temporary output directory cleaned."
