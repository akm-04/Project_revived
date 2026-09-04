# Portable development workspace — Pass348 runtime

This packaging layer keeps the accepted Pass348 PostgreSQL architecture while
removing the production assumption that project files live under `/opt`, config
under `/etc`, runtime sockets under `/run`, and processes under systemd.

## Recommended workspace

```text
workdir/
├── backend/             versioned gxb-backend ZIPs
├── current_backend/     disposable extraction of the newest ZIP
├── preserve/            immutable legacy JSON migration input
│   ├── player_db.json
│   └── server_state/...
├── runtime/             persistent development state
│   ├── venv/
│   ├── postgres/data/
│   ├── logs/
│   ├── run/
│   ├── migration/
│   ├── proxy/
│   ├── gxb.env
│   └── gxb.env.local    optional operator overrides
└── gxb_backend_workspace.sh
```

`current_backend` may be removed and replaced at any time. PostgreSQL and
migration evidence survive because they are siblings under `runtime/`.

## Pass352 wrapper v6 lifecycle

For the normal post-migration development loop, legacy JSON is **not** re-imported by `update`. The canonical state is PostgreSQL under the sibling `runtime/` directory. Use the workspace wrapper from the workspace root:

```bash
./gxb_backend_workspace_portable_v6.sh update
./gxb_backend_workspace_portable_v6.sh backup before-experiment
./gxb_backend_workspace_portable_v6.sh restore
# or: ./gxb_backend_workspace_portable_v6.sh restore backup/gxb-postgresql-<timestamp>-<label>.tar.gz
```

`update` creates a logical PostgreSQL safety backup, stops the application stack when necessary, clears only `runtime/logs/`, atomically replaces `current_backend/`, applies current schema/runtime initialization against the preserved database, and restarts the application only if it was running before the update. It never invokes `legacy-migrate`.

`backup` creates a self-contained `backup/gxb-postgresql-*.tar.gz` containing the PostgreSQL custom-format dump, database metadata, backend version metadata, and a SHA-256 manifest. `restore` verifies that archive and dump, takes a safety `pre-restore` logical backup of the current database, restores PostgreSQL, applies current Alembic upgrades/runtime grants, and restarts only when appropriate. The `preserve/` tree remains immutable one-shot migration provenance.


## What changed from the old JSON workspace helper

The old helper's extraction, version selection, atomic replacement, asset links,
and `preserve/` concept remain useful. Two behaviors are no longer valid:

1. `preserve/server_state` must **not** be copied into `current_backend/data/`
   as live authority. It is immutable/offline migration source evidence.
2. `python3 server.py` is the legacy JSON launcher. The normal Pass348 runtime is
   Gunicorn HTTP + RealtimeGateway + Scheduler/Projection over PostgreSQL.

The replacement `tools/workspace/gxb_backend_workspace.sh` keeps `preserve/`
outside the extracted backend and wires it into `migration_inputs/` by symlink.

## Rootless development runtime

Run as your normal user:

```bash
./gxb-dev.sh doctor
./gxb-dev.sh deps
./gxb-dev.sh init
```

`init` creates a Python environment and a user-owned PostgreSQL cluster. It does
not write to `/opt`, `/etc`, `/run`, `/var/lib/pgsql`, or systemd. PostgreSQL
listens only on `127.0.0.1` on development port 55432 by default. The default
candidate database is `gxb_dev_test`, preserving the I7 rehearsal safety rule
that migration databases end in `_test`.

Pass348 was validated with PostgreSQL 16. The launcher warns, rather than
silently claiming validation, if another major PostgreSQL version is used.

## Vendor/no-root discovery

The launcher first accepts explicit environment overrides and then searches
portable vendor prefixes before system packages:

```text
vendor/python/bin/python3
vendor/postgresql/bin/postgres
vendor/openresty/bin/openresty
vendor/openresty/nginx/sbin/nginx
vendor/nginx/sbin/nginx
```

Equivalent overrides are `GXB_PYTHON`, `GXB_PG_BINDIR`, and `GXB_PROXY_BIN`.
The existing offline wheelhouse remains the preferred dependency source for
Linux x86_64 CPython 3.12. Python 3.13 is supported by `pyproject.toml`, but the
launcher must use the configured Python package index because the sealed
wheelhouse is CPython-3.12-specific.

## HTTP edge modes

`GXB_DEV_EDGE=auto` is the default.

