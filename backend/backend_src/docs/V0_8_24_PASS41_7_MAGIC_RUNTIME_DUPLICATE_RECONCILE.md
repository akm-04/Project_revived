# GXB backend v0.8.24 — Pass41.7 Magic runtime + duplicate reconciliation

This revision reconciles the user runtime test of Pass41.6 and promotes Magic/Gachapon MID70/MID71 to runtime-confirmed status. It also replaces the provisional private duplicate-conversion quantities with newly recovered historical Vending behavior.

## Runtime-confirmed Magic
- MID71 owned-target selection persists through MID56/reopen/relogin.
- MID70 Buy1 costs 500 Crystal, returns 1 pool700008 result row and x5 selected-Girl fragments via `stick_items`.
- MID70 Buy10 costs 5000 Crystal, returns 10 pool700008 rows and one selected-fragment bundle.
- The supplied run captured 24 Magic purchases with correct result cardinality and selected-fragment IDs.

## Global duplicate conversion
Historical gameplay evidence supplied by the user recovers native-star duplicate quantities:
- native 1★ -> 7 corresponding Girl fragments
- native 2★ -> 14 fragments
- native 3★ -> 30 fragments

The rule uses source `partner.ini_star` plus `partner.stone_id`. It is centralized in `data/summon_duplicate_conversion_policy.json` and reused by Hero-producing summon families. Unsupported native-star classes fail closed; no 4★/5★ value is invented.

Classic RNG and Magic RNG balance remain modular and private-policy-owned where historical server math is unrecoverable. Small100, ticket/coupon variants and SX remain deferred.
