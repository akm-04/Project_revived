# Pass433 / I0 dependency qualification

Date: 2026-09-06.

Target: Go 1.27.1 and PostgreSQL 18.6. PostgreSQL 19 is still beta and is excluded from the implementation baseline.

Qualified candidate versions are frozen in `DEPENDENCIES.lock.json`. Exact runtime dependencies enter `go.mod` only when the owning wave actually imports them; this avoids a fake dependency graph and keeps DRY/least-dependency discipline.

Notable review decisions:

- pgx v5.10.0: native pgx/pgxpool approved candidate. Its June 2026 release contains server-input hardening. An Aug 2026 open issue concerns `database/sql` prepared-statement behavior; V2 intends direct pgx/pgxpool and records this as a reason not to introduce an ORM/stdlib prepared-statement layer casually.
- goose v3.27.3: approved migration-tool candidate; preceding v3.27.2 explicitly upgraded x/crypto and x/net for security advisories.
- River v0.47.0: approved behind an adapter only. MPL-2.0 obligations are explicitly tracked. River wakeups/jobs never become GXB authority.
- chi v5.3.1: approved thin HTTP router candidate.
- Testcontainers v0.44.0: approved test-only candidate for real PostgreSQL gates.
- OpenTelemetry v1.45.0 and Prometheus client v1.24.1: approved observability candidates; bounded-cardinality/redaction remains project policy.
- sqlc v1.31.1: approved typed-query build-tool candidate.
- goAMF3 v1.0.2: **not runtime-approved**. I2 may promote it only after captured corpus + Pass353 differential equivalence.

Pass438 W1 resolved the tagged dependency closure under Go 1.27.1 and exposed packaging defects before stock execution. Pass440 commits that closure and adds a connected preseal validator. Pass440 captured the last normal-chat executable compatibility gate under Go 1.23.2 before Pass441 froze the W1-resolved `go 1.26.0` language floor. The exact Pass441 module therefore requires the Work Go 1.27.1 executable preseal; PostgreSQL 18.6, River, and stock runtime remain W1 proofs.

Selected I7A-10 security repair: compiler/runtime patch pin Go 1.27.2 is approved by normal660; exact replacement qualification follows. Keep Go language floor 1.26.0 and all runtime module, PostgreSQL and River pins unchanged. Earlier Go 1.27.1 qualification above remains historical provenance. Seven current reachable-symbol standard-library advisories make the existing pinned security gate fail; physicalW2 remains deferred.

Selected I8-0 security repair (user-approved 2026-10-21): compiler/runtime patch pin Go 1.27.3 fixes GO-2026-6809 (crypto/x509, reachable under the postgres,river tags), found by the full dated vulnerability database shipped in portable tools r3. Qualified with portable tools r4. Keep Go language floor 1.26.0 and all runtime module, PostgreSQL and River pins unchanged. Go 1.27.2 above remains historical provenance.
