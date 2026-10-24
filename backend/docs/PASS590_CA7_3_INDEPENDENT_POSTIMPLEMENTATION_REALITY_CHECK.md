# Pass590 — CA7-3 Independent Postimplementation Reality Check

## Authority and candidate

This review is bound to sealed Pass589 authority and the exact accepted CA7-2 parent `gxb-backend-v2-v0.81.1-pass588-ca7-2-accepted-pass589.zip` (SHA-256 `ed2898e704d033607e41e3350765b20ba0343057cfe05d980bde774aecd5b685`, Git parent `b545f9568ada16183b1de7d13b2cb380815284ed`). Pass589 placed CA7-3 in preimplementation research and required a candidate-bound service/transaction/receipt/error/reload contract before coding. Research checkpoint R2 closed that gate before implementation. This review rereads the produced code and exact source-oracle evidence rather than treating tests alone as acceptance.

## Ownership and persistence reality

Hero remains the sole durable owner for ordinary skin, timed/permanent skin entitlement and illusion selector state. No Cosmetics aggregate, schema migration or foreign-owner SQL was introduced. `SaveHeroAppearanceMutationTx` is a Character-store primitive: an optional entitlement upsert and selector write share the caller-owned transaction, and the Hero CAS advances `state_version` exactly once. If the CAS loses, the transaction returns an error so the earlier child write cannot commit independently.

The separate typed `TxPermanentSkinMaterializer` is a future-consumer seam, not a second owner. It accepts only Character facts, locks Hero, validates the bound appearance revision/model-family, converges a permanent entitlement, preserves effective pre-selection rather than auto-equipping, and advances Hero `state_version` only on a durable change. Commerce pricing/settlement and Commerce receipts remain outside Character.

## MID60 ordinary/timed semantics reality

MID60 binds one immutable appearance revision and one DB-authoritative `DecisionAt`, fences the actor, performs same-attempt receipt lookup, locks Hero, rechecks the receipt under the lock, qualifies the item/model against the Hero origin family, builds effective appearance at that same instant, and only then chooses the state-dependent branch. Character rank-410 ownership is acquired before any I5 material debit.

The implemented branches preserve the researched state machine: absent+permanent and absent+timed consume one card without auto-equip; active timed+timed converges to selection without debit or extension; expired timed+timed consumes one card and replaces the deadline without auto-equip; timed+permanent consumes once and promotes to permanent; permanent+permanent selects without debit; permanent+timed trial rejects with recovered error 35035 and no debit. Missing/invalid/unqualified items and insufficient material fail closed without inventing another stock numeric error.

The response projects effective `current_skin_id` plus deterministic `skin_ids`; `remove_item:1` appears only on a consumptive branch. No unsupported `server_time` field was invented. Fresh identical stock requests get a new operation identity and therefore re-evaluate current state; only same-operation UNKNOWN-COMMIT/retry resolution replays the semantic receipt.

## MID61 and MID2979 reality

MID61 is an explicit ordinary-skin reset. It preserves the illusion selector, records a terminal semantic receipt on a valid no-op, and advances Hero version only when ordinary state actually changes.

MID2979 preserves the distinct presentation axis. Wire `item_id=0` and `1` are accepted sentinels; a positive item ID must resolve to a qualified skin model with an effective entitlement at `DecisionAt`; negative wire values are rejected because current stock evidence does not establish `-1` as a request shape. Durable/effective `-1` remains the inherited illusion sentinel/fallback. MID2979 never changes ordinary `current_skin_id`, so combat skin-skill selection continues to follow the ordinary axis.

## Time, receipts and concurrency reality

All three operations use the existing timed runner with Serializable transactions and bounded retry. The one DB-bound `DecisionAt` is retained through retry/UNKNOWN-COMMIT and governs actor fencing, entitlement qualification, deadline comparison, new timed deadlines and Hero mutation timestamps. Timed validity remains equality-valid (`DecisionAt <= expires_at`).

D11 receipt identities use the server operation ID, not the raw packet payload. Receipts are checked before the transaction, again before Hero lock work, and after Hero lock acquisition. No-op assignment receipts do not manufacture Hero revisions. Concurrent expired reacquisition is covered by a race/behavior test: one request consumes/reacquires under the Hero lock and the waiter observes the new active state rather than double-debiting or extending the deadline.

## Projection, reload and downstream invariants

CA7-3 reuses CA7-2 `BuildEffectiveHeroAppearanceTx` instead of duplicating qualification/normalization. Stale ordinary selection projects to base and stale explicit illusion to inherit-qualified-ordinary under the accepted compatibility policy. Stock reload continues through the already-accepted CA7-2 projection, and repository-wide regression re-runs that projection coverage. Every real CA7-3 Hero mutation advances `state_version`, preserving CA6 Practice stale-proposal invalidation without a special bypass.

Current source evidence reconfirms that combat skin-skill selection uses `getOldModelID()`/ordinary skin while visual presentation can apply illusion. The current active Pet window does not route Hero MID60/61; the source-present `PetAttributeWindow0` path is orphaned under the current window registry. CA7-5 Pet mutation ownership therefore remains fenced.

## Production scope and later-stage fences

Production registration adds only Hero MIDs 60, 61 and 2979. CA7-4 MIDs 68/69 and later Pet-style MIDs 1893/1894/1895 remain absent. The pre-existing CA4 production-MID architecture guard was repaired from an exact historical list comparison to membership assertions so legitimate later Hero registrations do not falsely fail while required older MIDs remain protected.

## Test and environment reality

The unmodified canonical candidate was attempted first. Canonical requires Go >=1.26 with toolchain Go1.27.1, and this sandbox cannot obtain that toolchain from `proxy.golang.org`; exact executable proof is therefore `ENVIRONMENT_BLOCKED`. Canonical `go.mod`, `go.sum` and `.go-version` were not altered.

A fresh disposable copy changed only `.go-version` and Go language/toolchain declarations to the locally installed Go1.23.2. On that copy, focused CA7-3 tests, focused race, focused vet and bounded package regression are GREEN; the final package regression is 94/94 GREEN. Cumulative retained validators are GREEN when explicitly run with `GXB_COMPAT_SCRATCH=1`. An R4D run without that marker correctly rejected the adapted toolchain pins, demonstrating that the compatibility copy is not being mistaken for canonical proof.

Canonical static checks are GREEN for dependency policy, cumulative content-generation policy, sqlc generation policy, schema/query ownership, foundation trace, CA7-3 source oracle and CA7-3 structural validation. The exact current/old-client source oracle is independently hash-pinned. Real PostgreSQL/River and exact-toolchain accumulated proof remain the documented CA7-7 mandatory gate; physical unmodified-stock-client proof remains W2-deferred.

## Verdict

`GREEN_LOCAL_CA7_3_ACCEPTED_COMPATIBILITY_COPY_ONLY_NATIVE_AGGREGATE_DEFERRED_TO_CA7_7`.

No demonstrated product defect, ownership conflict, source contradiction or changed parent invariant requires reopening CA7-1/CA7-2. CA7-3 may close locally and the research frontier may advance to CA7-4. This verdict does not mark the CA7-7 exact/native aggregate gate or W2 stock-client proof as passed.
