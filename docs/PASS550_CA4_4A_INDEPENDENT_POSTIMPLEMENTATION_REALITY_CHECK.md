# Pass550 CA4-4A Independent Postimplementation Reality Check

Status: **GREEN — CA4-4A LOCAL ACCEPTANCE / COMPATIBILITY_COPY_ONLY EXECUTABLE PROOF; CA4 NATIVE AGGREGATE GATE DEFERRED**

Authority parent: sealed Pass549 CA4-4A research closure, frozen A01–A27 acceptance matrix, and the user’s explicit authorization for I1–I5 implementation. Product parent is accepted v0.71.0 archive SHA-256 `657c71af6adc8d4ef304cb096cd7501025022fcb91a0c89bedfe3f0a309cedb7`, implementation revision `8024da821abc0e67091ac602a682e43fbcd57105869a43f75aaa49fe3813442a`. Source/oracle archive independently used for this check is `all-assest-rechecked-1.zip` SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.

No separate human reviewer participated. “Independent” here means a postimplementation reread/check performed independently of the implementation sequence, against the frozen acceptance matrix and source/authority artifacts.

## A01–A27 reality matrix

| ID | Result | Independent finding |
|---|---|---|
| A01 | **GREEN** | Generated Pet topology rechecked: 2592 positions = 2322 ordinary + 200 special + 70 zero; 93 mapped IDs; base/awakened parity and special slot/color/level guards are compiled/tested. |
| A02 | **GREEN** | Every nonzero Pet mapping resolves through accepted CA4-1 equipment primitives under one immutable content revision; recipe closure and compatibility EXP curve are revision-qualified and not duplicated. |
| A03 | **GREEN** | Migration 00024 adds three default-zero binary equipment columns; domain validation rejects non-binary values. |
| A04 | **GREEN** | CharacterPet SavePetStateTx is the cohesive StateVersion CAS for star/level/exp/skills/equipment; progression compatibility wrapper delegates to it. |
| A05 | **GREEN** | MID780/bootstrap share StockPrivate projection of durable equipment; Fumo remains [0,0,0] and outside CA4-4A. |
| A06 | **GREEN** | Neutral I5 equipment-resource seam is an alias/adapter over the accepted Hero Prepare/Apply implementation; no second store/lock owner is introduced. |
| A07 | **GREEN** | MID783 validates request/Pet/show state/mapping/level/finished item before canonical debit; focused failure-path tests cover the required cases. |
| A08 | **GREEN** | Ordinary MID783 consumes exactly one finished mapped item, changes one Pet slot in the cohesive CAS, receipts the semantic result and projects HTTP200 {}. |
| A09 | **GREEN** | Cross-request already-equipped returns HTTP200 error_code=30001 with no second debit; same-operation receipt replay preserves original result kind. |
| A10 | **GREEN** | Already-awakened special direct equip is enabled via immutable Pet-template state; unawakened special fails closed without creating mission state. |
| A11 | **GREEN** | Special success carries a typed PetUniqueEquipmentCommittedFact; no Objective reducer/backedge is activated. |
| A12 | **GREEN** | MID792 wire accepts only pet_id; dispatcher strict-shape tests reject invented client plan/resource fields. |
| A13 | **GREEN** | MID792 replans canonically slots 1..3, excludes zero/special/collected, and promotes slot-local reservations globally only after accepting a slot. |
| A14 | **GREEN** | Rick red1 shared-shortage oracle: slot2 80001079 succeeds at 177000 Mana and slot3 is skipped after shared reservation pressure. |
| A15 | **GREEN** | Rick red1 finished-80001056 oracle: slot2=162000 Mana, both=441000 exact equality, 440999 admits only slot2. |
| A16 | **GREEN** | Planner uses maximum partnerExp shortfall, deterministic compatibility potion order 50001087->50001088->50001089, and normalizes zero-count debits. |
| A17 | **GREEN** | Compatibility vector proves level95->req98 shortfall 209000, 28x7500=210000, real Pet progression can end at level97 while equip remains accepted. |
| A18 | **GREEN** | MID792 recipe/Mana/potion debit and Pet EXP/equipment mutation share one transaction; stock response is {} and never projects economy_.mana. |
| A19 | **GREEN** | Valid canonical no-work is a zero-mutation semantic receipt and HTTP200 {}; same-operation replay cannot debit again. |
| A20 | **GREEN** | Server never trusts client-computed plan; canonical locked replan is authoritative and stock-wire divergence converges by reload rather than invented fields. |
| A21 | **GREEN** | CA4-4A-specific ambiguous-COMMIT test commits Pet/debit/receipt then returns a transport error; receipt resolution returns committed result with no second debit. Generic receipt absence remains UNKNOWN. |
| A22 | **GREEN** | CA4-4A-specific late-receipt-failure test demonstrates transaction rollback of Pet mutation and resource debit together. |
| A23 | **GREEN** | CA4-4A-specific concurrent MID783 race test serializes same-Pet operations to one debit plus one 30001 convergence; focused package race tests are GREEN. |
| A24 | **GREEN** | Independent scan found no CharacterPet foreign-owner SQL, parallel recipe/receipt framework, CharacterHero owner dependency, or Objective backedge. |
| A25 | **GREEN** | Current+old Pet advance/reset source reread shows future CA4-4B can clear ordinary bits/preserve special bits using the same three-bit state plus topology; no schema replacement is required and Fumo remains deferred. |
| A26 | **GREEN_WITH_ENVIRONMENT_LIMIT** | Canonical static/source/query/schema guards are GREEN; fresh compatibility copy full go test ./..., go vet ./..., focused race/recovery tests are GREEN. Exact executable candidate is ENVIRONMENT_BLOCKED by unavailable pinned Go 1.27.1 and evidence remains COMPATIBILITY_COPY_ONLY. |
| A27 | **GREEN_DEFERRED_GATE_PRESERVED** | Exact Go1.27.1 + real PostgreSQL/River accumulated CA4 gate remains OPEN and mandatory pre-CA4-E; W2 physical stock proof remains deferred as authorized. |

