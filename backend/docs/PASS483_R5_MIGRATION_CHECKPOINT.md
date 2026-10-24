# Pass483 R5 migration checkpoint

Status: **INCOMPLETE MIGRATION CHECKPOINT — NOT R5 PHASE ACCEPTED**.

Purpose: preserve the exact latest R5 implementation and reality-review repairs before chat migration. This checkpoint supersedes the older Pass482 packaged ZIP for continuation, while Pass476 remains the last fully phase-accepted backend.

## Preserved implementation

Includes all Pass482 merged R5 work: immutable R5 content, nullable temporal anchors, progression/D01 composite PlayerExp, RF-015 bootstrap/MID1 hydration, C07 semantic receipt/wire projection, RF-019 receipt-protected stack consumption, function eligibility, narrow I4 directory-level projection, and provisional VIP/monthly privilege seam.

## Newer reality-review repair

The separate same-agent reality review found that the frozen Pass480 R5-C02 contract required an explicit legacy temporal -> immutable policy migration path. Activation alone must never reinterpret a legacy persisted temporal row. Pass483 adds an explicit receipt-protected `RebindLegacyTemporal` command and owner CAS (`RebindTemporalTx`). It materializes the old exact legacy policy to operation time first, then binds the caller-supplied exact immutable content revision without consulting the active pointer. Historical terminal receipts remain terminal and are not retroactively upgraded.

The reality review also corrected historical outer-v1 PlayerExp response projection: replay projects current canonical progression but does not fabricate R5 Energy/function side effects.

## Proof boundary

- Canonical Go/module/toolchain pins remain pristine.
- Untouched exact Go 1.27.1 execution is environment-blocked in normal chat because the toolchain cannot be downloaded.
- Fresh compatibility-copy full R5 gate was green before the reality-review repair.
- Focused compatibility-copy tests for the new reality-review repair are green for `internal/domain/economy`, `internal/application/i5`, and `internal/adapters/postgres/i5store`.
- Full post-repair compatibility regression has **not** been rerun.
- Native PostgreSQL 18.6 / Goose / pgx concurrency-crash-restart / River R5 acceptance has **not** been run.
- Separate same-agent R5 reality review is **IN PROGRESS**, not closed.
- R6 remains blocked until R5 reality review + full local gate + native Work gate + evidence/seal are green.

## Next permitted action

In the new chat, initialize from Pass483 HOT/CURRENT and this backend. Verify hashes, reread Pass480 R5 implementation contract and Pass483 handoff, then continue the separate R5 reality review. First validate the explicit temporal-rebind repair against current src_64/frozen V1 and add/rerun its required acceptance cases. Then rerun a fresh full compatibility-copy local gate. If green, prepare the exact candidate for Work/native PostgreSQL 18.6/River R5 gate. Do not start R6.
