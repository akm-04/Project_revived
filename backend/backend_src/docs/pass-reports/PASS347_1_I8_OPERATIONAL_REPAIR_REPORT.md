# Pass347.1 I8 operational-gate repair

Status: **PASS_AFTER_OPERATIONAL_GATE_REPAIR**.

The sealed Pass347.0 runtime already implemented the PostgreSQL authority,
relational/JSONB strangler, durable outbox, one-worker/RLock boundary, database
reversal triggers, and permanent JSON fallback refusal. A comparison with the
incomplete normal-chat attempt exposed one material operating gap: initial
services could not run an internal smoke while authority was `PREPARED`, and
public admission did not have a physical maintenance fence.

Pass347.1 makes the bounded repair without reopening the Pass337 architecture:

- `/run/gxb/maintenance` is the physical admission gate. nginx returns 503
  while it exists.
- HTTP may start at `PREPARED` only with that marker. Health reports
  `maintenance_ready`; normal startup still requires `TRAFFIC_OPEN`.
- The RealtimeGateway may own its listener but rejects player admission and
  does not recover/poll outbox or sweep liveness while maintenance is active.
- Scheduler/projection recovery and claims are paused behind the same marker.
- Gunicorn uses private `unix:/run/gxb/http.sock`; the unit creates the shared
  runtime directory and retains exactly one non-preloaded `gthread` worker.
- `gxb.target` and `bin/gxb-stack` provide the three-process operator surface.
- `open` requires the marker and deliberately leaves it in place.
  `maintenance-off` separately proves `TRAFFIC_OPEN` before releasing traffic.

Fresh PostgreSQL 16.15 validation applied all eight migrations, imported and
validated the representative immutable JSON state, prepared cutover evidence,
ran the stock-like MID18 -> MID1 -> MID17 flow under maintenance, opened traffic
with the exact irreversible confirmation, proved the marker remained, then
released it. The full live suite passed 289 tests with one intentionally skipped
PREPARED-only test; the dedicated PREPARED run passed separately. Gunicorn,
RealtimeGateway, and Scheduler were exercised as actual processes/components.

The Work sandbox denies AF_UNIX socket creation (`EPERM`) even under `/tmp`.
Therefore the packaged Unix path and nginx linkage are invariant-tested, while
Gunicorn pre/post-open process startup was dynamically tested through an
explicit loopback bind override. This is an environment limitation, not a
substitution in the shipped production configuration.

No gameplay/client behavior changed. All frozen src_64 network, MID1,
transition, realtime-control, and mail evidence hashes remain identical. One
HTTP worker and the legacy process-global `RLock` remain mandatory until I9.

