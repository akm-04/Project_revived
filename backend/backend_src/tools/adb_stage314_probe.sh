#!/usr/bin/env bash
set -u
PKG=com.carolgames.gxb
BASE=/data/data/$PKG
HOT=$BASE/files/$PKG
OUT=${1:-stage314_client_probe}
mkdir -p "$OUT"

echo "== Cocos prefs ==" | tee "$OUT/summary.txt"
adb shell "su -c 'cat $BASE/shared_prefs/Cocos2dxPrefsFile.xml 2>/dev/null'" | tee "$OUT/Cocos2dxPrefsFile.xml" >> "$OUT/summary.txt"

echo "== package prefs ==" >> "$OUT/summary.txt"
adb shell "su -c 'cat $BASE/shared_prefs/${PKG}_preferences.xml 2>/dev/null'" | tee "$OUT/com.carolgames.gxb_preferences.xml" >> "$OUT/summary.txt"

echo "== hot/download root top level ==" >> "$OUT/summary.txt"
adb shell "su -c 'ls -la $HOT 2>/dev/null'" | tee "$OUT/hot_root_ls.txt" >> "$OUT/summary.txt"

echo "== targeted MainScene/hot-update files ==" >> "$OUT/summary.txt"
adb shell "su -c 'if [ -d $HOT ]; then find $HOT -type f \\( -name version.json -o -name version_64.json -o -path \"*main_scene*\" -o -path \"*eco_sidebar*\" -o -path \"*skill_full*\" -o -path \"*LoadingScene.lua*\" -o -path \"*SelfPlayer.lua*\" -o -path \"*WindowManager.lua*\" \\) -print; fi'" | tee "$OUT/targeted_files.txt" >> "$OUT/summary.txt"

echo "== targeted checksums ==" >> "$OUT/summary.txt"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  adb shell "su -c 'md5sum \"$f\" 2>/dev/null || ls -l \"$f\" 2>/dev/null'" >> "$OUT/targeted_md5.txt"
done < "$OUT/targeted_files.txt"
cat "$OUT/targeted_md5.txt" 2>/dev/null >> "$OUT/summary.txt" || true

echo "== live game meta ==" >> "$OUT/summary.txt"
adb shell "su -c 'sqlite3 $BASE/files/game.db \"select id,sid,regionID,regionName,playerID,playerName from meta;\" 2>/dev/null'" | tee "$OUT/game_meta.txt" >> "$OUT/summary.txt"

echo "== native SDK user/session ==" >> "$OUT/summary.txt"
adb shell "su -c 'sqlite3 $BASE/databases/Xinyd.db \"select user_id,session,current_user_type,is_visiable,last_login from user;\" 2>/dev/null'" | tee "$OUT/xinyd_user.txt" >> "$OUT/summary.txt"

echo "Saved targeted Stage 3.1.4 probe to $OUT/"
