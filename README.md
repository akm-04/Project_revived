# GXB v2

The GXB v2 rebuild: Go backend, stock-APK patcher for it, and the tools to test it. Only v2 lives here; the v1 Flask backend,
its APK patch scripts and the decompiled client sources are on `main`.

| Path | What |
|---|---|
| `backend/` | v2 Go backend with its full history (merged from the workspace repo, branch i8-go1273). `git log <merge>^2 -- cmd/gxb-api/main_postgres.go` (paths without `backend/`) shows a file's history. Update: `git fetch <v2 repo> i8-go1273 && git merge -X subtree=backend/ FETCH_HEAD`. |
| `backend/virtualclient/` | the virtual stock client (own Go module) that tests the backend without a phone |
| `app_repack/patch_game_v2.sh` | builds the stock APK for a v2 backend: `app_repack/patch_game_v2.sh <engine origin> <sdk origin> [build dir]`. Needs the stock APK 1.631.0 placed in `app_repack/app/` (not in the repo; see `app/placeholder.txt`), Java 17+ and python3. `origin_lua/` holds the eight origin-bearing Lua files in plaintext, `mods/` optional overlays (MODS=1). |
| `tools/` | toolchain, virtual client kit, Android emulator bundle (with an already patched emulator APK) and client baseline, split into 90 MB parts; `tools/assemble.sh` rejoins, checks sha256 and unzips |
| `workspace/` | snapshot of the agent workspace's `ops/` scripts and `RECOVERY.md` (the live copies are in the workspace) |

Logging needs no client patch: MID1 issues a per-session log URL, the stock ErrorLogPoster uploads to it (client_log_uploads,
attributed to account and player), and the backend journals every HTTP request (request_journal).
