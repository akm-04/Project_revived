#!/usr/bin/env python3
"""Generate the backend system map under docs/architecture/system_map."""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIRECTORY = ROOT / "docs" / "architecture" / "system_map"
SYSTEMS_DIRECTORY = OUTPUT_DIRECTORY / "systems"
APPLICATION_DIRECTORY = ROOT / "internal" / "application"
CLIENT_CALLERS = OUTPUT_DIRECTORY / "client_mid_callers.json"
SCENARIO_COVERAGE = OUTPUT_DIRECTORY / "scenario_coverage.json"
SHARED_STORE_SYSTEMS = 10
MODULE_PATH = "gxb.local/backend/v2/"
APPLICATION_PREFIX = MODULE_PATH + "internal/application/"
POSTGRES_PREFIX = MODULE_PATH + "internal/adapters/postgres/"
HELPER = "./tools/system_map_mids"

MID_LINE_RE = re.compile(r"^\s*xyd\.mid\.([A-Za-z0-9_]+)\s*=\s*(\d+)\s*;?\s*(?:--.*)?$")
MID_USE_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\.mid\.([A-Za-z0-9_]+)")
SENDER_RE = re.compile(r"\brequest\s*\(")
TOKEN_RE = re.compile(r"[A-Za-z0-9_]+")
PACKAGE_COMMENT_RE = re.compile(r"^//\s?(.*)$")
CREATE_TABLE_RE = re.compile(
    r"\bcreate\s+(?:unlogged\s+)?table\s+(?:if\s+not\s+exists\s+)?([A-Za-z0-9_.\"]+)",
    re.IGNORECASE,
)
INSERT_RE = re.compile(r"\binsert\s+into\s+([A-Za-z0-9_.\"]+)", re.IGNORECASE)
UPDATE_RE = re.compile(r"\bupdate\s+([A-Za-z0-9_.\"]+)", re.IGNORECASE)
DELETE_RE = re.compile(r"\bdelete\s+from\s+([A-Za-z0-9_.\"]+)", re.IGNORECASE)
FROM_RE = re.compile(r"\bfrom\s+([A-Za-z0-9_.\"]+)", re.IGNORECASE)
IMPORT_BLOCK_RE = re.compile(r"(?ms)^import\s*\((.*?)\)")
IMPORT_LINE_RE = re.compile(r'^\s*(?:([A-Za-z0-9_.]+|\.|_)\s+)?"([^"]+)"\s*$')


def json_text(value):
    return json.dumps(value, indent=1, ensure_ascii=False, sort_keys=True) + "\n"


def parse_mid_line(line):
    match = MID_LINE_RE.match(line.lstrip("﻿"))
    if not match:
        return None
    return match.group(1), int(match.group(2))


def doc_tokens(text):
    return set(TOKEN_RE.findall(text))


def normalize_table(token):
    name = token.strip().strip('"')
    if "." in name:
        name = name.split(".")[-1]
    return name.strip('"').lower()


def scenario_mids(scenario, name_to_mid):
    mids = set()
    for step in scenario.get("steps") or []:
        if not isinstance(step, str) or not step.startswith("lua:"):
            continue
        for name in MID_USE_RE.findall(step):
            if name in name_to_mid:
                mids.add(name_to_mid[name])
    for key in ("expect_ok", "expect_inactive"):
        for value in scenario.get(key) or []:
            if isinstance(value, int):
                mids.add(value)
    return mids


def classify_client_lines(text):
    names = set(MID_USE_RE.findall(text))
    senders = set()
    other = set()
    for line in text.splitlines():
        line_names = set(MID_USE_RE.findall(line))
        if not line_names:
            continue
        target = senders if SENDER_RE.search(line) else other
        target.update(line_names)
    return names, senders, other


