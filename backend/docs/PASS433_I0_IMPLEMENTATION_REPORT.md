# Pass433 — I0 clean V2 repository + dependency/bootstrap qualification

## Implemented
- New V2 tree created from scratch; no Pass353 application/source tree copied.
- Repository ownership layout from Pass431 established.
- Go 1.27.1 target pinned (`.go-version`, `toolchain` directive); current offline compatibility build uses installed Go with `GOTOOLCHAIN=local`.
- Candidate dependency versions/licenses pinned separately from runtime imports.
- Direct candidate SPDX inventory + notices committed; River MPL-2.0 handled explicitly.
- Source/V1/native/old-client/probe archive hashes pinned and executable oracle verification added.
- Secret-redacting bootstrap configuration mechanism added.
- Architecture import guard forbids domain direct protocol/projection/adapter and direct pgx/River/database/sql bypass.
- Local build/test/vet/check scripts established.
- No gameplay/product behavior claimed.

## Environment-bounded item
The current sandbox cannot download Go 1.27.1 or module data. Exact target-toolchain build, resolved-transitive SBOM/license scan and `govulncheck` are therefore an explicit connected-environment check. This does not prove PostgreSQL/River runtime behavior; W1 remains after I4.

## Bounded source/V1 cross-check
Verified current `src_64` still exhibits same-MID/same-param retry and JSON→`string.urlencode` ordinary web encoding, with no generic stock operation nonce/context epoch in `Backend.lua`. Frozen Pass353 remains visibly a Python/V1 implementation oracle and no V1 application code was copied into V2. See `PASS433_I0_ORACLE_CROSSCHECK.md`.

## I0 verdict
**PASS_WITH_ENVIRONMENT_DEFERRED_EXTERNAL_TOOLCHAIN_FETCH.** The clean V2 repository, offline build/test/vet, architecture rules, oracle integrity, candidate-version pins, direct SBOM/license inventory, secret-redaction baseline, and deterministic local scripts are green. Exact Go 1.27.1 execution and resolved-transitive `govulncheck` cannot run in this network-isolated sandbox and remain an explicit connected-environment proof. This is not PostgreSQL/River runtime proof; W1 remains after I4.
