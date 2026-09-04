# GXB backend v0.9.3 — Pass71.0 Temporal Resources

## Status

Pass70.1 is **RUNTIME_ACCEPTED** from the 2026-08-22 user client smoke. Pass71.0 is **STATIC_ACCEPTED_RUNTIME_PENDING** until a fresh client smoke is reviewed.

Pass71 is a backbone migration only. It does not implement Campaign, Vows, Workshop, Pet, or other deferred gameplay features, and it intentionally does not fix the newly observed MID52 Hero Evolve Mana omission because that belongs to the next Hero/Girls Progression phase.

## Source-derived temporal contract

Effective-source precedence remains `downloaded-assets/output/src_64/` over `app-assets/output/assets/src_64/` path-by-path. The effective tree contains 4,370 files (62 downloaded winners + 4,308 app winners) and is hash-identical to the frozen Pass57 whole-tree fingerprint.

`SelfPlayer.lua` establishes one common recovery shape without making the resources generic currencies:

- recovery is based on authoritative server epoch time;
- only whole elapsed intervals materialize;
- partial interval progress remains in the anchor;
- natural cap stops recovery and uses anchor `0` as a paused/full sentinel;
- when a resource drops below its natural cap, a zero anchor is rearmed from current server time;
- natural cap is not a hard inventory ceiling, so explicit grants/purchases may leave a balance above cap while recovery remains paused.

Policies recovered and rechecked for this pass:

| Resource | Interval | Natural cap | Pass71 owner state |
| --- | ---: | --- | --- |
| Energy | 300 s | `player` table level-derived energy cap | enabled |
| Spirit Energy | 360 s | 180 | enabled |
| Skill Points | 300 s | VIP cap + monthly privilege bonus | enabled |
| Invitations | 1800 s | source-drifted: client calls missing `player:invitation(level)` | modeled, fail-closed/disabled |

The effective `misc.lua` also describes `spirit_energy_buy_limit=10` as a path whose front end is currently suppressed. Pass71 therefore does not invent or activate Spirit Energy purchasing.

## Implementation

### `TemporalPolicyService`

A specialized request-scoped owner now controls Energy, Spirit Energy, Skill Points, and the fail-closed Invitation policy. It owns amount/anchor materialization and exposes MATERIALIZE/CREDIT/DEBIT transitions. The service deliberately does not add these fields to `EconomyLedger`, which remains exactly the 30 true scalar resources established in Pass69.

### Typed `TEMPORAL` MutationPlan operations

`TemporalTransition` is now an active typed MutationPlan operation. `MutationSettlementService` validates and settles RESOURCE, STACK, and TEMPORAL operations inside the same one-player `PlayerUnitOfWork`. TEMPORAL journal rows contain before/after temporal state and only receive an economy projection tag when the frozen ResourceRegistry permits it.

### Pass70 projection reuse

`ResponseProjector` consumes committed TEMPORAL journal rows alongside RESOURCE rows and emits the cumulative canonical `economy_` value. It does not emit deltas and does not fabricate a complete 47-field economy envelope. Invitation projection remains suppressed by its source-drifted ResourceRegistry policy.

### Migrated live seams

- Login/MID17 materializes Energy, Spirit Energy, and Skill Points before bootstrap detail is returned.
- MID27 Energy item use settles `STACK debit + TEMPORAL Energy credit` atomically. The client already removes the item locally after success, so no synthetic item award is returned.
- MID90 Skill Point item use settles `STACK debit + TEMPORAL Skill Point credit` atomically with the same local-stack reconciliation rule.
- MID99 Skill Point purchase settles scalar Crystal cost and temporal Skill Point grant in one UoW while retaining the purchase counter contract.
- MID39 and MID53 Skill Point spends use the temporal owner inside the existing Hero skill handlers.
- legacy Energy compatibility calls delegate to the temporal owner in the normal request-scoped service graph.
- Player EXP/level remains progression-owned and is not migrated in this pass.

Compatibility-only fallback branches remain in several repositories for standalone/pre-RequestServices construction. They are not the live request-scoped path and are retained under the Strangler Fig doctrine until those callers are individually removed.

## Runtime acceptance inherited from Pass70.1

The accepted debug contains 41 engine requests across 22 MIDs with zero fallbacks, zero Python tracebacks, zero HTTP 5xx, and zero nonzero engine errors. Login Mana was 999,887,894. Two MID59 2-star fragment summons (`stone_num=30`) returned cumulative Mana 999,837,894 and 999,787,894 respectively: exactly 50,000 Mana each, confirming the Pass70.1 fix.

The same smoke contained two successful MID52 Hero Evolve requests with empty response bodies and no economy projection. This is recorded as a real known neighbor defect and explicitly deferred to Hero/Girls Progression rather than being patched out of roadmap order.

## Validation

Pass71's self-test covers deterministic whole-interval catch-up, partial-progress preservation, natural-cap pause semantics, above-cap explicit grants, debit rearming, Invitation fail-closed behavior, mixed STACK+TEMPORAL atomic settlement, rollback journal silence, cumulative projection, and MID17 zero-anchor preservation.

Required predecessor gates are rerun before packaging. The historical standalone Campaign economy self-test remains stale on the same pre-existing summon assertion in untouched Pass70.1 and is not a Pass71 regression.

## Roadmap after runtime acceptance

After a clean Pass71 client smoke, the next backbone/domain phase is Hero/Girls Progression and Gear/state preservation. The recorded MID52 Hero Evolve Mana defect belongs there. Dependent gameplay feature implementation remains deferred until those ownership layers are stable.
