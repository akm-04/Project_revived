# Pass567 CA5 Native Repair4 — A03 reconciliation and foundation contract amendment

## Authority and status

Repair4 is an **unaccepted retest candidate** based on exact Repair3 `9c364ce2eeef9c19f9e5db606a1bb6dc60f8fd709175cef463f6a180dd0c36f3` / implementation revision `b190366d5a9288e35b0ba5ae524995e2c741f03bbb5783f1e1a5f0b1ed553041` under sealed Pass567 `7766392d376a6b939a75eda2b477c69959f63e0dbb895520f891648423e99a2f`. The latest Repair3 native evidence is `cbb27af77e2e83369132a7278cb64ec72ee2afe88ebea99ec6d17b76871338e9`. CA5 remains open and CA5-E remains blocked.

## What failed

The exact Repair3 candidate passed exact sqlc 1.31.1 in three fresh extractions, exact Go test/vet/race, PostgreSQL/River build-tag closure, migrations 00001–00028, bootstrap, restart/restore and most CA5 cases. The decisive native product defect was A03: twenty simultaneous same-player SavedPreset operations reproduced `SQLSTATE 40001` twice on independent fresh PostgreSQL 18.6 databases. PostgreSQL logged `Canceled on identification as a pivot, during write` at semantic receipt insertion. This is **RUNTIME_OBSERVED** and reopens the CA5-3 transaction-isolation subclause.

Fourteen additional matrix failures were not demonstrated product defects: `F01 F02 F06 P05 C07 C08 C09 C10 C14 C15 C16 C22 G09 G10` lacked the prompt-required dedicated native execution. They remain mandatory proof gaps.

## Foundation reality check

Pass407 establishes the V2 transaction baseline: ordinary gameplay uses **READ COMMITTED + explicit canonical owner/parent locks + constraints/state-version fences**. SERIALIZABLE is selective for predicate/set invariants that cannot be safely or naturally fenced. D01 requires one caller-owned transaction, a complete typed effect/lock plan before mutation, deterministic global lock order, locked revalidation, and retry/replan before mutation if newly discovered identities escape the plan.

CA5-3 already has precisely that closure: actor fence; preflight aggregate; complete old∪desired Hero/Pet refs; rank 410→430→440 locks; root-locked reread/re-resolution; `Covers(plan)`; whole-aggregate CAS; and semantic receipt in the same transaction. It therefore does not require SERIALIZABLE to protect an unfenced predicate invariant.

Pass563 nevertheless specified SERIALIZABLE for CA5-3. The new PostgreSQL evidence contradicts that implementation choice: with many same-player operations, SSI repeatedly cancels otherwise valid operations as pivots while writing receipts. Increasing `MaxAttempts` would only hide the mismatch and broadening the generic tx runner would disturb accepted foundations. Adding a global/advisory player mutex would also conflict with the existing owner-lock model.

## Repair4

Repair4 changes only CA5-3 SavedPreset mutation isolation from `tx.Serializable` to `tx.ReadCommitted`, and adds a regression assertion to the CA5-3 validator/archguard. It intentionally leaves the full lock plan, lock ranks, CAS, receipts, retry budget, UNKNOWN-COMMIT reconciliation, actor fence, MID1793 wire behavior, MID1 reload projection, reverse guards, migrations, owner boundaries and I6 time semantics unchanged.

The historical Pass563 record is not rewritten. `docs/PASS567_CA5_NATIVE_REPAIR4_CONTRACT_AMENDMENT.json` supersedes only its SERIALIZABLE subclause for this path once the Repair4 native retest proves the amendment. `savedPresetPolicyVersion` remains the Pass563 semantic-policy lineage because request/wire/replay semantics did not change.

## Local evidence

Current canonical pins remain Go language 1.26.0 / toolchain 1.27.1. Exact Go/sqlc/PostgreSQL cannot be executed in this chat environment. Retained I1–I5 validators, foundation trace, connected-candidate static preseal, CA5-2/3/4 validators, schema/query ownership, sqlc-generation policy and dependency policy are green. A disposable Go 1.23.2 compatibility copy passes focused tests/race/vet and full `go test ./...`; those results are **COMPATIBILITY_COPY_ONLY**. A negative mutation back to SERIALIZABLE is rejected by the amended CA5-3 validator.

## Required retest

Luna must first run a focused exact Repair4 A03 proof on fresh PostgreSQL databases. A repeated failure blocks immediately. If A03 is green, Luna must execute the full exact/native aggregate matrix on Repair4, with dedicated emphasis on the fourteen Repair3 coverage gaps. CA5-E may begin only after every mandatory native gate is green, with N01/W2 the sole authorized deferral.
