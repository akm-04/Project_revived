# Third-party notices — I4 W1-repair candidate

No third-party source is vendored in this snapshot. The resolved Go runtime closure is pinned in `go.mod`/`go.sum` and mirrored in `DEPENDENCIES.lock.json` and `SBOM.spdx.json`.

Direct runtime modules:
- github.com/go-chi/chi/v5 v5.3.1 — MIT.
- github.com/jackc/pgx/v5 v5.10.0 — MIT.
- github.com/riverqueue/river v0.47.0 — MPL-2.0.
- github.com/yuin/gopher-lua v1.1.2 — MIT (Copyright (c) 2015 Yusuke Inuzuka); linked only into the isolated combat worker resolver.

Resolved indirect runtime modules:
- github.com/jackc/pgpassfile v1.0.0 — MIT.
- github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 — MIT.
- github.com/jackc/puddle/v2 v2.2.2 — MIT.
- github.com/riverqueue/river/{riverdriver,rivershared,rivertype} v0.47.0 — MPL-2.0.
- github.com/tidwall/{gjson v1.19.0,match v1.2.0,pretty v1.2.1,sjson v1.2.5} — MIT.
- golang.org/x/sync v0.22.0 and golang.org/x/text v0.41.0 — BSD-3-Clause.

Qualified non-linked tools/services remain listed in `DEPENDENCIES.lock.json` (sqlc, goose, Testcontainers, OpenTelemetry, Prometheus, PostgreSQL, and the differential-only goAMF3 candidate).

River remains behind `internal/adapters/river`. River job identity is never GXB canonical truth. If River MPL-2.0 source files are modified and distributed, preserve the applicable file-level source/noticing obligations. Project-owned GXB files remain separately licensed.
