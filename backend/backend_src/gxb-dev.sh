#!/usr/bin/env bash
set -euo pipefail

# Portable development launcher for the Pass348 PostgreSQL runtime.
# Project/runtime state stays outside root-owned deployment directories.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$ROOT/.gxb-workspace" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/.gxb-workspace"
fi

if [[ -z "${GXB_DEV_HOME:-}" ]]; then
  if [[ "$(basename "$ROOT")" == "current_backend" ]]; then
    GXB_DEV_HOME="$(cd "$ROOT/.." && pwd)/runtime"
  else
    GXB_DEV_HOME="$ROOT/.runtime"
  fi
fi
DEV_HOME="$(mkdir -p "$GXB_DEV_HOME" && cd "$GXB_DEV_HOME" && pwd)"
VENV="$DEV_HOME/venv"
RUN_DIR="$DEV_HOME/run"
LOG_DIR="$DEV_HOME/logs"
PG_HOME="$DEV_HOME/postgres"
PG_DATA="$PG_HOME/data"
PG_SOCKET="$PG_HOME/socket"
MIGRATION_DIR="$DEV_HOME/migration"
PROXY_HOME="$DEV_HOME/proxy"
ENV_FILE="$DEV_HOME/gxb.env"
LOCAL_ENV_FILE="$DEV_HOME/gxb.env.local"
SUPPORT_DIR="$DEV_HOME/support"
BACKUP_DIR="$DEV_HOME/backups"
DEV_EDIT_DIR="$DEV_HOME/dev-edit"
VENV_FINGERPRINT="$VENV/.gxb-host-fingerprint"

PG_PORT="${GXB_DEV_PG_PORT:-55432}"
DB_NAME="${GXB_DEV_DB_NAME:-gxb_dev_test}"
RUNTIME_DB_ROLE="${GXB_DEV_DB_ROLE:-gxb_dev_runtime}"
HTTP_INTERNAL_PORT="${GXB_DEV_HTTP_INTERNAL_PORT:-19080}"
SDK_PORT="${GXB_SDK_PORT:-5000}"
ENGINE_PORT="${GXB_ENGINE_PORT:-9000}"
CHAT_PORT="${GXB_CHAT_PORT:-9100}"
HTTP_WORKERS="${GXB_HTTP_WORKERS:-1}"
HTTP_THREADS="${GXB_HTTP_THREADS:-8}"
EDGE_MODE="${GXB_DEV_EDGE:-auto}"