def self_check():
    aliased = "var_0_2.Backend.get():request(var_0_2.mid.SET_HERO_EQUIP, var_157_0, function(c, r)"
    names, senders, other = classify_client_lines(aliased)
    assert names == {"SET_HERO_EQUIP"} and senders == {"SET_HERO_EQUIP"} and other == set()
    assert classify_client_lines("arg_0.mid.RETRIEVE_TOKEN = xyd.event.TOKEN")[2] == {"RETRIEVE_TOKEN"}
    assert parse_mid_line("xyd.mid.RETRIEVE_TOKEN = 1") == ("RETRIEVE_TOKEN", 1)
    assert parse_mid_line('xyd.mid.LOAD_ANNOUNCE = 7;') == ("LOAD_ANNOUNCE", 7)
    assert parse_mid_line("-- xyd.mid.NOPE = 9") is None
    assert doc_tokens('"114" and 1140') == {"114", "and", "1140"}
    assert normalize_table('"public"."account_sessions"') == "account_sessions"
    scenario = {"steps": ["lua:xyd.mid.A + xyd.mid.B"], "expect_ok": [7], "expect_inactive": [8]}
    assert scenario_mids(scenario, {"A": 1, "B": 2}) == {1, 2, 7, 8}
    assert json_text({"b": 1, "a": [2, 1]}) == '{\n "a": [\n  2,\n  1\n ],\n "b": 1\n}\n'


def read_text(path):
    return path.read_text(encoding="utf-8", errors="replace")


def go_files(directory, include_tests=False):
    for path in sorted(directory.rglob("*.go")):
        if not include_tests and path.name.endswith("_test.go"):
            continue
        yield path


def imports_of(path):
    text = read_text(path)
    paths = []
    for block in IMPORT_BLOCK_RE.findall(text):
        for line in block.splitlines():
            match = IMPORT_LINE_RE.match(line)
            if match:
                paths.append(match.group(2))
    for line in text.splitlines():
        if not line.startswith("import "):
            continue
        match = IMPORT_LINE_RE.match(line[len("import "):])
        if match:
            paths.append(match.group(2))
    return paths


def relative(path):
    return path.relative_to(ROOT).as_posix()


def import_to_directory(import_path):
    if not import_path.startswith(MODULE_PATH):
        return None
    return import_path[len(MODULE_PATH):].rstrip("/")


def directory_imports(directory):
    paths = set()
    for path in go_files(directory):
        paths.update(imports_of(path))
    return paths


def build_package_graph():
    graph = {}
    for base in (ROOT / "internal", ROOT / "cmd"):
        if not base.is_dir():
            continue
        for directory in sorted({path.parent for path in base.rglob("*.go")}):
            relative_directory = relative(directory)
            targets = set()
            for import_path in directory_imports(directory):
                target = import_to_directory(import_path)
                if target is not None:
                    targets.add(target)
            graph[relative_directory] = targets
    return graph


def reachable_packages(graph, starts):
    seen = set()
    frontier = list(starts)
    while frontier:
        current = frontier.pop()
        if current in seen or current not in graph:
            continue
        seen.add(current)
        frontier.extend(graph[current])
    return seen


def application_systems():
    return sorted(
        path.name
        for path in APPLICATION_DIRECTORY.iterdir()
        if path.is_dir() and any(path.glob("*.go"))
    )


def package_purpose(name):
    directory = APPLICATION_DIRECTORY / name
    for path in sorted(directory.glob("*.go")):
        if path.name.endswith("_test.go"):
            continue
        lines = read_text(path).splitlines()
        for index, line in enumerate(lines):
            if not re.match(r"^package\s+" + re.escape(name) + r"\b", line):
                continue
            comment_lines = []
            previous = index - 1
            while previous >= 0 and lines[previous].startswith("//"):
                comment_lines.append(lines[previous])
                previous -= 1
            if not comment_lines:
                continue
            text = " ".join(
                (PACKAGE_COMMENT_RE.match(line).group(1).strip() if PACKAGE_COMMENT_RE.match(line) else "")
                for line in reversed(comment_lines)
            )
            text = re.sub(r"^Package\s+" + re.escape(name) + r"\s+", "", text).strip()
            return text.split(". ")[0].rstrip(".").strip()
    return ""


