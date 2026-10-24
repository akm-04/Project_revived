# F8 — I6C post-acceptance repair acceptance

Status: **F_REPAIR_ACCEPTED_SEALED_CANDIDATE_READY_FOR_PASSMAP_REBIND**

The exact product implementation accepted here is the F4 candidate previously tested at SHA-256
`c0b84f3a4ed4663f9343d6916cde6a30322115d791b31a9922c8cfdf26a95518`.

F8 is a release/evidence metadata snapshot only. Product Go source, tests, migrations, generated SQL,
source-oracle fixtures, go.mod, go.sum and .go-version are preserved byte-for-byte from the F4
candidate. F6 exact-native requalification is GREEN only after the initial report, targeted delta,
and final micro-delta were jointly adjudicated. F7 independent post-repair reality review is GREEN.

Accepted repair:
* F01 membership reincarnation receipt identity uses durable current JOIN event_id incarnation.
* F02 Guild applications converge from current canonical state; current apply_type chooses the branch.
* Create and all membership-establishment paths enforce zero outgoing applications.
* migration 00013 is data-cleanup-only for pre-existing member+application contradictions.
* historical validators remain strict; cumulative candidate validation is separate.
* Guild replay census is explicit; paid rename nonce-less ambiguity remains bounded/non-overclaimed.

I6D research is preserved and may be rebound to this repaired backend after PassMap F8 synchronization.
I6D implementation remains not started. Parent Phase I6 remains open; I6E is still mandatory after I6D.