- If nginx/OpenResty is available, Gunicorn stays private on loopback port 19080
  and the proxy owns stock ports 5000 and 9000. This is also the only portable
  PREPARED/maintenance mode because it preserves the physical HTTP 503 gate.
- After PostgreSQL is irreversibly `TRAFFIC_OPEN` and maintenance is off, the
  proxy becomes optional for development. Gunicorn can own both 5000 and 9000
  directly in one master; the mature Flask resource gateway serves `/res/`.
- Realtime remains a separate process on 9100 and Scheduler/Projection remains
  a separate process. PostgreSQL remains the sole durable runtime authority.

Production deployment is unchanged: the accepted reference remains
systemd + nginx + PostgreSQL with the packaged deployment files.

## Legacy migration helpers

Inventory the preserved source without mutating it:

```bash
./gxb-dev.sh legacy-inventory /path/to/preserve/server_state
```

Create an immutable snapshot and perform the I7 candidate migration/validation:

```bash
./gxb-dev.sh legacy-migrate /path/to/preserve/server_state
```

Evidence is stored under `runtime/migration/<UTC timestamp>/`. This does not
bypass I8. `TRAFFIC_OPEN` still requires the evidence-gated prepare/open flow;
the exact irreversible confirmation remains required.

## Common commands

```bash
./gxb-dev.sh status
./gxb-dev.sh start
./gxb-dev.sh stop          # app processes only; PostgreSQL remains available
./gxb-dev.sh down          # app processes + local PostgreSQL
./gxb-dev.sh logs http
./gxb-dev.sh logs realtime
./gxb-dev.sh cutover-status
./gxb-dev.sh scale-preflight 2
```

Personal environment changes belong in `runtime/gxb.env.local`; the generated
`runtime/gxb.env` is refreshed by the launcher.

## Diagnostics and support bundles

All long-running development service logs are written under `runtime/logs/`:

- `http.log`
- `realtime.log`
- `scheduler.log`
- `postgres.log`
- `proxy-error.log` and `proxy-access.log` when nginx/OpenResty is used
- `launcher.log` for portable launcher commands/messages
- `migration.log`, `cutover.log`, and `scale-preflight.log` for those operator flows
- `backend/` for the backend's own request/runtime logs, stock-client error uploads, crash captures, resource probes/audits, and update-event observability (`GXB_RUNTIME_LOG_DIR`)

For a client-debug handoff, prefer:

```bash
./gxb-dev.sh support-bundle
```

This creates `runtime/support/gxb-support-<UTC>.zip` containing the logs plus
host/runtime status, package versions, Alembic/runtime-authority summaries,
sanitary environment snapshots, and non-restricted migration reports. It does
not include the PostgreSQL data directory, venv, immutable legacy snapshot, or
the restricted source manifest.

## Moving the workspace or changing distributions

`runtime/venv` is a cache, not portable state. The launcher fingerprints the
base interpreter, Python ABI, architecture, libc/platform, distro ID/version,
and development-home path. A mismatch causes the venv to be rebuilt from the
pinned runtime lock. On Linux x86_64 CPython 3.12 the bundled wheelhouse is used
offline, so no separate wheel synchronization is required.

The PostgreSQL data directory is more sensitive than ordinary project files.
Keep PostgreSQL on the validated major version when moving a raw cluster. For a
clean distro/major-version transition, use a PostgreSQL logical backup/restore
(or the appropriate PostgreSQL upgrade procedure) rather than assuming
`runtime/postgres/data` is universally portable.

## Portable-dev3 additions

### Updating backend code without losing PostgreSQL state

From the workspace parent, use the wrapper's update transaction:

```bash
./gxb_backend_workspace.sh update
```

The wrapper stops the application stack if it is running, creates a logical
`pg_dump` under `runtime/backups/`, atomically replaces only
`current_backend/`, runs the new backend's `init`/Alembic upgrade against the
preserved sibling PostgreSQL cluster, and restarts the application if it was
running before the update. Per-update metadata is kept under
`runtime/update-snapshots/<UTC>/`.

The PostgreSQL cluster itself stays under `runtime/postgres/`; the dump is a
second safety copy rather than the primary persistence mechanism.

Manual backup:

```bash
./gxb-dev.sh db-backup before-experiment
```

### Known historical sandbox region anomaly

The old JSON runtime could move special sandbox account `13371337` to another
selected region without reallocating its historical player ID `12525385`.
Strict I7 migration correctly rejects such a state because the player ID still
encodes region 125.