def run_helper():
    completed = subprocess.run(
        ["go", "run", HELPER],
        cwd=str(ROOT),
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        sys.stderr.write(completed.stderr)
        raise SystemExit("tools/system_map_mids failed")
    return json.loads(completed.stdout)


def refresh_client(source_directory):
    mid_file = source_directory / "app" / "common" / "network" / "mid.lua"
    if not mid_file.is_file():
        raise SystemExit("missing %s" % mid_file)
    names = {}
    for line in read_text(mid_file).splitlines():
        parsed = parse_mid_line(line)
        if parsed is None:
            continue
        names[parsed[1]] = parsed[0]
    if len(names) < 1000:
        raise SystemExit("mid.lua parsed only %d MIDs" % len(names))
    files_by_name = {name: set() for name in names.values()}
    senders_by_name = {name: set() for name in names.values()}
    other_by_name = {name: set() for name in names.values()}
    application = source_directory / "app"
    for path in sorted(application.rglob("*.lua")):
        if path == mid_file:
            continue
        used, senders, other = classify_client_lines(read_text(path))
        rel = relative_from(source_directory, path)
        for name in used:
            if name in files_by_name:
                files_by_name[name].add(rel)
        for name in senders:
            if name in senders_by_name:
                senders_by_name[name].add(rel)
        for name in other:
            if name in other_by_name:
                other_by_name[name].add(rel)
    output = {}
    for mid in sorted(names):
        name = names[mid]
        output[str(mid)] = {
            "name": name,
            "files": sorted(files_by_name[name]),
            "senders": sorted(senders_by_name[name]),
            "other": sorted(other_by_name[name]),
        }
    CLIENT_CALLERS.parent.mkdir(parents=True, exist_ok=True)
    CLIENT_CALLERS.write_text(json_text(output), encoding="utf-8")
    empty = sum(1 for entry in output.values() if not entry["files"])
    print("wrote %s (%d MIDs, %d without caller)" % (relative(CLIENT_CALLERS), len(output), empty))


def refresh_coverage(source):
    mids = sorted({
        int(line.strip())
        for line in read_text(source).splitlines()
        if line.strip().isdigit()
    })
    completed = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=str(ROOT), capture_output=True, text=True
    )
    commit = completed.stdout.strip() if completed.returncode == 0 else "unknown"
    payload = {"commit": commit, "mids": mids}
    SCENARIO_COVERAGE.write_text(json_text(payload), encoding="utf-8")
    print("wrote %s (%d MIDs, commit %s)" % (relative(SCENARIO_COVERAGE), len(mids), commit))


def load_coverage():
    if not SCENARIO_COVERAGE.is_file():
        return None
    return json.loads(read_text(SCENARIO_COVERAGE))


def relative_from(base, path):
    return path.relative_to(base).as_posix()


def load_client_callers():
    if not CLIENT_CALLERS.is_file():
        raise SystemExit(
            "missing %s; run --refresh-client <src_64>" % relative(CLIENT_CALLERS)
        )
    return json.loads(read_text(CLIENT_CALLERS))


def group_registrations(registrations):
    grouped = {}
    for entry in registrations:
        grouped.setdefault(entry["mid"], []).append(entry)
    for entries in grouped.values():
        entries.sort(key=lambda item: (item["registration_file"], item["registration_line"]))
    return grouped


def primary_owner(entries):
    for entry in entries:
        if entry.get("owner"):
            return entry["owner"], entry
    return None, entries[0]


def unresolved_reason(entries):
    reasons = sorted({entry.get("reason", "") for entry in entries if entry.get("reason")})
    if not reasons:
        return "no application system"
    return reasons[0]


def store_directories(registrations):
    stores = set()
    for entry in registrations:
        for store in entry.get("stores") or []:
            if store.startswith(POSTGRES_PREFIX):
                stores.add(store[len(MODULE_PATH):].rstrip("/"))
    return sorted(stores)


def store_matches(path, stores):
    normalized = path.rstrip("/")
    for store in stores:
        if normalized == store or normalized.startswith(store + "/"):
            return True
    return False


def store_owner_system(store, systems):
    stem = Path(store).name
    if stem.endswith("store"):
        stem = stem[: -len("store")]
    if stem in systems:
        return stem
    candidates = [name for name in systems if name.startswith(stem)]
    if len(candidates) == 1:
        return candidates[0]
    return None


def matching_stores(paths, stores):
    return [store for store in stores if any(store_matches(path, [store]) for path in paths)]


