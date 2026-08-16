#!/usr/bin/env bash
# Targeted post-failure HeroMain probe. Run after reproducing Aquaris if the
# Stage 4A.2 four-slot element-equipment fix does not fully open hero_main.
set -u

PKG=com.carolgames.gxb
BASE=/data/data/$PKG
HOT=$BASE/files/$PKG
OUT=${1:-stage4a2_hero_probe}
mkdir -p "$OUT" "$OUT/hot_files"
SUMMARY="$OUT/summary.txt"
: > "$SUMMARY"

echo "== Stage 4A.2 HeroMain probe ==" | tee -a "$SUMMARY"
echo "package=$PKG" | tee -a "$SUMMARY"
echo "hot_root=$HOT" | tee -a "$SUMMARY"

# Pull the game's private error DB and query it with host sqlite3. The release
# APK does not reliably mirror Lua exceptions to Android logcat.
adb exec-out "su -c 'cat $BASE/files/log.db 2>/dev/null'" > "$OUT/log.db" </dev/null || true
if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 "$OUT/log.db" 'select time,app_v,version,isCrash,dump,log from errorlog order by time;' \
    > "$OUT/errorlog.txt" 2>/dev/null || true
else
  echo "host sqlite3 not found; raw log.db was still captured" | tee -a "$SUMMARY"
fi

echo "== targeted hot HeroMain files ==" | tee -a "$SUMMARY"
adb shell "su -c 'if [ -d $HOT ]; then find $HOT -type f \
  \( -name HeroMainWindow.lua \
  -o -path \"*/windows/hero/hero.csb\" \
  -o -path \"*/windows/hero/info_container.csb\" \
  -o -path \"*/windows/hero/element_equip.csb\" \
  -o -path \"*/windows/hero/equip.csb\" \
  -o -path \"*/windows/hero/breach/breach_item.csb\" \
  -o -path \"*/skeletons/ui_effect/hero/hero_bg_effect01*\" \
  -o -path \"*/skeletons/ui_effect/hero/hero_bg_effect02*\" \
  \) -print; fi'" </dev/null \
  | tee "$OUT/targeted_files.txt" | tee -a "$SUMMARY" >/dev/null || true

: > "$OUT/targeted_md5.txt"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  adb shell "su -c 'md5sum $f 2>/dev/null || ls -l $f 2>/dev/null'" </dev/null >> "$OUT/targeted_md5.txt" || true
  rel=${f#"$HOT"/}
  local_path="$OUT/hot_files/$rel"
  mkdir -p "$(dirname "$local_path")"
  adb exec-out "su -c 'cat $f 2>/dev/null'" > "$local_path" </dev/null || true
done < "$OUT/targeted_files.txt"

{
  echo "== errorlog =="
  cat "$OUT/errorlog.txt" 2>/dev/null || true
  echo "== checksums =="
  cat "$OUT/targeted_md5.txt" 2>/dev/null || true
  echo "== pulled files =="
  find "$OUT/hot_files" -type f -printf '%P\t%s bytes\n' 2>/dev/null | sort || true
} >> "$SUMMARY"

echo "Saved Stage 4A.2 HeroMain probe to $OUT/"
