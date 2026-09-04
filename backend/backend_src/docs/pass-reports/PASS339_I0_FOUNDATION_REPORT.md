# Pass339 I0 Foundation Implementation Report

## Outcome

Pass339 completes the frozen I0 scaffold for the Identity / Session /
Concurrency foundation. The implementation is additive and behavior-neutral:
Pass299 JSON state remains canonical, the mature Python gameplay core is
unchanged, all HTTP gameplay still runs under the legacy process-global
`StateRepository` request `RLock`, and no client/Lua/native byte changed.

## Delivered

- Exact runtime and test dependency locks for CPython 3.12, plus 24 hashed
  Linux x86_64 wheels under `vendor/` and an offline bootstrap tool.
- SQLAlchemy Core 2.x + synchronous psycopg3 process-local engine ownership,
  PostgreSQL-only configuration, `READ COMMITTED`, bounded pools, fork
  disposal, and credential-safe configuration summaries.
- Alembic configuration and revision `0001_pass339_i0`. The revision creates
  only the `gxb` namespace and Alembic version authority; there are no gameplay
  tables and no persistence switch.
- Least-privilege NOLOGIN role scaffolding for owner/migration, HTTP app,
  realtime, and scheduler boundaries. Passwords and LOGIN identities remain
  operator-owned and absent from the archive.
- Frozen typed resource classes and deterministic order:
  `SESSION -> CONTEXT -> ACCOUNT_GLOBAL -> REGION -> GENERATION -> SHARED ->
  PLAYER(sorted numeric IDs) -> CHILD`.
- Mechanism-neutral transaction, player-aggregate repository, post-commit bus,
  and request-runtime protocols for I2-I4. The explicit legacy adapter delegates
  to Pass299 but is intentionally not wired into `EngineDispatcher` in I0.
- Central recursive secret redaction and a minimal JSON-lines signal contract.
- Unit, offline Alembic, live PostgreSQL, dependency bootstrap, byte-invariant,
  and controlling Pass299 regression gates.

## Validation

- 19/19 foundation tests pass.
- A fresh environment installed entirely from the backend-local wheelhouse;
  all 24 wheels passed size and SHA-256 verification before installation.
- PostgreSQL 16.15 live integration passes against disposable
  `gxb_i0_test`: synchronous psycopg connection, online Alembic upgrade,
  `READ COMMITTED`, schema existence, and exact revision verification.
- The four SQL role definitions execute twice-safe and were observed with
  `rolsuper=false`, `rolcreatedb=false`, `rolcreaterole=false`, and
  `rolcanlogin=false`.
- Fifteen controlling Pass299-era regression programs pass. Pass280 is
  deliberately excluded because Pass281 formally reverted/superseded it.
- Compileall passes for backend, tools, and migrations.
- The runtime-invariant guard covers 486 files / 83,403,668 content bytes and
  matches frozen Pass299 root SHA-256
  `224defa8d957ab3e10f6fcd4b0eb84939f84f2f6ca013033a23d9dd63d9d9f96`.

## Source/backend reality check

Current `src_64` reconfirms both I1 client requirements examined at this gate:
manual retry reuses the request parameter table, while the normal response path
has no context epoch fence; `LoadingScene.login_` tests `isLoggingIn_` but never
sets it. Frozen Pass299 reconfirms the global `RLock` and mature handler core.
These facts support the frozen roadmap and reveal no architecture-threatening
anomaly. `PASS339_SOURCE_BACKEND_CROSSCHECK.json` records exact hashes.

## Gate and next step

I0 is complete. I1 remains separately gated: implement the client compatibility
patch and ingress/auth perimeter without moving PostgreSQL gameplay authority
forward early. The RLock, one-worker constraint, and JSON authority remain until
their later frozen gates.