def scan_sql(tables):
    write_files = {}
    read_files = {}
    writers = {}
    table_names = set(tables)
    for path in sorted((ROOT / "internal" / "adapters" / "postgres").rglob("*.go")):
        if path.name.endswith("_test.go"):
            continue
        text = read_text(path)
        relative_path = relative(path)
        package = relative(path.parent)
        for pattern in (INSERT_RE, UPDATE_RE, DELETE_RE):
            for token in pattern.findall(text):
                table = normalize_table(token)
                if table not in table_names:
                    continue
                write_files.setdefault(table, set()).add(relative_path)
                writers.setdefault(table, set()).add(package)
        for token in FROM_RE.findall(text):
            table = normalize_table(token)
            if table in table_names:
                read_files.setdefault(table, set()).add(relative_path)
    sql_directory = ROOT / "sql"
    if sql_directory.is_dir():
        for path in sorted(sql_directory.rglob("*")):
            if not path.is_file():
                continue
            text = read_text(path)
            relative_path = relative(path)
            for pattern in (INSERT_RE, UPDATE_RE, DELETE_RE):
                for token in pattern.findall(text):
                    table = normalize_table(token)
                    if table in table_names:
                        write_files.setdefault(table, set()).add(relative_path)
            for token in FROM_RE.findall(text):
                table = normalize_table(token)
                if table in table_names:
                    read_files.setdefault(table, set()).add(relative_path)
    return write_files, read_files, writers


def scan_migrations():
    candidates = [path for path in ROOT.rglob("migrations") if path.is_dir() and any(path.glob("*.sql"))]
    if not candidates:
        return {}
    candidates.sort(key=lambda path: (len(path.parts), path.as_posix()))
    directory = candidates[0]
    tables = {}
    for path in sorted(directory.glob("*.sql")):
        for token in CREATE_TABLE_RE.findall(read_text(path)):
            tables.setdefault(normalize_table(token), set()).add(relative(path))
    return {table: sorted(files) for table, files in tables.items()}


def documentation_files():
    files = {}
    for base in (ROOT / "docs" / "i9", ROOT / "docs" / "architecture"):
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file() or path.suffix not in (".md", ".json", ".txt"):
                continue
            rel = relative(path)
            if path.name == "CANONICAL_TABLE_OWNERSHIP.json" or rel.startswith("docs/architecture/system_map/"):
                continue
            files[rel] = doc_tokens(read_text(path))
    return files


