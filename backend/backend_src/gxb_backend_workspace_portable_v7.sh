#!/usr/bin/env bash
set -euo pipefail

WRAPPER_VERSION="7"
WRAPPER_BUILD="pass353-persistent-ota-topology"

# Workspace wrapper for canonical/portable GXB backend ZIPs.
# Keeps mutable runtime and legacy migration input outside current_backend so
# replacing the extracted backend never destroys PostgreSQL or source evidence.

RES_PATH="${RES_PATH:-/home/akm/Miscallaneus/recovery/gxb/tmp/backend/local_assets/res}"
OLD_RES_PATH="${OLD_RES_PATH:-/home/akm/Miscallaneus/recovery/gxb/decode_asses/com.carolgames.gxb/res}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${BACKEND_DIR:-$SCRIPT_DIR/backend}"
PRESERVE_DIR="${PRESERVE_DIR:-$SCRIPT_DIR/preserve}"
CURRENT_DIR="${CURRENT_DIR:-$SCRIPT_DIR/current_backend}"
RUNTIME_DIR="${GXB_DEV_HOME:-$SCRIPT_DIR/runtime}"
WORKSPACE_BACKUP_DIR="${GXB_WORKSPACE_BACKUP_DIR:-$SCRIPT_DIR/backup}"
OTA_DIR="${GXB_OTA_HOME:-$RUNTIME_DIR/ota}"

log()  { printf '[gxb-workspace] %s\n' "$*"; }
warn() { printf '[gxb-workspace] WARNING: %s\n' "$*" >&2; }
die()  { printf '[gxb-workspace] ERROR: %s\n' "$*" >&2; exit 1; }

heal_exec_permissions() {
  local root="$1"
  [[ -d "$root" ]] || return 0

  # Portable archives occasionally lose Unix execute mode metadata when they are
  # repacked on another platform/tool.  Treat scripts/program launchers as
  # executable workspace assets and repair their mode bits after extraction.
  find "$root" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod a+x {} + 2>/dev/null || true
  if [[ -d "$root/bin" ]]; then
    find "$root/bin" -type f -exec chmod a+x {} + 2>/dev/null || true
  fi
  if [[ -d "$root/vendor" ]]; then
    find "$root/vendor" -type f \( -path '*/bin/*' -o -path '*/sbin/*' \) -exec chmod a+x {} + 2>/dev/null || true
  fi

  # These are required by the wrapper itself; fail loudly if they remain
  # non-executable after the repair rather than producing a later opaque error.
  if [[ -f "$root/gxb-dev.sh" && ! -x "$root/gxb-dev.sh" ]]; then
    die "could not repair executable permission on $root/gxb-dev.sh"
  fi
  log "executable permissions verified/healed under: $root"
}


clear_runtime_logs() {
  local logs="$RUNTIME_DIR/logs"
  mkdir -p "$logs"
  find "$logs" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || true
  log "runtime logs cleared for new backend update: $logs"
}

