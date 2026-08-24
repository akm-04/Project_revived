# Backend machine memory — Pass140.0

Canonical implementation: `gxb-backend-v0.16.1-pass140.0`.

## Current accepted state

- Pass131 Campaign Player EXP + Mana is runtime accepted.
- Pass137 Phase1 Magic ROS under `summon.magic`: static/regression accepted; runtime pending Phase4.
- Pass138 Phase2 deterministic MID241 foundation: 1,431 operations / 382 source items static/regression accepted.
- Pass139 research: 199 deterministic `gift.equip` rows are server-side hero-equipment expansion; exact expansion cardinality UNKNOWN; fail-closed and deferred into Girls/Equipment Economy Closure.
- Pass140 Phase3 ordinary random MID241: 100 operations / 100 source items / 134 ordered drop occurrences activated under request ROS namespace `gift.open`; static/regression accepted; runtime pending Phase4.
- OTA remains 1.631.8 unchanged.

## Permanent source rule

Before every backend behavioral modification, cross-check effective `app-assets/output/assets/src_64`. Keep SOURCE_FACT, RUNTIME_OBSERVED, INFERENCE, IMPLEMENTATION_COMPATIBILITY_DECISION, UNKNOWN and DISPROVEN/SUPERSEDED distinct. Recovered original behavior is not compatibility implementation.

## Phase3 policy and architecture

- Immutable Gift Opening catalog remains source facts only and byte-identical to fresh effective-source reconstruction.
- `GiftRandomOutcomeAdapter` binds request `RandomOutcomeService` to namespace `gift.open`; it owns no pool/rate/batching/settlement policy.
- Positive `drop_rate` values are relative integer weights; zero candidates cannot win; all-zero/invalid source fails before draw.
- Every source `gift.drops` occurrence is executed in order, including duplicate pool IDs. `num` repeats the whole operation and aggregates first-seen awards. These are explicit compatibility decisions.
- Exact operation, quantity, source shape and all possible reward owners are preflighted before entropy. Settlement remains one canonical PlayerUnitOfWork.
- Generated Hero/HUNQI/unique, raw `gift.equip`, missing-source and unsupported lanes remain fail-closed. No MID241 UUID/receipt.

## Roadmap

Phase1 Magic ROS: COMPLETE static/regression.
Phase2 deterministic MID241: COMPLETE static/regression.
Phase3 ordinary random MID241: COMPLETE static/regression.
NEXT Phase4: client smoke/debug and runtime acceptance for Magic/MID241.
After Phase4: Generated/Unique Instance Settlement -> Girls/Equipment Economy Closure (including deferred gift.equip) -> deferred Store/Battle Pass/Arena/Pet/Guild/March/World Boss/Task-Sign/Monthly Privilege/events.
