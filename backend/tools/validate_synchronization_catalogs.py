#!/usr/bin/env python3
"""Offline fail-closed validation for immutable synchronization catalogs."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.synchronization import SynchronizationCatalogs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", type=Path, default=ROOT / "data")
    args = parser.parse_args()
    catalogs = SynchronizationCatalogs.load(args.data_dir)
    report = {
        "status": "PASS",
        "hydration_contracts": len(catalogs.hydration_rows()),
        "stage3_mids": list(catalogs.stage3_mids()),
        "semantic_channels": [row.channel for row in catalogs.semantic_channels()],
        "deferred_adapter_mids": [row.mid for row in catalogs.deferred_adapters()],
        "message_push_types": [row.message_type for row in catalogs.message_push_types()],
        "realtime_event_mids": [row.mid for row in catalogs.realtime_events()],
        "wave_a_realtime_enabled": [row.mid for row in catalogs.realtime_events() if row.enabled_in_wave_a],
        "wave_e_realtime_publication_enabled": [row.mid for row in catalogs.realtime_events() if row.publication_enabled],
        "compatibility_policies": [row.policy_id for row in catalogs.compatibility.all()],
    }
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
