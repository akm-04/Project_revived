# Pass436 — Milestone I3 Identity / Session / Logical Server / Character Bootstrap

## Implemented
- typed provider/account/session/context/server/player identities;
- HMAC credential digests and stable rederived gameplay bearer; raw credentials are not persistence values;
- strict production SID+login_token pair authentication and account/session liveness;
- idempotent provider binding without implicit cross-provider/account merge;
- durable session/context/credential revocation planning;
- same-target MID1 context/bearer coalescence and target-change supersession planning only after target admission;
- logical Server 1/2 semantic model, lifecycle, separate existing/new admission and region-encoded allocator;
- MID18 source-shaped region/player/recall arrays and same-session server observation concept;
- atomic pure first-character bootstrap plan with required contributor rollback semantics and replay-safe `first_entry_pending`;
- source-shaped MID1 stable fields `token/region/uid/detail/is_new`;
- semantic MID1 fingerprint and unknown-COMMIT reconciliation that refuses to call partial canonical state absent;
- forward-only PostgreSQL migration and sqlc-ready I3 query contracts;
- application-layer architecture guard so orchestration cannot import adapters/protocol/projections.

## Honest deferrals
Normal chat proves pure models, static schema/query ownership, source fixtures and concurrency/race safety only. Real PostgreSQL row locking, uniqueness races, final-slot capacity, ambiguous COMMIT reconciliation against a live DB, sqlc generation/pgx compilation, and unmodified stock-client bootstrap remain W1 after I4.
