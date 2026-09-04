#!/usr/bin/env python3
"""Verify Pass343 I4 is a bounded persistence strangler over sealed Pass342."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from pass_artifact_resolver import resolve_pass_artifact

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
PASS340_RUNTIME = ROOT / "docs/json/PASS340_RUNTIME_DELTA_MANIFEST.json"
PASS342_COMMIT = ROOT / "docs/json/PASS342_IMPLEMENTATION_COMMIT.json"
PASS342_CROSSCHECK = ROOT / "docs/json/PASS342_SOURCE_BACKEND_CROSSCHECK.json"
I4_MANIFEST = ROOT / "docs/json/PASS343_I4_PERSISTENCE_MANIFEST.json"
EXPECTED_BASELINE_FILES = 495
EXPECTED_BASELINE_ROOT = "d90e6b6e73bf1bebb760a51762191e04e6d53ff55065e125cd1c989736e176f1"
EXPECTED_CURRENT_ROOT = "acf9220097059037be2699dac33640757dd1a853fadb10df9e7b99c427a70eaa"
EXPECTED_CURRENT_BYTES = 83_556_375
ALLOWED_RUNTIME_MODIFIED = {"gxb_backend/state/repository.py"}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def baseline_runtime() -> dict[str, str]:
    data = json.loads(PASS340_RUNTIME.read_text(encoding="utf-8"))
    expected = dict(data["baseline_sha256_by_path"])
    expected.update(data["allowed_modified_sha256"])
    expected.update(data["allowed_added_sha256"])
    return expected


def root_digest(paths: dict[str, Path]) -> tuple[str, int]:
    digest = hashlib.sha256(); total = 0
    for rel in sorted(paths):
        content = paths[rel].read_bytes(); rel_bytes = rel.encode("utf-8")
        total += len(content)
        digest.update(len(rel_bytes).to_bytes(4, "big")); digest.update(rel_bytes)
        digest.update(len(content).to_bytes(8, "big")); digest.update(content)
    return digest.hexdigest(), total


def verify_runtime_delta() -> tuple[str, int, int]:
    expected = baseline_runtime()
    if len(expected) != EXPECTED_BASELINE_FILES:
        raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL baseline count={len(expected)}")
    pass340 = json.loads(PASS340_RUNTIME.read_text(encoding="utf-8"))
    if pass340["current_root_sha256"] != EXPECTED_BASELINE_ROOT:
        raise SystemExit("PASS343 I4 INVARIANTS: FAIL embedded Pass340 runtime root drift")
    changed=[]; observed={}
    for rel,wanted in expected.items():
        path=resolve_pass_artifact(ROOT, rel)
        if not path.is_file(): raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL missing runtime {rel}")
        got=sha(path); observed[rel]=path
        if got != wanted: changed.append(rel)
    if set(changed) != ALLOWED_RUNTIME_MODIFIED:
        raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL runtime delta {changed}")
    digest,total=root_digest(observed)
    if digest != EXPECTED_CURRENT_ROOT or total != EXPECTED_CURRENT_BYTES:
        raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL runtime root/bytes {digest}/{total}")
    return digest,total,len(observed)


def verify_src64_and_seams() -> None:
    data=json.loads(PASS342_CROSSCHECK.read_text(encoding="utf-8"))
    for row in data["client_runtime_rechecked"]:
        if sha(ROOT/row["path"]) != row["sha256"]:
            raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL src64 drift {row['path']}")
    rows={x["path"]:x for x in data["backend_runtime_rechecked"]}
    for rel in ("gxb_backend/state/multiuser_database.py","gxb_backend/dispatch/engine_dispatcher.py","gxb_backend/auth/perimeter.py"):
        if sha(resolve_pass_artifact(ROOT, rel)) != rows[rel]["sha256"]:
            raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL mature seam drift {rel}")
    repo=(ROOT/"gxb_backend/state/repository.py").read_text(encoding="utf-8")
    for required in ("threading.RLock()","PlayerStateStore","LegacyJsonPlayerStateStore","player_state_store or LegacyJsonPlayerStateStore(self.store)"):
        if required not in repo: raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL StateRepository boundary {required}")


def verify_pass342_preserved() -> int:
    data=json.loads(PASS342_COMMIT.read_text(encoding="utf-8"))
    intentional={"gxb_backend/foundation/schema.py","migrations/env.py","tests/i3/test_schema_and_migration.py","VERSION.json","gxb_backend/version.py","pyproject.toml"}
    failures=[]; checked=0
    for rel,wanted in data["implementation_sha256"].items():
        if rel in intentional: continue
        path=resolve_pass_artifact(ROOT, rel); got=sha(path) if path.is_file() else "MISSING"
        if got != wanted: failures.append((rel,wanted,got))
        checked += 1
    if failures: raise SystemExit("PASS343 I4 INVARIANTS: FAIL Pass342 drift="+json.dumps(failures[:20]))
    return checked


def verify_i4_manifest() -> int:
    data=json.loads(I4_MANIFEST.read_text(encoding="utf-8")); failures=[]
    for rel,wanted in data["sha256_by_path"].items():
        path=resolve_pass_artifact(ROOT, rel); got=sha(path) if path.is_file() else "MISSING"
        if got != wanted: failures.append((rel,wanted,got))
    if failures: raise SystemExit("PASS343 I4 INVARIANTS: FAIL I4 hashes="+json.dumps(failures[:20]))
    return len(data["sha256_by_path"])


def verify_scope() -> None:
    from gxb_backend.identity.schema import players as i3_players
    from gxb_backend.persistence.schema import account_global_state, players as i4_players
    if set(i3_players.c.keys()) != {"player_id","account_uid","region_id","created_at"}:
        raise SystemExit("PASS343 I4 INVARIANTS: FAIL I3 directory metadata mutated")
    if set(i4_players.c.keys()) != {"player_id","account_uid","region_id","created_at","schema_version","state_version","payload","updated_at"}:
        raise SystemExit("PASS343 I4 INVARIANTS: FAIL I4 player projection")
    if set(account_global_state.c.keys()) != {"account_uid","schema_version","state_version","payload","updated_at"}:
        raise SystemExit("PASS343 I4 INVARIANTS: FAIL account-global boundary")
    migration=(ROOT/"migrations/versions/0004_pass343_i4_player_persistence.py").read_text(encoding="utf-8")
    for forbidden in ("mail_items","shared_resources","global_projections","player_states"):
        if forbidden in migration: raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL future table creep {forbidden}")
    hits=[]
    for path in (ROOT/"gxb_backend").rglob("*.py"):
        rel=path.relative_to(ROOT).as_posix()
        if rel.startswith("gxb_backend/persistence/"): continue
        text=path.read_text(encoding="utf-8",errors="replace")
        if "TransactionBoundPostgresPlayerStateStore" in text or "relational_player_sub_uow" in text:
            hits.append(rel)
    if hits: raise SystemExit(f"PASS343 I4 INVARIANTS: FAIL relational player store wired into runtime {hits}")


def main() -> None:
    root,total,count=verify_runtime_delta(); verify_src64_and_seams()
    preserved=verify_pass342_preserved(); i4=verify_i4_manifest(); verify_scope()
    print(f"PASS343 I4 INVARIANTS: PASS runtime_files={count} runtime_bytes={total} runtime_root={root} pass342_preserved={preserved} i4_hashes={i4}")

if __name__ == "__main__": main()
