# v0.8.21 / Pass41.4 — Classic Small/Medium Private-Server Activation

This revision implements the first explicitly custom EOL server policy. It is intentionally narrower than the full Vending surface.

## Activated

- MID50 `(1,2)` Small paid1 — 10,000 Mana
- MID50 `(1,3)` Small paid10 — 90,000 Mana
- MID50 `(2,1)` Medium paid1 — 288 Crystal
- MID50 `(2,2)` Medium paid10 — 2,590 Crystal

## Source/runtime authority

The four request pairs were captured from the stock client. Costs and pull counts are from effective `summon.lua`; result row kinds are from recovered client handling; pool rows are copied from recovered dropbox topology; Hero star and fragment identities come from GameDataCatalog source metadata.

## Explicit private policy

Historical server RNG/counter/duplicate/retry math is unavailable because the official service is EOL. `summon_private_server_policy.json` therefore owns deliberately custom choices. The missing Small ordinary pool200001 is replaced by source-valid non-Hero pool200003. Medium retains recovered base200003/super200004/special pools. Counters advance one result slot. Duplicates are converted server-side to `partner.stone_id`. A short replay receipt protects immediate identical paid retries.

These choices are not assertions about historical official behavior.

## Deferred

Small100, all ticket/coupon/discount variants, Magic MID70/71 result planning, SX/Soul Box and unrelated RNG systems remain fail closed.

## Validation

No Flask, HTTP, emulator, ADB or gameplay execution was performed by the assistant for v0.8.21. Validation is static/syntax/JSON/source-contract/hash/archive only. User runtime testing is the next gate.
