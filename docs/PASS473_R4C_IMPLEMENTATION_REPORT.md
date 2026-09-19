# Pass473 R4C implementation closure

Completed the exact Pass472 incomplete working tree, preserving R4A/R4B and all existing repairs. Scope is immutable content installation, activation and API readiness only. R4D operation pinning, revision-qualified I5 consumption, Grant replay semantics and legacy exact lookup are NOT implemented here.

Changes: repaired strict-decoder compile error; made Bundle metadata private and raw bytes copy-returned; required explicit provider configuration; rejected missing/null/noncanonical capability lists; completed startup composition after database Ping and before HTTP traffic, without migrations or automatic switching. Added registry transaction-model/adapter/startup tests and a dedicated R4C static gate. Historical R4B now delegates later content-path validation to that gate, preserving its original schema/receipt checks.

Pinned sqlc 1.31.1 found that the original expected-progression recordset rename was not analyzable. Verification now explicitly extracts/casts the same embedded JSON fields via jsonb_array_elements. Insertion remains jsonb_to_recordset; exact bidirectional EXCEPT and row-count verification remain. The raw source artifact and zero/false values are unchanged. Generated runtime constants were regenerated from canonical SQL.

Transaction ownership remains caller-owned Serializable through the existing runner, advisory registry fence, bounded profile, stable operation time, exact install verification and positive-only ambiguous-COMMIT resolution. Same-ID corruption fails closed without filling rows. Ordinary bootstrap never replaces an existing pointer; host-only explicit activation CASes expected revision/version, and target-already-active is a no-op. There is no gameplay/admin endpoint for activation.

Validation used exact Go 1.27.1 and sqlc 1.31.1 on a disposable unmodified source copy. No go.mod/go.sum/toolchain accommodation was needed. `go list -buildvcs=false` disables unavailable archive VCS metadata only. Focused race tests, vet, architecture, PostgreSQL-tagged package tests/builds, sqlc generation, all 67 package-by-package Go tests, source regeneration and the bounded V1 differential passed. Final metadata/SBOM checks are recorded in the evidence inventory.

Global I5 validator remains RED for known RF-015/R5 temporal bootstrap work; it is not hidden or fixed outside scope. R4C is bounded local acceptance, not whole-foundation green. Actual PostgreSQL/River/client execution was NOT_RUN; targeted real-PG end-R4 proof remains after sealed R4D before R5, and R7 remains mandatory later.
