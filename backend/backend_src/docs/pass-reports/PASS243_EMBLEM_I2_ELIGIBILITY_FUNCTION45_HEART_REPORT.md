# Pass243 — Emblem I2 Eligibility + Function45 + Heart Composition

## Status

**PASS — I2 implemented/static-regression accepted; public Emblem RNG remains fenced.**

Executable base is Pass242 v0.37.1. Pass243 promotes the backend to **v0.37.2** and keeps OTA **1.631.22** because no client/Lua/resource payload changed.

## Current-source cross-check

Current `src_64` remains authority. `function.lua` row 45 identifies Emblem and carries level spec `7|100`; current `FunctionOpenTable.lua` treats kind 7 as a level gate. Current `NormalHero.lua` and `SuperHero.lua` independently expose Emblem only for a Hero that is Blood Awakened and level >=100. Current item data confirms Heart of Medal `50001346` is composed from Dot of Heart of Medal `50001347 x60` with zero Mana through ordinary MID83.

Pass243 packages the current `FunctionOpenTable.lua` evidence and keeps the exact source facts in `emblem_source_catalog.json`.

## I2 implementation

- Added `EmblemEligibilityCoordinator` as the guide-sensitive Function45/per-Hero policy seam. Function45 is **not** a security boundary for Emblem mutations.
- Account/player level 100 alone makes Function45 level-eligible/pending but does **not** announce it.
- Terminal Blood Awakening reconciles Function45 only after the just-mutated Hero is canonically stage3 and level>=100. Normal `new_funcs_` projection is used; the rejected Pass228 Blood `common_alert` is not restored.
- Terminal Blood MID161 replay payload stores `new_funcs_=[45]` when the unlock first occurs, so commit-then-response-loss replay does not lose the unlock while also remaining idempotent for Blood stage3.
- Load/maintenance reconciliation repairs historical accounts that already contain a qualifying Blood-stage3 level-100 Hero but are missing Function45. Maintenance repair has no semantic-response channel and therefore does not manufacture a login popup.
- MID1402 Insert now authorizes against canonical Hero state: Blood stage3 + Hero level>=100. Function45 announcement state is not trusted for authorization.
- MID1403 Remove remains recovery-safe: a source-valid already-equipped medal can be removed even if imported/malformed Hero eligibility is no longer satisfied, preventing trapped inventory.
- Added narrow `EmblemCompositionProvider` to the existing provider-based MID83 composition owner for exactly `50001347 x60 -> 50001346`, zero Mana. Multi-compose scales components linearly. Arbitrary item-table composition remains fenced.
- MID83 response remains `{}` after committed Stack debit/credit because the stock client mutates target/components locally; no generic award is synthesized, preventing double Backpack mutation.

## Guarded later waves

MID1400 Forge, MID1401 Reforge, MID1405 Save and MID1406 Abandon remain fail-closed. The `emblem-v1` Scholarship compatibility policy is still inactive. RNG/proposal foundation remains I3.

## Validation

- compileall: PASS
- Pass243 I2 dedicated self-test: **8/8 PASS**
- Pass242 I1 deterministic reconciliation: **7/7 PASS**
- Pass129 architecture hygiene: **5/5 PASS**
- Pass212 P2 Stage-G: PASS
- Pass227 Blood MID867 + terminal stage3: PASS
- Pass230 dev-account cleanup: PASS (with intended `PYTHONPATH=.` test launcher)
- Pass231 no-popup corrective OTA: PASS
- Pass232 event recovery/log rollover: PASS

## Next wave

**I3 — RNG/policy/proposal foundation:** activate no public Forge/Reforge route yet. Implement the versioned `emblem-v1` compatibility policy, fixed-point Scholarship-rate state, source relative weights, ordinary-current-result filtering, durable latest-proposal state, and deterministic entropy/state tests. MID1400/1401/1405/1406 remain fail-closed until their later waves.
