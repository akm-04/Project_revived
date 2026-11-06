# Load test (user request R2)

Repeatable measurement of what happens when N virtual players log in and start
battles at once. The players are real rows: accounts in SQL, stock MID18 + MID1
birth through the HTTP edge, the production level grant, and stock MID59 hero
summons. Every measured call is a stock MID over HTTP against the worktree
binaries on private ports.

## Build and run

```bash
W=/home/akm/Chatgpt/EOL_Game
T=$W/tmp/tools_r4_accept/gxb-e2e-self-contained
export GOROOT=$T/opt/go-1.27.3 GOMODCACHE=$W/tmp/cache/tools_r4/go-mod \
  GOCACHE=$W/tmp/cache/tools_r4/go-build GOTOOLCHAIN=local \
  GOPROXY=file://$T/cache/go-mod/cache/download GOSUMDB=off CC=$T/bin/zig-cc \
  GOFLAGS=-mod=mod PATH=$T/bin:$T/opt/go-1.27.3/bin:$PATH

# backend binaries (once)
cd $W/work/backend_load_test
go build -tags "postgres river" -o $W/tmp/load/bin/gxb-api ./cmd/gxb-api
go build -tags "postgres river" -o $W/tmp/load/bin/gxb-worker ./cmd/gxb-worker
go build -tags "postgres river" -o $W/tmp/load/bin/gxb-combat-worker ./cmd/gxb-combat-worker
cd virtualclient
go build -tags postgres -o $W/tmp/load/bin/gxb-load-provision ./cmd/gxb-load-provision

# one measured size, fresh database, private stack on 18970
SIZES=100 RAMP=0 bash tools/load_test/run_sweep.sh
```

`run_sweep.sh` does, per size: `fresh_load_db.sh <db>` (drops `load_nSRAMP` on the
shared `i853_dev` cluster, migrates, deploys content), `stack.sh start <db>`,
`load_test.py setup`, `load_test.py run`, `stack.sh stop`. It holds
`$W/tmp/vc.lock` for each run. Results go to `$W/tmp/load/results/`.

Manual pieces:

```bash
bash tools/load_test/fresh_load_db.sh load_demo
bash tools/load_test/stack.sh start load_demo
python3 -B tools/load_test/load_test.py setup --database load_demo --players 100
python3 -B tools/load_test/load_test.py run --database load_demo --players 100 \
  --ramp-seconds 0 --out-file $W/tmp/load/results/demo.json
python3 -B tools/load_test/load_test.py report $W/tmp/load/results/*.json
bash tools/load_test/stack.sh stop
```

## What is measured

Per client, in order: MID 1 login, MID 272 top floor load (opponent list),
MID 280 top floor START/settle, MID 819 sky tower (pet campaign) START,
MID 820 sky tower result. Every call records HTTP status, error body cause and
latency. The sampler records the API process tree CPU and `pg_stat_activity`
connection and wait-event counts every second.

`--login-mode burst` keeps MID 1 inside the measured burst. The default
`prelogin` logs each player in first at `--login-concurrency 4`, because above
about ten simultaneous logins MID 1 itself collapses (see `LOAD_RESULTS.md`).

## Why a Go helper

`virtualclient/provision` (module `gxb.local/backend/v2/virtualclient`, a
separate module with `replace ../`) owns the production level grant and hero
fragment policy. Reimplementing that in SQL would bypass the I5 owner, so
`virtualclient/cmd/gxb-load-provision` calls it once per account. It cannot live
in the backend module because that module cannot import the virtualclient module.