workspace_backup() {
  local stamp label capture dump meta stage archive zip py
  [[ -d "$CURRENT_DIR" ]] || die "current_backend does not exist; run '$0 setup' first"
  heal_exec_permissions "$CURRENT_DIR"
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  label="${1:-manual}"; label="${label//[^A-Za-z0-9._-]/_}"
  mkdir -p "$WORKSPACE_BACKUP_DIR" "$RUNTIME_DIR"
  capture="$RUNTIME_DIR/.workspace-backup-$stamp.txt"
  "$CURRENT_DIR/gxb-dev.sh" db-backup "workspace-$label-$stamp" | tee "$capture"
  dump="$(tail -n 1 "$capture")"; rm -f "$capture"
  [[ -f "$dump" ]] || die "database backup did not produce a dump: $dump"
  meta="${dump%.dump}.json"
  [[ -f "$meta" ]] || die "database backup metadata missing: $meta"
  stage="$WORKSPACE_BACKUP_DIR/.gxb-backup-$stamp.$$"
  archive="$WORKSPACE_BACKUP_DIR/gxb-postgresql-$stamp-$label.tar.gz"
  rm -rf -- "$stage"; mkdir -p "$stage"
  cp -- "$dump" "$stage/database.dump"
  cp -- "$meta" "$stage/database.json"
  [[ -f "$CURRENT_DIR/VERSION.json" ]] && cp -- "$CURRENT_DIR/VERSION.json" "$stage/VERSION.json"
  zip="$(select_latest_backend_zip)"
  py="$(command -v python3 || true)"; [[ -n "$py" ]] || die "python3 is required to create workspace backup archive"
  "$py" - "$stage" "$archive" "$zip" "$WRAPPER_VERSION" "$WRAPPER_BUILD" <<'PYBACKUP'
from pathlib import Path
import hashlib,json,os,sys,tarfile,time
stage=Path(sys.argv[1]); archive=Path(sys.argv[2]); backend_zip=Path(sys.argv[3]); wrapper_version=sys.argv[4]; wrapper_build=sys.argv[5]
def sha(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()
meta=json.loads((stage/'database.json').read_text(encoding='utf-8'))
manifest={
  'format':'GXB_WORKSPACE_POSTGRESQL_BACKUP_V1',
  'created_unix':int(time.time()),
  'wrapper_version':wrapper_version,
  'wrapper_build':wrapper_build,
  'database_dump':'database.dump',
  'database_sha256':sha(stage/'database.dump'),
  'database_metadata':meta,
  'backend_archive_name':backend_zip.name,
  'backend_archive_sha256':sha(backend_zip),
  'restore_semantics':'PostgreSQL canonical state only; no legacy JSON remigration',
}
(stage/'BACKUP_MANIFEST.json').write_text(json.dumps(manifest,indent=2,sort_keys=True)+'\n',encoding='utf-8')
with tarfile.open(archive,'w:gz') as tf:
    for name in ('BACKUP_MANIFEST.json','database.dump','database.json','VERSION.json'):
        p=stage/name
        if p.exists(): tf.add(p,arcname=name,recursive=False)
print(archive)
PYBACKUP
  rm -rf -- "$stage"
  log "workspace PostgreSQL backup ready: $archive"
  printf '%s\n' "$archive"
}

select_restore_archive() {
  local requested="${1:-}" selected
  if [[ -n "$requested" ]]; then
    [[ -f "$requested" ]] || die "backup archive not found: $requested"
    printf '%s\n' "$requested"; return
  fi
  [[ -d "$WORKSPACE_BACKUP_DIR" ]] || die "backup directory not found: $WORKSPACE_BACKUP_DIR"
  selected="$(find "$WORKSPACE_BACKUP_DIR" -maxdepth 1 -type f -name 'gxb-postgresql-*.tar.gz' -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
  [[ -n "$selected" && -f "$selected" ]] || die "no gxb-postgresql-*.tar.gz backup found under $WORKSPACE_BACKUP_DIR"
  printf '%s\n' "$selected"
}

workspace_restore() {
  local archive stage py expected_sha was_running=0
  archive="$(select_restore_archive "${1:-}")"
  [[ -d "$CURRENT_DIR" ]] || die "current_backend does not exist; run '$0 setup' first"
  heal_exec_permissions "$CURRENT_DIR"
  py="$(command -v python3 || true)"; [[ -n "$py" ]] || die "python3 is required to restore workspace backup archive"
  stage="$RUNTIME_DIR/.restore-staging.$$"; rm -rf -- "$stage"; mkdir -p "$stage"
  expected_sha="$($py - "$archive" "$stage" <<'PYRESTORE'
from pathlib import Path
import hashlib,json,sys,tarfile
archive,stage=Path(sys.argv[1]),Path(sys.argv[2])
allowed={'BACKUP_MANIFEST.json','database.dump','database.json','VERSION.json'}
with tarfile.open(archive,'r:gz') as tf:
    members=tf.getmembers()
    names={m.name for m in members}
    if not {'BACKUP_MANIFEST.json','database.dump','database.json'} <= names:
        raise SystemExit('backup archive is missing required members')
    for m in members:
        p=Path(m.name)
        if m.name not in allowed or m.isdir() or p.is_absolute() or '..' in p.parts or not m.isfile():
            raise SystemExit(f'unsafe/unexpected backup member: {m.name}')
    tf.extractall(stage, filter='data')
manifest=json.loads((stage/'BACKUP_MANIFEST.json').read_text(encoding='utf-8'))
if manifest.get('format') != 'GXB_WORKSPACE_POSTGRESQL_BACKUP_V1':
    raise SystemExit('unsupported backup manifest format')
h=hashlib.sha256()
with open(stage/'database.dump','rb') as f:
    for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
actual=h.hexdigest(); expected=str(manifest.get('database_sha256') or '')
if not expected or actual != expected:
    raise SystemExit(f'database dump hash mismatch expected={expected} actual={actual}')
print(expected)
PYRESTORE
)" || { rm -rf -- "$stage"; die "backup verification failed: $archive"; }
  for svc in http realtime scheduler proxy; do
    if [[ -f "$RUNTIME_DIR/run/$svc.pid" ]] && kill -0 "$(cat "$RUNTIME_DIR/run/$svc.pid" 2>/dev/null || echo 0)" 2>/dev/null; then was_running=1; break; fi
  done
  if (( was_running )); then log "stopping application stack before restore"; "$CURRENT_DIR/gxb-dev.sh" stop; fi
  log "restoring canonical PostgreSQL state from: $archive"
  "$CURRENT_DIR/gxb-dev.sh" db-restore "$stage/database.dump" "$expected_sha"
  rm -rf -- "$stage"
  if (( was_running )); then log "application was running before restore; restarting it"; "$CURRENT_DIR/gxb-dev.sh" start; fi
  log "workspace PostgreSQL restore complete"
}


