# Pass484 R5 independent post-implementation reality-review checkpoint

Status: **GREEN_BOUNDED_CODE_TRACE / NORMAL-CHAT SOURCE-ORACLE-GENERATOR GATE GREEN / NATIVE R5 GATE PENDING / NOT R5 PHASE ACCEPTED**.

This is the continuation of the separate same-agent reality review that began in Pass483. It does not replace the frozen Pass480 research contract, does not claim original-server truth from frozen V1, and does not advance R6.

## Candidate lineage

- Parent package: Pass483 v0.55.2, SHA256 `99db6b7fc346f515ad983de418af4986b5bf97639ce9829a95f06cf3986a7752`.
- Last fully phase-accepted backend: Pass476 v0.54.5, R4 accepted.
- Immutable R5 content revision remains `050e93ca758d4c3b85b24cfca2f33c0d808005dcda21a2eca2325839fffae3f0`.
- Pass483 product rebind implementation files are preserved byte-for-byte. Pass484 changes acceptance tests/static guard coverage plus the stale v0.55.1->v0.55.2 SBOM metadata repair discovered during canonical checks.
- Canonical `go.mod`, `go.sum`, `.go-version` remain pinned and unchanged from Pass483.

## R5-C02 temporal rebind review

**SOURCE_FACT** — Pass480 R5-C02 requires persisted legacy temporal policy identity to remain legacy until an explicit one-time migration/rebind receipt; activation alone must not reinterpret the row; mixed-revision composites must fail before affected mutation.

**SOURCE_FACT / code inspection** — `Service.RebindLegacyTemporal` binds a caller-supplied exact target revision, never reads the active pointer, resolves legacy policy by persisted key/version, and writes `gxb.i5.temporal-rebind.v1` through the canonical receipt resolver. `TemporalState.RebindLegacyPolicy` materializes under the old exact policy to `operation.StartedAt` before changing policy/content identity. PostgreSQL `RebindTemporalTx` requires expected `state_version` and `content_revision IS NULL`.

**STRONG_INFERENCE bounded by local execution** — repeated semantic requests replay the receipt; an unresolved COMMIT does not blindly replay a value mutation; a later visible receipt reconciles; an immutable row without the receipt fails closed; stale/mixed PlayerExp content revision rejects before mutation. Native SERIALIZABLE/concurrency behavior remains assigned to the Work gate.

Direct Pass484 acceptance covers:
- old-policy materialization before immutable boundary;
- changed cadence starts at boundary;
- remainder preservation/full pause/over-cap debit/zero/shortage/negative elapsed;
- known cap-increase rearm;
- NULL anchor -> stock numeric `0` projection;
- repeat + service restart replay exactly once;
- unknown-COMMIT no blind retry + later receipt recovery;
- missing legacy policy failure before mutation;
- immutable-state-without-receipt failure;
- PlayerExp mixed-revision rejection before mutation;
- PostgreSQL legacy-only optimistic CAS shape.

## Mandatory lifecycle trace

### Bootstrap / creation

**SOURCE_FACT** — character bootstrap content is bound only for a genuinely new character immediately before root creation. The bound operation is held outside Runner retry callbacks and passed to all contributors. Economy seeds use the exact bound revision. `r5.bootstrap.v1` quantities remain an **IMPLEMENTATION_DECISION**, not recovered original-server fact.

### Mutation / ownership / lock closure

**SOURCE_FACT** — R5 grant preflight constructs the frozen suffix before mutation: mail 610 when needed; economy owner 700; progression 710; scalar 720; temporal 721; stack 722; function-state 730; I4 directory projection 740. PlayerExp reserves progression, Energy temporal, function-state and I4 directory dependencies even if the eventual grant does not level.

**SOURCE_FACT** — PlayerExp mutation composes progression + Energy + function eligibility/qualified announcement + narrow I4 directory projection + terminal receipt in the caller-owned transaction. No foreign-owner directory SQL was found in I5.

### Receipt / recovery

**SOURCE_FACT** — current Grant v2 and historical v1 terminal replay remain dual-identity aware. Historical outer-v1 PlayerExp projection reads current canonical progression but does not synthesize R5 Energy/function side effects. Generic receipt miss after unknown COMMIT remains `ResolutionUnknown`, preventing blind replay.

### Reload / MID1 projection

