# Pass348 I9 concurrency and worker-scaling reference

PostgreSQL is the sole runtime authority. The PostgreSQL StateRepository no
longer owns a process-global authenticated-request lock: request bindings are
thread-local, PlayerState instances are transaction-local, and all canonical
mutation remains inside an ordered ResourceTransaction. The historical JSON
StateRepository still keeps its lock because it is migration provenance, not a
multi-worker authority. Realtime registry/liveness locks and other bounded
subsystem-local locks are likewise not removed.

The production default remains `GXB_HTTP_WORKERS=1`. Widen deliberately through
the live-proven stages 1, 2, then 4:

```text
bin/gxb-stack scale-preflight 1
bin/gxb-stack scale-preflight 2
bin/gxb-stack scale-preflight 4
```

The preflight is read-only. It requires PostgreSQL `TRAFFIC_OPEN`, requires the
physical maintenance marker to be absent, validates that the stage is one of
1/2/4, and reserves capacity for HTTP, RealtimeGateway, Scheduler/Projection,
and administration. After a PASS, update `GXB_HTTP_WORKERS` and restart only
`gxb-http.service`. Observe readiness, error rate, transaction conflicts,
database latency, pool timeouts, and client smoke before advancing.

Rollback never changes canonical data authority: set `GXB_HTTP_WORKERS=1` and
restart `gxb-http.service`. Do not start the JSON launcher, restore JSON over
PostgreSQL, or attempt dual writes. Database recovery remains the I7
pgBackRest/WAL/PITR procedure.

`tests/integration/test_postgresql_i9_concurrency.py` proves row/resource
serialization, independent-player overlap, allocator uniqueness, liveness
leases, idempotency, SKIP LOCKED claims, and crash boundaries.
`tests/integration/test_postgresql_i9_gunicorn.py` starts real Gunicorn workers
over loopback for the 1/2/4 process proof. The packaged Unix-socket nginx edge
topology from I8 is unchanged.
