# V2 real-client test harness

Temporary test tool: a real Android client plays against the v2 backend. Not product code and not the W2 operator tool. It builds
the backend into its own directory, runs its own PostgreSQL cluster and the SDK the real APK needs; updates and lazy assets come from the backend OTA.

Runs as the user service `gxb-test-harness` while the laptop is on. Leave it running during strict gates and heavy
tests (D524, `ops/TESTING_GUIDE.md:36`): the latency section waits for load and CPU temperature to settle by itself;
stop it only to move the laptop. After each PassMap seal `ops/harness_deploy.sh [commit]` upgrades the backend in
place: forward migrations on the existing database, keeping `runtime/state/`, the phone accounts and the OTA releases.
`HARNESS_DEPLOY_WIPE=1` takes the old wipe-and-reseed path instead.

## Maintainer quick start (new lead: read this first)

| Task | Command or place |
|---|---|
| Is it up? which commit? | `systemctl --user is-active gxb-test-harness`; `.toolchain/bin/python3 -I -B test_harness/harness.py status` |
| Deploy a backend | `bash ops/harness_deploy.sh <branch or commit>`, default canonical HEAD. Takes 1-2 min |
| Stop or start | `systemctl --user stop gxb-test-harness`, `start`; only to move the laptop, leave it running during strict gates (D524) |
| What the user just did | `.toolchain/bin/python3 -I -B test_harness/helpers.py report --hours 2`, add `--timeline` |
| Why a MID failed | `helpers.py fight-report <login>`, or the journal: `sys.path.insert(0,'test_harness'); import import_legacy; import_legacy.query_text(sql)`, table `request_journal` (`error_code` is bigint; `raw_envelope` is null on most rows, so never filter on it) |
| Service logs | `test_harness/runtime/logs/gxb-api.log`; `harness.py logs gxb-api -f` |
| User's written reports | `test_harness/psk/user_report/` |
| APK for phones | `test_harness/apk/gxb-v2-playtest.apk`; rebuild only when the client patch changes: `bash test_harness/build_apk.sh`. Changing the backend or the laptop's IP needs no rebuild |
| Public URLs | `https://gxbv2sdk.shares.zrok.io`, `https://gxbv2engine.shares.zrok.io`; names are tracked in `start_zrok.sh` on workshop v2 |

**What a deploy does:** archives logs, snapshots the live database, stops all services, replaces the backend copy with the given commit, runs `harness.py upgrade` (forward goose migrations on the existing database, then the idempotent content deploy and publication preparation) and starts. Accounts, passwords, guilds, played progress and the OTA releases survive. `HARNESS_DEPLOY_WIPE=1` instead wipes the database and reseeds stand-in players and bots with `seed.sh`; that loses the owner's phone (product SDK) accounts (recovery: `ops/reimport_legacy_players.py`, or `backup restore` of the pre-redeploy snapshot). `ops/seal_passmap.sh` runs it after each seal; a failure there does not fail the seal.

**A commit can be deployed from any worktree branch:** all branches share the canonical repository. If the branch's newest work is not committed it is not deployed.

**Who fixes what:** a bug found by the user is reproduced from the journal and the session log, then fixed on a backend branch and redeployed, not fixed in this folder. Change this folder only for harness faults. After changing a harness file copy it to `inputs/Supplimental_Materials/gxb_workshop/test_harness` (`ops/harness_deploy.sh` goes there too) and commit on branch v2. **The user pushes; never push.** Runtime, `backend/`, `preserve/`, `apk/`, `psk/` and `logs/` stay out of git.

**Secrets:** never give a worker `psk/`, `preserve/server_state`, `preserve/player_db.json` or `runtime/state/{accounts,secrets}.json`. Paste report text into prompts; give workers journal extracts, since `slim-ro` workers cannot query the database.