Do not edit `preserve/server_state` in place. Create a fail-closed normalized
copy instead:

```bash
./gxb-dev.sh legacy-normalize-sandbox /path/to/preserve/server_state
```

The tool verifies the exact known sandbox identity, verifies singleton
`player_db.json` corroboration and absence of competing ownership references,
then writes a new migration copy plus an audit report under `runtime/migration/`.
Ordinary player identity contradictions remain fatal.

### Editing a live development player's JSONB aggregate

After PostgreSQL is canonical, editing `preserve/server_state/*.json` does not
change runtime state. For QA-only state surgery, stop the application stack and
export the canonical player JSONB aggregate:

```bash
./gxb-dev.sh stop
./gxb-dev.sh player-export 12525385
# edit runtime/dev-edit/player-12525385.json
./gxb-dev.sh player-import 12525385 runtime/dev-edit/player-12525385.json \
  'IMPORT DEV PLAYER 12525385'
```

The import refuses non-`*_test` databases, refuses typed identity/schema
changes, requires the exported `state_version` still to match, and increments
that version on success. This is intentionally a development escape hatch: it
bypasses gameplay-domain validation and should be used only while HTTP,
RealtimeGateway, Scheduler and proxy processes are stopped. Relationalized
mail, sessions, account-global state and other extracted authorities are not
part of this editable player payload.

### Fresh development database

To discard the current candidate and create an empty schema:

```bash
./gxb-dev.sh db-reset-empty 'RESET EMPTY DEV DATABASE'
```

The command first creates a logical backup. An entirely empty database cannot
become I8 runtime authority because the accepted I8 contract requires at least
one validated account/player source. For a practical "fresh server" baseline
that ignores `preserve/server_state`, create a new candidate from the packaged
sandbox fixture:

```bash
./gxb-dev.sh scratch-candidate 'RESET DEV DATABASE FROM SCRATCH'
```

This also backs up the previous database first. It intentionally does not open
traffic by itself. For an immutable legacy migration, `prepare-latest` builds
and applies the I8 PREPARED evidence gate; `cutover-open` still requires its
exact irreversible confirmation before normal gameplay traffic can start.

## Portable-dev4 startup-probe correction

Portable-dev4 changes only portable development supervision. The accepted Pass348 runtime is unchanged.

- HTTP startup now waits up to 30 seconds by default for `/health/live` instead of performing one aggressive cold-start probe.
- Override the window with `GXB_DEV_HTTP_STARTUP_TIMEOUT=<seconds>` when diagnosing unusually slow hosts.
- On a genuine failure, the launcher prints the tail of `runtime/logs/http.log` before stopping the HTTP process.
- This is especially useful after a clean install or cold page cache where first Gunicorn application import can take longer than two seconds.

## Portable-dev5 rootless nginx path correction

Portable-dev5 keeps the accepted Pass348 application/runtime unchanged and corrects only portable development proxy supervision. System nginx builds on Debian/RHEL-family distributions may compile default error/temp paths beneath root-owned locations such as `/var/log/nginx` and `/var/lib/nginx`. The portable launcher now explicitly assigns the bootstrap error log and every nginx temporary-path class (client body, proxy, FastCGI, uWSGI, SCGI) beneath `GXB_DEV_HOME`, so normal dev startup requires no recursive chmod and no root-owned nginx runtime directories.

## Pass353 persistent OTA topology

`current_backend/` is disposable. Canonical PostgreSQL already lives outside it; Pass353 applies the same rule to MID2 publication state. Workspace wrapper v7 stores `release_registry.json`, `update_manifest.json`, `update_controller_state.json`, and generated `updates/` volumes under `runtime/ota/`, then symlinks them into each extracted backend. Ordinary `update` therefore cannot erase published OTA history.

Production HTTP is Gunicorn `gxb_backend.runtime.wsgi:app`, so `gxb-dev.sh start` runs `update_controller.py ensure` in the operator process **before** opening HTTP listeners. If the required initial barrier cannot be built/verified, start fails loudly rather than accepting a clean client with an unpublished MID2 barrier.

The proxy does not serve `/res/` through a flat filesystem alias. Stock lazy resource URLs contain only `<basename>.<md5>`; they are proxied to the backend ResourceGateway, which resolves the authoritative catalog path (for example `res/web/...`) and verifies MD5 before serving.
