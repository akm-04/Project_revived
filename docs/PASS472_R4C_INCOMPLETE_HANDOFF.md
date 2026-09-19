# Pass472 R4C Incomplete Migration Handoff

Status: INCOMPLETE / UNTESTED / NOT ACCEPTED.

This snapshot preserves the canonical R4C working tree at chat migration. It is newer than sealed Pass470 R4B, but it has NOT completed R4C implementation, compatibility-copy tests, independent reality check, evidence classification, or R4C seal. Do not advance to R4D.

Base sealed backend: gxb-backend-v2-v0.54.1-pass470-r4b-immutable-content.zip
Base SHA-256: 30faa2013cf1a0010be52314412447249eea123baa97b38d1279043fc61b0adb
Base lineage commit: 76d4b71d205cb5a2b40945be2de06bc3fabd147b
R4A content revision: 77d0b329b0e4c6199fe8484837e025923ca89bf7dc8ebcdd96efa361bbea98b1
Incomplete implementation delta SHA-256: 3df76a3a89f409c8ee4d73c0e413560e6b6cef60015076b10fe5a03a0abb38e6

Implemented/started in this tree:
- content architecture layer amendment and fixtures
- sql/content sqlc target
- canonical sql/content/content.sql
- deterministic content querytext generator and generated query constants
- content-registry Bundle/ProviderSet/state/repository types
- first registry service semantics for install/bootstrap/explicit activation
- first PostgreSQL contentstore adapter
- ownership/check tooling amendments required by those paths

Still mandatory before R4C can be accepted:
- finish historical validator transition and add validate_r4c.py
- finish service/store/query tests, unknown-COMMIT/retry/readiness tests
- finish gxb-api startup composition
- run disposable compatibility-copy Go tests/race/vet/full package sweep
- cross-check exact current src_64 and Pass353 oracle after final code
- independent Pass470->R4C scope/reality check
- evidence classification
- package completed backend + HOT/COLD seal
- then R4D PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION; no R4D coding beforehand

Testing rule: canonical go.mod/go.sum/toolchain stay pristine. Clone exact candidate to disposable tmp; make minimum environment-only edits for available Go; label COMPATIBILITY_COPY_ONLY; fix real product defects only in canonical; discard/reclone and repeat; never copy adapted tree wholesale back.
