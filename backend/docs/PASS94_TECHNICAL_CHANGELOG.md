# Pass94.0 Technical Changelog — Global Economy Player Progression Strangler

## Decision

Pass94 is a bounded implementation pass. It closes only the Player EXP/level ownership seam identified in Pass93 and deliberately stops before RandomOutcomeService, MID97, or additional feature work.

## New canonical owner

`gxb_backend/state/player_progression_service.py` introduces `PlayerProgressionService`, matching the owner name already present in `data/resource_registry.json` for both `exp` and `lev`.

The service owns cumulative Player EXP and level mutation. It preserves effective `src_64` semantics: cumulative `total_exp` thresholds, no demotion, per-crossed-level `award_energy`, source max-Energy cap for the resulting level, and existing FunctionStateRepository level-crossing observation.

Level-up Energy is not absorbed into progression ownership. It is credited through `TemporalPolicyService` in live composition so regeneration anchor/cap semantics remain under the temporal owner.

## Strangler routing

`RewardTransactionService` now routes `player_exp` directly to `PlayerProgressionService` inside the same outer `PlayerUnitOfWork`. Scalar and stack rewards continue through `MutationSettlementService`; Energy continues through TEMPORAL settlement. The transaction remains atomic because all owners participate in the same Player UoW.

`EconomyRepository` retains its historical API for old callers, but `grant_player_exp()` and mixed `player_exp_gain` now delegate to the canonical progression service. The repository no longer contains the EXP threshold/level-up implementation.

## Direct-fallback fence

The old compatibility facade still contains direct scalar/Energy fallbacks for isolated legacy constructors. Pass94 adds an explicit `allow_legacy_direct_mutation` fence and turns it **off** in both live `RequestServices` and `PlayerMaintenanceServices`.

The production request graph therefore requires canonical owners for live mutations:

- Mana/Crystal and the existing scalar family: `EconomyLedger`
- Energy: `TemporalPolicyService`
- EXP/level: `PlayerProgressionService`
- Function eligibility/announcement: `FunctionStateRepository`

## Boundaries

No source probability, Campaign reward amount, Campaign Energy cost, VIP privilege, Daily Reset behavior, Store behavior, MID97, MID117/MID118, or Monthly Privilege lifecycle is modified.

RandomOutcomeService remains the next architectural phase **after Pass94 runtime smoke/reconciliation**.
