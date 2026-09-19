#!/usr/bin/env python3
"""Enforce canonical PostgreSQL table/query ownership across the whole backend.

Strict mode is the ordinary project gate and fails on both unknown and known-open
violations. --allow-known-open exists so R0 can prove the guard itself is wired
correctly before later repair batches remove the deliberately exposed violations.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "docs/architecture/CANONICAL_TABLE_OWNERSHIP.json"
CREATE_RE = re.compile(r"(?is)\bCREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([A-Za-z_][A-Za-z0-9_]*)")
OWNER_RE = re.compile(r"(?im)^\s*--\s*owner:\s*([^\r\n]+)\s*$")


def path_matches(rel: str, patterns) -> bool:
    for pat in patterns:
        if pat.endswith("/") and rel.startswith(pat):
            return True
        if rel == pat:
            return True
    return False


def access_patterns(table: str):
    e = re.escape(table)
    return {
        "write": re.compile(rf"(?is)\b(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+{e}\b"),
        "read": re.compile(rf"(?is)\b(?:FROM|JOIN)\s+{e}\b"),
    }


def classify_access(text: str, table: str):
    pats = access_patterns(table)
    out = []
    if pats["write"].search(text):
        out.append("write")
    if pats["read"].search(text):
        out.append("read")
    return out


def exception_allows(entry, rel: str, finding_id=None) -> bool:
    for ex in entry.get("write_exceptions", []):
        if path_matches(rel, [ex["path"]]):
            return True
    return False


def load_contract():
    if not CONTRACT_PATH.exists():
        raise SystemExit(f"missing {CONTRACT_PATH.relative_to(ROOT)}")
    data = json.loads(CONTRACT_PATH.read_text())
    if data.get("schema_version") != 1 or not isinstance(data.get("tables"), dict):
        raise SystemExit("invalid canonical table ownership contract")
    return data


def scan_operational_files():
    files = []
    files.extend(sorted((ROOT / "sql").glob("**/*.sql")))
    files.extend(sorted((ROOT / "internal").glob("**/*.go")))
    return [p for p in files if p.is_file() and not p.name.endswith("_test.go")]


def known_key(v):
    return (v["access"], v["table"], v["path"])


def run(allow_known_open=False):
    data = load_contract()
    tables = data["tables"]
    errs = []
    violations = []

    # Owner query-source -> runtime generated-query freshness proofs.
    for label, qrel, grel, const_name in [
        ("kernel", "sql/kernel/receipts.sql", "internal/adapters/postgres/kernelqueries/querytext_gen.go", "SourceSHA256"),
        ("content", "sql/content/content.sql", "internal/adapters/postgres/contentqueries/querytext_gen.go", "SourceSHA256"),
        ("character-hero", "sql/character/hero.sql", "internal/adapters/postgres/characterqueries/querytext_gen.go", "SourceSHA256"),
        ("character-pet", "sql/character/pet.sql", "internal/adapters/postgres/characterqueries/querytext_gen.go", "PetSourceSHA256"),
        ("character-saved-preset", "sql/character/preset.sql", "internal/adapters/postgres/characterqueries/querytext_gen.go", "PresetSourceSHA256"),
    ]:
        q = ROOT / qrel; gen = ROOT / grel
        if not q.exists() or not gen.exists():
            errs.append(f"{label} query/generated query text missing")
        else:
            expected = hashlib.sha256(q.read_text().encode()).hexdigest()
            m = re.search(rf'const {const_name} = "([0-9a-f]{{64}})"', gen.read_text())
            if not m or m.group(1) != expected:
                errs.append(f"generated {label} query text is stale")

    # Forward-only migration law and complete CREATE TABLE ownership coverage.
    created = {}
    for p in sorted((ROOT / "migrations").glob("*.sql")):
        text = p.read_text(errors="replace")
        if "-- +goose Down" in text:
            errs.append(f"production migration contains DOWN section: {p.relative_to(ROOT)}")
        for name in CREATE_RE.findall(text):
            rel = p.relative_to(ROOT).as_posix()
            if name in created:
                errs.append(f"canonical table {name} created by multiple migrations: {created[name]} and {rel}")
            created[name] = rel
    unregistered = sorted(set(created) - set(tables))
    stale = sorted(set(tables) - set(created))
    if unregistered:
        errs.append("unregistered canonical tables: " + ", ".join(unregistered))
    if stale:
        errs.append("ownership contract references uncreated tables: " + ", ".join(stale))
    for name, rel in created.items():
        if name in tables and tables[name].get("migration") != rel:
            errs.append(f"{name}: creating migration is {rel}, contract says {tables[name].get('migration')}")

    # Operational query/inline SQL ownership.
    for p in scan_operational_files():
        rel = p.relative_to(ROOT).as_posix()
        text = p.read_text(errors="replace")
        owner_marker = None
        if p.suffix == ".sql":
            m = OWNER_RE.search(text)
            owner_marker = m.group(1).strip() if m else None
        for table, entry in tables.items():
            accesses = classify_access(text, table)
            if not accesses:
                continue
            if p.suffix == ".sql":
                if owner_marker is None:
                    errs.append(f"{rel}: canonical SQL references {table} without -- owner marker")
                elif owner_marker not in entry.get("allowed_query_owners", []):
                    violations.append({"access":"query-owner","table":table,"path":rel,"detail":f"owner marker {owner_marker!r} not allowed"})
            for access in accesses:
                patterns = entry.get("allowed_write_paths" if access == "write" else "allowed_read_paths", [])
                allowed = path_matches(rel, patterns)
                if access == "write" and not allowed:
                    allowed = exception_allows(entry, rel)
                if not allowed:
                    violations.append({"access":access,"table":table,"path":rel,"detail":f"owner={entry.get('owner')}"})

    known = {known_key(v): v for v in data.get("known_open_violations", [])}
    known_hits = []
    unknown_hits = []
    for v in violations:
        k = (v["access"], v["table"], v["path"])
        if k in known:
            x = dict(v)
            x.update({"finding_id": known[k]["finding_id"], "reason": known[k].get("reason", "")})
            known_hits.append(x)
        else:
            unknown_hits.append(v)
    # Known records must still correspond to a live violation; otherwise remove/update them.
    live_keys = {(v["access"],v["table"],v["path"]) for v in violations}
    stale_known = [v for k,v in known.items() if k not in live_keys]
    if stale_known:
        errs.extend(f"stale known-open ownership record {v['finding_id']}: {v['access']} {v['table']} in {v['path']}" for v in stale_known)

    if errs or unknown_hits or (known_hits and not allow_known_open):
        print("SCHEMA/QUERY OWNERSHIP: FAIL")
        for e in errs:
            print(" -", e)
        for v in unknown_hits:
            print(f" - UNKNOWN ownership violation: {v['access']} {v['table']} in {v['path']} ({v['detail']})")
        for v in known_hits:
            print(f" - KNOWN OPEN {v['finding_id']}: {v['access']} {v['table']} in {v['path']} -- {v['reason']}")
        return 1
    if known_hits:
        print("SCHEMA/QUERY OWNERSHIP: PASS WITH KNOWN OPEN FINDINGS")
        for v in known_hits:
            print(f" - KNOWN OPEN {v['finding_id']}: {v['access']} {v['table']} in {v['path']}")
    else:
        print("SCHEMA/QUERY OWNERSHIP: PASS")
    return 0


def self_test():
    assert path_matches("internal/adapters/postgres/i5store/store.go", ["internal/adapters/postgres/i5store/"])
    assert not path_matches("internal/adapters/postgres/i4store/bootstrap_runtime.go", ["internal/adapters/postgres/i5store/"])
    sample = "SELECT x FROM foo JOIN bar ON true; UPDATE baz SET x=1; INSERT INTO quux(x) VALUES(1)"
    assert classify_access(sample, "foo") == ["read"]
    assert classify_access(sample, "bar") == ["read"]
    assert classify_access(sample, "baz") == ["write"]
    assert classify_access(sample, "quux") == ["write"]
    print("SCHEMA/QUERY OWNERSHIP SELF-TEST: PASS")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--allow-known-open", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    return run(args.allow_known_open)

if __name__ == "__main__":
    sys.exit(main())