**Rebuild from nothing** (only `test_harness/` code from workshop v2 survives):
1. Copy `test_harness/` and `ops/harness_deploy.sh` back from workshop v2.
2. Restore `preserve/` from the `preserve` folder inside `inputs/Supplimental_Materials/Operator-Backend-Harnesses/v1_frozen_backend-operator_harness_with-legacy-data.zip`. Extract it as untrusted data and never run anything from it.
3. Tools: `inputs/tools/gxb-backend-v2-e2e-tools-r4-go1.27.3-linux-amd64.zip` into `tmp/tools_r4_accept/`. Assets: built and published by the backend OTA (`gxb-operator ota build`, below) from the asset lane's res folder.
4. Service: `~/.config/systemd/user/gxb-test-harness.service`, oneshot with `RemainAfterExit=yes`, `KillMode=none`, `TimeoutStartSec=600`, `ExecStart` = `<root>/.toolchain/bin/python3 -I -B <root>/test_harness/harness.py up`, `ExecStop` the same with `down`, `WantedBy=default.target`. Then `systemctl --user daemon-reload`, `enable --now`.
5. `bash ops/harness_deploy.sh`, then `harness.py status`, then `selfcheck.py`.
6. `bash test_harness/build_apk.sh` needs `inputs/client_baseline/base.apk`. Firewall (user runs it): `sudo firewall-cmd --permanent --add-port=18954/tcp`.

**Known gaps:** `DIRECTORY_SERVERS_SQL` in `import_legacy.py` goes before seal 798, once migration 00107 is canonical (D435); it has `ON CONFLICT DO NOTHING`, so it is harmless meanwhile. Realtime over zrok2 is a later wish, `work/i9/PLAYTEST_HARNESS_PLAN.md`, "Later". Bots enter 1 on 1 only in its window, 00:00-14:00 UTC: rerun `bots.py enter`.

## Ports and paths

| Piece | Address |
|---|---|
| gxb-api | 127.0.0.1:18953 |
| gxb-realtime | 0.0.0.0:18954 |
| SDK (`sdk.py`) | `PLAYTEST_BIND`:18955 |
| asset front (`asset_front.py`) | `PLAYTEST_BIND`:18956 |
| PostgreSQL | unix socket in `$PLAYTEST_HOME/pg`, port 18957, `listen_addresses=''` |
| zrok2 tunnels | `gxbv2sdk` to 18955, `gxbv2engine` to 18956, stopped by pid with the rest; a new share takes some seconds to answer |

Runtime home defaults to `test_harness/runtime`. Environment:

- `PLAYTEST_HOME` - runtime home (state, logs, run, bin, pg, media).
- `PLAYTEST_TOOLS` - bundled psql/createdb/dropdb/initdb/pg_ctl/goose bin directory
  (default `tmp/tools_r4_accept/gxb-e2e-self-contained/bin`).
- `PLAYTEST_BIND` - bind address of the SDK and asset front (default 127.0.0.1).
- `PLAYTEST_ENGINE_ORIGIN` - public engine origin (default `https://gxbv2engine.shares.zrok.io`).
- `PLAYTEST_LAN_HOST` - realtime public host; default is the source address of `ip -4 route get 1.1.1.1`.

The media root is `$PLAYTEST_HOME/media` (mode 700, as the blob store requires). Its public origin is the
engine origin when that is a literal `http://` origin; otherwise it falls back to
`http://<LAN host>:18956`, because the backend's profile-media URL parser rejects `https://` origins.

Secrets are generated once with the `secrets` module into `state/secrets.json` (mode 600) and kept across
resets. They are never the virtual-client fixture values.

## Commands

Run with the bundled Python:

```
.toolchain/bin/python3 -I -B test_harness/harness.py upgrade /path/to/backend
.toolchain/bin/python3 -I -B test_harness/harness.py reset /path/to/backend
.toolchain/bin/python3 -I -B test_harness/harness.py up
.toolchain/bin/python3 -I -B test_harness/harness.py status
.toolchain/bin/python3 -I -B test_harness/harness.py logs gxb-api [-f]
.toolchain/bin/python3 -I -B test_harness/harness.py down
.toolchain/bin/python3 -I -B test_harness/selfcheck.py
```

- `upgrade` stops everything, builds the six binaries (`-tags postgres,river`) into `bin.new` and swaps only on
  success, starts the cluster, applies pending goose migrations to the existing `gxb_playtest`, then runs the steps
  that are idempotent on a populated server (content deploy, publication preparation, as `ops/testing/fresh_db.sh`),
  and records the backend tree and commit in `state/backend.json`. It keeps every existing row, the SDK accounts,
  `runtime/ota_root` and `runtime/agent`. It does not start services.