def build_system_map():
    helper = run_helper()
    client = load_client_callers()
    registrations = helper["registrations"]
    grouped = group_registrations(registrations)
    systems = application_systems()
    name_to_mid = {}
    for mid, entry in sorted(client.items(), key=lambda item: int(item[0])):
        name_to_mid.setdefault(entry["name"], int(mid))

    owners = {}
    for mid, entries in grouped.items():
        owners[mid] = primary_owner(entries)[0]

    ownership = json.loads(read_text(ROOT / "docs" / "architecture" / "CANONICAL_TABLE_OWNERSHIP.json"))
    ownership_tables = ownership["tables"]
    migration_tables = scan_migrations()
    _, _, writers = scan_sql(ownership_tables)
    documents = documentation_files()

    system_imports = {
        system: directory_imports(APPLICATION_DIRECTORY / system) for system in systems
    }
    graph = build_package_graph()
    command_starts = sorted(directory for directory in graph if directory.startswith("cmd/"))
    reachable = reachable_packages(graph, command_starts)
    unwired = sorted(system for system in systems if "internal/application/" + system not in reachable)

    scenario_directory = ROOT / "virtualclient" / "scenarios"
    scenario_files = {}
    if scenario_directory.is_dir():
        for path in sorted(scenario_directory.glob("*.json")):
            scenario_files[relative(path)] = scenario_mids(json.loads(read_text(path)), name_to_mid)

    system_entries_by_system = {
        system: [
            entry for mid, entries in grouped.items()
            for entry in entries
            if entry.get("owner") == system and owners[mid] == system
        ]
        for system in systems
    }
    system_stores = {
        system: store_directories(entries)
        for system, entries in system_entries_by_system.items()
    }
    store_counts = {}
    for stores in system_stores.values():
        for store in stores:
            store_counts[store] = store_counts.get(store, 0) + 1
    shared_stores = {
        store for store, count in store_counts.items() if count >= SHARED_STORE_SYSTEMS
    }

    system_records = {}
    for system in systems:
        directory = APPLICATION_DIRECTORY / system
        system_entries = system_entries_by_system[system]
        unique_mids = {}
        for entry in system_entries:
            unique_mids.setdefault(entry["mid"], entry)
        mid_rows = []
        for mid in sorted(unique_mids):
            entry = unique_mids[mid]
            client_entry = client.get(str(mid), {"name": "", "files": []})
            mid_rows.append({
                "mid": mid,
                "name": client_entry["name"],
                "dispatcher_file": entry["dispatcher_file"],
            })
        stores = system_stores[system]
        owner_tables = {
            table for table, record in ownership_tables.items()
            if owner_system_name(record.get("owner", ""), systems) == system
        }
        writable = {
            table for table, record in ownership_tables.items()
            if table_visible(record, stores, shared_stores, systems, system, "allowed_write_paths")
        }
        owned_tables = sorted(owner_tables | writable)
        read_tables = sorted(
            table for table, record in ownership_tables.items()
            if table_visible(record, stores, shared_stores, systems, system, "allowed_read_paths")
        )
        touched = set(owned_tables) | set(read_tables)

        imports = system_imports[system]
        calls = sorted({
            sys for sys in systems
            if sys != system and APPLICATION_PREFIX + sys in imports
        })
        called_by = sorted(
            other for other in systems
            if other != system and APPLICATION_PREFIX + system in system_imports[other]
        )

        wiring_files = {entry.get("construction_file", "") for entry in system_entries}
        wiring_files.discard("")
        wired_apps = set()
        for wiring_file in sorted(wiring_files):
            path = ROOT / wiring_file
            if not path.is_file():
                continue
            for import_path in imports_of(path):
                if import_path.startswith(APPLICATION_PREFIX):
                    wired_apps.add(import_path[len(APPLICATION_PREFIX):].rstrip("/"))
        wired_apps.discard(system)

        contract_files = []
        identifiers = {str(mid) for mid in unique_mids} | set(touched)
        for document, tokens in sorted(documents.items()):
            count = len(identifiers & tokens)
            if count:
                contract_files.append({"file": document, "count": count})

        pushes = []
        for push in helper["pushes"]:
            if push_system(push, systems) != system:
                continue
            row = {key: value for key, value in push.items() if key != "app_imports"}
            pushes.append(row)
        pushes.sort(key=lambda row: (row["kind"], row.get("mid", 0), row.get("parent_mid", 0), row["file"], row["line"], row.get("notice_type", 0)))

        unit_tests = sorted(relative(path) for path in directory.glob("*_test.go"))
        integration = []
        integration_root = ROOT / "internal" / "integration"
        if integration_root.is_dir():
            for candidate in sorted(integration_root.iterdir()):
                if not candidate.is_dir():
                    continue
                if any(APPLICATION_PREFIX + system in imports_of(path) for path in candidate.rglob("*.go")):
                    integration.append(relative(candidate))
        scenarios = sorted(
            scenario for scenario, mids in scenario_files.items()
            if mids & set(unique_mids)
        )

        system_records[system] = {
            "name": system,
            "path": "internal/application/" + system,
            "mids": mid_rows,
            "pushes": pushes,
            "tables": {"owned": owned_tables, "read": read_tables},
            "calls": calls,
            "called_by": called_by,
            "wired_with": sorted(wired_apps),
            "stores": stores,
            "wiring_files": sorted({entry.get("wiring_file", entry["registration_file"]) for entry in system_entries}),
            "contracts": contract_files,
            "tests": {"unit": unit_tests, "integration": integration, "scenarios_naming": scenarios},
        }

    index_rows = []
    mid_to_system = {}
    table_systems = {}
    for system in systems:
        record = system_records[system]
        index_rows.append({
            "name": system,
            "path": record["path"],
            "purpose": package_purpose(system),
            "mids": len(record["mids"]),
            "tables": len(record["tables"]["owned"]),
            "callers": len(record["called_by"]),
            "callees": len(record["calls"]),
        })
        for row in record["mids"]:
            mid_to_system.setdefault(str(row["mid"]), system)
        for table in record["tables"]["owned"]:
            table_systems.setdefault(table, []).append(system)

    table_to_system = {}
    for table, candidates in sorted(table_systems.items()):
        preferred = owner_system_name(ownership_tables[table].get("owner", ""), systems)
        if preferred in candidates:
            table_to_system[table] = preferred
        else:
            table_to_system[table] = sorted(candidates)[0]

    index = {
        "systems": index_rows,
        "lookups": {"mid_to_system": mid_to_system, "table_to_system": table_to_system},
    }

    inactive_mids = sorted(
        mid for mid, entries in grouped.items() if all(entry.get("fallback") for entry in entries)
    )
    inactive_set = set(inactive_mids)
    unattributed = []
    for mid in sorted(grouped):
        if owners[mid] is not None or mid in inactive_set:
            continue
        client_entry = client.get(str(mid), {"name": "", "files": []})
        unattributed.append({
            "mid": mid,
            "name": client_entry["name"],
            "client_files": client_entry["files"],
            "reason": unresolved_reason(grouped[mid]),
        })

    coverage = load_coverage()
    coverage_note = None
    live_not_covered = []
    if coverage is None:
        coverage_note = "scenario_coverage.json absent; run --refresh-coverage <file> after a full suite"
    else:
        covered = set(coverage.get("mids") or [])
        live_not_covered = [
            {
                "mid": mid,
                "name": client.get(str(mid), {"name": ""})["name"],
                "system": owners[mid],
            }
            for mid in sorted(grouped)
            if owners[mid] is not None and mid not in covered and mid not in inactive_set
        ]

    live_without_caller = []
    for mid in sorted(grouped):
        client_entry = client.get(str(mid))
        if client_entry and client_entry["files"]:
            continue
        live_without_caller.append({
            "mid": mid,
            "name": client_entry["name"] if client_entry else "",
            "system": owners[mid] or "",
        })

    client_not_live = []
    for raw_mid, client_entry in sorted(client.items(), key=lambda item: int(item[0])):
        if not client_entry["files"] or int(raw_mid) in grouped:
            continue
        client_not_live.append({
            "mid": int(raw_mid),
            "name": client_entry["name"],
            "files": client_entry["files"],
        })

    several_writers = []
    for table in sorted(writers):
        if len(writers[table]) <= 1:
            continue
        allowed = ownership_tables[table].get("allowed_write_paths", []) + [
            entry["path"] for entry in ownership_tables[table].get("write_exceptions", []) if isinstance(entry, dict)
        ]
        several_writers.append({
            "table": table,
            "packages": sorted(writers[table]),
            "declared": all(any(store_matches(path, [package]) for path in allowed) for package in writers[table]),
        })

    without_owner = []
    for table in sorted(migration_tables):
        if table in ownership_tables:
            continue
        without_owner.append({"table": table, "migrations": migration_tables[table]})

    findings = {
        "note": "These lists are leads for a reviewer, not verdicts. Confirm each entry against the source it cites.",
        "client_mids_not_live": client_not_live,
        "inactive_mids": {"count": len(inactive_mids), "mids": inactive_mids},
        "live_mids_not_covered": live_not_covered,
        "live_mids_without_client_caller": live_without_caller,
        "systems_not_wired": unwired,
        "tables_with_several_writers": several_writers,
        "tables_without_owner_row": without_owner,
        "unattributed_mids": unattributed,
    }
    if coverage_note:
        findings["live_mids_not_covered_note"] = coverage_note

    files = {"INDEX.json": json_text(index), "FINDINGS.json": findings_text(findings)}
    for system, record in system_records.items():
        files["systems/" + system + ".json"] = json_text(record)
    return files


