# V2 real-client test harness

Temporary test tool: a real Android client plays against the v2 backend. Not product code and not the W2 operator tool. It builds
the backend into its own directory, runs its own PostgreSQL cluster, and serves the SDK and lazy assets the real APK needs.

Runs as the user service `gxb-test-harness` while the laptop is on. Stop it during strict gates and heavy tests:
`systemctl --user stop gxb-test-harness`, then `start`. After each PassMap seal `ops/harness_deploy.sh [commit]` replaces the
backend, wipes the database and reseeds players and bots; it keeps `runtime/state/secrets.json`.

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
- `PLAYTEST_ASSET_TREE` - lazy asset tree (default `tmp/virtualclient/update-tree`).

The media root is `$PLAYTEST_HOME/media` (mode 700, as the blob store requires). Its public origin is the
engine origin when that is a literal `http://` origin; otherwise it falls back to
`http://<LAN host>:18956`, because the backend's profile-media URL parser rejects `https://` origins.

Secrets are generated once with the `secrets` module into `state/secrets.json` (mode 600) and kept across
resets. They are never the virtual-client fixture values.

## Commands

Run with the bundled Python:

```
.toolchain/bin/python3 -I -B test_harness/harness.py reset /path/to/backend
.toolchain/bin/python3 -I -B test_harness/harness.py up
.toolchain/bin/python3 -I -B test_harness/harness.py status
.toolchain/bin/python3 -I -B test_harness/harness.py logs gxb-api [-f]
.toolchain/bin/python3 -I -B test_harness/harness.py down
.toolchain/bin/python3 -I -B test_harness/selfcheck.py
```

- `reset` stops everything, builds gxb-api, gxb-combat-worker, gxb-worker and gxb-realtime
  (`-tags postgres,river`) into `bin.new` and swaps only on success, starts the cluster, recreates
  `gxb_playtest` (goose, content deploy, publication preparation as `ops/testing/fresh_db.sh`), clears the
  SDK accounts and records the backend tree and commit in `state/backend.json`. It does not start services.
- `up` starts the cluster, the five services and the two tunnels as detached processes with logs in `logs/` and pids in
  `run/`; it refuses a port held by another process and waits for `/health/live`.
- `down` stops them by recorded pid after checking `/proc/<pid>/cmdline`, then stops the cluster.
- `status` prints one line per service, the backend commit and the LAN host.

## Asset front

`GET|HEAD /res/<basename>.<md5>` streams the file from the asset tree. The index is keyed by
`<basename>.<md5>`, cached in `state/asset_index.json`, and rebuilt when the tree file count or total size
changes. A miss or a wrong md5 is a 404, one log line, and one append to `state/missing_assets.txt`.
Everything else is forwarded unchanged to gxb-api; the only rewrite is an object reply whose
`res_download_url` is empty (MID 20480), which becomes `<engine origin>/res/`.

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
- MID 2 is answered with no update (`is_appstore`, `is_inapp`, `is_review`, `need_restart` all 0), so
  `UpdateScene.lua:518` calls `startGame_()` and never requests an update package.
- Lazy entries come from the client's local `version.json` (`UpdateScene.lua:394-403`); the APK ships
  `assets/src_64/version.json`. `AssetDownload.lua:46-50` reads the same file and
  `AssetDownload.lua:1194` builds `<resDownloadUrl><basename>.<md5>`. Nothing else is needed in the
  URL, so the front's exact basename+md5 lookup matches it.
- The served tree holds the `res/` files; `version.json` also lists `src_32`/`src_64` Lua entries that are
  already packaged in the APK and are not in the tree, so those requests (if any) are honest 404s.

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

## Limits

- Realtime (chat and live notices) is raw TCP and reaches clients on the LAN only: `sudo firewall-cmd --permanent --add-port=18954/tcp`.
  A changed laptop IP needs a harness restart, no APK rebuild. On mobile data the game works without chat and live notices.
- Champion's first load for a 123-girl account with 20 ranked bots takes about 8 s (client timeout 20-30 s); a repeat load 0.2 s.

- MID 2 remains no-update; there is no delta/update-package server.
- The served tree holds 25,420 of the 29,931 lazy `res/` files named by `version.json`; the other 4,511
  (for example some `res/web/images/maps/map_avatar/` entries) are absent from the supplied tree along with
  `version.json` entries that are `force=1`/`md5=0` and therefore not lazy at all.
- The asset tree does not cover every `version.json` entry; missing ones are recorded in
  `state/missing_assets.txt`.
- The SDK keeps one session per account, as planned for playtesting; it is not a production SDK.
- Do not run this beside the emulator or a strict gate: the laptop runs realtime and PostgreSQL here.