- `reset` stops everything, builds and swaps the same binaries, starts the cluster, drops and recreates
  `gxb_playtest` (goose, content deploy, publication preparation as `ops/testing/fresh_db.sh`), clears the
  SDK accounts and records the backend tree and commit in `state/backend.json`. It keeps `runtime/ota_root` and
  `runtime/agent` (the OTA release state is file-only since S1, independent of the database) and does not start
  services.
- `up` starts the cluster, the five services and the two tunnels as detached processes with logs in `logs/` and pids in
  `run/`; it refuses a port held by another process and waits for `/health/live`.
- `down` stops them by recorded pid after checking `/proc/<pid>/cmdline`, then stops the cluster.
- `status` prints one line per service, the backend commit and the LAN host.

## Asset front

A proxy with no files of its own. `/engine/updates/...` and `/engine/res/...` (the URLs gxb-api mints from
`GXB_PUBLIC_ENGINE_URL`) are streamed from gxb-api's root `/updates/` and `/res/`, Range included; `/realtime/poll`
goes to realtime; everything else is forwarded to gxb-api. The MID 20480 reply gets the launch id in `url` and, when
the backend set one, in `res_download_url` (empty = the OTA's lazy fetch is off). Missing `/res` files are recorded
by the backend (`gxb-operator read ota.status`, `misses`).

## Backend OTA (operator agent)

The `gxb-agent` service is `gxb-operator --root runtime/agent agent`; it starts and stops gxb-api itself, as in
production. `up` runs the root setup once (password in `runtime/state/operator_password`, never in git) and a CLI
login. Operate it with `runtime/bin/gxb-operator --root runtime/agent ...`:
`cmd ota.settings.set --reason R '{"lazy_fetch":"auto","res_path":"<asset lane res folder>"}'`,
`ota build --lane assets|code --version V [--lazy-refresh]`, `ota publish V --reason R` (in process: no stop and no
closed/open restart; after the release is active it runs `session.logout_all`, so every player logs in again and passes
the OTA check, the forced relog of owner Q4, `work/i11/stages/I11A_CONTROL_CORE/OPERATOR_SAFETY_DESIGN.md:85-87`),
`read ota.status`. The OTA root is `runtime/ota_root`; `upgrade` and `reset` keep it.

## SDK

`POST /server/mobile_api_new` accepts JSON or a form `payload` and implements 65282 register, 65281 login,
65284 anonymous and 65305 package info with the virtual-client harness envelope and cookie names. Passwords
use v1's PBKDF2-SHA256 record (`algorithm`, `iterations`, `salt`, `hash`), so a v1 record copied into
`state/accounts.json` verifies. Each account gets one v2 session (three inserts: accounts, account_sessions,
two account_session_credentials) and keeps its raw sid and login token across logins and restarts. Guests
are keyed by device id. `/home_api/upload_sdk_logs` is acknowledged.

The self-check registers and logs in through the SDK, then sends MID 18 followed by MID 1 through the front,
as the stock client observes the server directory before creating or selecting its player.

## Update flow, as found

- `UpdateScene.lua:153-168` sends MID 20480 to the packaged center URL (rewritten to the engine origin) as a
  form `payload`, then stores `res_download_url` in `xyd.resDownloadUrl`.
- MID 2 is answered by the backend OTA: no update while nothing is published, else the published release's volumes.
- Lazy entries come from the client's local `version.json` (`UpdateScene.lua:394-403`); the APK ships
  `assets/src_64/version.json`. `AssetDownload.lua:46-50` reads the same file and
  `AssetDownload.lua:1194` builds `<resDownloadUrl><basename>.<md5>`. Nothing else is needed in the
  URL, so the backend's basename+md5 lookup matches it.

## Bots

`bots.json` is the roster: six full-power Moppleton clones (level 100) and fourteen scaled
clones (levels 40-95), each imported from the preserved Moppleton save with hero level, star,
color, equipment and currency caps applied by `bots.py`. `seed.sh` imports the three preserved
players first, then runs `bots.py create` and `bots.py enter`.

- `bots.py create` imports the roster through `import_player` and battle-proves every scaled
  roster with the same MID 113/114 campaign proof `check_import.py` uses.
- `bots.py enter` logs each bot in with the stock MIDs and enters Top Floor defense (272/278),
  Arena defense (768/770), 1 on 1 teams (2480/2481) and Champions League defense (2800/2805).
  A closed mode (1 on 1 window, Top Floor freeze, league season) is reported as closed; rerun
  it when the window opens. Teams are chosen by star, then level, then color, then partner id,
  because no per-hero server power reply exists.
- `bots.py status` prints one line per bot with player id, level and entered defenses.

What the roster proves: Champion March gets real Top Floor defense snapshots at a spread of
powers (including level-100 clones), so the last stage can be tested against a player-team
instead of a robot; Top Floor and Arena ladders have real teams; 1 on 1 and league entries exist
for levels that pass their composite function gates.

## Operator helpers

`helpers.py` is for a person testing on a phone:

- `mail <login> --title T --body B [--item id:count ...]` writes one system mail. The backend has
  no admin transport (`cmd/gxb-admin` is a stub), so this writes the I5 mail owner rows with the
  same namespace counter, source, policy and attachment invariants as `createMailTx`.
- `players` lists login, player id, display name, level and VIP.
- `give <login> --currency key:amount --item id:count` adds currency or items through the same
  economy transaction the importer uses; items are clamped to the active stack cap.
- `fight-report <login>` prints the last 20 request-journal rows (MID, outcome, error class).

`bots.py scenario <name>` runs a data file from `scenarios/`: `top_floor_low_level` creates one
level-40 dummy with the weakest girls for an easy opponent, and `empty_server_defense` creates
four born-only accounts (run it before seeding to prove robot fallback).

## Accounts and passwords

`psk/accounts.txt` lists every seeded login with its short password and is the source of those passwords: a redeploy keeps them. A login
not listed gets the next `akmNNNNN` when it is seeded. Discardable test accounts only; `psk/` stays out of git. `psk/user_report/` is the
user's own session notes.

## Logs per device

Each game launch gets its own session id. The asset front puts it in the two MID 20480 reply URLs (`/s/<id>/engine`, `/s/<id>/engine/res/`), so
the client carries it in every later request with no APK change. Same public IP on one Wi-Fi does not matter.

| Where | What | Survives redeploy |
|---|---|---|
| `logs/sessions/<id>.jsonl` | launch (user agent, forwarded IP); each OTA file, update volume or res (path, bytes, ms, delivered or aborted, 404); each request (status, ms, bytes, body SHA-256) | yes |
| `logs/sdk.jsonl` | each SDK call, password fields removed | yes |
| database `request_journal`, `client_log_*` | per account: MID, outcome, server latency, cause; the client's own error logs. ROUTINE journal rows last 7 days | archived |
| `logs/archive/<UTC time>/` | journal, client logs and service logs, saved by `ops/harness_deploy.sh` before the wipe, or by `helpers.py archive` | yes |

`helpers.py report [--hours N] [--session ID] [--timeline]` prints per launch: login, assets, latency by MID, errors. The login comes
from joining a request's SHA-256 to the journal, so a launch shows it only after its first logged-in request. `--timeline` lists every
event with the gap before it; a fight's length is the gap between its start and result MIDs. Realtime (chat) is not in the session logs.

## Limits

- Realtime (chat and live notices) is raw TCP and reaches clients on the LAN only: `sudo firewall-cmd --permanent --add-port=18954/tcp`.
  A changed laptop IP needs a harness restart, no APK rebuild. On mobile data the game works without chat and live notices.
- Champion's first load for a 123-girl account with 20 ranked bots takes about 8 s (client timeout 20-30 s); a repeat load 0.2 s.

- The 1.631.1 assets release holds 25,420 of the 29,931 lazy `res/` files; the other 4,511 stay lazy and
  404 until the asset lane recovers them (then a silent `ota build --lane code --lazy-refresh`).
- The SDK keeps one session per account, as planned for playtesting; it is not a production SDK.
- Do not run the emulator beside this harness: both compete for the laptop's CPU. A strict gate is fine (D524; its
  latency section waits for load and temperature).