def findings_text(findings):
    return json.dumps(findings, indent=1, ensure_ascii=False) + "\n"


def table_visible(record, stores, shared_stores, systems, system, path_key):
    paths = list(record.get(path_key, []))
    if path_key == "allowed_write_paths":
        paths += [entry["path"] for entry in record.get("write_exceptions", []) if isinstance(entry, dict)]
    matching = matching_stores(paths, stores)
    if not matching:
        return False
    if owner_system_name(record.get("owner", ""), systems) == system:
        return True
    if any(store not in shared_stores for store in matching):
        return True
    return any(store_owner_system(store, systems) == system for store in matching)


def owner_system_name(owner, systems):
    token = re.sub(r"[^a-z0-9]", "", owner.lower())
    if not token:
        return None
    for system in sorted(systems, key=lambda name: (-len(name), name)):
        if token == system or token.startswith(system) or token.endswith(system):
            return system
    return None


def push_system(push, systems):
    base = Path(push["file"]).stem
    for suffix in ("_notice", "_delivery", "_events", "_reload"):
        if base.endswith(suffix):
            base = base[: -len(suffix)]
            break
    token = base.replace("_", "")
    for system in sorted(systems, key=lambda name: (-len(name), name)):
        if token == system or token.startswith(system):
            return system
    imports = push.get("app_imports") or []
    if len(imports) == 1:
        return imports[0]
    return None


