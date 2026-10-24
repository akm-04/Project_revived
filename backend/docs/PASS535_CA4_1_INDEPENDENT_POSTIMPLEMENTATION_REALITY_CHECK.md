# Pass535 CA4-1 Independent Postimplementation Reality Check

## Verdict

**GREEN_LOCAL_STAGE_ACCEPTANCE; NATIVE AGGREGATE PROOF DEFERRED.** The produced CA4-1 implementation matches the sealed Pass534 Shared Foundation contract and exact authoritative source evidence. This verdict is sufficient for local CA4-1 stage acceptance only under the user-authorized Pass535 lifecycle amendment. It does **not** promote compatibility-copy execution to exact-toolchain, PostgreSQL, River, or stock-client proof.

## Independence / checker correction

The independent postimplementation checker was written against the exact v0.67.1 accepted parent, Pass534 contract/matrix, exact current src_64 archive and final W4 evidence rather than trusting the implementation validator. Its first runs were deliberately allowed to fail. The failures were checker defects: `diff -qr` path parsing retained textual suffixes, guard/test literals were mistakenly counted as product universal-equipment usage, family slot types were expected in the application package although the implementation correctly places them in the Character domain, and a newly introduced application directory needed directory-level diff handling. Those checker defects were corrected against repository reality before any verdict.

The corrected independent run is **42/42 GREEN**.

## Candidate and source integrity

- Parent accepted backend SHA-256: `e0a989eee4940cbfaf22218c669c1463b78b97953b1c25756892ce4c90ebf3f0`.
- Pass534 authority SHA-256: `70f2e539269f0421102e0a95b7d661dc48bf695df825d2f51e5bc3529b275ac3`.
- Exact current source/archive SHA-256: `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.
- Canonical Go/toolchain pins remain `go 1.26.0`, `toolchain go1.27.1`, `.go-version 1.27.1`.
- The implementation delta is restricted to the sealed CA4-1 content, I5 combined-exchange, Character shared-contract, architecture-guard, query/migration and cumulative-validator surfaces. No later CA4 handler family is implemented.

## W1 immutable-content reality

Exact-source regeneration derives the same source-qualified graph sealed in research: 604 type-1/type-8 roots, 1,176 reachable items, 797 recipe-bearing nodes, 1,934 ordered recipe edges and 29 recipes with repeated component identities. Every closure item remains an I5-qualified stack resource. The implementation preserves source **1-based** recipe ordinals and duplicate edges.

Migration `00019_ca4_equipment_primitives.sql` is content-registry-only. It adds immutable equipment primitive and recipe-edge relations and does not create mutable Hero/Pet/Super equipment ownership, a universal `equipment_items` table, or a second active content pointer.

## W2 I5 combined material-exchange reality

The produced I5 seam is a narrow caller-owned-transaction Prepare/Apply port. It reuses MaterialCost and Grant preflight/apply behavior; rejects cross-side stack identity collisions; computes Grant overflow-to-Mail before mutation; canonicalizes the union of Mail/Economy/Stack synchronization identities; acquires that union in D01 order; rechecks the nested Grant receipt after waiting; computes debit next state while planned locks are held; and exposes an opaque prepared plan.

The final strengthened test explicitly checks a mixed lock case and confirms global ordering `Mail namespace (610) -> Economy owner (700) -> Stack identities (722)`. The first version of that **test** expected Economy before Mail; direct lock-rank reread proved the implementation was correct and the test was repaired before a fresh final clone.

Apply owns no transaction lifecycle and discovers no new synchronization identity. Existing nested restoration settlement fails closed before debit. Prepared replay cannot double-debit or double-credit. Overflow-Mail behavior is inherited from Grant rather than reimplemented by Character.

## W3 Character/shared-contract reality

Family-qualified `HeroEquipmentSlotRef`, `PetEquipmentSlotRef` and `SuperEquipmentSlotRef` live in the Character domain; no universal equipment-instance identity is synthesized. `PlayerProgressionMaxHeroColorProvider` remains borrowed and no value `5` is hard-coded. `RestorationModifier` is an extension seam only. `SpiritRef` is a borrowed foreign-owner reference with no Spirit/Horcrux lifecycle implementation. Raw equipment state is only a future export observation contract and carries no equip-time content revision.

No MID54/62/58/51/57/783/792/785/790/304 mechanics are activated by CA4-1.

## W4 evidence reread

**Canonical/static:** exact CA4-1 source oracle, generated query text, schema/query ownership, dependency/SBOM/sqlc policy, connected-candidate static preseal, cumulative R5, cumulative CA3-3, CA4-1 validator and current-candidate validator are GREEN on pristine canonical bytes.

**COMPATIBILITY_COPY_ONLY:** a fresh final disposable clone changed only Go/toolchain accommodation (`go 1.26.0 -> 1.23.0`, removed `toolchain go1.27.1`, `.go-version -> 1.23.2`). Strengthened focused tests are GREEN; focused race is GREEN; bounded package-by-package regression is **92/92 GREEN**; bounded package-by-package vet is **92/92 GREEN**. A cumulative integrated invocation completed source/oracle/query/schema, full `go test ./...`, full `go vet ./...` and I1-I5 before the outer command cap during retained historical validators; remaining validators were run separately. R5's deliberate canonical-toolchain-pin guard was evaluated on pristine canonical rather than weakened for the compatibility clone.

## Lifecycle amendment / remaining proof boundary

The user explicitly authorized moving native PostgreSQL/River/exact-toolchain proof from each CA4 internal stage to one mandatory aggregate Work gate after CA4-1 through CA4-5 local closure and **before CA4-E**.

Accordingly, the following are **OPEN / DEFERRED, not PASS**: exact Go 1.27.1 execution; pinned sqlc 1.31.1 execution where applicable; real PostgreSQL 18.6 migration from the accepted pre-CA4 schema through accumulated CA4 migrations; restore/mixed-version/deployment checks; real PostgreSQL lock/replay/concurrency; River only where accumulated CA4 behavior depends on it; aggregate service/runtime E2E. CA4-E cannot accept until that Work gate is GREEN and reconciled in normal chat.

The existing W2 physical unmodified-stock-client obligation is unchanged and remains separately routed by its historical authority.

## Conclusion

No source, ownership, identity, D01, content-authority, replay, migration-scope or phase-boundary contradiction remains in CA4-1. Under the explicit lifecycle amendment, CA4-1 may be sealed as **locally accepted with aggregate-native proof deferred**, and the next permitted work becomes **CA4-2 preimplementation research/reconciliation**. CA4-2 implementation still requires its own research closure/contract/reality gate before coding.
