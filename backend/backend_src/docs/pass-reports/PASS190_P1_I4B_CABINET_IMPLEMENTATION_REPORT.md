# Pass190 — P1-I4B Cabinet Implementation Report

## Scope
P1-I4B implements only deterministic Cabinet research on top of the already accepted Pass189 Event Centre/Bookshelf foundation. P2 Awakening and non-P1 Event Centre systems remain out of scope.

## Source-shaped contract
- GET_CABINET_INFO: nested `book_info[book_id][skill_id].lev` + cabinet timer/recent-completion state.
- LEARN_SKILL: request `skill_id`; validates book possession, Cabinet/book star, target-level prerequisites and source resources/time.
- GIVE_UP_LEARN_SKILL: cancels a RUNNING job; response exposes `return_skillpage`.
- SPEED_UP_SKILL: source-exact Event Centre Crystal acceleration; returns `book_id` and that book's nested skill levels.
- CABINET_SKILL_CONFIRM: clears pending completion acknowledgement.

## Architecture
Reuses `PlayerUnitOfWork`, `MutationSettlementService`, `EconomyLedger`, `StackInventory`/inventory repository, typed Hero mutations, `DurableTimedJobPolicy`, `EventCentreAccelerationPolicy`, `EventCentreBuildingService`, and canonical `workshop_state`. No new persistence plane or transaction framework.

## Compatibility/unknowns
- Ordinary cancellation refund is the approved compatibility policy `floor(original_cost * remaining / total)` against an immutable start snapshot. Exact original server formula is unknown.
- Skill Pages are returned in full only when cancellation occurs before READY; no return after completion.
- Server-side natural timer completion is lazily materialized on a subsequent Cabinet/Workshop request. The client visibly derives its timer expiry locally, while exact original server materialization timing is unavailable.

## Static acceptance
Dedicated `selftest_pass190_p1_i4b_cabinet.py`: 7/7 PASS. Inherited P1-I4A/P1-I3/P1-I2 plus current P0/Vows/Horcrux/Gods Trial/architecture regressions pass. The Pass186 historical flat `book_info` and empty-initializer assertions are superseded by the approved Pass189/190 design.
