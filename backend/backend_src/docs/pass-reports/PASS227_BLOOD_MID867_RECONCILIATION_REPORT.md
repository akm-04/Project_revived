# Pass227 — Blood MID867 Stock-Wire Reconciliation

## Scope
Server-only correction authorized from sealed Pass226 research. No client Lua/resource change; OTA remains `1.631.20`.

## Runtime evidence carried from Pass226
Two clean stock Blood victories sent MID867 with `num=20`, matching `twice_awake_mission/incubus_id`, and `npc_ids={}`. Pass225 rejected both with `blood_awake_terminal_npc_mismatch`, leaving mission `2200002` incomplete and allowing repeated MID866 starts. Current and v1.164 `BattleUnlimit.lua` both originate this field as an untouched empty Lua table.

## Correction
`AwakeningMissionService.unlimited_result()` now accepts exactly two semantic-empty Blood wire shapes when the `npc_ids` field is present: empty JSON object `{}` (stock Lua/cjson runtime) and empty JSON array `[]` (legacy Python characterization/replay compatibility). Missing, null, scalar, nonempty object, and nonempty array remain rejected.

The normalization is scoped inside the Blood Awakening branch only. MID867 is shared with ordinary Incubus, where `npc_ids` may legitimately be nonempty; no dispatcher/global JSON normalization is introduced.

## Lifecycle retained
MID866 still owns the generation-bound trial session. MID867 still requires stage 2, matching mission/incubus IDs, terminal `num=20`, and a matching session before marking the Blood mission complete. MID161 remains the only owner of the final `twice_awake_stage 2 -> 3` transition.

## Regression policy
Pass210 Stage-E characterization is updated to exercise the real stock `{}` wire, strict malformed/nonempty negatives, and `[]` semantic-empty replay compatibility. Pass227 adds a dedicated wire selftest.
