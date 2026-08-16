# v0.6.4 — Skill regeneration parity and MID2 hot-update probe

> **Superseded safety warning (v0.7.0):** the historical probe version `1.631.0-local1` below is unsafe for this client. `UpdateScene.compareVersion()` accepts numeric `N.N.N` only. Use `1.631.1` or a later numeric resource version with the v0.7.0 tools.

Date: 2026-08-17

## 1. Runtime evidence that exposed the Joan skill issue

The user completed Campaign `200002`, successfully claimed Joan through MID2064, and
MID114 subsequently advanced the map. Story partner claim is therefore runtime-confirmed.

Later the client sent repeated:

```text
MID39 SET_ALL_SKILL_LEVEL
partner_id=10002
skill_colors=1
skill_counts=20
```

The backend returned:

```text
skills=1|1|1|1|1|1
skill_point=10
```

The user saw the local skill animation/level temporarily, but reopening Joan returned to
skill level 1. This is explained by the backend rejecting the 20-point batch because its
persisted balance was only 10.

## 2. Why the client legitimately had more than 10 points

Authoritative `src_64/app/model/SelfPlayer.lua`:

- `getSkillPoint()` calls `recoverByTime("skillPoint", "lastSkillPoint", ...)`.
- `recoverByTime()` computes whole recovery ticks from server time and advances the
  stored timer by exactly the recovered tick duration.
- when the pool reaches its maximum, the recovery timer becomes zero.

Authoritative tables:

- `data/tables/misc.lua`: `skill_point_incr_time = 300` seconds.
- `data/tables/vip.lua`: `skill_max`; VIP 15 = 80.
- `data/tables/monthly_privilege.lua`: row 1 `skill_max = 10` extra while active.

The captured bootstrap had `skill_point=10` and a `skill_time` about 9,144 seconds old.
That is 30 complete 300-second recovery ticks with a partial remainder. The client
therefore saw roughly 40 points and could legitimately queue a 20-point skill batch.

## 3. v0.6.4 implementation

New `gxb_backend/state/skill_point_policy.py` mirrors the client timer using generated
source metadata in `data/hero_skill_regen_meta.json`.

Recovery occurs before:

- token/bootstrap hydration;
- MID39 batched skill upgrades;
- MID53 single-skill upgrades through the same repository;
- MID99 skill-point purchase mutation;
- MID90 skill-point consumable mutation.

After a successful skill spend:

- the recovered remainder boundary is preserved;
- the timer is started at server-now only when spending from a full pool whose timer was
  zero, matching HeroMainWindow behavior.

An offline reconstruction of the captured case passes:

```text
10 persisted points
+ 30 timed recovery
= 40 canonical points
- 20 MID39 spend
= 20 remaining
skills[1]: 1 -> 21
```

## 4. Lua asset provenance catalog

`data/lua_asset_catalog.json` was generated from the uploaded recovery archive.

Observed snapshot facts:

- 4,370 APK baseline files in each architecture tree;
- zero byte mismatches between paired APK src_32/src_64 files;
- 62 recovered writable override files in each architecture;
- zero byte mismatches between paired writable src_32/src_64 overrides;
- all 62 writable overrides differ from their APK baseline counterpart.

This supports the project model that `downloaded-assets` is a true historical writable
hot-update layer.

Generator:

```text
tools/build_lua_asset_catalog.py
```

Sparse import helper:

```text
tools/import_lua_override.py
```

## 5. MID2 package test

The source-confirmed update plane is:

```text
MID2 response is_inapp=1 + res[]
→ UpdateScene.update_()
→ FileDownloader downloads resource.001 ... resource.NNN
→ append into <version>.zip
→ MD5 whole ZIP
→ UnzipUtils extracts to xyd.versionUpdatePath
→ resource version stored
→ restart
→ writable src_32/src_64 precede APK Lua
```

v0.6.4 adds a `--probe-only` mode to `tools/build_local_lua_update.py`. It creates only:

```text
src_32/gxb_hotupdate_probe.lua
src_64/gxb_hotupdate_probe.lua
```

These are valid but unreferenced Lua modules, so the first delivery test does not alter
loaded gameplay code.

Offline package validation performed during build:

- one volume created;
- manifest size equals volume size;
- manifest MD5 equals the actual volume MD5;
- ZIP contains exactly the two expected marker paths.

The package is shipped disabled. Operator command to enable/rebuild:

```bash
python3 tools/build_local_lua_update.py --version 1.631.0-local1 --probe-only
```

Runtime server events are recorded in:

```text
runtime_logs/local_update_events.jsonl
```

The MID2 transport remains **source-confirmed, offline-package-validated, but not yet
user-runtime-confirmed** at v0.6.4 handoff.
