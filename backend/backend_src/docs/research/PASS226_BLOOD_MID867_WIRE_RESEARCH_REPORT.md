# Pass226.0 — Blood MID867 Wire-Shape Research

Status: RESEARCH ONLY — NO IMPLEMENTATION
Canonical backend remains gxb-backend-v0.34.0-pass225.0 / OTA 1.631.20.

## Trigger
Clean Pass225 runtime smoke successfully completed ordinary Awakening, Blood open/equip/stage-one claim, stock Blood selection UI, and the full Blood ritual battle twice. After each victory the Awaken Task remained incomplete and the battle could be started again.

## RUNTIME_OBSERVED
The first successful Blood battle emitted:
- MID866: `twice_awake_mission=2200002`, `incubus_id=2200002` -> `error_code=0`.
- MID867: `twice_awake_mission=2200002`, `incubus_id=2200002`, `num=20`, `npc_ids={}`.
- Server response: `{"error_code":1,"msg":"blood_awake_terminal_npc_mismatch"}`.

The second successful Blood battle emitted the same MID866/MID867 shape and received the same rejection.

After each rejection, TASK_LOAD_BY_TYPE mission_type=5 returned mission 2200002 as `is_complete=0,count=0`. Therefore the repeated-battle symptom is a direct consequence of settlement rejection, not a stale client refresh.

Input debug.zip SHA-256: `721426a87de739a12d1a5d216c75e673fb6251cd9e45929f626fffcff77fa3ad`.

## SOURCE_FACT — current effective src_64
`app/scenes/BattleUnlimit.lua` SHA-256 `18379155319fee810eb645bccf0ec299c4fe720ae0380e6c222f596a452dc6be`:
- initializes `deadHeros_ = {}`;
- Blood (`isAwakeSecond_`) terminal request sends `npc_ids = deadHeros_` and `num = currentTimes - 2`;
- on Blood win it adds `twice_awake_mission = unlimitID`;
- on Blood loss it returns locally before MID867;
- the Blood branch never inserts into `deadHeros_` before sending MID867;
- insertion of dead IDs occurs only in the non-Blood Incubus branch.

Therefore the source-exact Blood semantic contract is **an empty Lua table**, not specifically a JSON array.

`framework/json.lua` SHA-256 `c6b04241008d47e56f6b4d5ebcc9b7946730d6bab204dd602cc18a20f7dd671a` directly wraps `cjson.encode()` and applies no empty-array marker/configuration.

## HISTORICAL CORROBORATION — v1.164
Historical `BattleUnlimit.lua` has the same Blood construction: `deadHeros_ = {}`, direct `npc_ids = deadHeros_`, no Blood-branch insertion, and insertion only in ordinary Incubus. Historical/current `framework/json.lua` are byte-identical.

This strongly corroborates that the empty-table wire ambiguity is longstanding client behavior, not a current-client regression.

## IMPLEMENTATION BUG IDENTIFIED (not fixed in this pass)
Pass210 encoded the recovered semantic statement as Python `npc_ids=[]` and the Stage-E server validator now requires:

`isinstance(npc_ids, list) and not npc_ids`

The real stock client sends the same semantic empty collection as JSON `{}`. The current validator therefore rejects the authentic client wire shape.

Pass210's source verifier established only `npc_ids = deadHeros_`; its emitted JSON summary `mid867_terminal_npc_ids: []` was an inference/modeling choice, not a literal wire observation. The first clean runtime capture supersedes that representation claim.

## INTERLINK / BLAST RADIUS
MID866/MID867 are shared with ordinary Incubus.

Ordinary Incubus:
- MID866 contains `incubus_id` only;
- non-Blood BattleUnlimit populates `deadHeros_` from dead team-B NPCs;
- MID867 may carry a nonempty numeric collection;
- its response is consumed for items/exp/record data.

Blood:
- MID866 additionally contains `twice_awake_mission`;
- MID867 winning request additionally contains `twice_awake_mission`;
- Blood `npc_ids` is semantically empty;
- Blood response is expected to project `twice_awake_mission_` completion and can otherwise keep `items=[]`.

Therefore any future normalization must be **Blood-scoped inside AwakeningMissionService**, not a global request-decoder or MID867 normalization. Regular Incubus remains a separate future implementation surface.

## BOUNDED CORRECTION PLAN FOR LATER AUTHORIZATION
Do not implement in Pass226 research.

For the Blood MID867 branch only:
1. Require the `npc_ids` field to be present.
2. Accept an empty JSON object `{}` as the canonical runtime representation of the client's empty Lua table.
3. Also retain acceptance of an empty JSON array `[]` as a test/tool compatibility representation of the same semantic empty collection.
4. Reject every nonempty list/object and every other type.
5. Keep internal/persisted `terminal_npc_ids` normalized to an empty semantic list if desired; it is not echoed on wire.
6. Preserve all existing generation-bound MID866 session checks, `num==20`, mission/incubus equality, trial-source validation, idempotent replay, and MID161 terminal claim ownership.
7. Update Stage-E tests/reality-lock wording so SOURCE_FACT says `npc_ids = empty Lua deadHeros_`; RUNTIME_OBSERVED says stock wire is `{}`. Do not call `[]` the canonical wire format.

Required regression additions:
- `{}` accepted after valid MID866 and completes mission.
- `[]` accepted as compatibility-equivalent empty representation.
- `{1:...}` / nonempty object rejected.
- `[1]` rejected.
- missing/null/scalar `npc_ids` rejected.
- no-session result rejected.
- replay after completion returns same mission projection.
- MID866 restart rejected after completion.
- MID161 terminal claim advances twice_awake_stage to 3 and clears active mission.
- regular Incubus behavior is not silently routed through this Blood normalization.

## RESEARCH VERDICT
The current Blood gameplay/UI/gear path is runtime healthy through the full battle. The unresolved P2 blocker is a narrowly identified server wire-shape mismatch at MID867. No evidence supports changing Blood assets, selection UI, battle construction, `num`, stage lifecycle, roster transport, or Hero mutation.
