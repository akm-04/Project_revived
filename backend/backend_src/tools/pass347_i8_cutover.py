#!/usr/bin/env python3
"""Seal JSON evidence and perform the explicit one-way I8 cutover."""
from __future__ import annotations
import argparse
import gzip
import hashlib
import json
import os
import tarfile
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0, str(ROOT))

from sqlalchemy import text

from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.runtime.authority import CutoverEvidence, RuntimeAuthorityRepository
from gxb_backend.runtime.maintenance import MaintenanceGate


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""): h.update(chunk)
    return h.hexdigest()


def json_file(path: Path): return json.loads(path.read_text(encoding="utf-8"))


def require_reports(backup: dict, client: dict) -> None:
    pg = backup.get("postgresql") if isinstance(backup, dict) else None
    required_pg = ("logical_dump_restore", "wal_archive_check", "full_backup_label", "pitr_marker_observed", "promoted_timeline")
    if backup.get("status") != "PASS" or not isinstance(pg, dict) or any(not pg.get(k) for k in required_pg):
        raise SystemExit("I7 backup/restore/WAL/PITR evidence is incomplete")
    for key in ("equivalence_verified", "stock_client_ready", "maintenance_active", "json_writes_stopped", "src64_crosschecked"):
        if client.get(key) is not True:
            raise SystemExit(f"client readiness gate failed: {key}")


def seal_archive(source: Path, destination: Path) -> None:
    source = source.resolve()
    if not source.is_dir(): raise SystemExit("JSON source must be a directory")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.PAX_FORMAT) as archive:
                for path in sorted(source.rglob("*"), key=lambda p: p.relative_to(source).as_posix()):
                    if path.is_symlink(): raise SystemExit("snapshot archive refuses symlinks")
                    arcname = Path("server_state") / path.relative_to(source)
                    info = archive.gettarinfo(str(path), str(arcname))
                    info.uid = info.gid = 0; info.uname = info.gname = ""; info.mtime = 0
                    if path.is_file():
                        with path.open("rb") as stream: archive.addfile(info, stream)
                    else: archive.addfile(info)


def provider():
    env = dict(os.environ)
    if not env.get("GXB_DATABASE_URL") and env.get("GXB_TEST_DATABASE_URL"):
        env["GXB_DATABASE_URL"] = env["GXB_TEST_DATABASE_URL"]
    return ProcessEngineProvider(DatabaseSettings.from_env(env))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("status")
    pre = sub.add_parser("preflight"); pre.add_argument("--maintenance", action="store_true")
    sub.add_parser("maintenance-on"); sub.add_parser("maintenance-off")
    seal = sub.add_parser("seal-json-archive"); seal.add_argument("--source-root", required=True); seal.add_argument("--output", required=True)
    ev = sub.add_parser("make-evidence")
    for arg in ("source-archive", "migration-report", "backup-report", "client-report", "immutable-json-archive-path", "output"):
        ev.add_argument("--" + arg, required=True)
    prepare = sub.add_parser("prepare"); prepare.add_argument("--migration-run-id", required=True); prepare.add_argument("--evidence", required=True)
    opened = sub.add_parser("open"); opened.add_argument("--confirmation", required=True)
    args = parser.parse_args()
    gate=MaintenanceGate(Path(os.environ.get("GXB_MAINTENANCE_FILE","/run/gxb/maintenance")))
    if args.command=="maintenance-on":
        gate.enable(); print(json.dumps({"status":"PASS","maintenance_active":True,"path":str(gate.path)},sort_keys=True)); return

    if args.command == "seal-json-archive":
        seal_archive(Path(args.source_root), Path(args.output))
        print(json.dumps({"status":"SEALED", "path":str(Path(args.output)), "sha256":sha256(Path(args.output))}, sort_keys=True)); return
    if args.command == "make-evidence":
        backup = json_file(Path(args.backup_report)); client = json_file(Path(args.client_report)); require_reports(backup, client)
        evidence = CutoverEvidence(
            source_archive_sha256=sha256(Path(args.source_archive)), migration_report_sha256=sha256(Path(args.migration_report)),
            backup_restore_report_sha256=sha256(Path(args.backup_report)), client_readiness_report_sha256=sha256(Path(args.client_report)),
            immutable_json_archive_path=str(args.immutable_json_archive_path),
        ).validated()
        Path(args.output).write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(json.dumps({"status":"EVIDENCE_READY", "output":args.output, "evidence_digest":evidence["evidence_digest"]}, sort_keys=True)); return

    db = provider()
    try:
        if args.command=="maintenance-off":
            with db.engine().connect() as connection: RuntimeAuthorityRepository().require_postgresql(connection)
            gate.disable()
            print(json.dumps({"status":"PASS","authority":"TRAFFIC_OPEN","maintenance_active":False,"database":db.settings.safe_url},sort_keys=True)); return
        with db.engine().begin() as connection:
            authority = RuntimeAuthorityRepository()
            if args.command == "status": row = authority.status(connection)
            elif args.command == "preflight":
                revision = connection.execute(text("SELECT version_num FROM public.gxb_alembic_version")).scalar_one()
                if revision != "0008_pass347_i8": raise SystemExit(f"unexpected Alembic revision {revision}")
                if args.maintenance:
                    if not gate.active(): raise SystemExit("maintenance marker is not active")
                    row=authority.require_service_start(connection,maintenance_active=True)
                else: row=authority.require_postgresql(connection)
            elif args.command == "prepare":
                if not gate.active(): raise SystemExit("prepare requires the physical maintenance gate")
                raw = json_file(Path(args.evidence))
                allowed = {field for field in CutoverEvidence.__dataclass_fields__}
                row = authority.prepare_cutover(connection, migration_run_id=args.migration_run_id, evidence=CutoverEvidence(**{k:v for k,v in raw.items() if k in allowed}))
            else:
                if not gate.active(): raise SystemExit("TRAFFIC_OPEN requires the physical maintenance gate")
                row=authority.open_traffic(connection,confirmation=args.confirmation)
        print(json.dumps({"status":"PASS","authority":None if row is None else str(row["authority"]),"maintenance_active":gate.active(),"database":db.settings.safe_url},sort_keys=True))
    finally: db.dispose()

if __name__ == "__main__": main()
