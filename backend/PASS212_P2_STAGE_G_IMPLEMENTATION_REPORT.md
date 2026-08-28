# Pass212 — P2 Stage G Closure / Release-Candidate Report

## Scope
Stage G only, forked from sealed Pass211 v0.25.0. This pass executes the frozen P2 closure gate: exhaustive ordinary/Blood route execution, Give-Up anomaly/no-list coverage, retry/replay/relog/state-migration checks, final effective-`src_64` reality validation, and surgical retirement of only the P2 fences whose canonical implementations are already complete. Pet Awakening and full manual/co-op Occult remain fenced. No post-P2 feature work is started.

## Exhaustive closure
- Executed all 164 ordinary stage-one roots through open/replay/Give-Up/replay.
- Executed all 81 Blood stage-one roots through open/replay/Give-Up/replay.
- Route partition remains exact: ordinary = 131 Campaign + 22 Occult + 11 event; Blood = 74 Campaign + 7 event.
- Locked all 19 source rows with no Give-Up delete list (12 ordinary + 7 Blood).
- Locked the four preserved ordinary anomalous/mismatched delete lists source-exactly, including Nikita mission 1125001 order `[50001452, 20001291]`; no normalization is performed.
- Existing 18 approved event entitlement policies remain canonical and nonfarmable, including Odin's RESTORABLE one-live-entitlement behavior.

## Surgical fence retirement
### MID171 Wish Bottle
The old mutation-contract firewall is retired because the Stage-B durable implementation is already canonical and UoW-backed. Contract 171 is now `DURABLE_MUTATION / ALLOW_DURABLE / NONE_DURABLE_OWNER_ACTIVE`.

Stock client sends `{item_num=1}` and locally applies the returned `{item_id,item_num}` after removing one Wish Bottle. The server's durable STACK mutations are journaled, but ResponseProjector does not convert STACK journal rows into generic awards and current projection profiles keep `project_journal_stack_credits=false`. Therefore the response remains callback-local and does not double-apply Backpack mutation.

MID171 remains nonce-less. Two wire-identical calls with two available Wish Bottles are treated as two legitimate requests; universal exactly-once retry semantics are impossible without a wire nonce.

### MID51 / MID57 promotion
The live repository promotion semantics were already active and source-backed. Stage G removes only the dead handler transport adapter for the obsolete `awakening_equipment_promotion_deferred` result. The repository no longer emits that result. No promotion behavior is broadened beyond the sealed Stage-C policy: Awakening/Blood special gear and special Fumo preservation remain authoritative.

### Preserved fences
- Pet Awakening MIDs 165/166/823 remain fail-closed; Pet is a future separate domain.
- Full manual/co-op Occult remains unrouted. Only the sealed Stage-F MID2362 information and MID2385 Awakening sweep dependency remains active.

## Migration / replay / relog
- Fresh Awakening state normalizes into v2 authority.
- Existing v1 state migrates lazily to v2 while preserving active mission state and unknown root extensions, assigning generation 1 / next generation 2 and replay buckets.
- Canonical bootstrap/relog continues to hydrate from AwakeningMissionService rather than generic mission shadow state.
- Generation-bound and receipt/session replay behavior from Stages D/E remains intact.

## Final source reality
Effective `src_64` remains exactly 4,370 files. Final Stage-G source verification locks the live MID171 callback, Give-Up full-stack client behavior, MID51/MID57 source callers, Pet Awake surfaces, and the minimal Occult boundary.

Prior P2 source corrections remain authoritative:
- executable Blood Campaign routes use dropbox 931001 / rate 2650; source row 931002 / 4990 is unreferenced;
- Blood Campaign topology is 74 missions × 271 shared eligible nodes = 20,054 mappings;
- KongMing has five source-valid skill/book mappings while the current stock slot-5 picker exposes three choices;
- raw Occult `0.6` and `awaken_nums=30` are not recovered server-yield math; deterministic one Scroll -> one active fragment remains COMPATIBILITY_POLICY.

## Evidence discipline
- SOURCE_FACT: route partitions, Give-Up lists/order, stock MID171 callback/wire, current MID51/MID57 callers, 4,370-file source census, Pet/full-Occult client surfaces.
- COMPATIBILITY_POLICY: 18 event entitlements, Odin restorative semantics, deterministic Occult fragment yield.
- IMPLEMENTATION: exhaustive Stage-G verification harness, MID171 durable contract activation, dead MID51/MID57 transport-adapter removal.
- PROTOCOL_LIMIT: MID171 (like MID83/MID2385) has no nonce and cannot provide universal exactly-once semantics for wire-identical repeats/retries.

## Validation posture
Dedicated Pass212 Stage-G characterization passes 7/7. Stages D/E/F remain fully green (11/11, 7/7, 7/7), Stage C is green, the Stage-B behavioral subset remains green, and architecture/Challenge/Campaign EXP+Mana regressions remain green. The historical Pass206 assertion that MID171 must remain blocked is intentionally superseded by Stage G and is not modified.

## Release posture
Pass212 is the **P2 server-side release candidate**, not final runtime acceptance. The frozen Pass204 gate requires stock-client smoke/reconciliation before P2 runtime release can be declared accepted. The known Blood MID54 immediate client Backpack/equipment-cache risk remains an explicit smoke target.
