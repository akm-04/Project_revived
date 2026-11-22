# Testing the backend (I8.5 onward)

How agents test GXB v2 without a real phone or lobby stubs (D9 Q3). Four layers, cheapest first. Run each layer before the next.
All paths are relative to /home/akm/Chatgpt/EOL_Game. Logs go to your session scratchpad, never to the repo.

## 0. Environment
- Python: `.toolchain/bin/python3 -B` (never system Python or .venv).
- Go: `. ops/testing/goenv.sh` (pinned r4 Go 1.27.3, tmp/ caches, cd backend). Virtual client module: `. ops/testing/vcenv.sh`.
- PostgreSQL dev cluster: `tmp/test-databases/i853_dev`, port 55853, user postgres (start it with `ops/testing/start_cluster.sh` if down; a bare `pg_ctl start` uses the wrong port and socket).
  Never touch `tmp/test-databases/i7c5a_dev` (port 55493).
- Worker cluster (G6): a queue writer task (profile slim) gets its own private cluster and the variables `GXB_TEST_PGHOST`
  (socket directory) and `GXB_TEST_PGPORT`. Use them in every DSN: `postgres://postgres@/<db>?host=$GXB_TEST_PGHOST&port=$GXB_TEST_PGPORT`.
  `fresh_db.sh` and the preflight already follow them; unset, both fall back to i853_dev on 55853. The queue removes the cluster when
  the task ends. A native test in your own cluster may run beside a strict gate; a virtual client or emulator run may not.
- Fresh database (what the gate and the virtual client expect): `ops/testing/fresh_db.sh <db>` clones a template built once per
  tree state (HEAD, uncommitted changes, migrations). By hand, on `$GXB_TEST_PGPORT` or 55853:
  1. `$T/bin/createdb -h <socket> -p 55853 -U postgres <db>`
  2. `$T/bin/goose -dir migrations postgres "$DSN" up`
  3. `GXB_POSTGRES_DSN=$DSN go run -tags postgres,river ./cmd/gxb-content-broadcast-deploy`
  4. `GXB_I7A9_DSN=$DSN GXB_I7A9_PREPARE_PROCESS=1 go test -tags postgres,river -run '^(TestPreparePublicationProcess|TestPreparePublicationRiver)$' ./internal/integration/publication ./internal/adapters/river`
- Drop with `$T/bin/dropdb --force ... </dev/null`. Never reuse one database for different tag sets.

## 1. Unit, vet, validators (minutes)
- `go test ./...` (no tags), `go vet` on the tag sets `postgres`, `postgres river`, `postgres river socialintegration channelintegration`.
- `gofmt -l .` must be empty; `tools/check.sh` validators must pass (archguard: non-test code only in registered layers;
  pgx/river imports only under internal/adapters/postgres|river).

## 2a. Gate preflight (seconds to minutes; every leaf close and every merge)
- `python3 -B tools/gate_preflight.py --base <branch point> --database <prefix>_preflight` (from the backend tree, after sourcing goenv.sh).
  Census of test variables and gofmt in about a second; then every changed package runs whole with the gate's tags, -p=1 and a fresh
  database, judged by the gate's own known-debt and skip-allowlist rules. `--static-only` skips the package runs.
- Leaves report GATE_PREFLIGHT GREEN before calling writing work done; the lead's merge check runs it on the merge. A strict gate is
  only started on a commit whose last merge passed the preflight (rule added after the I9-10 closing gate went RED on 95 items, 2026-11-09).

## 2. Strict gate (hours; the acceptance test for a commit)
Leave the real-client test harness running (D524): the latency section waits until load and CPU temperature hold under their limits for 5 minutes, so any background load that matters delays it on its own.
- `.toolchain/bin/python3 -B work/backend_i7c4_full/backend/tools/strict_gate.py --toolchain tmp/tools_r4_accept/gxb-e2e-self-contained
  --cache tmp/cache/tools_r4 --work tmp/gate_<x> --commit <sha> --populated59-dump work/authority_p<G>/cold/IMPLEMENTATION_EVIDENCE/PASS715/I7C3B/F2_RECOVERY_EVIDENCE.dump`
- It tests an exported clean commit: commit first. `--select REGEX` reruns units such as `recipe:populated35` or `suite:postgres`.
- Run it inside the 1on1 window, 08:00-22:00 GMT+8, and outside the TopFloor freeze, 21:00-21:30 GMT+8. Some tests need those modes open.
  Latency units fail on a hot laptop or beside another heavy job (never run a VC suite beside a gate): cool down and rerun with `--select reference-host:latency`.
- Focused reruns (user, 2026-11-09): a RED gate is not rerun whole after its fixes. Each fix is checked with the preflight on its packages,
  then the gate reruns only the units that were red (`--select` with the failing suites, recipes or `reference-host:latency`) on the fixed
  commit. The full gate runs once more only for the sealing commit, and only when product code changed outside the rerun units.
