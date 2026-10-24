# Pass530 CA3-3 Independent Postimplementation Reality Check

## Result

**GREEN_LOCAL_CANDIDATE_ONLY.** This reality check does not grant CA3 aggregate acceptance and does not promote compatibility-copy execution to exact-toolchain, PostgreSQL/River, deployment, or stock-client proof.

## Authority reread

- **SOURCE_FACT:** Pass529 HOT/CURRENT is the migration/WIP authority. Pass528 CA3-3 research closure, implementation contract, acceptance matrix, M4 typed dependency model and M5 compaction remain controlling for gameplay mechanics.
- **SOURCE_FACT:** exact current `src_64` archive SHA256 is `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.
- **SOURCE_FACT:** Pass528 requires CA3-3 source-qualified progression for MID786/MID787/MID134/MID791 plus A525-02/A525-03/A525-04 shared repairs; receipt ordering is `receipt check -> lock Pet -> receipt recheck -> first mutation`.
- **SOURCE_FACT:** Pass465 Work Place time semantics are not a universal rule. Pet lifecycle equality/backward-clock behavior is governed by the CA3 contract/source-qualified Pet path.

## Produced-code reread

- **RUNTIME_OBSERVED:** `characterpet/progression.go` performs pre-lock receipt check, `LockPetByIDTx`, post-lock receipt recheck, then `IsShow`/content/mutation for evolve, EXP and skill paths. MID787/MID134 ration EXP lookup occurs after this fence.
- **RUNTIME_OBSERVED:** I5 Pet EXP uses an opaque prepare/apply plan. Prepare locks Economy -> Progression -> sorted Stack resources and computes next states; Apply performs only planned writes and acquires no new locks.
- **RUNTIME_OBSERVED:** five raw Pet skills are typed `[5]int64`, persisted explicitly by the new writer, and migration 00018 retains mixed-version `NOT NULL DEFAULT 1 CHECK >=1` compatibility.
- **RUNTIME_OBSERVED:** StockRuntime implements MID786/787/134/791 through strict Pet-local integral decoding without changing the legacy shared decoder. MID782 projects current absolute crystal only after settlement/replay.
- **RUNTIME_OBSERVED:** acquisition/hatch paths use Generation `DecisionAt`, stored `CreationContentRevision`, backward-clock rejection and equality-ready comparisons as required by A525-03/A525-04.
- **RUNTIME_OBSERVED:** all eight new Pet progression content tables are owned by `content-registry`; migration 00018 is sealed in the cumulative migration lock.
- **RUNTIME_OBSERVED:** startup/content activation code retains install/verify versus active-pointer separation; operational old-node drain/CAS ordering remains a live deployment proof obligation.

## Exact source cross-check

- **SOURCE_FACT:** exact current source declares MID786 `PET_EVOLVE`, MID787 `PET_FEED`, MID791 `PET_UPGRADE_ALL_SKILL`, and MID134 `PET_USE_EXP_ITEMS`.
- **SOURCE_FACT:** Pet evolution request is `pet_id`; client consumption uses next-star `StarLevelSuipian`; source-qualified generated evolution rows are 20/50/100/150 for target stars 2/3/4/5.
- **SOURCE_FACT:** stock Pet EXP UI/source uses item IDs 50001087/50001088/50001089, rejects one-key when current level is already max, and permits submitting available stock even when it does not reach the calculated target.
- **SOURCE_FACT:** skill upgrade wire uses `pet_id`, `skill_colors`, `skill_counts`; skill-book source item is 50001090. Generated CA3-3 content has 54 progression forms, 270 skill-slot rows, 100 EXP rows and 130 skill-book rows.
- **RUNTIME_OBSERVED:** `tools/generate_builtin_content.py --source-archive exact_src64 --check` regenerates revision `0c76be19146fbd477a7f63aac3cb955335f4529090906c13447ef54872da9931` without drift.

## Local execution reread

- **COMPATIBILITY_COPY_ONLY:** fresh disposable clone, only Go/toolchain compatibility edits (`go 1.26.0` -> `1.23.0`, remove `toolchain go1.27.1`, `.go-version` -> `1.23.2`). No product/test assertions were weakened.
- **COMPATIBILITY_COPY_ONLY:** focused `go test -race` GREEN for CharacterPet, I5, StockRuntime, Generation, content registry/builtin, content store, Character domain, Pet projection and archguard.
- **COMPATIBILITY_COPY_ONLY:** focused `go vet` GREEN.
- **COMPATIBILITY_COPY_ONLY:** bounded package-by-package regression GREEN 91/91.
- **COMPATIBILITY_COPY_ONLY:** integrated `tools/check.sh` was GREEN through source/oracle/query/ownership, Go test/vet and I1-I5 before the outer execution cap occurred in historical Python validation. Remaining historical validators were then run separately and GREEN. The outer timeout is not represented as an integrated-check PASS.
- **RUNTIME_OBSERVED:** canonical deterministic/static checks are GREEN, including CA3-3 source oracle, content regeneration, kernel/content/character querytext, schema ownership, R0, cumulative R5, CA3-3 validator, current-candidate validator, dependency/SBOM/sqlc policy and connected-candidate preseal.

## Remaining proof boundary

**NOT_RUN / required in Work:** exact canonical Go 1.27.1 and pinned sqlc 1.31.1 execution; real PostgreSQL 18.6 migration/restore/mixed-writer/locking/concurrency proof; real River only where the exercised CA3 path actually depends on it; old-node drain/new-binary-only activation; A525-07 stock no-reload/reload convergence; unmodified stock-client combined CA3-1/CA3-2/CA3-3 E2E with effective-client identity.

## Classification

**STRONG_INFERENCE:** no unresolved CA3-3 mechanic or current `src_64` contradiction remains in the inspected implementation. The next discriminating checks are operational/native/stock gates, not additional gameplay reconstruction.
