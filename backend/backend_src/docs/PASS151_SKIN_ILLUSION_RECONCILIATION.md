# Pass151 — Skin illusion runtime reconciliation / Phase C entry

## Runtime observation

The supplied client smoke reached MID60 successfully for permanent skin activation/skill state, then sent MID2979 `USE_ILLUSION_SKIN_ITEM` three times when **Use** was pressed on the owned cosmetic. Pass150 had no semantic MID2979 route, so the compatibility layer blocked every request. This exactly matches the observed split symptom: skin skill/state could activate while the rendered cosmetic did not switch.

## Source facts

Effective `src_64` was rechecked before the backend behavior change.

- `HeroMainWindow:updateSkinBtn()` sends MID2979 with `{partner_id,item_id}` for an already-owned skin and assigns `response.illusion_skin_id` to `hero.illusionSkinId_` before refreshing the model.
- The same UI sends sentinel `item_id=0` for normal appearance and `item_id=1` for awakened/current-table appearance.
- A not-yet-owned physical permanent skin follows MID60 instead, so MID60 ownership/skill state and MID2979 cosmetic appearance are distinct axes.
- `NormalHero` bootstraps `current_skin_id` and `illusion_skin_id` separately. `getModelID()` uses `illusion_skin_id`: 0 -> first/base model, 1 -> current table model, >1 -> explicit skin model.
- Expired temporary skins can send MID2979 item 0 after SKIN_CANCEL; temporary acquisition/expiry semantics remain outside the current permanent-skin implementation.

## Compatibility implementation

The existing `SkinOwnershipService` remains the sole skin mutation owner. It now handles MID2979 without creating any parallel inventory/economy/UoW authority.

For MID2979:

- owned permanent skin item -> set `hero.illusion_skin_id` to the canonical source skin model;
- item 0/1 -> persist the source-defined normal/current-table selector;
- do not consume physical inventory;
- do not modify `current_skin_id` or permanent ownership;
- unowned/wrong-Girl skin -> fail closed;
- temporary-only skin -> fail closed until the timed lifecycle is recovered;
- mutation persists through the existing PlayerUnitOfWork hero slice.

## Phase C gate

Phase C synthetic Recharge activation is **not** partially enabled in this pass. OTA remains 1.631.8 and the 272 synthetic EOL products remain hidden/unauthorized. This avoids a client/server mismatch. The next Phase C implementation pass should atomically pair cumulative OTA 1.631.9 (262 skin + 10 elemental rows and dynamic advertised-product purchase bridge) with the already-planned backend synthetic availability/settlement activation.