- Latency (user, 2026-11-09): pass/fail is the absolute p95 against its budget. Record beside it a machine baseline and CPU temperature over
  several repetitions; they explain a failure, they never excuse or normalize it. Implemented in bf04bd5: the gate runs 3 repetitions
  (`GXB_I8_LATENCY_REPETITIONS`), fails on the pooled p95, and writes a `reference-host:latency-conditions` step (hwmon temperatures,
  mean clock, load, 64 MiB sha256 baseline, before and after) into STRICT_GATE.json.
- `tools/strict_gate/known_debt.json` and `skip_allowlist.json` are generated by `work/i8_5/scripts/build_gate_lists.py <backend>`;
  never edit them by hand. Known debt is empty since I8.5-6, so any failure is RED.

## 3. Virtual client (the stock game client, emulated; minutes per scenario)
- What it is: `backend/virtualclient` (module of its own) runs the stock decompiled client Lua (`tmp/virtualclient/src_64`, pinned digest
  5ad9ee3a...) in a self-contained Lua engine with emulated cocos/tolua peers, stock HTTP transport, realtime socket, client log uploads
  and the SDK login. It is a real client boot (UpdateScene -> login -> story -> MainScene), not a protocol mock.
- Inputs in tmp/virtualclient: `src_64` (decompiled client Lua), `apk` (APK assets with res/), `update-tree` (lazy assets from the
  supplied tarball, built once with `bin/gxb-asset-tree -tarball ... -catalog ... -out update-tree`, MD5-verified; D30/D31).
- Build binaries into tmp/virtualclient/bin: `gxb-api` and `gxb-combat-worker` from backend with `-tags postgres,river` (gxb-api starts the worker from its own directory, so a stale worker runs old combat code and transforms); `gxb-virtual-client`, `gxb-mid-coverage`,
  `gxb-asset-tree`, `gxb-sdk-harness` from virtualclient/cmd with `-tags postgres` (the I9-2 provisioner uses the production pool). `vc_run.sh` does NOT build them; rebuild after every backend change.
- One run: `VCDB=<fresh db> SCENARIO=backend/virtualclient/scenarios/<name>.json UPDATE_TREE=$PWD/tmp/virtualclient/update-tree
  ops/testing/vc_run.sh <run-name>`; expect `client=0`. Read `runs/<run-name>/report.json`, `client.log`, `api.log`.
- Whole suite: `VCDB=<fresh db> ops/testing/vc_suite.sh` (every JSON scenario in virtualclient/scenarios/; every line must say client=0).
- Server-side evidence: per-uid client logs and the request journal (I8.5-3) are in the database; `gxb-mid-coverage` (COVERAGE=1)
  lists which stock MIDs the run exercised.
- New scenario: copy one in `virtualclient/scenarios/` (JSON steps of node-path taps and waits) and add it to the suite by file.
- Multi-wave battles (campaign and other PvE): the engine model has no quick-cocos NODE_TOUCH_EVENT on widgets, so the next-wave
  arrow cannot be tapped; set the stock auto preference first (`xyd.db.campaignAutoStatus:setCampaignAutoStatus(type, true)`) and
  end battle stories with `StoryWindow:onEnded()` (see `i9_3a_campaign.json`). Open stage windows after the stock loader
  (`loadWorldMap`), never with hand-built model state.
- Watch the client RSS (alarm above 3.5 GB). Never use gopher-lua SetContext in the client.

### 3a. Writing and debugging a scenario (read before your second failed run)
- One run at a time: gxb-api binds 18853/18854, so a second concurrent run fails on the port or reads the wrong server. Check
  `pgrep -fa 'gxb-api|gxb-virtual-client'` before a run; wait for it, never kill another agent's run. `vc_run.sh` holds
  `tmp/vc.lock` for the whole run, so a second run waits (up to 2 h) instead of colliding.
- Before the first run: rebuild the bins if the backend changed, use a fresh database when the scenario needs a new player state,
  pass SCENARIO as a full path, and set LIMIT above the scenario's total wait (default 120s; a campaign battle needs ~300s).
- Check the clock against mode windows first: Top Floor nodes are hidden 13:00-13:30 UTC; 1on1 opens 00:00-14:00 UTC.
- Read `client.log` from the bottom: the first `vc-...` error (your own `error('vc-...')` text) or Lua stack names the step.
  `api.log` and `request_journal` show what the server answered. Fix one thing per run; do not re-run unchanged.
- Diagnose with a probe, not with guessed taps: a `lua:` step that `error()`s with the values you need (window names, node
  bounding boxes, guide ids) is one run and tells you everything. Then write the real step.
- Geometry: the screen and STAGE are 1280x720. `getCascadeBoundingBox()` is parent-local; convert with
  `n:getParent():convertToWorldSpace(cc.p(b.x, b.y))` and tap the centre. Tap by node name (`tap:<name>`) when it is unique and visible.
- Guides: GuideNewWindow passes a touch only inside its hole (`g:isTouchInContent(x, y)`); scan the button box for a point inside
  the hole (see `i9_4_guide17.json`). When the VC lays a widget out off-screen (task sidebar), tap the hole and run the stock
  callback body, and say so in the scenario `note`.
