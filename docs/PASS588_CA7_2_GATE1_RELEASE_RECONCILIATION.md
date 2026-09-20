# Pass588 — CA7-2 Gate 1 release-closure reconciliation candidate

Status: **RETEST PENDING / NOT ACCEPTED**.

Pass587 Gate 1 tested the exact v0.81.0 candidate on Go 1.27.1 / sqlc 1.31.1 / PostgreSQL 18.6. The CA7-2 runtime/native slice was GREEN: migration 00030 fresh install + 00029->00030 upgrade, appearance content 262/264/12/4, owner-CAS rollback/concurrency, temporal qualification, reload, restart, dump/restore, race/vet/build, and the CA7-2 MID scope fence all passed. The exact candidate remained clean and Luna made no backend modifications.

Release closure was RED only because the release/retained-validation layer had not been advanced with CA7-2: stale resolved SBOM version, cumulative migration lock high-water 00029, and several retained validators each carrying their own copied list of permitted later content compiler generations. The Luna `verify_exact_candidate.sh` wrapper also expected legacy field names while the canonical identity tool emits `product_tree_digest_sha256`; that wrapper mismatch is a handoff-harness defect, not a product defect.

## Foundation / contract impact review

This repair does **not** change Go gameplay/runtime code, migration 00030 bytes, SQL ownership, transaction/lock order, Character ownership, stock protocol routing, time semantics, receipt/recovery behavior, or generated appearance content. The following controlling foundations were rechecked after the repair:

- I0 dependency/layering: dependency policy + archguard remain controlling; no product import graph was changed.
- I1-I5 validators: GREEN in normal-chat checks; kernel transaction/receipt, protocol, identity/bootstrap, realtime/public, and Economy contracts unchanged.
- Foundation trace: GREEN, including accepted R0-R7 and I6 lifecycle records.
- I2-I6 exact source-oracle suite: GREEN against the verified current/historical oracle bundle.
- CA3-3 and CA4-1 retained source-oracle checks: GREEN against exact current src_64 while still proving their historical content/cardinality semantics.
- Pass587 native PostgreSQL runtime evidence remains controlling for CA7-2 runtime behavior; Pass588 requires release-wide exact retest before acceptance.

## Root cause

The content compiler is cumulative: each later Character phase extends the same deterministic immutable builtin content generation. Historical retained validators correctly re-check their own capability/count/source/migration invariants against the current manifest, but several validators separately copied a finite set of "known later" compiler/parser identities. CA7-2 legitimately advanced the compiler to `ca7-2-appearance-foundation` / `lua-generated-v14-appearance`, while those copied lists stopped at CA6. This produced false release-closure failures even though the retained semantic assertions passed once the successor identity was recognized.

The migration and SBOM failures were analogous publication omissions: migration 00030 and BUILD/SNAPSHOT v0.81.0 had been implemented, but `CUMULATIVE_MIGRATION_LOCK.json` and the generated resolved SBOM were not refreshed.

## Repair

1. Add `docs/architecture/CUMULATIVE_CONTENT_GENERATION_LOCK.json`, an append-only reviewed generation ledger.
2. Add `tools/content_generation_policy.py` and `tools/check_content_generation_policy.py`.
   - Cumulative validators may accept only an explicitly registered successor at/after their historical baseline.
   - Parser identity must match the registered compiler generation.
   - Unregistered future compilers and wrong parser identities fail closed.
   - Historical validators retain all capability/count/source/migration/ownership assertions; the ledger does not waive them.
3. Reconcile the current cumulative validators used by the release checker (R5, CA3-3, CA4-1 and their retained source-oracle checks) with that shared policy instead of copied successor lists.
4. Add the shared policy guard to `tools/check.sh`.
5. Seal immutable migration `00030_ca7_2_appearance_foundation.sql` into `CUMULATIVE_MIGRATION_LOCK.json` and advance the high-water mark to 00030.
6. Regenerate `SBOM.spdx.json` from the current BUILD_INFO and dependency lock.
7. Refresh release metadata to distinct `v0.81.1-candidate` / Pass588 repair status. CA7-2 remains unaccepted and CA7-3 remains blocked pending exact retest/adjudication.
8. Fix the **handoff** exact-candidate verifier for retest to accept the canonical `product_tree_digest_sha256` field. This is not a backend runtime change.

## Normal-chat evidence

Canonical/source checks after repair:
- dependency policy: PASS
- cumulative content generation policy: PASS, including negative unknown-compiler and wrong-parser checks
- foundation trace: PASS
- I1-I5 validators: PASS
- full I2-I6 source-oracle suite: PASS
- CA3-3 retained source oracle: PASS
- CA4-1 retained source oracle: PASS
- R5 cumulative validator: PASS
- CA3-3 cumulative validator: PASS
- CA4-1 retained validator: PASS
- current cumulative candidate validator: PASS
- resolved SBOM check: PASS
- schema/query ownership and generated query-text checks: PASS in the compatibility release run

Disposable compatibility-copy execution (Go 1.23.2 with clone-only go/toolchain accommodation):
- `go test ./...`: PASS
- `go vet ./...`: PASS
- archguard: PASS
- retained R0-R5 / CA3-3 / CA4-1 / current-candidate checks: PASS
- focused race: archguard and builtin content completed GREEN; the larger combined race command exceeded the normal-chat execution window. Pass587 exact Gate 1 already proved full `go test -race -tags postgres ./...` GREEN and no Go runtime bytes changed in Pass588.

All compatibility-copy execution remains `COMPATIBILITY_COPY_ONLY`; it is not exact Go/PostgreSQL proof.

## Retest requirement

Luna must test the exact Pass588 archive first. At minimum the retest must prove:
- exact archive/tree/Git/snapshot identity;
- `tools/check.sh` release-wide GREEN with full oracle corpus;
- resolved SBOM current version;
- cumulative migration lock includes exact 00030 and high-water 00030;
- cumulative generation policy recognizes v14 and rejects unregistered/wrong-parser mutations;
- R5, CA3-3, CA4-1 retained checks and source-oracle checks remain GREEN;
- exact Go 1.27.1 / sqlc 1.31.1 checks remain GREEN;
- focused real PostgreSQL smoke/delta confirming migration high-water, content readiness/counts, owner-CAS rollback and reload are unchanged from Pass587 Gate 1.

CA7-2 is accepted only after returned Pass588 evidence is independently adjudicated. CA7-3 remains blocked until then.
