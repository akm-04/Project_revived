# Pass348 I9 — concurrency proof, RLock retirement, and bounded scaling

Pass348 completes the critical I9 foundation wave. It followed the frozen order:
the database/resource race suite passed first while the I8 global request lock
was retained; only then was the lock retired from the PostgreSQL runtime; only
then were actual Gunicorn processes widened through 1, 2, and 4 workers.

## Pre-retirement proof

A fresh clone of the Pass347.1 `TRAFFIC_OPEN` rehearsal database passed
independent-player overlap, same-player serialization, reversed multi-player
ordering, twelve-way region allocation, same-session context replacement,
receipt/mail/job idempotency, four-way outbox/job SKIP LOCKED claims, and process
death before/after commit. The run found one bounded defect: concurrent
identical mail deliveries could encounter the protocol-address unique index
before the named delivery-key conflict target. Mail delivery now suppresses
either uniqueness race and verifies the full semantic winner.

## Retirement boundary

Only `PostgresStateRepository` retired the process-global request lock.
`StateRepository` retains the legacy JSON lock; realtime/session registries and
other subsystem-local locks remain. Relational PlayerState is never put into a
process cache. Request identity and services remain thread-local, all gameplay
mutation retains the outer ordered ResourceTransaction and player row lock, and
the account projection reuses the already-owned transaction connection to avoid
pool starvation under gthread concurrency.

Expected stale identity, state-version, receipt-replay, and exhausted/retryable
database conflicts now return explicit 401/409/503 transport envelopes. No
arbitrary gameplay exception is swallowed.

## Multi-process proof

Actual Gunicorn `gthread` stages 1, 2, and 4 each passed on a fresh database
clone. Each run booted every configured worker and completed four distinct
SDK registrations/logins, MID18 directories, MID1 selections, and MID17 loads.
Concurrent same-session MID1 requests converged to exactly one live gameplay
token; the losing request/token was explicitly rejected. Concurrent same-player
SAVE_STORY operations preserved both fields and advanced state_version at least
twice. Independent-player mutations completed without collision.

The package accepts only the proven 1/2/4 stages and defaults to one. The new
read-only scale preflight checks PostgreSQL authority, maintenance state, and
connection capacity. Rollback is `GXB_HTTP_WORKERS=1` plus HTTP restart; it never
changes data authority.

## Reality check

The current Backend.lua/LoadingScene/LoginWindow/SwitchItem/MID and mail source
hashes remain byte-identical to Pass347.1. Source continues to require the
account→context transition, context epoch fence, logical operation identity,
and compound mail identity; it does not dictate an HTTP worker count or Python
lock. The mature backend domain core and all ownership boundaries are reused.
No material contradiction or Design loopback appeared.

I10 stock-client foundation reconciliation is next. Broad long-run hardening
and unrelated gameplay completion remain deferred under the project policy.
