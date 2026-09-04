# Pass246 — Emblem I4 MID1400 Forge Implementation

## Status

**PASS — MID1400 Forge is implemented and static/regression accepted. MID1401/MID1405/MID1406 remain fail-closed.**

Backend advances from Pass244 v0.37.3 to **Pass246 v0.37.4**. Pass245 was migration-only. OTA remains **1.631.22** because I4 changes server behavior only. This is not stock-client runtime acceptance; that remains I7.

## Current-source cross-check

Effective `src_64` from `all-assest-rechecked-1.zip` remains authority. A fresh Emblem source-catalog rebuild is byte-identical to the packaged catalog (`083f3d...d6e4`). Current `InscriptionWindow.lua` sends MID1400 as `{inscript_id=currentSelectInscription, make_num=1}`, checks the row's scalar `compound_material` and optional `compound_item` before sending, and consumes the returned raw `inscript_items` IDs by constructing reward objects locally. `Inscription:getMaterialNumByID` maps source IDs 19/20/21 to degree/graduate/patent certificates. Stock MID1400 has no nonce.

The current-source `inscription_rate.lua` evidence still does not recover original server outer Scholarship math. The active `emblem-v1` Lv7 gate therefore remains **STRONG_INFERENCE + COMPATIBILITY_POLICY**, replaceable without changing source facts.

## I4 implementation

- Only `INSCRIPTION_MAKE`/MID1400 is opened in the dispatcher. Rebuild/Save/Abandon stay on the existing fail-closed handler.
- `EmblemService.make()` validates stock shape, ordinary source row, type and level.
- Source-defined cost resolution maps `compound_material` 19/20/21 onto existing scalar certificate resources. Lv7 additionally requires Heart of Medal `50001346 x1`; non-Lv7 rows may not smuggle an item cost.
- **All certificate and Heart affordability is validated through `MutationSettlementService.validate()` before `EmblemOutcomePlanner` is called.** Failed preflight consumes no entropy and mutates no pity state.
- The existing Pass244 planner and independent Forge miss counter produce the concrete result. Hard pity remains deterministic and consumes no gate RNG.
- Final certificate debit, optional Heart debit and one concrete medal credit settle atomically within the same `PlayerUnitOfWork`. If final settlement fails after entropy/pity planning, UoW rollback restores inventory, counter/state version and journal.
- Successful MID1400 returns only stock `inscript_items=[concrete_item_id]`. The generated medal is not mirrored into `extra_drops_` or another generic award projection.
- No receipt/nonce was added. A repeated accepted wire-identical MID1400 request is another legitimate paid Forge, matching the stock protocol boundary.

## Validation

Dedicated I4 selftest passes **8/8**, covering current-source topology, entropy-inert invalid/insufficient cost paths, ordinary Forge settlement/projection, Lv7 miss, hard Scholarship/reset with no gate draw, rollback after post-entropy settlement failure, nonce-less paid repeat, and I5 route fences.

Controlling I3/I2 regressions pass after excluding only their historical assertions that MID1400 itself must still be fenced; I4 intentionally supersedes those assertions. New I4 coverage explicitly preserves MID1401/MID1405/MID1406 fences. I1, architecture hygiene, RandomOutcomeService, P2 Stage-G, Blood MID867, cleanup, popup-revert and Pass232 edge regressions remain green.

## Epistemic boundary

- **SOURCE_FACT:** MID1400 request/response shape; 19/20/21 scalar mapping; source Forge rows/costs/weights; raw `inscript_items`; no nonce.
- **COMPATIBILITY_POLICY:** `emblem-v1` Lv7 outer Scholarship gate/pity schedule.
- **IMPLEMENTATION:** preflight-before-entropy sequencing, UoW settlement, raw response projection and route opening.
- **RUNTIME_OBSERVED:** none added by I4. Public Forge is static/regression accepted only until I7 stock-client smoke.

## Next

**I5 Reforge** — MID1401 proposal generation plus MID1405 Save and MID1406 Abandon, reusing Pass244 latest-proposal-wins/frozen candidate-policy machinery and continuously checking current `src_64`. I6 hardening and I7 runtime acceptance follow.
