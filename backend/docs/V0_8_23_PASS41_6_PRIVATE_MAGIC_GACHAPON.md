# v0.8.23 / Pass41.6 — Private Magic/Gachapon

## Scope

Pass41.6 activates only the Magic/Gachapon protocol plane. It does not expand classic MID50 variants and does not activate SX.

## Recovered client/source contract

- `MID71` switches the selected target by Hero table ID.
- The stock target picker only permits a Girl the player has acquired; awakened ownership counts for the base target.
- `MID70` buys with `{partner_id, summon_time}` where `summon_time` is 1 or 10.
- Recovered Crystal costs are 500 and 5000.
- Main byproducts are source pool `700008`.
- Selected-fragment quantity source table is 5/10/25/50 with weights 87/10/2/1.
- Client code iterates `response.result` and separately credits/displays `stick_items`.
- Rule text says Buy 1 gives 5 selected-Girl scrolls and does not crit; Buy 10 may crit.

## Custom Private Server Magic Policy v1

Historical EOL server multiplicity/placement/retry math is unrecoverable, so the user authorized an explicit private policy:

- **Buy 1:** one pool700008 byproduct in `result`, plus one fixed x5 selected-fragment bundle in `stick_items`.
- **Buy 10:** ten independent pool700008 byproducts in `result`, plus one selected-fragment bundle in `stick_items` using the recovered quantity table.
- No extra `reward` item is emitted. `summon.lua` names/configures Magic Juice, but source does not prove item `50005182` should be additionally credited after the purchase; private v1 avoids double/invented rewards.
- A 1500 ms same-target/same-pull-count replay window protects against immediate transport retries because the stock request has no operation token.

## Transaction ownership

Crystal spend, byproduct inventory additions, selected-fragment addition, and paid receipt are committed inside the existing UnitOfWork boundary. A failed plan returns an iterable fail-closed `result=[]` and commits nothing.

## Deferred

- SX/Soul Box remains fail closed.
- Small100 and classic ticket/coupon/discount operations remain fail closed.
- Magic balance tuning should occur through versioned private-policy overlays, not by rewriting recovered source catalogs.
