# Pass347.1 I8 production reference

The production reference is one Linux host supervised by systemd: PostgreSQL,
one Gunicorn `gthread` HTTP worker, one dedicated RealtimeGateway, one
Scheduler/Projection process, and plain nginx. OpenResty is not required by the
foundation and remains an optional future edge experiment.

Project code, migrations, configuration examples, service units, nginx config,
operator tooling, and the `bin/gxb-stack` wrapper are shipped in this backend
archive. PostgreSQL, nginx, systemd, Gunicorn and pgBackRest are mature external
system packages and are intentionally not vendored as opaque binaries.

Before startup, place the backend at `/opt/gxb/backend`, create its virtualenv,
install `requirements/runtime.txt`, install the example units/config, populate
`/etc/gxb/gxb.env`, run Alembic, and complete `tools/pass347_i8_cutover.py`.

Gunicorn binds `/run/gxb/http.sock`; the nginx worker needs supplementary group
`gxb`. Initial activation is strictly: maintenance-on, prepare, private
readiness/stock smoke while nginx returns 503, explicit TRAFFIC_OPEN, then
maintenance-off. The open transaction never removes the marker. Maintenance-off
first proves TRAFFIC_OPEN; if marker removal fails PostgreSQL stays canonical
and public traffic stays closed. Realtime rejects admission/pauses outbox and
Scheduler/Projection claims nothing while maintenance is active.

`TRAFFIC_OPEN` is one-way. Once opened, the legacy JSON launcher refuses to
start even during a database outage. The immutable JSON archive remains audit
and disaster-recovery evidence, never a fallback authority.

HTTP TLS terminates at nginx. The stock realtime TCP protocol is plaintext;
for an untrusted Internet path, use a trusted VPN/protected transport or a
deliberate client/native encryption extension.

Docker is not part of the production reference: it would add a second service
supervisor and volume/network policy without improving the single-host proof.
Containers remain acceptable for disposable development tests.