**SOURCE_FACT** — temporal rows hydrate using their persisted exact legacy policy or immutable revision; projection materializes without silently rebinding persistence; nullable anchor maps to stock numeric `0`. Fresh/existing/reconciled MID1 use canonical economy hydration. `max_lev` is a current active-progression projection while temporal policy identity remains row-bound; no Pass480 contradiction was found, so this was not changed speculatively.

### Migration / restore

**SOURCE_FACT** — migrations 00009 and 00010 retain accepted hashes. Migration 00011 only expands R5 schema/capabilities and makes temporal anchor nullable; it does not update existing temporal policy/content identity and has no Down section. Therefore activation/migration00011 alone does not perform legacy->immutable rebind.

**UNKNOWN / native gate** — fresh PostgreSQL18.6 migration chain, 00011 upgrade behavior, SERIALIZABLE rebind concurrency, process crash/restart, backup/restore and River integration have not been executed for this candidate.

### Extension seams

**SOURCE_FACT** — Skill privilege remains behind `PrivilegeSnapshotProvider` with provisional baseline provider `PROVISIONAL_REPLACE_ON_COMMERCE_OWNER/v1`; nonbaseline state fails closed. Function announcement remains separated from eligibility and production `NoFunctionAnnouncements` is fail-closed. Invitation remains unsupported/fail-closed.

## Current source / frozen V1 review boundary

The Pass483 additional-materials package contains manifest-sealed bounded current-src64 and frozen-V1 extracts used for this review. Current `SelfPlayer.lua` consumes `energy_time`, `spirit_energy_time` and `skill_time` as last-regeneration anchors and uses `0` as paused/full. Frozen V1 independently corroborates last-anchor materialization, natural caps and full-pause `0`; it is differential evidence only.

The five external archives required by `oracles.lock.json`/`INPUTS.json` are present and were matched by SHA256, not filename suffix. `verify_oracles.py`, I2-I5 source-oracle guards, current MID-registry regeneration check and Pass353 differential-wire fixture regeneration check all pass against those exact archives. See `EVIDENCE/PASS484_R5/oracle_source_generator_postrestore.log`.

## Local proof

**RUNTIME_OBSERVED — exact source/oracle/generator checks**: all five external archives match the locked SHA256 identities; oracle identity verification, I2 wire, I3 bootstrap, I4 Wave-S, I5 player-core, current MID registry and Pass353 differential-wire fixture checks pass on the canonical candidate.

**RUNTIME_OBSERVED — COMPATIBILITY_COPY_ONLY**: after the Pass484 test/metadata fixes, a fresh disposable copy with only `go.mod`/`.go-version` relaxed to local Go1.23.2 passed focused acceptance, `go test -count=1 ./...`, focused race for economy/I5/PostgreSQL-store/bootstrap/content-registry, `go vet ./...`, archguard and explicit package-by-package regression.

**RUNTIME_OBSERVED — canonical static**: dependency policy, resolved SBOM, SQLC generation policy, connected-candidate static preseal, kernel/content querytext, ownership guard, foundation trace, I1-I5/R0-R5 validators and gofmt all pass on canonical.

**ENVIRONMENT_BLOCKED**: exact local Go execution remains unavailable: local Go is 1.23.2; pinned Go1.27.1 download fails because DNS/network access to `proxy.golang.org` is blocked.

## Defects found during Pass484 review

1. Incoming Pass483 had no direct tests for its newly required `RebindLegacyTemporal` path. **REPAIRED** with targeted acceptance tests.
2. Incoming `validate_r5.py` did not require the C02 rebind seam, so deletion of the new path could escape the static R5 guard. **REPAIRED**.
3. Incoming Pass483 `BUILD_INFO.json` was v0.55.2 while `SBOM.spdx.json` still identified the application as v0.55.1. **REPAIRED** by deterministic SBOM regeneration; dependency versions did not change.

No additional gameplay product-code defect was found in the mandatory lifecycle trace.

## Gate state / next permitted action

R5 is **not phase accepted**. R6 remains blocked. The complete normal-chat source/oracle/generator local gate is now green against the exact SHA256-locked external archives. The next permitted gate is native PostgreSQL18.6/Goose/pgx/River on the exact packaged candidate, including migration00011, temporal rebind repeat/restart/concurrency/unknown-COMMIT, D01 rollback, semantic replay, and backup/restore. Native evidence must return to normal chat for reconciliation/evidence classification/final R5 HOT+COLD seal. R6 remains blocked.