def write_output(files):
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    SYSTEMS_DIRECTORY.mkdir(parents=True, exist_ok=True)
    expected = set(files)
    for relative_path, content in sorted(files.items()):
        path = OUTPUT_DIRECTORY / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    for path in sorted(SYSTEMS_DIRECTORY.glob("*.json")):
        if "systems/" + path.name in expected:
            continue
        path.unlink()
    print("wrote %d files under %s" % (len(files), relative(OUTPUT_DIRECTORY)))


def check_output(files):
    differences = []
    for relative_path, content in sorted(files.items()):
        path = OUTPUT_DIRECTORY / relative_path
        if not path.is_file() or read_text(path) != content:
            differences.append(relative_path)
    expected = set(files)
    for path in sorted(SYSTEMS_DIRECTORY.glob("*.json")):
        if "systems/" + path.name not in expected:
            differences.append("systems/" + path.name)
    if not differences:
        print("system map is current")
        return 0
    for difference in differences:
        print("stale: %s" % difference)
    return 1


def show_entry(key):
    index = json.loads(read_text(OUTPUT_DIRECTORY / "INDEX.json"))
    if key in {row["name"] for row in index["systems"]}:
        print(json.dumps(json.loads(read_text(SYSTEMS_DIRECTORY / (key + ".json"))), indent=1, ensure_ascii=False))
        return
    if key.isdigit():
        system = index["lookups"]["mid_to_system"].get(key)
        if system is None:
            raise SystemExit("MID %s is not attributed to a system" % key)
        record = json.loads(read_text(SYSTEMS_DIRECTORY / (system + ".json")))
        rows = [row for row in record["mids"] if str(row["mid"]) == key]
        client = load_client_callers().get(key, {"name": "", "files": [], "senders": [], "other": []})
        print(json.dumps({
            "system": system,
            "mid": rows[0] if rows else None,
            "client": client,
        }, indent=1, ensure_ascii=False))
        return
    system = index["lookups"]["table_to_system"].get(key)
    ownership = json.loads(read_text(ROOT / "docs" / "architecture" / "CANONICAL_TABLE_OWNERSHIP.json"))["tables"]
    write_files, read_files, writers = scan_sql(ownership)
    record = ownership.get(key)
    output = {
        "system": system,
        "table": key,
        "owner": record.get("owner") if record else None,
        "allowed_write_paths": record.get("allowed_write_paths", []) if record else [],
        "allowed_read_paths": record.get("allowed_read_paths", []) if record else [],
        "sql_writes": sorted(write_files.get(key, [])),
        "sql_reads": sorted(read_files.get(key, [])),
        "writer_packages": sorted(writers.get(key, [])),
    }
    if system is not None:
        system_record = json.loads(read_text(SYSTEMS_DIRECTORY / (system + ".json")))
        output["owned"] = key in system_record["tables"]["owned"]
        output["read"] = key in system_record["tables"]["read"]
    print(json.dumps(output, indent=1, ensure_ascii=False))


def main():
    self_check()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--refresh-client", metavar="SRC_64")
    parser.add_argument("--refresh-coverage", metavar="FILE")
    parser.add_argument("words", nargs="*")
    arguments = parser.parse_args()
    if arguments.refresh_client:
        refresh_client(Path(arguments.refresh_client).resolve())
        return 0
    if arguments.refresh_coverage:
        refresh_coverage(Path(arguments.refresh_coverage).resolve())
        return 0
    if arguments.write:
        write_output(build_system_map())
        return 0
    if arguments.check:
        return check_output(build_system_map())
    if arguments.words:
        words = arguments.words
        if len(words) == 2 and words[0] == "show":
            show_entry(words[1])
            return 0
        if len(words) == 1:
            show_entry(words[0])
            return 0
    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
