# Pass193 — P1-I5 Second Runtime Reconciliation: Cabinet MID1078 Wire Contract

## Decision

The second Pass192 stock-client smoke demonstrates that Cabinet learning is durably persisted, but the MID1078 speed response is incomplete for the stock client's update path. This is a bounded wire-shape defect, not a lost-state or transaction defect.

## Evidence classification

- **RUNTIME_OBSERVED:** Courses reopen without the prior Electives bootstrap crash. Course proficiency reaches and persists at 1680. Bookshelf reaches level 31 and persists after restart. Cabinet building reaches level 2 and persists after restart.
- **RUNTIME_OBSERVED:** Cabinet research speed succeeds server-side, later GET_CABINET_INFO contains the learned node, and retrying the same node receives `Cabinet skill is already max level`. The durable mutation therefore committed before the client desync.
- **RUNTIME_OBSERVED:** only two client Lua errors were recorded in the smoke, `EventCentre.lua:569 attempt to index nil` and `JunkChestWindow.lua:1181 attempt to index nil`; the second is downstream state corruption caused by the first partial update.
- **SOURCE_FACT:** effective `app/model/EventCentre.lua` loops every skill ID for the book and directly dereferences `arg_44_1.book_info[tostring(skill_id)].lev` during MID1078 processing. Sparse omission of an unlearned skill is invalid for this response.
- **IMPLEMENTATION:** MID1078 active-completion and replay responses now project a complete per-book skill map with explicit zeroes while canonical durable `workshop_state.book_info` remains sparse.

## Scope boundary

No building/research economy, timer, prerequisite, refund, persistence, Hero projection, or P2 progression semantics were changed. GET_CABINET_INFO retains the existing sparse durable projection. The patch changes only the MID1078 response projection required by stock-client source.

## Workshop dependency discovery

The runtime stalls are source-correct prerequisites rather than a Pass192 defect:

- Bookshelf uses building type 1 (Cabinet) as its `type_request`; level bands increase the required Cabinet level.
- Cabinet uses building type 3 (Recycle Bin) as its prerequisite.
- Recycle Bin in turn gates on Cabinet, forming the original reciprocal progression ladder.

The remaining Event Centre dependency graph is therefore a separate architecture/research scope. Pass193 does not fabricate implementations for those deferred buildings.

## Runtime gate

P1 remains runtime-open for one focused Cabinet stock-client re-smoke of learn → speed → local visual update → confirm/reopen/restart. If that wire fix is clean, the already-passing P1 surfaces can be closed and roadmap can advance to separately authorized P2 research/planning.
