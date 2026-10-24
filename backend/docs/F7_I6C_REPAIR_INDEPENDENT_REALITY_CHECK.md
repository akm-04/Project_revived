# F7 — Independent post-repair reality check

Status: **GREEN_INDEPENDENT_POST_REPAIR_REALITY_CHECK**

Candidate under review: exact F4 repair candidate
`c0b84f3a4ed4663f9343d6916cde6a30322115d791b31a9922c8cfdf26a95518`

This review is independent of the native harness assertions. It rereads the repaired product code, F1/F2 contracts, source constraints, migration 00013, replay policy, and the combined F5/F6 evidence.

## Decision

The bounded I6C F01/F02 repair is coherent and may proceed to F8 seal/rebind.

* F01 correctly separates durable **membership incarnation** from mutable `membership_version`; the current JOIN event `event_id` is the durable non-reused server-internal identity.
* F02 correctly treats Guild application MID580 as current-state convergence for a reversible nonce-less operation. Current locked `apply_type` selects the branch; a current application converges before creation-only capacity/cooldown gates.
* Old v1 receipts are retained as history but cannot authorize a new membership/application lifecycle.
* Create now enforces the same member=>zero-outgoing-applications invariant as the other membership-establishment paths.
* `00013_i6c_guild_replay_repair.sql` is cleanup-only and repairs legacy member+application contradictions without introducing a new owner or schema concept.
* UNKNOWN-COMMIT and definitive-abort semantics remain fail-closed and transactionally atomic.
* No stock wire field was added; source still provides no membership/application nonce.
* F06 validation maintenance separates historical snapshot validation from cumulative-candidate validation rather than weakening historical gates.
* Guild replay classification is now explicit. Paid rename's nonce-less delayed-vs-new ambiguity remains bounded and must not be overclaimed.
* No I6D/future-owner feature was pulled into this repair.

## Evidence adjudication

F5 local/compatibility gate:
`5db2f3b07af6b81091706b3d49abf90e0c16109700c6d857c9da0a214ab5a78e`

F6 initial native report:
`fd6f3afeb54f6841c6f6b1142f6cc12808418cb9ef52de70e99690bbd1ec68aa`

F6 targeted native delta:
`fbd6d3a5fdc0e0f39f865608ae343df3d124996dc40050c43bbd86f010c63611`

F6 final micro-delta:
`275abdf2a37207a7da7058977d6bbe1e0aae3dfd90e0cabf5e59318ff953e184`

Combined F6 adjudication: **GREEN_EXACT_NATIVE_I6C_REPAIR_REQUALIFICATION**.

The final micro-delta measures rather than hard-codes SQLSTATE/deadlock metrics, directly proves SetRole role/version rollback, and proves production-Service resolver-miss one-effect semantics for Apply/Leave/Kick/SetRole.

## Remaining bounded items

1. **F03 realtime Guild provider wiring** remains an I6D integration task.
2. **Paid Guild rename A→B→C→B** remains inherently nonce-less and ambiguous; current policy explicitly does not promise perfect exactly-once across distinct indistinguishable intents.
3. Parent Phase I6 remains open after F8. I6D still needs implementation/native/reality acceptance, then I6E performs the whole-I6 independent reality barrier.

No contradiction requires another F repair stage before F8.
