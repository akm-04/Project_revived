#!/usr/bin/env bash
# Rejoins the artifacts split in tools/parts (GitHub's 100 MB file limit), checks each against MANIFEST.sha256 and unzips
# the zips into <destination>/<name without .zip>/ (EXTRACT=0 skips unzipping).
# usage: tools/assemble.sh <destination dir> [artifact name ...]   (no names: every artifact in MANIFEST.sha256)
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DESTINATION=$(realpath -m "${1:?destination directory}")
shift
mkdir -p "$DESTINATION"
names=("$@")
if [ ${#names[@]} -eq 0 ]; then mapfile -t names < <(awk '{print $2}' "$HERE/MANIFEST.sha256"); fi
for name in "${names[@]}"; do
  expected=$(awk -v name="$name" '$2 == name {print $1}' "$HERE/MANIFEST.sha256")
  [ -n "$expected" ] || { echo "unknown artifact $name (see $HERE/MANIFEST.sha256)" >&2; exit 1; }
  cat "$HERE/parts/$name".part-* > "$DESTINATION/$name"
  actual=$(sha256sum < "$DESTINATION/$name" | cut -d' ' -f1)
  [ "$actual" = "$expected" ] || { echo "checksum mismatch for $name: $actual" >&2; exit 1; }
  echo "assembled $DESTINATION/$name (sha256 ok)"
  if [ "${EXTRACT:-1}" = 1 ] && [[ $name == *.zip ]]; then
    unzip -q -o "$DESTINATION/$name" -d "$DESTINATION/${name%.zip}"
    echo "  extracted to $DESTINATION/${name%.zip}/"
  fi
done
