#!/usr/bin/env python3
"""Create or restore a safe I7 custom-format PostgreSQL rehearsal archive."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.migration.backup import create_custom_dump, restore_custom_dump


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    dump = sub.add_parser("dump")
    dump.add_argument("archive")
    dump.add_argument("--pg-dump", default="pg_dump")
    restore = sub.add_parser("restore")
    restore.add_argument("archive")
    restore.add_argument("--pg-restore", default="pg_restore")
    args = parser.parse_args()
    url = os.environ.get("GXB_DATABASE_URL") or os.environ.get("GXB_TEST_DATABASE_URL") or ""
    if not url:
        raise SystemExit("GXB_DATABASE_URL or GXB_TEST_DATABASE_URL is required")
    if args.command == "dump":
        artifact = create_custom_dump(url, Path(args.archive), pg_dump=args.pg_dump)
        print(json.dumps({"status": "PASS", "format": "pg_dump_custom", "path": str(artifact.path), "bytes": artifact.size, "sha256": artifact.sha256}, sort_keys=True))
    else:
        restore_custom_dump(url, Path(args.archive), pg_restore=args.pg_restore)
        print(json.dumps({"status": "PASS", "format": "pg_restore_single_transaction", "archive": str(Path(args.archive).resolve())}, sort_keys=True))


if __name__ == "__main__":
    main()