## Additional independent findings

1. Canonical `.go-version`, `go.mod`, and `go.sum` remain byte-identical to the accepted parent pins. No compatibility accommodation leaked into canonical.
2. The current `src_64` oracle was rerun against the exact verified source archive and remains GREEN for MID783/MID792 request shapes, 30001 convergence, direct finished-item behavior, one-key planning, partnerExp/potion behavior, and stock local Mana subtraction.
3. Query generation, schema/query ownership, SQLC generation policy, immutable builtin generation and CA4-4A I1–I4/aggregate structural validators are GREEN on canonical source.
4. Fresh disposable compatibility-copy `go test ./...` and `go vet ./...` are GREEN. Focused race packages, including CharacterPet, I5, relevant PostgreSQL stores, registry/domain/projection and CA4-4A recovery/concurrency tests, are GREEN.
5. Exact canonical executable proof remains ENVIRONMENT_BLOCKED: the sandbox only has Go 1.23.2 and cannot download the pinned Go 1.27.1 toolchain. This is not promoted to exact-toolchain/native proof.
6. The CA4-4A-specific late-failure, ambiguous-COMMIT and same-Pet concurrency tests close the local orchestration proof gap: rollback is atomic, matching committed receipts reconcile without a second debit, and same-Pet operations serialize without double debit/lost slot update.
7. CA4-4B future-consumer reread is structurally compatible with the three-bit equipment representation: ordinary equipment may be cleared while special equipment is preserved according to qualified topology; Fumo remains a separate CA4-4B concern.

## Verdict

**GREEN for CA4-4A local acceptance under COMPATIBILITY_COPY_ONLY executable constraints.** No source contradiction, ownership violation, resource-planning mismatch, receipt/recovery defect, projection/reconnect defect, unauthorized Objective/Awakening ownership, Pet-Fumo leakage, or route-shape mismatch was found in the final candidate.

This closes **CA4-4A Pet Equipment** locally and permits the internal frontier to advance to **CA4-4B Pet Advance/Reset + equipment/Fumo restoration PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION**. It does **not** close parent CA4. Exact Go 1.27.1, real PostgreSQL/River accumulated semantics and the mandatory native CA4 aggregate gate remain OPEN pre-CA4-E; W2 stock proof and I8_TECH Spirit/Horcrux obligations remain open.
