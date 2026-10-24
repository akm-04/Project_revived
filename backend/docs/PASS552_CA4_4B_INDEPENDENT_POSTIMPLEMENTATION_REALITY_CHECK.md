# Pass552 CA4-4B Independent Postimplementation Reality Check

Status: **GREEN — CA4-4B LOCAL ACCEPTANCE / COMPATIBILITY_COPY_ONLY EXECUTABLE PROOF; CA4 NATIVE AGGREGATE GATE REMAINS OPEN**

Authority parent: sealed Pass551 CA4-4B research closure, implementation contract, A01–A32 acceptance matrix, and explicit user authorization for I1–I5. Product parent is accepted Pass550 v0.72.0 SHA-256 `a0c8b3e60f8de8f6ad2b79467a1495ebef3587f538b9a7540c899c1b1f9e2b69`.

No separate human reviewer participated. “Independent” means a postimplementation reread/check against the frozen source, contract, acceptance matrix, produced code, recovery paths and final test evidence.

## A01–A32 reality matrix

| ID | Result | Independent finding |
|---|---|---|
| A01 | **GREEN** | MID785 and MID790 dispatcher tests enforce exact pet_id-only shapes and reject malformed/extra fields. |
| A02 | **GREEN** | CharacterPet is locked through Pet430 before the mutable I5 settlement suffix; explicit prepare-hook tests prove ordering. |
| A03 | **GREEN** | All three slots resolve through immutable current topology/content revision b36ac5…; deterministic source guard and generator check are GREEN. |
| A04 | **GREEN** | CharacterPet durably owns three independent nonnegative raw Fumo values; PostgreSQL read/write plus StockPrivate/MID780 projection tests are GREEN. |
| A05 | **GREEN** | The cohesive CharacterPet state-version CAS now covers color, progression, skills, equipment and all three Fumo values with no side writer. |
| A06 | **GREEN** | MID785 rejects max color and rejects missing ordinary collected prerequisites before mutation. |
| A07 | **GREEN** | Special/Awakening and empty slots are excluded from ordinary promotion prerequisites. |
| A08 | **GREEN** | Promotion clears ordinary equipment/Fumo only while preserving special/Awakening and empty-slot state. |
| A09 | **GREEN** | q1 ordinary raw Fumo greater than zero fails closed; q1 zero remains allowed. |
| A10 | **GREEN** | Restoration eligibility includes ordinary raw Fumo even when the equipment bit is zero. |
| A11 | **GREEN** | Special/empty raw Fumo is excluded from restoration and preserved. |
| A12 | **GREEN** | Neutral I5 restoration policy retains exact q2..q6 source-qualified rational fractions and source-order denominations. |
| A13 | **GREEN** | Adversarial vectors prove aggregate-floor-once semantics and deterministic greedy 200→60→10 decomposition. |
| A14 | **GREEN** | MID785 uses no debit path; restoration grant and Pet transition share one transaction. |
| A15 | **GREEN** | MID790 rejects a fresh request when there is no missing ordinary equipment to advance/collect. |
| A16 | **GREEN** | MID790 computes the complete missing-ordinary set all-or-nothing; rejected reservations do not escape into mutation. |
| A17 | **GREEN** | The accepted CA4-4A recursive recipe/equality planner is reused; no second recipe authority was introduced. |
| A18 | **GREEN** | Accepted partnerExp planning compatibility and real Pet progression/cap application are reused. |
| A19 | **GREEN** | Accepted deterministic potion order 50001087→50001088→50001089 is reused. |
| A20 | **GREEN** | MID790 color<16 promotion applies one color increment, ordinary clear, and restoration from all destroyed ordinary Fumo in the same operation. |
| A21 | **GREEN** | MID790 color16 collect leaves color/Fumo unchanged and creates no restoration award. |
| A22 | **GREEN** | Promotion-resource preparation closes the full potential stack before mutation and reuses existing owner-qualified lock/resource seams. |
| A23 | **GREEN** | Stock wire returns only restore_items when present; no economy_.mana or invented branch/state fields are projected. |
| A24 | **GREEN** | Same-operation outer semantic receipt replay returns the committed result without second debit, grant or CAS. |
| A25 | **GREEN** | Ambiguous COMMIT reconciles through matching outer receipt; receipt absence remains UNKNOWN with no blind replay. |
| A26 | **GREEN** | A preexisting nested restoration receipt without the matching outer transition fails closed. |
| A27 | **GREEN** | Late/body failure tests roll back resource debit, restoration grant and Pet CAS together. |
| A28 | **GREEN** | A fresh operation after success revalidates canonical state; cross-request exactly-once is not claimed. |
| A29 | **GREEN** | Advance does not mutate persisted raw skills merely to reveal color-gated client presentation. |
| A30 | **GREEN** | No Pet-specific activity modifier was source-qualified; Hero-only double-refund behavior is not imported. |
| A31 | **GREEN** | Deterministic current+old source guard and five-oracle lock are GREEN, including MID785/MID790, Fumo clear/collect and restore_items evidence. |
| A32 | **GREEN_DEFERRED_GATE_PRESERVED** | Exact Go1.27.1 plus real PostgreSQL/River accumulated CA4 gate remains OPEN and mandatory before CA4-E; W2 stock proof remains deferred. |

## Final execution/evidence boundary

1. Exact candidate execution was attempted first and is **ENVIRONMENT_BLOCKED** because the sandbox cannot resolve/download pinned Go 1.27.1. Canonical dependency/toolchain pins are unchanged.
2. Fresh compatibility execution is GREEN for focused behavior/race/vet, full `./internal/...` test+vet, `./cmd/...`, architecture, query/schema ownership and dependency policy.
3. Deterministic builtin generation reproduces content revision `b36ac5cac34e64ed980f8c5beb3437e1bfceb34a55400b2af50620d09e87b8eb`; character/content querytext checks are GREEN.
4. Current+old source guard and the five locked oracle archives are GREEN. Frozen V1 remains corroborative only.
5. Final cumulative release validation exposed and repaired two metadata-integrity defects: the migration lock omitted 00025/00026, and the resolved SBOM still advertised v0.70.1. The lock now carries exact 00025/00026 hashes and regenerated SBOM identifies v0.72.0; cumulative validator is GREEN.
6. The exact Go1.27.1 + real PostgreSQL/River accumulated CA4 gate remains **OPEN** and mandatory after CA4-5 and before CA4-E. This local closure does not satisfy it.

## Verdict

**GREEN for CA4-4B local acceptance under COMPATIBILITY_COPY_ONLY executable constraints.** I1–I5 are complete locally. No source contradiction or acceptance-matrix defect remains in the final candidate. Parent CA4 remains open.

The internal frontier advances to **CA4-5 Super Hero / Super Equipment PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION**. MID54/MID62 deferral belongs to CA4-5. W2 physical stock proof and I8_TECH Spirit/Horcrux obligations remain open.
