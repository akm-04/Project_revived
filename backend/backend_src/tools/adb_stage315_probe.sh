#!/usr/bin/env bash
set -u

PKG=com.carolgames.gxb
BASE=/data/data/$PKG
HOT=$BASE/files/$PKG
OUT=${1:-stage315_client_probe}
mkdir -p "$OUT" "$OUT/hot_files"

SUMMARY="$OUT/summary.txt"
: > "$SUMMARY"

echo "== Stage 3.1.5 runtime probe ==" | tee -a "$SUMMARY"
echo "package=$PKG" | tee -a "$SUMMARY"
echo "hot_root=$HOT" | tee -a "$SUMMARY"

echo "== Cocos prefs ==" | tee -a "$SUMMARY"
adb exec-out "su -c 'cat $BASE/shared_prefs/Cocos2dxPrefsFile.xml 2>/dev/null'" > "$OUT/Cocos2dxPrefsFile.xml" </dev/null || true
cat "$OUT/Cocos2dxPrefsFile.xml" 2>/dev/null | tee -a "$SUMMARY" >/dev/null || true

echo "== hot/download root top level ==" | tee -a "$SUMMARY"
adb shell "su -c 'ls -la $HOT 2>/dev/null'" </dev/null | tee "$OUT/hot_root_ls.txt" | tee -a "$SUMMARY" >/dev/null || true

# Capture the small hot-update metadata files directly.
for meta in .revision .download_infos; do
  adb exec-out "su -c 'cat $HOT/$meta 2>/dev/null'" > "$OUT/${meta#.}.txt" </dev/null || true
done

# These paths can actually change runtime behavior.  Unlike the Stage 3.1.4
# helper, match the real CamelCase Lua names and pull the files rather than
# merely listing them.
echo "== targeted runtime Lua/resources ==" | tee -a "$SUMMARY"
adb shell "su -c 'if [ -d $HOT ]; then find $HOT -type f \
  \\( -name version.json \
  -o -name LoadingScene.lua \
  -o -name LoginWindow.lua \
  -o -name RegionWindow.lua \
  -o -name SelfPlayer.lua \
  -o -name WindowManager.lua \
  -o -name Backend.lua \
  -o -name AssetDownload.lua \
  -o -name StoryData.lua \
  -o -name \"MainScene*.lua\" \
  -o -path \"*eco_sidebar.csb\" \
  -o -path \"*skill_full*\" \\) -print; fi'" </dev/null \
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
cat "$OUT/targeted_md5.txt" 2>/dev/null | tee -a "$SUMMARY" >/dev/null || true

# Pull the three small client DBs as raw SQLite files, then query with host
# sqlite3.  This avoids depending on a sqlite3 binary existing on Android.
echo "== local game/native/error databases ==" | tee -a "$SUMMARY"
adb exec-out "su -c 'cat $BASE/files/game.db 2>/dev/null'" > "$OUT/game.db" </dev/null || true
adb exec-out "su -c 'cat $BASE/databases/Xinyd.db 2>/dev/null'" > "$OUT/Xinyd.db" </dev/null || true
adb exec-out "su -c 'cat $BASE/files/log.db 2>/dev/null'" > "$OUT/log.db" </dev/null || true

if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 "$OUT/game.db" 'select id,sid,regionID,regionName,playerID,playerName from meta;' > "$OUT/game_meta.txt" 2>/dev/null || true
  sqlite3 "$OUT/game.db" 'select id,storyID,guideID,funcIDs from storyGuideData;' > "$OUT/story_guide.txt" 2>/dev/null || true
  sqlite3 "$OUT/game.db" 'select formationID,playerID,formationData from formation order by playerID,formationID;' > "$OUT/formations.txt" 2>/dev/null || true
  sqlite3 "$OUT/Xinyd.db" 'select user_id,session,current_user_type,is_visiable,last_login from user;' > "$OUT/xinyd_user.txt" 2>/dev/null || true
  sqlite3 "$OUT/log.db" 'select time,app_v,version,isCrash,dump,log from errorlog order by time;' > "$OUT/errorlog.txt" 2>/dev/null || true
else
  echo "host sqlite3 not found; raw DB files were still captured" | tee -a "$SUMMARY"
fi

for f in game_meta.txt story_guide.txt formations.txt xinyd_user.txt errorlog.txt; do
  echo "== $f ==" >> "$SUMMARY"
  cat "$OUT/$f" 2>/dev/null >> "$SUMMARY" || true
done

# Produce a compact inventory of what was actually pulled.
echo "== pulled targeted files ==" | tee -a "$SUMMARY"
find "$OUT/hot_files" -type f -printf '%P\t%s bytes\n' 2>/dev/null | sort \
  | tee "$OUT/pulled_files.txt" | tee -a "$SUMMARY" >/dev/null || true

echo "Saved Stage 3.1.5 runtime probe to $OUT/"
