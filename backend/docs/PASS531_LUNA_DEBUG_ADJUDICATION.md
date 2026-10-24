# Pass531 — Luna CA3 Work-debug adjudication

Status: **IMPLEMENTATION_DECISION / local repair candidate; NOT CA3 acceptance**

## Inputs adjudicated

- Exact Pass530 backend archive: `c329abe73765cb8af90d394bc3362116cf8f32f4f03808c0ea58817847e9d7ef`.
- Luna evidence archive: `3f7f3b17aa878d51dcb0a7196b561c7999d6fe890b8255cadc5deaddf228e581`.
- Luna proposed backend archive: `cd2ff21e6996b8c607f9d83493a9f11c2e6b97293c1ae2fa19e8c2504554425c`.
- Current `src_64` archive: `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.
- Current `src_64/app/common/network/Backend.lua`: `95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840`.

Luna correctly kept the exact Pass530 candidate untouched and labeled its changed copy `PROPOSED_LUNA_MODIFICATION_NOT_ACCEPTED`.

## Finding 1 — HTTP command envelope metadata

**RUNTIME_OBSERVED:** Luna's exact native HTTP run returned HTTP 400 for Pet MIDs before the Pet services executed. The strict Pet dispatcher saw transport/client envelope fields as unexpected gameplay parameters.

**SOURCE_FACT:** the active `src_64` ordinary HTTP sender writes six top-level values into the JSON command table before encoding it: `mid`, `token`, `region`, `v_`, `app_v`, and `platform`. The sealed I2 wire design records these as source-added fields/transport normalization concerns.

**ADJUDICATION:** accept Luna's diagnosis, reject the exact three-key exception as incomplete. Luna's proposed helper ignored `mid/token/region` only. A harness omitting `v_/app_v/platform` is not the complete active stock request shape.

**IMPLEMENTATION_DECISION:** Pass531 adds one StockRuntime top-level validator that permits exactly those six recovered metadata keys plus the command's explicit gameplay keys. It is applied to strict Pet routes and to strict Hero routes, because Hero shared the same latent transport leak. Nested gameplay row/object validators remain strict and do not inherit metadata exemptions. No global HTTP-edge stripping is performed because `platform` is semantically consumed by other routes such as I5 MID230.

## Finding 2 — Pet lock errors

**RUNTIME_OBSERVED:** Luna's real PostgreSQL 18.6 concurrent Evolve probe produced SQLSTATE 40001 at the Pet row lock. Pass530 converted that error to semantic `ErrPetNotFound`, so one caller did not enter the stable operation retry path even though only one durable effect committed.

**ADJUDICATION:** accept Luna's diagnosis, reject the exact helper as too narrow. Luna's proposed `petLockFailure` preserved configured definite-abort errors but continued mapping any other database/timeout/cancellation/connection error to `ErrPetNotFound`.

**IMPLEMENTATION_DECISION:** `characterpet.Store.LockPetByIDTx` now returns `(Pet, found, error)`. The PostgreSQL adapter converts only normalized `kernelstore.ErrNoRows` to `found=false,nil`; every other error is propagated unchanged. Application callers return `ErrPetNotFound` only on `!found`. This preserves SQLSTATE 40001/40P01 for the transaction runner and also fails closed for unrelated infrastructure errors.

## Tests added

- Full six-key stock-envelope metadata acceptance plus invented gameplay-key rejection for Pet.
- Equivalent six-key acceptance/rejection on strict Hero routing.
- PostgreSQL adapter distinction between normalized no-row and arbitrary infrastructure failure.
- CharacterPet lock behavior proving definite-abort retry, ordinary-error propagation, and true missing-Pet semantic mapping.
- CA3-3 validator updated to enforce the stronger `(pet, found, err)` lock contract rather than the superseded textual form.

## Normal-chat result

**COMPATIBILITY_COPY_ONLY:** fresh Go-1.23-adapted copy passed focused unit/race/vet and bounded 91/91 package regression.

**RUNTIME_OBSERVED (canonical deterministic/static):** exact `src_64` compiler regeneration, CA3-3 source oracle, kernel/content/character query generation, schema/query ownership, CA3-3 validator, R0, cumulative R5/R6, current-candidate, dependency/SBOM/sqlc policy checks are green on canonical bytes before final identity packaging.

## Acceptance boundary

Pass531 is a repair candidate only. Luna's first Work run remains valuable evidence for rows already run on the exact Pass530 candidate, but rows affected by these changed boundaries must be rerun on exact Pass531. CA3 aggregate acceptance remains blocked by any mandatory non-PASS row, including A525-07 stock runtime, old-node drain/activation sequencing, UNKNOWN-COMMIT injection, and controlled time/revision scenarios.