select_latest_backend_zip() {
  [[ -d "$BACKEND_DIR" ]] || die "backend directory not found: $BACKEND_DIR"
  local selected
  selected="$(find "$BACKEND_DIR" -maxdepth 1 -type f -name 'gxb-backend-v*-pass*.zip' -printf '%f\n' | python3 -c '
import re,sys
rows=[]
pat=re.compile(r"^gxb-backend-v(\d+(?:\.\d+)*)-pass(\d+(?:\.\d+)*)(?:-([A-Za-z0-9._-]+))?\.zip$")
for raw in sys.stdin:
    name=raw.strip(); m=pat.match(name)
    if not m: continue
    parts=lambda s: tuple(int(x) for x in s.split("."))
    suffix=m.group(3) or ""
    # For the same canonical backend/pass, prefer the highest portable-devN
    # packaging revision over the unsuffixed archive. Semantic backend/pass
    # versions still dominate packaging revisions.
    dm=re.search(r"(?:^|-)portable-dev(\d+)(?:$|-)", suffix)
    packaging_rank=int(dm.group(1)) if dm else 0
    rows.append((parts(m.group(1)), parts(m.group(2)), packaging_rank, name))
if not rows: raise SystemExit(2)
rows.sort(); print(rows[-1][3])
')" || die "no canonical gxb-backend-v*-pass*.zip found in $BACKEND_DIR"
  printf '%s\n' "$BACKEND_DIR/$selected"
}

link_dir() {
  local path="$1" target="$2" label="$3"
  rm -rf -- "$path"
  [[ -n "$target" ]] || { log "$label disabled"; return; }
  [[ -d "$target" ]] || { warn "$label not found; skipping: $target"; return; }
  ln -s -- "$target" "$path"; log "$label -> $target"
}

link_file() {
  local path="$1" target="$2" label="$3"
  rm -f -- "$path"
  [[ -f "$target" ]] || return 0
  ln -s -- "$target" "$path"; log "$label -> $target"
}

seed_and_wire_ota_state() {
  local root="$1" source="${2:-}" f
  mkdir -p "$OTA_DIR" "$OTA_DIR/updates"

  # Upgrade from pre-v7 workspaces without discarding any already-generated
  # publication state. Only seed files that do not yet exist in persistent OTA.
  if [[ -n "$source" && -d "$source/local_assets" ]]; then
    if [[ ! -e "$OTA_DIR/updates/.gxb-seeded" && -d "$source/local_assets/updates" && ! -L "$source/local_assets/updates" ]]; then
      cp -a "$source/local_assets/updates/." "$OTA_DIR/updates/" 2>/dev/null || true
      : > "$OTA_DIR/updates/.gxb-seeded"
    fi
    for f in release_registry.json update_manifest.json update_controller_state.json; do
      if [[ ! -e "$OTA_DIR/$f" && -f "$source/local_assets/$f" && ! -L "$source/local_assets/$f" ]]; then
        cp -- "$source/local_assets/$f" "$OTA_DIR/$f"
      fi
    done
  fi

  # First v7 setup seeds the persistent store from the new package defaults.
  for f in release_registry.json update_manifest.json update_controller_state.json; do
    if [[ ! -e "$OTA_DIR/$f" && -f "$root/local_assets/$f" ]]; then
      cp -- "$root/local_assets/$f" "$OTA_DIR/$f"
    fi
  done

  rm -rf -- "$root/local_assets/updates"
  ln -s -- "$OTA_DIR/updates" "$root/local_assets/updates"
  for f in release_registry.json update_manifest.json update_controller_state.json; do
    rm -f -- "$root/local_assets/$f"
    [[ -e "$OTA_DIR/$f" ]] && ln -s -- "$OTA_DIR/$f" "$root/local_assets/$f"
  done
  log "persistent OTA publication state -> $OTA_DIR"
}

