# Pass206 — P2 Stage B Implementation Report

## Scope
Stage B only. Stage A remains authoritative foundation. Stage C is not started. Broader P2 release remains closed.

## Implemented
- Provider-based MID83 ItemCompositionService. Cabinet provider remains first and preserves one-owned-book replay behavior. Awakening provider exposes only the 417 source-backed Awakening/Blood recipe targets (ordinary intermediate+gear; Blood intermediate+gear, including the Reo metadata anomaly without normalization).
- MID2738 now opens stage-one missions incomplete (`is_complete=0,count=0`), allocates the Stage-A activation generation, durably sets Blood stage1, and records a success-equivalent activation replay.
- All 18 approved event/outlier routes now receive the mission-specific intermediate through canonical Inventory settlement at activation and the same grant via `extra_drops_=[{table_id,item_num}]`. Retry replays the delivery payload without a second durable credit.
- MID2737 applies the exact source `delete_item` IDs as full-stack canonical debits, emits an inactive/tombstone task row, resets Blood stage0 durably, and retains generation-aware success replay. Source anomalies/no-list rows are preserved verbatim.
- Odin ordinary mission 1258001 implements the approved live-entitlement restoration policy: when source Give Up itself purges the granted intermediate and no exclusive gear is in Inventory, the entitlement becomes RESTORABLE; reopening restores exactly one live intermediate without increasing the lifetime entitlement cardinality.
- MID171 Wish Bottle now has a durable ordinary-stage1 service: debit 1x50005037, credit 1x active mission intermediate, return `{item_id,item_num}`. The source 11-item `awake_item_wish_not` blacklist is enforced. Its mutation-contract HTTP409 remains intentionally active during Stage B.

## Source/wire constraints preserved
- MID83 returns no generic stack awards; `SelfPlayer.makeItem` locally adds target/removes recipe components after success. Mana remains cumulative economy projection from canonical settlement.
- `extra_drops_` rows use `table_id`, not `item_id`, because `SelfPlayer.handleRewards` consumes `table_id/item_num` before the endpoint callback.
- Give Up does not return stack debit projections because the callback already executes `Backpack:delItem` for each source ID.
- Nonce-less MID83/MID171 remain explicitly limited by the stock protocol; no fake universal exactly-once key was introduced.

## Validation
Dedicated Pass206 Stage-B tests cover ordinary/Blood composition, Cabinet preservation, incomplete activation, activation replay, event grant replay, full-stack Give Up, tombstone replay, Odin restore, Blood stage reset, Wish Bottle/blacklist, 18-route policy census, 417-target composition census and live MID171 HTTP409 firewall preservation. Effective `src_64` remains 4,370 files; 10 Stage-B critical files are hash-locked.

## Regression note
Selected P0/P1 suites remain green, including Pass179 and Pass187-190, Pass192 6/6 and Pass193 3/3. Historical Pass73 fails identically on untouched sealed Pass205 and is recorded as baseline-stale rather than rewritten. Pass74's old lifecycle characterization is intentionally superseded by Stage B and is no longer a release gate.

## Next
After artifact/passmap sealing, Stage C is next: special MID54 equipment planning/settlement, atomic stage-one completion, stage-one MID161 successor transition with Blood stage2, and selective promotion preserving special gear/Fumo. P2 public release remains closed.
