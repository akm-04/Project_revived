#!/usr/bin/env python3
"""Read-only gate for the Pass348 gradual 1 -> 2 -> 4 HTTP-worker stages."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys

from sqlalchemy import text

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.foundation.database import ProcessEngineProvider
from gxb_backend.runtime.authority import RuntimeAuthorityRepository
from gxb_backend.runtime.config import PROVEN_HTTP_WORKER_STAGES, ProductionRuntimeSettings


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workers", type=int, required=True, choices=PROVEN_HTTP_WORKER_STAGES)
    args = parser.parse_args()
    env = dict(os.environ)
    env["GXB_HTTP_WORKERS"] = str(args.workers)
    runtime = ProductionRuntimeSettings.from_env(env, application_name="gxb-i9-scale-preflight")
    if runtime.maintenance_active:
        raise SystemExit("scaling is blocked while the physical maintenance gate is active")
    provider = ProcessEngineProvider(runtime.database)
    try:
        with provider.engine().connect() as connection:
            authority = RuntimeAuthorityRepository().require_postgresql(connection)
            max_connections = int(connection.scalar(text("SHOW max_connections")))
            reserved = int(connection.scalar(text("SHOW superuser_reserved_connections")))
        # HTTP workers each own one bounded pool. Realtime and Scheduler each
        # own another pool; preserve five connections for administration and
        # recovery instead of validating only the happy-path HTTP footprint.
        pool_width = runtime.database.pool_size + runtime.database.max_overflow
        required = (args.workers + 2) * pool_width + 5
        usable = max_connections - reserved
        if usable < required:
            raise SystemExit(
                f"PostgreSQL connection capacity too small: usable={usable}, required={required}"
            )
        print(
            json.dumps(
                {
                    "status": "PASS",
                    "pass": "348.0",
                    "authority": str(authority["authority"]),
                    "maintenance_active": False,
                    "workers": args.workers,
                    "worker_stage": f"1->2->4 (selected {args.workers})",
                    "legacy_rlock_retained": False,
                    "database": runtime.database.safe_url,
                    "connection_capacity": {"usable": usable, "required": required},
                    "rollback": "set GXB_HTTP_WORKERS=1 and restart gxb-http.service",
                },
                sort_keys=True,
            )
        )
    finally:
        provider.dispose()


if __name__ == "__main__":
    main()
