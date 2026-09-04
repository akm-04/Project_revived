# Pass349 I10 login pre-auth reconciliation candidate

## Symptom
Stock client displays `Tip` / `Invalid or expired gameplay credential` immediately after Login is pressed.

## Root cause
The support bundle shows MID2864 (`GET_PLAYER_GROUP_BY_KEY`, `unique_key=mtspy`) is emitted **before MID1** and contains no gameplay token/region. Raw `src_64` confirms this is the AB-test lookup. Historical Pass251/253 runtime evidence already recorded `MID7 -> MID2864 -> MID1`. Pass348's default-deny auth registry omitted MID2864 from its pre-login public set, and the PostgreSQL request binder duplicated that omission, so it attempted gameplay credential resolution before MID1 could issue such a credential.

## Bounded correction
MID2864 is classified as `PUBLIC_BOOTSTRAP` for this private-server compatibility path. The handler remains context-free (`mtspy -> B`). All other known MIDs retain the existing default selected-player requirement unless separately classified. The Pass340 client context fence also admits MID2864 so a later client OTA does not suppress the source-proven lookup.

## Validation
Targeted auth/client/I3/I4/I10 tests: **46 passed**, one Flask-dependent ingress test deselected only because this build sandbox lacks Flask on Python 3.13. Compileall passes. Stock-client runtime acceptance remains pending.
