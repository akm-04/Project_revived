# Pass242 — Emblem I1 Deterministic Reconciliation

## Status

**PASS — deterministic Emblem ownership reconciled; public RNG remains fenced.**

Executable base is Pass241 v0.37.0. Pass242 promotes the backend to **v0.37.1** and keeps OTA **1.631.22** because no client/Lua/resource payload changed.

## Current-source cross-check

Current `src_64` remains authority. `InscriptionTable:getItemPos(inscription_id, concrete_item_id)` uses ordinary `item_pos` when nonzero and otherwise scans `inscription_pos.lua` for the concrete Scholarship item. Pass242 therefore uses the Pass241/Pass236 generated catalog's exact `concrete item -> physical_position` mapping for all 254 medals.

Stock `Inscription.lua` confirms callback-local inventory behavior: MID1402 removes the inserted medal locally and adds `replace_item_id` locally; MID1403 adds the removed medal locally; MID1404 removes the dissolved stack locally. The server therefore persists canonical Stack/Resource/Hero state but does not synthesize generic inventory awards for these callbacks.

## I1 implementation

- Live HeroHandlers for MID1402/1403/1404/1407 route directly to the single `EmblemService` semantic owner.
- `EmblemService.insert()` preserves Pass232 empty-slot/replacement semantics and the source 20-Crystal replacement cost. Scholarship pieces now equip correctly through concrete positions 1/2/3.
- `EmblemService.remove()` preserves the source 20-Crystal removal cost and supports ordinary/Scholarship/source-present artifact medals through the same concrete resolver.
- `EmblemService.resolve()` derives the inscription row from the concrete medal and credits scalar resources 19/20/21 (`degree_cer`/`graduate_cer`/`patent_cer`). All 254 current-source concrete medals have a valid dissolve row.
- `EmblemService.exchange_materials()` consumes all held Stars 50001343/344/345 and credits resources 19/20/21 at 5 points per physical Star, preserving the existing `currency_change` wire shape and empty successful no-op.
- The old HeroAdvanced direct Inscription methods are compatibility shims only and delegate into the same `EmblemService`; duplicate operational position/economy code is removed.
- No Hero `inscript_items` migration is introduced; the existing dense concrete-item array remains canonical.

## Guarded later waves

MID1400 Forge, MID1401 Reforge, MID1405 Save and MID1406 Abandon remain the same fail-closed public behavior. Function45 eligibility and Heart composition remain I2. RNG/pending proposal policy remains I3+.

## Validation

- compileall: PASS
- Pass242 I1 dedicated self-test: **7/7 PASS**
- current-source catalog rebuild from packaged source evidence: byte-exact PASS
- Pass129 architecture hygiene: **5/5 PASS**
- Pass70 response projection: PASS (`stack_awards_synthesized=false`)
- Pass212 P2 Stage-G: PASS
- Pass227 Blood MID867 + stage3: PASS
- Pass230 dev cleanup: PASS
- Pass231 no-popup corrective OTA: PASS
- Pass232 event recovery/log rollover: PASS

Historical Pass241 I0 route-neutrality hash assertion is intentionally superseded by I1 because I1 is the authorized routing change. Older Pass73/179/104 monolithic tests contain unrelated stale assertions that fail before or outside the I1 behavior and are retained as historical evidence rather than rewritten.

## Next wave

**I2 — Eligibility + Heart integration:** implement source-correct Function45/Blood-stage/level eligibility coordination, enforce canonical Girl eligibility on Emblem insert, and add the exact MID83 Heart recipe provider (`50001347 x60 -> 50001346`, zero Mana). Keep all RNG MIDs fenced.
