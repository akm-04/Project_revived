# Pass525 — CA3-2 implementation report

## Outcome

CA3-2 is implemented as a local GREEN checkpoint on exact Pass523 bytes under sealed Pass524 authority. This checkpoint is intentionally not CA3 aggregate/native/stock acceptance; exact Go 1.27.1, sqlc 1.31.1, real PostgreSQL and stock-client E2E remain scheduled for the combined CA3-1/2/3 Work gate.

## Implemented boundary

- deterministic `PET_ACQUISITION_CA3` content with 27 base Pet acquisition rows;
- Function 38 `PET_STARTER_CA3` capability;
- migration 00017 acquisition/policy tables and PetRoot `first_free_hatch_used`;
- I5-owned one-time Function-38 starter reconciliation and ensure-one Ross egg;
- committed `extra_drops_` projection before `new_funcs_`;
- I5-owned egg-first/essence-fallback Pet acquisition debit;
- MID781 source-bound Pet creation and same-lineage lost-response recovery;
- MID782 natural/first-free/paid acceleration settlement with authoritative hatch formula;
- MID789 natural-deadline/idempotent show transition;
- production Pet router limited to MIDs 780/781/782/789.

## Deliberate exclusions

No CA3-3 Pet EXP/feed/evolution/skills are activated. MIDs 783-788, 790-792 and MID134 remain closed; MID785/790 cross-owner equipment reset remains CA4-gated. Pet Campaign, formation/reference fencing, Practice and styles retain their approved later owners.

## Test result

Canonical static/source/query/content/SBOM guards are GREEN. A fresh compatibility copy with only Go/toolchain accommodation to local Go 1.23.2 passes `go test ./...`, `go test -race ./...` and `go vet ./...`; these are `COMPATIBILITY_COPY_ONLY`, not exact canonical-toolchain or real PostgreSQL proof.

See `docs/PASS525_CA3_2_LOCAL_GATE_EVIDENCE.json`, `docs/PASS525_CA3_2_INDEPENDENT_POSTIMPLEMENTATION_REALITY_CHECK.md`, and `EVIDENCE/PASS525_CA3_2/`.