[[ "$DB_NAME" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || { printf '[gxb-dev] ERROR: invalid GXB_DEV_DB_NAME\n' >&2; exit 64; }
[[ "$RUNTIME_DB_ROLE" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || { printf '[gxb-dev] ERROR: invalid GXB_DEV_DB_ROLE\n' >&2; exit 64; }
for _p in "$PG_PORT" "$HTTP_INTERNAL_PORT" "$SDK_PORT" "$ENGINE_PORT" "$CHAT_PORT"; do
  [[ "$_p" =~ ^[0-9]+$ ]] && (( _p >= 1 && _p <= 65535 )) || { printf '[gxb-dev] ERROR: invalid port: %s\n' "$_p" >&2; exit 64; }
done

mkdir -p "$RUN_DIR" "$LOG_DIR" "$PG_HOME" "$PG_SOCKET" "$MIGRATION_DIR" "$PROXY_HOME" "$SUPPORT_DIR" "$BACKUP_DIR" "$DEV_EDIT_DIR"

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log()  { local m="[gxb-dev] $*"; printf '%s\n' "$m"; printf '%s %s\n' "$(ts)" "$m" >>"$LOG_DIR/launcher.log"; }
warn() { local m="[gxb-dev] WARNING: $*"; printf '%s\n' "$m" >&2; printf '%s %s\n' "$(ts)" "$m" >>"$LOG_DIR/launcher.log"; }
die()  { local m="[gxb-dev] ERROR: $*"; printf '%s\n' "$m" >&2; printf '%s %s\n' "$(ts)" "$m" >>"$LOG_DIR/launcher.log"; exit 1; }
record_invocation() { printf '%s [gxb-dev] COMMAND:' "$(ts)" >>"$LOG_DIR/launcher.log"; printf ' %q' "$0" "$@" >>"$LOG_DIR/launcher.log"; printf '\n' >>"$LOG_DIR/launcher.log"; }

resolve_exe() {
  local candidate="${1:-}"
  [[ -n "$candidate" ]] || return 1
  if [[ "$candidate" == */* ]]; then
    [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  else
    command -v "$candidate" 2>/dev/null && return 0
  fi
  return 1
}

find_python() {
  local c resolved
  for c in "${GXB_PYTHON:-}" "$ROOT/vendor/python/bin/python3" python3.12 python3.13 python3; do
    resolved="$(resolve_exe "$c" || true)"
    [[ -n "$resolved" ]] || continue
    if "$resolved" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if (3, 12) <= sys.version_info[:2] < (3, 14) else 1)
PY
    then printf '%s\n' "$resolved"; return 0; fi
  done
  return 1
}

pg_bindir() {
  local d="${GXB_PG_BINDIR:-}"
  if [[ -n "$d" && -x "$d/postgres" && -x "$d/initdb" ]]; then printf '%s\n' "$d"; return 0; fi
  d="$ROOT/vendor/postgresql/bin"
  if [[ -x "$d/postgres" && -x "$d/initdb" ]]; then printf '%s\n' "$d"; return 0; fi
  if command -v pg_config >/dev/null 2>&1; then
    d="$(pg_config --bindir 2>/dev/null || true)"
    if [[ -n "$d" && -x "$d/postgres" && -x "$d/initdb" ]]; then printf '%s\n' "$d"; return 0; fi
  fi
  if command -v postgres >/dev/null 2>&1; then dirname "$(command -v postgres)"; return 0; fi
  return 1
}

find_proxy() {
  local c resolved
  for c in "${GXB_PROXY_BIN:-}" \
           "$ROOT/vendor/openresty/bin/openresty" \
           "$ROOT/vendor/openresty/nginx/sbin/nginx" \
           "$ROOT/vendor/nginx/sbin/nginx" \
           openresty nginx; do
    resolved="$(resolve_exe "$c" || true)"
    [[ -n "$resolved" ]] && { printf '%s\n' "$resolved"; return 0; }
  done
  return 1
}

require_nonroot() {
  [[ "${EUID:-$(id -u)}" -ne 0 ]] || die "portable dev runtime must be run as your normal user, not root"
}

pid_alive() {
  local f="$1" pid
  [[ -f "$f" ]] || return 1
  pid="$(cat "$f" 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

port_open() {
  local port="$1"
  python3 - "$port" <<'PY' >/dev/null 2>&1
import socket,sys
s=socket.socket(); s.settimeout(.35)
try: s.connect(('127.0.0.1',int(sys.argv[1])))
except OSError: raise SystemExit(1)
finally: s.close()
PY
}

wait_port() {
  local port="$1" tries="${2:-60}"
  while (( tries-- > 0 )); do port_open "$port" && return 0; sleep .2; done
  return 1
}

detect_advertise_host() {
  if [[ -n "${GXB_ADVERTISE_HOST:-}" ]]; then printf '%s\n' "$GXB_ADVERTISE_HOST"; return; fi
  python3 - <<'PY'
import socket
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
try:
    s.connect(('1.1.1.1',53)); host=s.getsockname()[0]
except OSError:
    host='127.0.0.1'
finally:
    s.close()
print(host)
PY
}

runtime_python() {
  [[ -x "$VENV/bin/python" ]] || die "runtime venv missing; run '$0 init'"
  printf '%s\n' "$VENV/bin/python"
}

host_fingerprint() {
  local py="$1"
  "$py" - "$DEV_HOME" <<'PYF'
import json, os, platform, sys, sysconfig
osrel = {}
try:
    for line in open('/etc/os-release', encoding='utf-8'):
        if '=' in line:
            k,v=line.rstrip('\n').split('=',1); osrel[k]=v.strip().strip('"')
except OSError:
    pass
payload = {
    "dev_home": os.path.realpath(sys.argv[1]),
    "base_python": os.path.realpath(sys.executable),
    "python": platform.python_version(),
    "implementation": platform.python_implementation(),
    "cache_tag": getattr(sys.implementation, "cache_tag", None),
    "machine": platform.machine(),
    "system": platform.system(),
    "libc": platform.libc_ver(),
    "platform": sysconfig.get_platform(),
    "distro_id": osrel.get("ID"),
    "distro_version": osrel.get("VERSION_ID"),
}
print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
PYF
}

venv_init() {
  require_nonroot
  local py ver arch lock_hash stamp
  py="$(find_python || true)"
  [[ -n "$py" ]] || die "Python 3.12 or 3.13 is required. Set GXB_PYTHON to a compatible interpreter."
  ver="$($py -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
  arch="$(uname -m)"
  lock_hash="$(sha256sum "$ROOT/requirements/runtime.lock" | awk '{print $1}')"
  stamp="$VENV/.gxb-runtime-lock.sha256"
  local fingerprint current_fingerprint=""
  fingerprint="$(host_fingerprint "$py")"
  [[ -f "$VENV_FINGERPRINT" ]] && current_fingerprint="$(cat "$VENV_FINGERPRINT" 2>/dev/null || true)"
  if [[ -d "$VENV" && ( ! -x "$VENV/bin/python" || "$current_fingerprint" != "$fingerprint" ) ]]; then
    warn "runtime venv belongs to a different host/path/interpreter (or predates fingerprinting); rebuilding it"
    rm -rf -- "$VENV"
  fi
  if [[ ! -x "$VENV/bin/python" ]]; then
    log "creating portable venv with $py ($ver) -> $VENV"
    "$py" -m venv "$VENV" || die "venv creation failed (Debian/Ubuntu may need python3-venv)"
    printf '%s\n' "$fingerprint" > "$VENV_FINGERPRINT"
  fi
  if [[ -f "$stamp" && "$(cat "$stamp")" == "$lock_hash" ]]; then
    log "runtime dependencies already match requirements/runtime.lock"
    return
  fi
  if [[ "$ver" == "3.12" && "$arch" == "x86_64" && -d "$ROOT/vendor/wheels/linux-x86_64-cp312" ]]; then
    (cd "$ROOT" && "$py" -c 'from tools.bootstrap_python_env import verify_wheelhouse; print("verified", verify_wheelhouse(), "offline wheels")')
    "$VENV/bin/python" -m pip install --disable-pip-version-check --no-index \
      --find-links "$ROOT/vendor/wheels/linux-x86_64-cp312" -r "$ROOT/requirements/runtime.lock"
  else
    [[ "${GXB_DEV_OFFLINE:-0}" != "1" ]] || die "offline wheelhouse is CPython 3.12 x86_64 only; use Python 3.12 or unset GXB_DEV_OFFLINE"
    warn "no matching bundled wheelhouse for Python $ver/$arch; installing pinned runtime dependencies from configured package index"
    "$VENV/bin/python" -m pip install --disable-pip-version-check -r "$ROOT/requirements/runtime.lock"
  fi
  printf '%s\n' "$lock_hash" > "$stamp"
}

pg_tools() {
  local d
  d="$(pg_bindir || true)"; [[ -n "$d" ]] || die "PostgreSQL server tools not found. See '$0 deps'."
  for x in postgres initdb pg_ctl psql createdb pg_isready; do [[ -x "$d/$x" ]] || die "missing PostgreSQL tool: $d/$x"; done
  printf '%s\n' "$d"
}

db_alive() { pid_alive "$RUN_DIR/postgres.pid"; }

db_start() {
  require_nonroot
  local d pid
  d="$(pg_tools)"
  [[ -f "$PG_DATA/PG_VERSION" ]] || die "local database is not initialized; run '$0 db-init'"
  if db_alive; then return 0; fi
  if port_open "$PG_PORT"; then die "port $PG_PORT is already occupied by another process"; fi
  mkdir -p "$PG_SOCKET"
  : > "$LOG_DIR/postgres.log"
  log "starting user-owned PostgreSQL on 127.0.0.1:$PG_PORT"
  "$d/postgres" -D "$PG_DATA" -h 127.0.0.1 -p "$PG_PORT" -k "$PG_SOCKET" >>"$LOG_DIR/postgres.log" 2>&1 &
  pid=$!; printf '%s\n' "$pid" > "$RUN_DIR/postgres.pid"
  if ! wait_port "$PG_PORT" 100; then
    tail -n 80 "$LOG_DIR/postgres.log" >&2 || true
    rm -f "$RUN_DIR/postgres.pid"
    die "PostgreSQL failed to start"
  fi
}

db_stop() {
  local d
  if ! db_alive; then rm -f "$RUN_DIR/postgres.pid"; return 0; fi
  d="$(pg_tools)"
  log "stopping local PostgreSQL"
  "$d/pg_ctl" -D "$PG_DATA" -m fast -w stop >/dev/null
  rm -f "$RUN_DIR/postgres.pid"
}

app_running() {
  local name
  for name in http realtime scheduler proxy; do
    pid_alive "$RUN_DIR/$name.pid" && return 0
  done
  return 1
}

require_app_stopped() {
  app_running && die "stop the application stack before direct dev-state/database surgery ('$0 stop')"
}

admin_pg_env() {
  export PGHOST=127.0.0.1 PGPORT="$PG_PORT"
  unset PGDATABASE PGUSER PGPASSWORD || true
}

admin_database_url() { printf 'postgresql+psycopg:///%s?host=127.0.0.1&port=%s\n' "$DB_NAME" "$PG_PORT"; }
runtime_database_url() { printf 'postgresql+psycopg://%s@127.0.0.1:%s/%s\n' "$RUNTIME_DB_ROLE" "$PG_PORT" "$DB_NAME"; }

db_init() {
  require_nonroot
  local d major init_args=()
  d="$(pg_tools)"
  if [[ ! -f "$PG_DATA/PG_VERSION" ]]; then
    mkdir -p "$PG_DATA"
    if "$d/initdb" --help 2>&1 | grep -q -- '--data-checksums'; then init_args+=(--data-checksums); fi
    log "initializing user-owned PostgreSQL cluster at $PG_DATA"
    "$d/initdb" -D "$PG_DATA" --encoding=UTF8 --auth-local=trust --auth-host=trust "${init_args[@]}"
  fi
  major="$(cut -d. -f1 "$PG_DATA/PG_VERSION")"
  if [[ "$major" != "16" ]]; then warn "PostgreSQL $major detected; Pass348 was validated on PostgreSQL 16. Development may work, but this version is not yet part of the sealed proof."; fi
  db_start
  admin_pg_env
  if ! "${d}/psql" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    log "creating local development database $DB_NAME"
    "${d}/createdb" --maintenance-db=postgres "$DB_NAME"
  fi
  "${d}/psql" -d postgres -v ON_ERROR_STOP=1 -f "$ROOT/deploy/postgresql/roles.sql" >/dev/null
  "${d}/psql" -d postgres -v ON_ERROR_STOP=1 <<SQL >/dev/null
DO \$gxbdev\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$RUNTIME_DB_ROLE') THEN
    CREATE ROLE $RUNTIME_DB_ROLE LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
  END IF;
END
\$gxbdev\$;
GRANT gxb_app TO $RUNTIME_DB_ROLE;
SQL
  log "applying Alembic migrations"
  (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" GXB_DATABASE_SCHEMA=gxb "$(runtime_python)" -m alembic -c alembic.ini upgrade head)
  "${d}/psql" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$ROOT/deploy/postgresql/runtime_grants.sql" >/dev/null
  log "local database ready: $DB_NAME on port $PG_PORT"
}

db_backup() {
  require_nonroot
  db_start
  local d dump stamp label meta
  d="$(pg_tools)"
  [[ -x "$d/pg_dump" ]] || die "pg_dump not found in PostgreSQL bindir: $d"
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  label="${1:-manual}"; label="${label//[^A-Za-z0-9._-]/_}"
  dump="$BACKUP_DIR/${stamp}-${label}-${DB_NAME}.dump"
  meta="$BACKUP_DIR/${stamp}-${label}-${DB_NAME}.json"
  admin_pg_env
  log "creating logical PostgreSQL backup: $dump"
  "$d/pg_dump" --format=custom --compress=6 --file="$dump" "$DB_NAME" 2>&1 | tee -a "$LOG_DIR/backup.log"
  "$d/psql" -d "$DB_NAME" -At -v ON_ERROR_STOP=1 <<'SQL' >"$meta.tmp"
SELECT json_build_object(
  'alembic_head',(SELECT version_num FROM public.gxb_alembic_version LIMIT 1),
  'authority',(SELECT authority FROM gxb.runtime_authority WHERE singleton_id=1),
  'players',(SELECT count(*) FROM gxb.players),
  'accounts',(SELECT count(*) FROM gxb.accounts)
)::text;
SQL
  "$(find_python)" - "$meta.tmp" "$meta" "$dump" <<'PYMETA'
import hashlib,json,os,sys
src,out,dump=sys.argv[1:]
raw=open(src,encoding='utf-8').read().strip() or '{}'
body=json.loads(raw); h=hashlib.sha256()
with open(dump,'rb') as f:
    for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
body.update({'status':'BACKUP_CREATED','dump':os.path.realpath(dump),'sha256':h.hexdigest()})
open(out,'w',encoding='utf-8').write(json.dumps(body,indent=2,sort_keys=True)+'\n')
PYMETA
  rm -f "$meta.tmp"
  printf '%s\n' "$dump"
}

db_restore() {
  require_nonroot
  require_app_stopped
  local dump="${1:-}" expected_sha="${2:-}" d actual_sha
  [[ -n "$dump" && -f "$dump" ]] || die "usage: $0 db-restore DUMP_FILE [EXPECTED_SHA256]"
  venv_init; db_start
  d="$(pg_tools)"
  [[ -x "$d/pg_restore" ]] || die "pg_restore not found in PostgreSQL bindir: $d"
  "$d/pg_restore" --list "$dump" >/dev/null || die "invalid PostgreSQL custom-format dump: $dump"
  if [[ -n "$expected_sha" ]]; then
    actual_sha="$(sha256sum "$dump" | awk '{print $1}')"
    [[ "$actual_sha" == "$expected_sha" ]] || die "backup SHA256 mismatch: expected=$expected_sha actual=$actual_sha"
  fi

  admin_pg_env
  if "$d/psql" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    log "creating safety backup before PostgreSQL restore"
    db_backup pre-restore >/dev/null
    log "replacing local database $DB_NAME from logical backup"
    "$d/psql" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE \"$DB_NAME\" WITH (FORCE);" >/dev/null
  fi
  "$d/createdb" --maintenance-db=postgres "$DB_NAME"
  "$d/psql" -d postgres -v ON_ERROR_STOP=1 -f "$ROOT/deploy/postgresql/roles.sql" >/dev/null
  "$d/psql" -d postgres -v ON_ERROR_STOP=1 <<SQL >/dev/null
DO \$gxbdev\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$RUNTIME_DB_ROLE') THEN
    CREATE ROLE $RUNTIME_DB_ROLE LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
  END IF;
END
\$gxbdev\$;
GRANT gxb_app TO $RUNTIME_DB_ROLE;
SQL
  "$d/pg_restore" --exit-on-error --no-owner --no-privileges --dbname "$DB_NAME" "$dump" 2>&1 | tee -a "$LOG_DIR/restore.log"
  log "upgrading restored schema to current backend Alembic head"
  (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" GXB_DATABASE_SCHEMA=gxb "$(runtime_python)" -m alembic -c alembic.ini upgrade head)
  "$d/psql" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$ROOT/deploy/postgresql/runtime_grants.sql" >/dev/null
  write_env
  log "PostgreSQL restore complete: $dump"
  "$d/psql" -d "$DB_NAME" -P pager=off -c 'SELECT singleton_id,authority,migration_run_id,prepared_at,traffic_open_at FROM gxb.runtime_authority;' || true
}

db_reset_empty() {
  require_nonroot
  [[ "${1:-}" == "RESET EMPTY DEV DATABASE" ]] || die "exact confirmation required: RESET EMPTY DEV DATABASE"
  stack_stop || true
  venv_init; db_start
  local d
  d="$(pg_tools)"; admin_pg_env
  if "$d/psql" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    db_backup pre-empty-reset >/dev/null
    log "dropping disposable development database $DB_NAME"
    "$d/psql" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE \"$DB_NAME\" WITH (FORCE);" >/dev/null
  fi
  write_env
  db_init
  warn "empty schema created. I8 intentionally will not start gameplay traffic until an authority source is prepared."
}

write_env() {
  local host
  host="$(detect_advertise_host)"
  : > "$ENV_FILE"
  printf '# Generated by gxb-dev.sh. Put personal overrides in gxb.env.local.\n' >> "$ENV_FILE"
  emit_export() { printf 'export %s=%q\n' "$1" "$2" >> "$ENV_FILE"; }
  emit_export GXB_DATABASE_URL "$(runtime_database_url)"
  emit_export GXB_DATABASE_SCHEMA gxb
  emit_export GXB_HTTP_WORKERS "$HTTP_WORKERS"
  emit_export GXB_HTTP_THREADS "$HTTP_THREADS"
  emit_export GXB_HTTP_BIND "127.0.0.1:$HTTP_INTERNAL_PORT"
  emit_export GXB_MAINTENANCE_FILE "$RUN_DIR/maintenance"
  emit_export GXB_BIND 0.0.0.0
  emit_export GXB_ADVERTISE_HOST "$host"
  emit_export GXB_SDK_PORT "$SDK_PORT"
  emit_export GXB_ENGINE_PORT "$ENGINE_PORT"
  emit_export GXB_CHAT_HOST "$host"
  emit_export GXB_CHAT_PORT "$CHAT_PORT"
  emit_export GXB_SELF_URL "http://$host:$ENGINE_PORT/api/v1"
  # StaticAssetRoot owns settings/release metadata; resource roots are derived
  # as <static_root>/res and <static_root>/old_res by backend config.
  emit_export GXB_STATIC_ASSET_ROOT "$ROOT/local_assets"
  emit_export GXB_RUNTIME_LOG_DIR "$LOG_DIR/backend"
  emit_export GXB_SESSION_ABSOLUTE_TTL_SECONDS 2592000
  emit_export GXB_SESSION_IDLE_TTL_SECONDS 86400
  emit_export GXB_SESSION_ACTIVITY_WRITE_SECONDS 60
  unset -f emit_export
}

load_env() {
  write_env
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  if [[ -f "$LOCAL_ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$LOCAL_ENV_FILE"
  fi
  export PYTHONPATH="$ROOT${PYTHONPATH:+:$PYTHONPATH}"
}

nginx_escape() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }
write_proxy_config() {
  local maintenance logp pidp
  maintenance="$(nginx_escape "$GXB_MAINTENANCE_FILE")"
  logp="$(nginx_escape "$LOG_DIR")"
  pidp="$(nginx_escape "$RUN_DIR/proxy.pid")"
  mkdir -p "$PROXY_HOME/conf" \
    "$PROXY_HOME/tmp/client" \
    "$PROXY_HOME/tmp/proxy" \
    "$PROXY_HOME/tmp/fastcgi" \
    "$PROXY_HOME/tmp/uwsgi" \
    "$PROXY_HOME/tmp/scgi"
  cat > "$PROXY_HOME/conf/nginx.conf" <<EOF
pid "$pidp";
error_log "$logp/proxy-error.log" info;
events { worker_connections 256; }
http {
    access_log "$logp/proxy-access.log";
    client_body_temp_path "$PROXY_HOME/tmp/client";
    proxy_temp_path "$PROXY_HOME/tmp/proxy";
    fastcgi_temp_path "$PROXY_HOME/tmp/fastcgi";
    uwsgi_temp_path "$PROXY_HOME/tmp/uwsgi";
    scgi_temp_path "$PROXY_HOME/tmp/scgi";
    upstream gxb_http { server 127.0.0.1:$HTTP_INTERNAL_PORT; keepalive 32; }
    server {
        listen $SDK_PORT;
        listen $ENGINE_PORT;
        client_max_body_size 16m;
        location / {
            if (-f "$maintenance") { return 503; }
            proxy_pass http://gxb_http;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF
}

authority_state() {
  load_env
  local py out
  py="$(runtime_python)"
  out="$(cd "$ROOT" && "$py" tools/pass347_i8_cutover.py status 2>/dev/null)" || return 1
  printf '%s' "$out" | "$py" -c 'import json,sys; print(json.load(sys.stdin).get("authority") or "NONE")'
}

start_bg() {
  local name="$1"; shift
  local pidfile="$RUN_DIR/$name.pid" logfile="$LOG_DIR/$name.log"
  if pid_alive "$pidfile"; then log "$name already running (pid $(cat "$pidfile"))"; return 0; fi
  : > "$logfile"
  (
    cd "$ROOT"
    nohup "$@" >>"$logfile" 2>&1 &
    echo $! > "$pidfile"
  )
  sleep .4
  pid_alive "$pidfile" || { tail -n 80 "$logfile" >&2 || true; die "$name failed to start"; }
}

stop_pid() {
  local name="$1" pidfile="$RUN_DIR/$1.pid" pid i
  [[ -f "$pidfile" ]] || return 0
  pid="$(cat "$pidfile" 2>/dev/null || true)"
  if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
    kill -TERM "$pid" 2>/dev/null || true
    for i in {1..50}; do kill -0 "$pid" 2>/dev/null || break; sleep .1; done
    kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
  fi
  rm -f "$pidfile"
}

proxy_start() {
  local proxy
  proxy="$(find_proxy || true)"; [[ -n "$proxy" ]] || return 1
  write_proxy_config
  if pid_alive "$RUN_DIR/proxy.pid"; then return 0; fi
  log "starting workspace-local edge with $(basename "$proxy")"
  "$proxy" -p "$PROXY_HOME/" -e "$LOG_DIR/proxy-bootstrap-error.log" -c "$PROXY_HOME/conf/nginx.conf"
  sleep .3
  pid_alive "$RUN_DIR/proxy.pid" || die "proxy failed to start; see $LOG_DIR/proxy-error.log"
}

proxy_stop() {
  local proxy
  if ! pid_alive "$RUN_DIR/proxy.pid"; then rm -f "$RUN_DIR/proxy.pid"; return 0; fi
  proxy="$(find_proxy || true)"
  if [[ -n "$proxy" ]]; then "$proxy" -p "$PROXY_HOME/" -e "$LOG_DIR/proxy-bootstrap-error.log" -c "$PROXY_HOME/conf/nginx.conf" -s quit >/dev/null 2>&1 || true; fi
  sleep .3
  if pid_alive "$RUN_DIR/proxy.pid"; then stop_pid proxy; else rm -f "$RUN_DIR/proxy.pid"; fi
}

http_probe() {
  local port="$1" path="${2:-/health/live}"
  "$(runtime_python)" - "$port" "$path" <<'PY' >/dev/null 2>&1
import sys,urllib.request
try:
    with urllib.request.urlopen(f"http://127.0.0.1:{sys.argv[1]}{sys.argv[2]}",timeout=1.0) as r:
        raise SystemExit(0 if 200 <= r.status < 500 else 1)
except Exception:
    raise SystemExit(1)
PY
}

wait_http_probe() {
  local port="$1" path="${2:-/health/live}" timeout="${3:-${GXB_DEV_HTTP_STARTUP_TIMEOUT:-30}}"
  local deadline=$((SECONDS + timeout))
  while (( SECONDS < deadline )); do
    http_probe "$port" "$path" && return 0
    pid_alive "$RUN_DIR/http.pid" || return 1
    sleep .25
  done
  return 1
}

http_start_failed() {
  warn "HTTP worker did not become healthy; last runtime/logs/http.log lines follow"
  tail -n 160 "$LOG_DIR/http.log" >&2 || true
  stop_pid http
  die "HTTP worker failed health probe"
}

prepare_stock_updates() {
  local py="$1"
  log "ensuring stock-client OTA baseline before opening HTTP listeners"
  (cd "$ROOT" && "$py" update_controller.py ensure)
}

stack_start() {
  require_nonroot
  venv_init
  db_start
  load_env
  local py authority proxy edge="$EDGE_MODE"
  py="$(runtime_python)"
  authority="$(authority_state || true)"
  if [[ "$authority" == "NONE" || -z "$authority" ]]; then
    die "runtime authority is not prepared. 'init' only created the schema. Next run: '$0 legacy-inventory', then '$0 legacy-migrate'. After that the I8 evidence/prepare/open gate must be completed for this disposable *_test database before stock-client traffic can start. See docs/guides/PORTABLE_DEV_WORKSPACE.md."
  fi
  if [[ -f "$GXB_MAINTENANCE_FILE" ]]; then
    (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$py" tools/pass347_i8_cutover.py preflight --maintenance >/dev/null)
  else
    (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$py" tools/pass347_i8_cutover.py preflight >/dev/null)
  fi
  proxy="$(find_proxy || true)"
  if [[ "$edge" == "auto" ]]; then
    if [[ -n "$proxy" ]]; then edge=proxy
    elif [[ "$authority" == "TRAFFIC_OPEN" && ! -f "$GXB_MAINTENANCE_FILE" ]]; then edge=direct
    else die "PREPARED/maintenance startup requires nginx/OpenResty as the physical HTTP gate. See '$0 deps' or vendor a proxy binary."
    fi
  fi
  if [[ "$edge" == "direct" && ( "$authority" != "TRAFFIC_OPEN" || -f "$GXB_MAINTENANCE_FILE" ) ]]; then
    die "direct edge is allowed only after TRAFFIC_OPEN with maintenance off"
  fi
  # Production HTTP is Gunicorn/WSGI, not gxb_backend.run.main(). Ensure/publish
  # the canonical MID2 baseline exactly once in the operator process before any
  # client-facing listener opens. This also fails startup loudly if the required
  # asset barrier cannot be built/verified.
  prepare_stock_updates "$py"
  case "$edge" in
    proxy)
      [[ -n "$proxy" ]] || die "proxy mode requested but nginx/OpenResty was not found"
      start_bg http "$VENV/bin/gunicorn" -c deploy/gunicorn.conf.py gxb_backend.runtime.wsgi:app
      wait_http_probe "$HTTP_INTERNAL_PORT" || http_start_failed
      proxy_start
      ;;
    direct)
      log "starting direct development edge on ports $SDK_PORT and $ENGINE_PORT (TRAFFIC_OPEN only)"
      start_bg http "$VENV/bin/gunicorn" -c deploy/gunicorn.conf.py \
        --bind "0.0.0.0:$SDK_PORT" --bind "0.0.0.0:$ENGINE_PORT" gxb_backend.runtime.wsgi:app
      wait_http_probe "$ENGINE_PORT" || http_start_failed
      ;;
    *) die "GXB_DEV_EDGE must be auto, proxy, or direct" ;;
  esac
  start_bg realtime "$py" -m gxb_backend.runtime.realtime_main
  wait_port "$CHAT_PORT" 40 || { stack_stop; die "realtime port $CHAT_PORT did not open"; }
  start_bg scheduler "$py" -m gxb_backend.runtime.scheduler_main
  log "stack started: authority=$authority edge=$edge HTTP=$SDK_PORT/$ENGINE_PORT realtime=$CHAT_PORT"
}

stack_stop() {
  proxy_stop || true
  stop_pid scheduler
  stop_pid realtime
  stop_pid http
}

stack_status() {
  local name state authority="UNKNOWN"
  if [[ -x "$VENV/bin/python" ]] && db_alive; then authority="$(authority_state 2>/dev/null || echo UNKNOWN)"; fi
  printf 'backend: %s\n' "$ROOT"
  printf 'dev home: %s\n' "$DEV_HOME"
  printf 'authority: %s\n' "$authority"
  for name in postgres http realtime scheduler proxy; do
    if pid_alive "$RUN_DIR/$name.pid"; then state="RUNNING pid=$(cat "$RUN_DIR/$name.pid")"; else state="STOPPED"; fi
    printf '%-10s %s\n' "$name" "$state"
  done
  printf 'ports: sdk=%s engine=%s realtime=%s postgres=%s\n' "$SDK_PORT" "$ENGINE_PORT" "$CHAT_PORT" "$PG_PORT"
}

legacy_source() {
  local p="${1:-${GXB_LEGACY_SERVER_STATE:-}}"
  [[ -n "$p" ]] || p="$ROOT/migration_inputs/server_state"
  [[ -d "$p" ]] || die "legacy server_state not found: $p"
  (cd "$p" && pwd)
}

legacy_inventory() {
  venv_init
  local src py
  src="$(legacy_source "${1:-}")"; py="$(runtime_python)"
  "$py" "$ROOT/tools/pass346_i7_migrate.py" inventory --source-root "$src"
}

legacy_normalize_sandbox() {
  venv_init
  local src dest stamp report singleton
  src="$(legacy_source "${1:-}")"
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  dest="${2:-$MIGRATION_DIR/${stamp}-normalized-server_state}"
  singleton="${GXB_LEGACY_SINGLETON:-$ROOT/migration_inputs/player_db.json}"
  [[ -f "$singleton" ]] || singleton="$ROOT/data/player_db.json"
  report="$MIGRATION_DIR/${stamp}-legacy-normalization.json"
  "$(runtime_python)" "$ROOT/tools/dev_legacy_sandbox_normalize.py" --source-root "$src" --destination "$dest" --singleton "$singleton" --report "$report"     2>&1 | tee -a "$LOG_DIR/migration.log"
  log "normalized migration copy: $dest"
}

legacy_migrate() {
  require_nonroot
  venv_init; db_start
  local src py stamp dir manifest snap_report migrate_report content
  src="$(legacy_source "${1:-}")"; py="$(runtime_python)"; stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  dir="$MIGRATION_DIR/$stamp"; mkdir -p "$dir"
  manifest="$dir/source-manifest.json"; snap_report="$dir/snapshot-report.json"; migrate_report="$dir/migration-report.json"
  log "creating immutable migration snapshot from $src"
  GXB_DATABASE_URL="$(admin_database_url)" "$py" "$ROOT/tools/pass346_i7_migrate.py" snapshot \
    --source-root "$src" --destination "$dir/server_state" --manifest "$manifest" --report "$snap_report" >/dev/null
  content="$($py -c 'import json,sys; print(json.load(open(sys.argv[1]))["source_content_root"])' "$snap_report")"
  log "migrating snapshot into $DB_NAME"
  (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$py" tools/pass346_i7_migrate.py migrate \
    --snapshot-root "$dir/server_state" --expected-content-root "$content" --manifest "$manifest" --report "$migrate_report") \
    2>&1 | tee -a "$LOG_DIR/migration.log"
  log "migration evidence kept at $dir"
}

scratch_candidate() {
  require_nonroot
  [[ "${1:-}" == "RESET DEV DATABASE FROM SCRATCH" ]] || die "exact confirmation required: RESET DEV DATABASE FROM SCRATCH"
  stack_stop || true
  venv_init; db_start
  local d py stamp dir report
  d="$(pg_tools)"; admin_pg_env
  if "$d/psql" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1; then
    db_backup pre-scratch-reset >/dev/null
    log "dropping disposable development database $DB_NAME"
    "$d/psql" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE \"$DB_NAME\" WITH (FORCE);" >/dev/null
  fi
  db_init
  py="$(runtime_python)"; stamp="$(date -u +%Y%m%dT%H%M%SZ)"; dir="$MIGRATION_DIR/${stamp}-scratch"; mkdir -p "$dir/scratch_source"
  report="$dir/migration-report.json"
  cp "$ROOT/data/player_db.json" "$dir/scratch_source/player_db.json"
  log "creating a fresh development baseline from packaged sandbox fixture (not preserve/server_state)"
  (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$py" tools/pass346_i7_migrate.py migrate --sandbox-file "$ROOT/data/player_db.json" --report "$report")     2>&1 | tee -a "$LOG_DIR/migration.log"
  log "scratch candidate validated; prepare/open authority explicitly before gameplay start"
}

prepare_latest_migration() {
  require_nonroot
  venv_init; db_start; load_env
  local report dir run_id archive evidence py source_dir
  report="$(find "$MIGRATION_DIR" -mindepth 2 -maxdepth 2 -type f -name migration-report.json -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)"
  [[ -n "$report" && -f "$report" ]] || die "no migration-report.json found under $MIGRATION_DIR"
  dir="$(dirname "$report")"; py="$(runtime_python)"
  run_id="$($py -c 'import json,sys; print(json.load(open(sys.argv[1]))["migration_run_id"])' "$report")"
  archive="$dir/immutable-source.tar.gz"; evidence="$dir/cutover-evidence.json"
  if [[ -d "$dir/server_state" ]]; then source_dir="$dir/server_state";
  elif [[ -d "$dir/scratch_source" ]]; then source_dir="$dir/scratch_source";
  else die "latest migration has no immutable source snapshot"; fi
  cutover_cmd maintenance-on >/dev/null
  (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$py" tools/pass347_i8_cutover.py seal-json-archive --source-root "$source_dir" --output "$archive")     2>&1 | tee -a "$LOG_DIR/cutover.log"
  (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$py" tools/pass347_i8_cutover.py make-evidence       --source-archive "$archive" --migration-report "$report"       --backup-report "$ROOT/docs/json/PASS346_STAGE_VALIDATION.json"       --client-report "$ROOT/docs/json/PASS347_CLIENT_CUTOVER_READINESS.json"       --immutable-json-archive-path "$archive" --output "$evidence") 2>&1 | tee -a "$LOG_DIR/cutover.log"
  cutover_cmd prepare --migration-run-id "$run_id" --evidence "$evidence"
  log "runtime authority PREPARED under maintenance. Opening gameplay traffic remains an explicit irreversible command for this database."
}

player_export() {
  require_app_stopped
  venv_init; db_start; load_env
  local pid="${1:-}" out="${2:-}"
  [[ "$pid" =~ ^[0-9]+$ ]] || die "usage: $0 player-export PLAYER_ID [FILE]"
  [[ -n "$out" ]] || out="$DEV_EDIT_DIR/player-${pid}.json"
  GXB_DATABASE_URL="$(admin_database_url)" "$(runtime_python)" "$ROOT/tools/dev_player_state.py" export "$pid" "$out"
}

player_import() {
  require_app_stopped
  venv_init; db_start; load_env
  local pid="${1:-}" file="${2:-}" confirmation="${3:-}"
  [[ "$pid" =~ ^[0-9]+$ && -f "$file" ]] || die "usage: $0 player-import PLAYER_ID FILE 'IMPORT DEV PLAYER PLAYER_ID'"
  GXB_DATABASE_URL="$(admin_database_url)" "$(runtime_python)" "$ROOT/tools/dev_player_state.py" import "$pid" "$file" --confirmation "$confirmation"     2>&1 | tee -a "$LOG_DIR/dev-state.log"
}

cutover_cmd() {
  venv_init; db_start; load_env
  local py; py="$(runtime_python)"
  (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$py" tools/pass347_i8_cutover.py "$@") 2>&1 | tee -a "$LOG_DIR/cutover.log"
}

scale_preflight() {
  venv_init; db_start; load_env
  (cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$(runtime_python)" tools/pass348_i9_scale_preflight.py --workers "${1:-}") 2>&1 | tee -a "$LOG_DIR/scale-preflight.log"
}

proxy_test() {
  local proxy
  load_env
  proxy="$(find_proxy || true)"; [[ -n "$proxy" ]] || die "nginx/OpenResty not found"
  write_proxy_config
  "$proxy" -t -p "$PROXY_HOME/" -e "$LOG_DIR/proxy-bootstrap-error.log" -c "$PROXY_HOME/conf/nginx.conf"
}

doctor() {
  local py pg proxy os="unknown" ver="" arch
  [[ -r /etc/os-release ]] && os="$(. /etc/os-release; printf '%s %s' "${NAME:-Linux}" "${VERSION_ID:-}")"
  arch="$(uname -m)"
  py="$(find_python || true)"; pg="$(pg_bindir || true)"; proxy="$(find_proxy || true)"
  printf 'OS:          %s\nArchitecture:%s\nBackend:     %s\nDev home:    %s\n' "$os" " $arch" "$ROOT" "$DEV_HOME"
  if [[ -n "$py" ]]; then printf 'Python:      %s (%s)\n' "$py" "$($py --version 2>&1)"; else printf 'Python:      MISSING (need 3.12/3.13)\n'; fi
  if [[ -n "$pg" ]]; then ver="$($pg/postgres --version 2>&1)"; printf 'PostgreSQL:  %s (%s)\n' "$pg" "$ver"; else printf 'PostgreSQL:  MISSING server binaries\n'; fi
  if [[ -n "$proxy" ]]; then printf 'Proxy:       %s\n' "$proxy"; else printf 'Proxy:       optional after TRAFFIC_OPEN; required for PREPARED maintenance smoke\n'; fi
  printf 'Assets:      %s\n' "$( [[ -d "$ROOT/local_assets/res" ]] && echo OK || echo MISSING )"
  printf 'Legacy:      %s\n' "${GXB_LEGACY_SERVER_STATE:-$ROOT/migration_inputs/server_state}"
}

deps() {
  local id="unknown"
  [[ -r /etc/os-release ]] && id="$(. /etc/os-release; printf '%s' "${ID:-unknown}")"
  cat <<EOF
Only host binaries are dependencies; runtime data/config stay in: $DEV_HOME

RHEL / AlmaLinux / Rocky / Fedora:
  sudo dnf install python3 python3-pip postgresql postgresql-server nginx unzip

Debian / Ubuntu:
  sudo apt update
  sudo apt install python3 python3-venv python3-pip postgresql postgresql-client nginx unzip

No-root alternative:
  - Python 3.12/3.13: vendor/python/bin/python3 or set GXB_PYTHON
  - PostgreSQL:       vendor/postgresql/bin/{postgres,initdb,...} or set GXB_PG_BINDIR
  - nginx/OpenResty:  vendor/nginx/sbin/nginx, vendor/openresty/... or set GXB_PROXY_BIN

Detected distro id: $id
The bundled offline Python wheelhouse is Linux x86_64 CPython 3.12.
EOF
}

show_logs() {
  local service="${1:-http}" file="$LOG_DIR/${1:-http}.log"
  [[ "$service" == "proxy" ]] && file="$LOG_DIR/proxy-error.log"
  [[ -f "$file" ]] || die "log not found: $file"
  tail -n "${GXB_LOG_LINES:-120}" "$file"
}

sanitize_env_file() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || return 0
  awk 'BEGIN{IGNORECASE=1} /^[[:space:]]*(export[[:space:]]+)?[^#=]*(PASSWORD|PASSWD|TOKEN|SECRET|API_KEY|PRIVATE_KEY)[^=]*=/{sub(/=.*/,"=<REDACTED>"); print; next} {print}' "$src" > "$dst"
}

support_bundle() {
  require_nonroot
  local stamp stage zip py d
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  stage="$SUPPORT_DIR/.gxb-support-$stamp"
  zip="$SUPPORT_DIR/gxb-support-$stamp.zip"
  rm -rf -- "$stage"; mkdir -p "$stage/logs" "$stage/migration" "$stage/backups"
  (stack_status || true) > "$stage/status.txt" 2>&1
  (doctor || true) > "$stage/doctor.txt" 2>&1
  cp -a "$LOG_DIR"/. "$stage/logs"/ 2>/dev/null || true
  { uname -a; printf '\n'; [[ -r /etc/os-release ]] && cat /etc/os-release; } > "$stage/host.txt" 2>&1
  sanitize_env_file "$ENV_FILE" "$stage/gxb.env.sanitized"
  sanitize_env_file "$LOCAL_ENV_FILE" "$stage/gxb.env.local.sanitized"
  [[ -f "$PG_DATA/PG_VERSION" ]] && cp "$PG_DATA/PG_VERSION" "$stage/postgresql-PG_VERSION.txt"
  if [[ -x "$VENV/bin/python" ]]; then
    "$VENV/bin/python" --version > "$stage/python-version.txt" 2>&1 || true
    "$VENV/bin/python" -m pip freeze > "$stage/python-packages.txt" 2>&1 || true
  fi
  d="$(pg_bindir || true)"
  if [[ -n "$d" ]]; then
    "$d/postgres" --version > "$stage/postgresql-version.txt" 2>&1 || true
    if db_alive; then
      admin_pg_env
      "$d/psql" -d "$DB_NAME" -Atc 'SELECT version_num FROM public.gxb_alembic_version;' > "$stage/alembic-head.txt" 2>&1 || true
      "$d/psql" -d "$DB_NAME" -P pager=off -c 'SELECT singleton_id,authority,migration_run_id,prepared_at,traffic_open_at FROM gxb.runtime_authority;' > "$stage/runtime-authority.txt" 2>&1 || true
      "$d/psql" -d "$DB_NAME" -P pager=off -c 'SELECT migration_run_id,status,started_at,validated_at,traffic_open_at FROM gxb.migration_runs ORDER BY started_at DESC LIMIT 5;' > "$stage/migration-runs.txt" 2>&1 || true
    fi
  fi
  while IFS= read -r f; do
    case "$(basename "$f")" in
      source-manifest.json) continue ;;
    esac
    mkdir -p "$stage/migration/$(basename "$(dirname "$f")")"
    cp "$f" "$stage/migration/$(basename "$(dirname "$f")")/$(basename "$f")"
  done < <(find "$MIGRATION_DIR" -maxdepth 2 -type f -name '*.json' 2>/dev/null | sort)
  find "$BACKUP_DIR" -maxdepth 1 -type f -name '*.json' -print0 2>/dev/null | sort -z | tail -z -n 10 | while IFS= read -r -d '' f; do cp "$f" "$stage/backups/"; done
  py="$(find_python || true)"
  [[ -n "$py" ]] || py="$(command -v python3 || true)"
  [[ -n "$py" ]] || die "Python is required to create the support ZIP"
  "$py" - "$stage" "$zip" <<'PYZ'
from pathlib import Path
import sys, zipfile
stage=Path(sys.argv[1]); out=Path(sys.argv[2])
with zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for p in sorted(stage.rglob('*')):
        if p.is_file(): z.write(p, p.relative_to(stage))
print(out)
PYZ
  rm -rf -- "$stage"
  log "support bundle ready: $zip"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") COMMAND [args]

Portable setup/runtime:
  doctor                 Show detected Python/PostgreSQL/proxy and paths
  proxy-test             Validate generated nginx/OpenResty dev-edge config
  deps                   Print Debian + RHEL/Fedora dependency options
  init                   Create venv + local PostgreSQL cluster/database/schema
  db-init|db-start|db-stop
  db-backup [LABEL]       Logical pg_dump into runtime/backups/
  db-restore DUMP [SHA256] Restore a logical dump (app stack must be stopped)
  db-reset-empty 'RESET EMPTY DEV DATABASE'
  scratch-candidate 'RESET DEV DATABASE FROM SCRATCH'
  start|stop|restart|status|down
  logs [http|realtime|scheduler|postgres|proxy|launcher|migration|cutover|scale-preflight|backup|dev-state]
  support-bundle          Create a sanitized debug ZIP under runtime/support/

Legacy JSON migration (never copied back as live authority):
  legacy-inventory [server_state]
  legacy-normalize-sandbox [source] [destination]
  legacy-migrate [server_state]    Snapshot + migrate + validate into *_test DB
  prepare-latest                   Build I8 evidence and PREPARE latest immutable migration

Development state editing (application stack must be stopped):
  player-export PLAYER_ID [FILE]
  player-import PLAYER_ID FILE 'IMPORT DEV PLAYER PLAYER_ID'

I8/I9 operator wrappers:
  maintenance-on|maintenance-off|cutover-status
  cutover-prepare MIGRATION_RUN_ID EVIDENCE_JSON
  cutover-open 'OPEN POSTGRESQL TRAFFIC PERMANENTLY'
  scale-preflight {1|2|4}

State defaults to a sibling runtime/ directory when extracted as current_backend.
Set GXB_DEV_HOME to move it. Personal environment overrides belong in:
  $LOCAL_ENV_FILE
EOF
}

record_invocation "$@"

case "${1:-}" in
  doctor) doctor ;;
  proxy-test) proxy_test ;;
  deps) deps ;;
  init) venv_init; db_init; write_env; doctor ;;
  db-init) venv_init; db_init; write_env ;;
  db-start) db_start ;;
  db-stop) db_stop ;;
  db-backup) db_backup "${2:-manual}" ;;
  db-restore) db_restore "${2:-}" "${3:-}" ;;
  db-reset-empty) db_reset_empty "${2:-}" ;;
  scratch-candidate) scratch_candidate "${2:-}" ;;
  start) stack_start ;;
  stop) stack_stop ;;
  restart) stack_stop; stack_start ;;
  down) stack_stop; db_stop ;;
  status) stack_status ;;
  logs) show_logs "${2:-http}" ;;
  support-bundle) support_bundle ;;
  legacy-inventory) legacy_inventory "${2:-}" ;;
  legacy-normalize-sandbox) legacy_normalize_sandbox "${2:-}" "${3:-}" ;;
  legacy-migrate) legacy_migrate "${2:-}" ;;
  prepare-latest) prepare_latest_migration ;;
  player-export) player_export "${2:-}" "${3:-}" ;;
  player-import) player_import "${2:-}" "${3:-}" "${4:-}" ;;
  maintenance-on) cutover_cmd maintenance-on ;;
  maintenance-off) cutover_cmd maintenance-off ;;
  cutover-status) cutover_cmd status ;;
  cutover-prepare) [[ $# -eq 3 ]] || die "usage: $0 cutover-prepare MIGRATION_RUN_ID EVIDENCE_JSON"; cutover_cmd prepare --migration-run-id "$2" --evidence "$3" ;;
  cutover-open) [[ $# -eq 2 ]] || die "usage: $0 cutover-open 'OPEN POSTGRESQL TRAFFIC PERMANENTLY'"; cutover_cmd open --confirmation "$2" ;;
  scale-preflight) [[ $# -eq 2 ]] || die "usage: $0 scale-preflight {1|2|4}"; scale_preflight "$2" ;;
  -h|--help|help|'') usage ;;
  *) usage >&2; exit 64 ;;
esac