setup_workspace() {
  local zip tmp old nested
  zip="$(select_latest_backend_zip)"; log "selected backend: $(basename "$zip")"
  unzip -tq "$zip" >/dev/null || die "ZIP integrity check failed: $zip"
  tmp="$SCRIPT_DIR/.current_backend.new.$$"; old="$SCRIPT_DIR/.current_backend.old.$$"
  rm -rf -- "$tmp" "$old"; mkdir -p "$tmp"
  trap 'rm -rf -- "$tmp" "$old"' EXIT
  unzip -q "$zip" -d "$tmp"
  if [[ ! -f "$tmp/server.py" ]]; then
    mapfile -t roots < <(find "$tmp" -mindepth 1 -maxdepth 1 -type d -print)
    if ((${#roots[@]} == 1)) && [[ -f "${roots[0]}/server.py" ]]; then
      nested="${roots[0]}"; mv "$nested" "$tmp.flatten"; rm -rf "$tmp"; mv "$tmp.flatten" "$tmp"
    else die "archive has no backend root/server.py"; fi
  fi

  heal_exec_permissions "$tmp"

  mkdir -p "$tmp/local_assets" "$tmp/migration_inputs" "$RUNTIME_DIR"
  seed_and_wire_ota_state "$tmp" "$CURRENT_DIR"
  link_dir "$tmp/local_assets/res" "$RES_PATH" "current res"
  link_dir "$tmp/local_assets/old_res" "$OLD_RES_PATH" "old_res"
  if [[ -d "$PRESERVE_DIR/server_state" ]]; then link_dir "$tmp/migration_inputs/server_state" "$PRESERVE_DIR/server_state" "legacy server_state (migration input only)"; fi
  link_file "$tmp/migration_inputs/player_db.json" "$PRESERVE_DIR/player_db.json" "legacy singleton"
  link_file "$tmp/migration_inputs/hocrux.txt" "$PRESERVE_DIR/hocrux.txt" "legacy hocrux"

  cat > "$tmp/.gxb-workspace" <<EOF
export GXB_DEV_HOME=$(printf '%q' "$RUNTIME_DIR")
export GXB_LEGACY_SERVER_STATE=$(printf '%q' "$PRESERVE_DIR/server_state")
export GXB_BACKEND_ARCHIVE=$(printf '%q' "$zip")
export GXB_OTA_HOME=$(printf '%q' "$OTA_DIR")
EOF

  if [[ -e "$CURRENT_DIR" || -L "$CURRENT_DIR" ]]; then mv "$CURRENT_DIR" "$old"; fi
  mv "$tmp" "$CURRENT_DIR"; rm -rf -- "$old"; trap - EXIT
  log "setup complete: $CURRENT_DIR"
  log "mutable runtime preserved at: $RUNTIME_DIR"
  log "legacy JSON remains read-only migration input under: $PRESERVE_DIR"
  [[ -x "$CURRENT_DIR/gxb-dev.sh" ]] && "$CURRENT_DIR/gxb-dev.sh" doctor || true
}

update_workspace() {
  local was_running=0 stamp newzip
  newzip="$(select_latest_backend_zip)"
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "$RUNTIME_DIR/update-snapshots/$stamp"
  printf 'new_archive=%s\n' "$newzip" > "$RUNTIME_DIR/update-snapshots/$stamp/update.env"

  heal_exec_permissions "$CURRENT_DIR"
  if [[ -x "$CURRENT_DIR/gxb-dev.sh" ]]; then
    for svc in http realtime scheduler proxy; do
      if [[ -f "$RUNTIME_DIR/run/$svc.pid" ]] && kill -0 "$(cat "$RUNTIME_DIR/run/$svc.pid" 2>/dev/null || echo 0)" 2>/dev/null; then was_running=1; break; fi
    done
    if (( was_running )); then
      log "stopping application stack before update"
      "$CURRENT_DIR/gxb-dev.sh" stop
    fi
    if [[ -f "$RUNTIME_DIR/postgres/data/PG_VERSION" ]]; then
      log "creating pre-update logical database backup"
      "$CURRENT_DIR/gxb-dev.sh" db-backup "pre-update-$stamp" | tee "$RUNTIME_DIR/update-snapshots/$stamp/db-backup.txt"
    else
      log "PostgreSQL runtime is not initialized yet; no database backup needed"
    fi
    [[ -f "$CURRENT_DIR/VERSION.json" ]] && cp "$CURRENT_DIR/VERSION.json" "$RUNTIME_DIR/update-snapshots/$stamp/VERSION.before.json"
  fi

  # A backend update starts a fresh operational log epoch. PostgreSQL data,
  # backups, snapshots and the venv remain intact; only runtime/logs is reset.
  clear_runtime_logs
  setup_workspace
  log "initializing/upgrading portable runtime against preserved database"
  "$CURRENT_DIR/gxb-dev.sh" init | tee "$RUNTIME_DIR/update-snapshots/$stamp/init.txt"
  if (( was_running )); then
    log "application was running before update; restarting it"
    "$CURRENT_DIR/gxb-dev.sh" start
  fi
  log "update complete; snapshot metadata: $RUNTIME_DIR/update-snapshots/$stamp"
}

repair_permissions() {
  [[ -d "$CURRENT_DIR" ]] || die "current_backend does not exist; run '$0 setup' first"
  heal_exec_permissions "$CURRENT_DIR"
  log "permission repair complete"
}

forward() {
  heal_exec_permissions "$CURRENT_DIR"
  [[ -x "$CURRENT_DIR/gxb-dev.sh" ]] || die "current_backend/gxb-dev.sh missing; run '$0 setup'"
  exec "$CURRENT_DIR/gxb-dev.sh" "$@"
}

usage() {
  cat <<EOF
Usage:
  $(basename "$0") version        Show workspace-wrapper version/build
  $(basename "$0") setup          Extract latest backend, auto-heal script permissions, wire assets/migration inputs
  $(basename "$0") update         Backup DB, clear logs, replace backend, run schema upgrade, restart if needed
  $(basename "$0") backup [LABEL] Create self-contained PostgreSQL backup archive under backup/
  $(basename "$0") restore [FILE] Restore latest/specified PostgreSQL backup archive
  $(basename "$0") init           Initialize portable venv + local PostgreSQL runtime
  $(basename "$0") start|stop|restart|status|down
  $(basename "$0") doctor|deps|support-bundle
  $(basename "$0") repair-permissions  Re-apply executable permissions to extracted scripts/launchers
  $(basename "$0") dev COMMAND... Forward any gxb-dev.sh command

Persistent workspace directories:
  backend/          versioned ZIPs
  preserve/         immutable legacy JSON migration input (one-shot source only; update never remigrates it)
  runtime/          local PostgreSQL, venv, logs, pids, generated config
  runtime/ota/      persistent MID2 release registry and published OTA volumes
  backup/           self-contained PostgreSQL backup archives
  current_backend/  disposable extraction of latest backend
EOF
}

case "${1:-}" in
  version) printf "gxb workspace wrapper v%s (%s)\n" "$WRAPPER_VERSION" "$WRAPPER_BUILD" ;;
  setup) setup_workspace ;;
  update) update_workspace ;;
  backup) workspace_backup "${2:-manual}" ;;
  restore) workspace_restore "${2:-}" ;;
  repair-permissions|permissions) repair_permissions ;;
  init|start|stop|restart|status|down|doctor|deps|support-bundle) forward "$1" ;;
  dev) shift; (($#)) || die "usage: $0 dev COMMAND..."; forward "$@" ;;
  -h|--help|help|'') usage ;;
  *) usage >&2; exit 64 ;;
esac