- Prefer stock model and window methods (`task:getTaskReward`, `window:goldSummon(10)`) over raw `xyd.Backend` requests; use a raw
  request only to probe a MID the UI cannot send (e.g. an inactive MID with `expect_inactive`).
- Earn state through real producers (battles, sweeps, pulls); use provisioner `level`/`heroes`/`vip`/`grants` only for what the
  scenario does not test. Never write mission, guide or reward state directly.
- Budget: after three failed runs on the same step, stop, write what you learnt into the stage RESUME_STATE, and take one
  checkpoint. Do not checkpoint between every run.

## 4. Android emulator (I8.5-7; real APK, slow, for what the virtual client cannot prove)
- SDK and AVD under tmp/android (KVM; x86_64 image with arm translation, since the APK is arm64-only).
- `ops/testing/build_emulator_apk.sh` rebuilds the stock APK from a copy of the app_repack inputs, using `app_repack/` taken by `git archive` from
  the workshop repo's branch v2 (patch_game_v2.sh, origin_lua/, patch_google_dns.py, apktool and signer jars). It points the origins at gxb-api (10.0.2.2:18853) and
  the Xinyd SDK at gxb-sdk-harness (10.0.2.2:18855). A client patch change is committed on branch v2 first, then rebuilt here. Never run
  patch_game.sh or scripts inside Supplimental_Materials in place.
- `ops/testing/fresh_db.sh <db>`, then `ops/testing/emulator_smoke.sh up <db>`: starts gxb-api, gxb-realtime (18854; without it the
  chat polls MID192 every 3 s), gxb-sdk-harness and the headless AVD, installs and launches. Then `shot <name>` (PNG in
  tmp/android/run/shots, read it to see the screen; screen is 2280x1080) / `tap x y` / `text` / `key` / `down`. Logs: tmp/android/run.
- GPU: `-gpu swangle_indirect` (default). swiftshader_indirect and guest segfault here: SELinux denies the SwiftShader GLES JIT.
- Login walk (2026-10-24, about 3 min): Guest Login (1072,414) -> Bind later (1403,211) -> title. A fresh install shows "Text Label"
  and MID1 fails invalid_region (stock picks regions[4], H07); the stock Tip's Confirm then exits the app. So run
  `emulator_smoke.sh remember-region 1` (relaunches), Bind later again, tap "Click to switch" (1302,875), pick S1 in Servers List
  (969,294), tap the screen: MID1 creates the player and the opening story starts; SKIP (2029,31) and taps reach the lobby.
- remember-region hides the fresh-install path, which is what real clients take. D435: with fewer than four listed servers that path breaks the login page. After any login or directory change, also walk a clean install (`pm clear com.carolgames.gxb`, no remember-region).
- A new character needs MID18 in the same session (server_observation_required, 409), which is why the region window is used.
  Take a screenshot and confirm the Servers List opened before tapping the title. The Click to switch tap can miss while the payment toast shows; repeat it.
- The SDK harness keeps one guest per device_id while it runs; restarting it makes a new guest.
- Client log path: `emulator_smoke.sh probe-errorlog [text]` puts one row in stock's errorlog store; ErrorLogPoster uploads it to the
  MID1 log_url within 30 s (client_log_uploads, attributed to account and player). Request journal: table request_journal.
- Evidence of the first full run: work/i8_5/stages/I8.5-7/evidence.
- Lost tmp/android? Unzip inputs/tools/gxb-android-emulator-i8.5-7.zip (`android/*` into tmp/); see its README.md.

## 5. Closing a stage or phase (D72)
On the closing commit, in order; write each result into the stage evidence, and a skipped layer with its reason:
1. Layer 1 (unit, vet, gofmt, tools/check.sh; oracle validators NOT_RUN without their zips).
2. Strict gate GREEN, known debt 0.
3. Virtual client suite on a fresh database: every line client=0. Then read the request journal: `outcome` counts, every UNKNOWN_MID
   and SERVER_ERROR row explained (I9-JOURNAL-ANOMALY-BACKLOG), and unattributed rows after MID1 only for the known reasons.
4. Android emulator login walk when login, MID1, the client patch or a client-visible screen changed.
A new mode adds at least one scenario that drives it through the stock UI, so later stages rerun it for free.

## Rules learnt the hard way
- Kill by pid, never `pkill -f`. Parent-test env vars are never set globally.
- Tests that start the API process must give it the same DSN as their fixtures.
- Recipe tests on old dumps (populated32/35/59) must seed with the schema of that dump (`legacyPlayer`), not today's birth chain.
- Do not run heavy integration packages concurrently on one database (`-p 1`).
- A native test that posts to a dispatcher must carry the stock fields (`app_v`, `platform`, `v_`, `token`, `region`). MID 301 refused every real client for two phases because its tests left them out.
- Run a delivered MID through a stock scenario at least once; a native test cannot find an envelope defect.
- Trial stages rotate by weekday. A scenario that fights one needs `fixture:strong_team` (then `relogin`), because provisioned heroes are summoned after startup and a startup flag cannot reach them.
- Long scenarios now hit the stock timed refresh (`payload=nil`, UNDECODABLE, D202) and MID 1152. Count them in the journal read; do not treat them as new defects.
