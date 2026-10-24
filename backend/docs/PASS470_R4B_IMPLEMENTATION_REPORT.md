# Pass470 R4B Immutable Content Persistence Implementation Report

## Outcome

R4B is complete as a bounded implementation subphase. It adds migration `00009`, immutable content revision/activation storage, canonical content table ownership, strict durable operation-policy reference encoding, kernel-owned receipt policy evidence, and nullable legacy temporal/objective content-revision references. R4C/D are not implemented in this snapshot; overall R4 remains in IMPLEMENTATION.

## Exact lineage

- Base artifact: `gxb-backend-v2-v0.54.0-pass468-r4a-deterministic-content.zip`
- Base artifact SHA-256: `ec73de55088caaa98b4ec9f393863df62fafb8c165ec3a9c753243c5cf79eaf2`
- Base lineage commit metadata: `76d4b71d205cb5a2b40945be2de06bc3fabd147b`
- R4B implementation revision SHA-256: `10914981c7108580becb76253bfd6e8d1778dd3529929eca79434a64549ee654`
- Built-in content revision remains: `77d0b329b0e4c6199fe8484837e025923ca89bf7dc8ebcdd96efa361bbea98b1`
- Canonical module remains `go 1.26.0` + `toolchain go1.27.1`; `go.mod`/`go.sum` are unchanged.

## Implemented R4B scope

- Forward-only `00009_r4_immutable_content_revisions.sql`; no DOWN.
- Five `content-registry` tables: revision, activation, resource definitions, PlayerTable progression, Objective definitions.
- `gxb_operation_receipts.operation_policy_refs JSONB NOT NULL DEFAULT []` with kernel-only persistence. Existing `policy_version` semantics are unchanged.
- Strict canonical policy JSON `[{"name":"content","version":"..."}]`; zero set is `[]`; malformed/unknown/duplicate/unsorted evidence fails closed.
- Nullable FK `content_revision` on temporal/objective state; no legacy backfill and NULL never means current.
- Revision-scoped resource uniqueness and typed class/cap/status constraints matching the sealed R4A artifact.
- No content loader/store, activation runtime, I5 policy resolver, Grant semantic-key v2, HTTP admission change, or legacy exact-version behavior in R4B.

## Tests and reality check

Canonical static/source/oracle validators pass through R4B. Direct current-src_64 independent checks reproduce the frozen source hashes and item boundaries; direct Pass353 comparison finds zero bounded positive-stack policy mismatches and corroborates owner/defer boundaries only. A fresh Pass468->R4B scope audit finds no R4C/R4D leakage.

Exact canonical Go execution is environment-blocked. In a disposable compatibility copy with only the Go language/toolchain accommodation, focused race PASS, `go vet ./...` PASS, package sweep 64/64 PASS, and R4B validation PASS. This remains `COMPATIBILITY_COPY_ONLY`. Real PostgreSQL execution is intentionally deferred to the agreed end-R4 Work gate after R4D and before R5; R7 remains the mandatory full PostgreSQL/River foundation gate.

The broad I5 validator remains RED exactly on the pre-existing RF-015 missing EconomyBootstrapContributor and temporal bootstrap persistence, both R5-scoped.

## Lifecycle result

R4B completed research -> implementation -> tests -> independent reality check -> evidence classification. After Pass470 HOT/COLD seal, the next permitted action is **R4C pre-implementation research/reconciliation**, not R4C coding.
