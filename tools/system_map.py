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
    assert balanced_span("f(a(b), c)", 1) == "(a(b), c)"
    assert defined_callables("func (s Service) Apply(c context.Context) error") == {"Apply": True}
    assert defined_callables("func Accessor() int") == {"Accessor": False}
    assert duration_milliseconds("500 * time.Millisecond") == 500
    assert duration_milliseconds("5 * time.Second") == 5000
    store_edge = [{"from": "x", "to": "store:internal/adapters/postgres/i4store", "method": "FindTx", "via_port": False}]
    assert top_level_names("a.B{X: f(1, 2)}, c.D{}, e") == ["a.B", "c.D", "e"]
    assert typed_calls(["x"], store_edge) == {"x": {"store:i4store": ["FindTx"]}}
    self_edge = [{"from": "x", "to": "x", "method": "FindTx", "via_port": False}]
    assert typed_calls(["x"], self_edge) == {"x": {}}
    assert json_text({"b": 1, "a": [2, 1]}) == '{\n "a": [\n  2,\n  1\n ],\n "b": 1\n}\n'
    trace = "Service.SettleGrantTx internal/application/i5/service.go:240\n  sql: write mail_records"
    anchors = ["Service.SettleGrantTx internal/application/i5/service.go:", "mail_records"]
    assert missing_trace_anchors(trace, anchors) == []
    assert missing_trace_anchors(trace.replace(":240", ":999"), anchors) == []
    assert missing_trace_anchors(trace.replace("Service.SettleGrantTx", "Service.Other"), anchors) == anchors[:1]
    assert missing_trace_anchors(trace.replace("application/i5/", "application/other/"), anchors) == anchors[:1]
    assert missing_trace_anchors(trace.replace("mail_records", "other_table"), anchors) == anchors[1:]


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


def run_helper(arguments=None):
    completed = subprocess.run(
        ["go", "run", HELPER] + list(arguments or []),
        cwd=str(ROOT),
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        sys.stderr.write(completed.stderr)
        raise SystemExit("tools/system_map_mids failed")
    return json.loads(completed.stdout)


def helper_trace(mid):
    completed = subprocess.run(
        ["go", "run", HELPER, "--trace", str(mid)],
        cwd=str(ROOT),
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        sys.stderr.write(completed.stderr)
        raise SystemExit("tools/system_map_mids --trace %s failed" % mid)
    return completed.stdout


TRACE_LOCAL_FUNCTION_VALUES = {
    "cancel", "release", "body", "acqCancel", "txCancel", "reconcileCancel",
}
TRACE_FANOUT_PATTERN = re.compile(r"^(FANOUT .*? has (\d+) implementers, not followed: )(.*)$")


def trace_indent(line):
    return len(line) - len(line.lstrip(" "))


def trace_call_line(line):
    value = line.lstrip()
    if not value or value.startswith(("MID ", "sql: ", "facts: ", "FANOUT ", "UNRESOLVED ", "BOUND ", "push: ")):
        return False
    return "(seen above, touches tables)" not in value


def trace_marker_line(line):
    value = line.lstrip()
    return value.startswith(("sql: ", "facts: ", "FANOUT ", "UNRESOLVED ", "BOUND ", "push: "))


def compact_fanout(line):
    match = TRACE_FANOUT_PATTERN.match(line.lstrip())
    if not match:
        return line
    implementer_count = int(match.group(2))
    names = match.group(3).split(", ")
    if implementer_count <= 5 or len(names) <= 5:
        return line
    shortened = ", ".join(names[:5]) + ", ... (+%d more)" % (implementer_count - 5)
    return line[:trace_indent(line)] + match.group(1) + shortened


def compact_trace(output):
    lines = output.splitlines()
    if not lines:
        return output

    authorization_root = next(
        (index for index, line in enumerate(lines)
         if line.lstrip().startswith("RealtimeAuthority.ResolveGameplayBearer ")),
        None,
    )
    hidden_authorization_lines = set()
    authorization_summary = {}
    if authorization_root is not None:
        authorization_indent = trace_indent(lines[authorization_root])
        authorization_end = authorization_root + 1
        while authorization_end < len(lines) and trace_indent(lines[authorization_end]) > authorization_indent:
            authorization_end += 1
        hidden_authorization_lines = set(range(authorization_root + 1, authorization_end))
        hidden_call_count = sum(trace_call_line(lines[index]) for index in hidden_authorization_lines)
        authorization_summary[authorization_root] = (
            lines[authorization_root] + " (shared auth path summarized; %d calls omitted)" % hidden_call_count
        )

    unresolved_function_value_lines = {}
    call_frame_stack = []
    for index, line in enumerate(lines):
        indent = trace_indent(line)
        while call_frame_stack and call_frame_stack[-1][0] >= indent:
            call_frame_stack.pop()
        value = line.lstrip()
        if value.startswith("UNRESOLVED "):
            local_function_value = value[len("UNRESOLVED "):]
            if local_function_value in TRACE_LOCAL_FUNCTION_VALUES:
                parent = call_frame_stack[-1][1] if call_frame_stack else None
                unresolved_function_value_lines.setdefault(parent, []).append(index)
        if trace_call_line(line):
            call_frame_stack.append((indent, index))

    closure_summaries = {}
    hidden_closure_lines = set()
    for unresolved_line_indexes in unresolved_function_value_lines.values():
        first = unresolved_line_indexes[0]
        closure_summaries[first] = " " * trace_indent(lines[first]) + (
            "UNRESOLVED local function values: %d" % len(unresolved_line_indexes)
        )
        hidden_closure_lines.update(unresolved_line_indexes[1:])

    keep = [True] * len(lines)
    for index, line in enumerate(lines):
        if index in hidden_authorization_lines and not trace_marker_line(line):
            keep[index] = False
            continue
        if index in hidden_closure_lines:
            keep[index] = False
            continue
        if not trace_call_line(line):
            continue
        if "internal/application/" in line or "(seen above, touches tables)" in line:
            continue
        if index == authorization_root:
            continue
        has_child = index + 1 < len(lines) and trace_indent(lines[index + 1]) > trace_indent(line)
        if not has_child:
            keep[index] = False

    compacted = []
    for index, line in enumerate(lines):
        if not keep[index]:
            continue
        if index in authorization_summary:
            line = authorization_summary[index]
        if index in closure_summaries:
            line = closure_summaries[index]
        compacted.append(compact_fanout(line))
    return "\n".join(compacted) + ("\n" if output.endswith("\n") else "")


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


def store_matches(path, stores):
    normalized = path.rstrip("/")
    for store in stores:
        if normalized == store or normalized.startswith(store + "/"):
            return True
    return False


def reached_stores(system, edges):
    return sorted({
        edge["store"]
        for edge in edges
        if edge["from"] == system and edge.get("store")
    })


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



GO_FUNC_DEF_RE = re.compile(r"(?m)^func\s+(?:\([^)]*\)\s*)?([A-Z][A-Za-z0-9_]*)\s*\(([^)]*)\)")
LOCK_CONST_RE = re.compile(r"([A-Za-z0-9_]*LockRank[A-Za-z0-9_]*)\s*(?:uint16)?\s*=\s*(?:uint16\()?(\d+)")
PROFILE_RE = re.compile(r"tx\.Profile\{Name:\s*\"([^\"]+)\"[^\n]*?LockTimeout:\s*([0-9]+\s*\*\s*time\.(?:Second|Millisecond|Minute)|[0-9]+)")
DURATION_UNITS = {"Second": 1000, "Millisecond": 1, "Minute": 60000}


def balanced_span(text, start, opening="(", closing=")"):
    depth = 0
    for index in range(start, len(text)):
        character = text[index]
        if character == opening:
            depth += 1
        elif character == closing:
            depth -= 1
            if depth == 0:
                return text[start:index + 1]
    return text[start:]


def defined_callables(text):
    return {
        name: bool(parameters.strip())
        for name, parameters in GO_FUNC_DEF_RE.findall(text)
    }


def cross_system_calls(systems, system_imports, system_texts):
    defined = {system: defined_callables(system_texts[system]) for system in systems}
    owners = {}
    for system, names in defined.items():
        for name in names:
            owners.setdefault(name, set()).add(system)
    calls = {}
    for system in systems:
        edges = {}
        for target in systems:
            if target == system or APPLICATION_PREFIX + target not in system_imports[system]:
                continue
            used = sorted(
                name for name, has_parameters in defined[target].items()
                if has_parameters and len(owners[name]) == 1
                and re.search(r"\." + re.escape(name) + r"\s*\(", system_texts[system])
            )
            if used:
                edges[target] = used
        calls[system] = edges
    return calls


def inverse_calls(systems, calls):
    inverse = {system: {} for system in systems}
    for source, edges in calls.items():
        for target, names in edges.items():
            if target not in inverse:
                continue
            inverse[target][source] = names
    return inverse


def fact_constants():
    constants = {}
    for path in sorted((ROOT / "internal" / "domain" / "objective").glob("*.go")):
        if path.name.endswith("_test.go"):
            continue
        for name, value in re.findall(r'([A-Za-z0-9_]+)\s*=\s*"([A-Z0-9_]+)"', read_text(path)):
            constants[name] = value
    catalog = ROOT / "internal" / "domain" / "adventure" / "catalog.go"
    if catalog.is_file():
        for name, value in re.findall(r'([A-Za-z0-9_]+)\s*=\s*(?:objective\.)?("?[A-Za-z0-9_]+"?)', read_text(catalog)):
            value = value.strip('"')
            constants.setdefault(name, constants.get(value, value))
    return constants


def fact_literals(text, constants):
    found = set()
    for match in re.finditer(r"objective\.Fact\{", text):
        span = balanced_span(text, match.end() - 1, "{", "}")
        for value in re.findall(r'Kind:\s*"([A-Z0-9_]+)"', span):
            found.add(value)
        for name in re.findall(r"Kind:\s*objective\.([A-Za-z0-9_]+)", span):
            if name in constants:
                found.add(constants[name])
        for name in re.findall(r"Kind:\s*([A-Za-z0-9_]+)", span):
            if name in constants:
                found.add(constants[name])
    return found


def emitted_facts(text, constants):
    if "RecordTx(" not in text and "objective.Fact{" not in text:
        return set()
    return fact_literals(text, constants)


def adventure_read_facts(constants):
    path = ROOT / "internal" / "domain" / "adventure" / "catalog.go"
    if not path.is_file():
        return set()
    text = read_text(path)
    match = re.search(r"func EventForFactKind\(kind string\).*?switch kind \{(.*?)default:", text, re.S)
    if not match:
        return set()
    names = re.findall(r"case\s+([A-Za-z0-9_]+):", match.group(1))
    return {constants[name] for name in names if name in constants}


def read_facts(system, text, constants):
    if system == "i5":
        return set(re.findall(r'AcceptedFactKind\s*==\s*"([A-Z0-9_]+)"', text))
    if system == "adventure":
        return adventure_read_facts(constants)
    return set()


def import_aliases(path):
    text = read_text(path)
    aliases = {}
    for block in IMPORT_BLOCK_RE.findall(text):
        for line in block.splitlines():
            match = re.match(r'^\s*(?:([A-Za-z0-9_.]+)\s+)?"([^"]+)"\s*$', line)
            if not match:
                continue
            alias = match.group(1) or match.group(2).split("/")[-1]
            aliases[alias] = match.group(2)
    for line in text.splitlines():
        if not line.startswith("import "):
            continue
        match = re.match(r'^import\s+(?:([A-Za-z0-9_.]+)\s+)?"([^"]+)"', line)
        if match:
            alias = match.group(1) or match.group(2).split("/")[-1]
            aliases[alias] = match.group(2)
    return aliases


def login_contributors(systems):
    path = ROOT / "cmd" / "gxb-api" / "main_postgres.go"
    text = read_text(path)
    start = text.find("i4store.BootstrapService{")
    if start < 0:
        return {}
    block = balanced_span(text, start + len("i4store.BootstrapService") - 1, "{", "}")
    aliases = import_aliases(path)
    result = {}
    for field in ("PersistenceContributors", "LoginReconcilers", "DetailContributors", "DirectoryReconciler"):
        for line in block.splitlines():
            if field + ":" not in line:
                continue
            value = line.split(field + ":", 1)[1]
            for package, name in re.findall(r"([a-z][A-Za-z0-9_]*)\.([A-Z][A-Za-z0-9_]*)", value):
                if not name.endswith(("Projection", "Bootstrap", "Reconciler", "Contributor")):
                    continue
                import_path = aliases.get(package)
                if not import_path or import_path == APPLICATION_PREFIX + "bootstrap":
                    continue
                if import_path.startswith(APPLICATION_PREFIX):
                    result.setdefault(import_path[len(APPLICATION_PREFIX):].rstrip("/"), set()).add(name)
                    continue
                if not import_path.startswith(POSTGRES_PREFIX):
                    continue
                adapter = ROOT / import_path[len(MODULE_PATH):]
                apps = set()
                for go_path in go_files(adapter):
                    for imported in imports_of(go_path):
                        if imported.startswith(APPLICATION_PREFIX):
                            apps.add(imported[len(APPLICATION_PREFIX):].rstrip("/"))
                apps.discard("bootstrap")
                if len(apps) == 1:
                    result.setdefault(next(iter(apps)), set()).add(name)
    for system in systems:
        text = system_source(system)
        for name in re.findall(r"func\s+\([^)]*\)\s+(OverlayMID1|OverlayRosterTx|ReconcileCharacterLogin|ReconcileDirectoryTx)\s*\(", text):
            result.setdefault(system, set()).add(name)
    return result


def system_source(system):
    return "\n".join(read_text(path) for path in go_files(APPLICATION_DIRECTORY / system))


def background_rows(systems, system_imports, system_texts):
    rows = {system: [] for system in systems}
    command_directory = ROOT / "cmd" / "gxb-api"
    for path in sorted(command_directory.glob("*.go")):
        if path.name.endswith("_test.go"):
            continue
        aliases = import_aliases(path)
        text = read_text(path)
        for alias in re.findall(r"go\s+runReconcile\([^)]*?,?\s*([A-Za-z0-9_]+)\.Reconciler\{", text):
            import_path = aliases.get(alias)
            if import_path and import_path.startswith(APPLICATION_PREFIX):
                system = import_path[len(APPLICATION_PREFIX):].rstrip("/")
                rows.setdefault(system, []).append({"kind": "reconcile", "binary": "gxb-api", "entry": alias + ".Reconciler"})
    worker_binaries = {}
    for binary_directory in sorted((ROOT / "cmd").iterdir()):
        if not binary_directory.is_dir():
            continue
        text = "\n".join(read_text(path) for path in go_files(binary_directory))
        for system in systems:
            if ("/" + system + "worker") in text:
                worker_binaries.setdefault(system, set()).add(binary_directory.name)
    for system in systems:
        text = system_texts[system]
        if "Enqueue.InsertTx(" not in text:
            continue
        enqueuers = sorted(
            binary.name for binary in (ROOT / "cmd").iterdir()
            if binary.is_dir() and any(
                system in read_text(path) and "river" in read_text(path)
                for path in go_files(binary)
            )
        )
        rows[system].append({
            "kind": "river",
            "enqueued_by": enqueuers,
            "workers": sorted(worker_binaries.get(system, [])),
        })
    return rows


def lock_constants():
    constants = {}
    for base in (ROOT / "internal" / "domain", APPLICATION_DIRECTORY):
        for path in go_files(base):
            package = path.parent.name
            for name, value in LOCK_CONST_RE.findall(read_text(path)):
                constants[package + "." + name] = int(value)
    return constants


def duration_milliseconds(raw):
    match = re.match(r"(\d+)\s*\*\s*time\.(\w+)", raw)
    if match:
        return int(match.group(1)) * DURATION_UNITS.get(match.group(2), 1)
    return int(raw)


def lock_rows(system, text, stores, constants):
    sources = [text] + [
        "\n".join(read_text(path) for path in go_files(ROOT / "internal" / "adapters" / "postgres" / store.split("/")[-1]))
        for store in stores
        if store.startswith("internal/adapters/postgres/")
    ]
    ranks = {}
    for source in sources:
        for reference in re.findall(r"([A-Za-z0-9_.]*LockRank[A-Za-z0-9_]*)", source):
            parts = reference.split(".")
            key = None
            if len(parts) == 2:
                key = parts[0] + "." + parts[1]
            elif len(parts) == 1:
                local = system + "." + parts[0]
                key = local if local in constants else None
                if key is None:
                    matches = [candidate for candidate in constants if candidate.endswith("." + parts[0])]
                    if len(matches) == 1:
                        key = matches[0]
            if key in constants:
                ranks[key] = constants[key]
    profiles = []
    for name, raw in PROFILE_RE.findall(text):
        profiles.append({"name": name, "lock_timeout_ms": duration_milliseconds(raw)})
    return {
        "ranks": [{"rank": ranks[key], "name": key} for key in sorted(ranks)],
        "profiles": sorted(profiles, key=lambda row: row["name"]),
    }


def soft_refusals(system_texts):
    rows = []
    dispatchers = ROOT / "internal" / "adapters" / "stockruntime"
    for path in go_files(dispatchers):
        if path.name.endswith("_test.go") or path.name == "inactive_dispatcher.go":
            continue
        text = read_text(path)
        for match in re.finditer(r'HTTPStatus:\s*http\.StatusOK[^\n}]*"error_code":\s*(?:int64\()?(\d+)', text):
            code = int(match.group(1))
            if code in (0, 30005):
                continue
            rows.append({"file": relative(path), "line": text.count("\n", 0, match.start()) + 1, "code": code, "kind": "code_1" if code == 1 else "stock_code"})
    for path in go_files(APPLICATION_DIRECTORY):
        text = read_text(path)
        for match in re.finditer(r'map\[string\]any\{\s*"error_code":\s*(?:int64\()?(\d+)', text):
            code = int(match.group(1))
            if code in (0, 30005):
                continue
            rows.append({"file": relative(path), "line": text.count("\n", 0, match.start()) + 1, "code": code, "kind": "code_1" if code == 1 else "stock_code"})
    return sorted(rows, key=lambda row: (row["file"], row["line"], row["code"]))


def enclosing_function(text, position):
    names = re.findall(r"(?m)^func\s+(?:\([^)]*\)\s*)?([A-Za-z0-9_]+)\s*\(", text[:position])
    return names[-1] if names else ""


def narrow_param_checks():
    rows = []
    directory = ROOT / "internal" / "adapters" / "stockruntime"
    for path in go_files(directory):
        if path.name.endswith("_test.go"):
            continue
        text = read_text(path)
        relative_path = relative(path)
        for match in re.finditer(r"allowed\s*:=\s*map\[string\](?:bool|struct\{\})\{", text):
            tail = text[match.start():match.start() + 1500]
            if "for k := range" in tail and ("!allowed[k]" in tail or "_, ok := allowed" in tail):
                rows.append({
                    "file": relative_path,
                    "line": text.count("\n", 0, match.start()) + 1,
                    "function": enclosing_function(text, match.start()),
                    "style": "allowed_map",
                })
        for match in re.finditer(r"for k := range (?:params|p)\s*\{", text):
            tail = text[match.start():match.start() + 300]
            if 'k != "mid"' in tail:
                rows.append({
                    "file": relative_path,
                    "line": text.count("\n", 0, match.start()) + 1,
                    "function": enclosing_function(text, match.start()),
                    "style": "inline_rejection",
                })
    return sorted(rows, key=lambda row: (row["file"], row["line"]))


def mode_surface():
    path = ROOT / "docs" / "i9" / "I9_MODE_SURFACE_V1.json"
    if not path.is_file():
        return {}
    return {entry["mid"]: entry for entry in json.loads(read_text(path)).get("mids", [])}


def system_read_facts(system, mission_map, adventure_events):
    if system == "i5":
        return {
            row["fact"]
            for key in ("tasks", "high_water", "entitlements")
            for row in mission_map.get(key, [])
        }
    if system == "adventure":
        return set(adventure_events)
    return set()


def content_tables(read_tables):
    return sorted(table for table in read_tables if table.startswith("content_"))



MISSION_TASK_RE = re.compile(r"(\d+):\s*\('([A-Z0-9_]+)',\s*'([^']*)'\)")
MISSION_HIGH_WATER_RE = re.compile(r"(\d+):\s*'([A-Z0-9_]+)'")
MISSION_ENTITLEMENT_RE = re.compile(r"(\d+):\s*'([A-Z0-9_]+)'")


def mission_mappings():
    path = ROOT / "tools" / "missions_content.py"
    if not path.is_file():
        return {"tasks": [], "high_water": [], "entitlements": []}
    text = read_text(path)
    delta_block = re.search(r"DELTA\s*=\s*\{(.*?)\n\}", text, re.S)
    high_block = re.search(r"HIGH_WATER\s*=\s*\{(.*?)\n\}", text, re.S)
    entitlement_block = re.search(r"ENTITLEMENTS\s*=\s*\{(.*?)\n\}", text, re.S)
    tasks = []
    for task_id, fact, stage in MISSION_TASK_RE.findall(delta_block.group(1) if delta_block else ""):
        tasks.append({"task": int(task_id), "fact": fact, "stage": stage or None})
    high_water = []
    for task_id, fact in MISSION_HIGH_WATER_RE.findall(high_block.group(1) if high_block else ""):
        high_water.append({"task": int(task_id), "fact": fact})
    update = re.search(r"HIGH_WATER\.update\(\{kind: '([A-Z0-9_]+)' for kind in \(\*range\((\d+),\s*(\d+)\),\s*([0-9,\s]+)\)\}\)", text)
    if update:
        fact, start, end, extras = update.group(1), int(update.group(2)), int(update.group(3)), update.group(4)
        for task_id in list(range(start, end)) + [int(value) for value in re.findall(r"\d+", extras)]:
            high_water.append({"task": task_id, "fact": fact})
    entitlements = []
    for task_id, fact in MISSION_ENTITLEMENT_RE.findall(entitlement_block.group(1) if entitlement_block else ""):
        entitlements.append({"task": int(task_id), "fact": fact})
    return {"tasks": tasks, "high_water": high_water, "entitlements": entitlements}


def adventure_fact_events(constants):
    path = ROOT / "internal" / "domain" / "adventure" / "catalog.go"
    if not path.is_file():
        return {}
    text = read_text(path)
    match = re.search(r"func EventForFactKind\(kind string\).*?switch kind \{(.*?)default:", text, re.S)
    if not match:
        return {}
    events = {}
    for name, event in re.findall(r"case\s+([A-Za-z0-9_]+):\s*return\s+Profile\((\w+)\)", match.group(1)):
        if name in constants:
            events[constants[name]] = event
    return events


def fact_consumers(missions, adventure_events):
    consumers = {}
    for row in missions["tasks"]:
        consumers.setdefault(row["fact"], {"missions": [], "stages": []})
        consumers[row["fact"]]["missions"].append(row["task"])
        if row["stage"]:
            consumers[row["fact"]]["stages"].append(row["stage"])
    for row in missions["high_water"]:
        consumers.setdefault(row["fact"], {"missions": [], "stages": []})
        consumers[row["fact"]].setdefault("high_water", []).append(row["task"])
    for row in missions["entitlements"]:
        consumers.setdefault(row["fact"], {"missions": [], "stages": []})
        consumers[row["fact"]].setdefault("entitlements", []).append(row["task"])
    for fact, event in adventure_events.items():
        consumers.setdefault(fact, {"missions": [], "stages": []})
        consumers[fact]["adventure"] = event
    for value in consumers.values():
        for key in ("missions", "high_water", "entitlements"):
            if key in value:
                value[key] = sorted(set(value[key]))
        value["stages"] = sorted(set(value["stages"]))
        for key in [key for key, item in value.items() if item == []]:
            del value[key]
    return consumers


def typed_calls(systems, edges):
    calls = {system: {} for system in systems}
    for edge in edges:
        source = edge["from"]
        if source not in calls:
            continue
        target = edge["to"]
        if target.startswith("store:"):
            target = "store:" + Path(target[len("store:"):]).name
        if target == source:
            continue
        if target.startswith("interface:"):
            name = target[len("interface:"):]
            name = name[len(APPLICATION_PREFIX):] if name.startswith(APPLICATION_PREFIX) else name
            target = "interface:" + name
        method = ("*" if edge["via_port"] else "") + edge["method"]
        calls[source].setdefault(target, set()).add(method)
    return {system: {target: sorted(methods) for target, methods in sorted(edges.items())} for system, edges in calls.items()}


def store_callers(edges):
    callers = {}
    for edge in edges:
        store = edge.get("store")
        if store:
            callers.setdefault((store, edge["method"]), set()).add(edge["from"])
    return callers


def client_senders_without_live_handler(client, grouped):
    status_counts = {
        "inactive_fallback": 0,
        "no_registration": 0,
        "unattributed_registration": 0,
        "registration_without_dispatch_handler": 0,
    }
    rows = []
    window_sender_mid_count = 0
    for raw_mid, client_entry in sorted(client.items(), key=lambda item: int(item[0])):
        sender_files = client_entry.get("senders") or []
        if not sender_files:
            continue
        mid = int(raw_mid)
        registrations = grouped.get(mid, [])
        has_live_handler = any(
            not registration.get("fallback")
            and registration.get("owner")
            and registration.get("handler_file")
            for registration in registrations
        )
        if has_live_handler:
            continue
        non_fallback_registrations = [
            registration for registration in registrations if not registration.get("fallback")
        ]
        if not registrations:
            status = "no_registration"
        elif not non_fallback_registrations:
            status = "inactive_fallback"
        elif all(not registration.get("owner") for registration in non_fallback_registrations):
            status = "unattributed_registration"
        else:
            status = "registration_without_dispatch_handler"
        window_sender_files = [
            sender_file for sender_file in sender_files if sender_file.startswith("app/windows/")
        ]
        if window_sender_files:
            window_sender_mid_count += 1
        status_counts[status] += 1
        rows.append({
            "mid": mid,
            "name": client_entry["name"],
            "registration_status": status,
            "senders": sender_files,
            "window_sender_files": window_sender_files,
            "non_window_sender_files": [
                sender_file for sender_file in sender_files
                if not sender_file.startswith("app/windows/")
            ],
            "runtime_reachability": "unknown",
        })
    return {
        "count": len(rows),
        "window_sender_mid_count": window_sender_mid_count,
        "non_window_sender_mid_count": len(rows) - window_sender_mid_count,
        "registration_status_counts": status_counts,
        "runtime_reachability": "unknown from source-file references alone",
        "mids": rows,
    }


def login_composition():
    path = ROOT / "cmd" / "gxb-api" / "main_postgres.go"
    text = read_text(path)
    start = text.find("i4store.BootstrapService{")
    block = balanced_span(text, start + len("i4store.BootstrapService") - 1, "{", "}")
    rows = {}
    for field in ("LoginReconcilers", "DetailContributors"):
        match = re.search(field + r":\s*\[\][\w.]+\{", block)
        if not match:
            raise SystemExit("login composition field missing: " + field)
        rows[field] = top_level_names(balanced_span(block, match.end() - 1, "{", "}")[1:-1])
    return rows


def top_level_names(body):
    names = []
    depth = 0
    at_start = True
    for index, character in enumerate(body):
        if at_start and not character.isspace():
            names.append(re.match(r"[\w.]+", body[index:]).group(0))
            at_start = False
        if character in "{([":
            depth += 1
        elif character in "})]":
            depth -= 1
        elif character == "," and depth == 0:
            at_start = True
    return names


def row_lock_methods_by_system(systems, locks, callers):
    rows = {system: {} for system in systems}
    for lock in locks:
        if not lock["table"]:
            continue
        store = lock["store"].rsplit("/", 1)[-1]
        for method in [lock.get("method", "")] + list(lock.get("callers") or []):
            for system in callers.get((lock["store"], method), set()):
                if system in rows:
                    rows[system].setdefault(lock["table"], set()).add(store + "." + method)
    return {
        system: {table: sorted(methods) for table, methods in sorted(tables.items())}
        for system, tables in rows.items()
    }


def row_locks_by_system(systems, locks, callers):
    rows = {system: set() for system in systems}
    for lock in locks:
        if not lock["table"]:
            continue
        methods = [lock.get("method", "")] + list(lock.get("callers") or [])
        for method in methods:
            for system in callers.get((lock["store"], method), set()):
                if system in rows:
                    rows[system].add(lock["table"])
    return {system: sorted(tables) for system, tables in rows.items()}


def build_system_map():
    helper = run_helper()
    typed = helper["typed"]
    if typed.get("analysis_errors"):
        raise SystemExit("typed analysis incomplete: " + "; ".join(typed["analysis_errors"]))
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
    system_texts = {system: system_source(system) for system in systems}
    call_edges = typed_calls(systems, typed["edges"])
    reverse_call_edges = inverse_calls(systems, call_edges)
    fact_kinds = fact_constants()
    emitted_by_system = {row["system"]: row["kinds"] for row in typed.get("facts", [])}
    emitted_all = set()
    for kinds in emitted_by_system.values():
        emitted_all.update(kinds)
    mission_map = mission_mappings()
    adventure_events = adventure_fact_events(fact_kinds)
    fact_consumer_map = fact_consumers(mission_map, adventure_events)
    lock_callers = store_callers(typed["edges"])
    system_row_lock_methods = row_lock_methods_by_system(systems, typed.get("row_locks", []), lock_callers)
    system_row_locks = row_locks_by_system(systems, typed.get("row_locks", []), lock_callers)
    unresolved_lock_methods = {system: set() for system in systems}
    for lock in typed.get("row_locks", []):
        if lock["table"]:
            continue
        for method in [lock["method"]] + list(lock.get("callers") or []):
            for system in lock_callers.get((lock["store"], method), set()):
                if system in unresolved_lock_methods:
                    unresolved_lock_methods[system].add(lock["store"].rsplit("/", 1)[-1] + "." + method)
    login_sets = login_contributors(systems)
    background = background_rows(systems, system_imports, system_texts)
    lock_rank_constants = lock_constants()
    modes = mode_surface()
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
        system: reached_stores(system, typed["edges"])
        for system in systems
    }

    system_pushes, unattributed_pushes = partition_pushes(helper["pushes"], systems)
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
            row = {
                "mid": mid,
                "name": client_entry["name"],
            }
            if entry.get("handler_file"):
                row["handler"] = {"file": entry["handler_file"], "line": entry.get("handler_line", 0)}
            mid_rows.append(row)
        stores = system_stores[system]
        owned_tables = sorted(
            table for table, record in ownership_tables.items()
            if owner_system_name(record.get("owner", ""), systems) == system
        )
        system_tables = typed["tables"].get(system, {})
        read_tables = sorted(set(system_tables.get("read") or []) & set(ownership_tables))
        written_tables = sorted(set(system_tables.get("written") or []) & set(ownership_tables))
        touched = set(owned_tables) | set(read_tables) | set(written_tables)

        decorated = set()
        for mid, entry in unique_mids.items():
            if owners[mid] == system:
                decorated.update(entry.get("wrappers") or [])

        contract_files = []
        identifiers = {str(mid) for mid in unique_mids} | set(touched)
        for document, tokens in sorted(documents.items()):
            count = len(identifiers & tokens)
            if count:
                contract_files.append({"file": document, "count": count})

        pushes = system_pushes[system]
        pushes.sort(key=lambda row: (row["kind"], row.get("mid", 0), row.get("parent_mid", 0), row["file"], row["line"], row.get("notice_type", 0)))

        unit_tests = sorted(path.name for path in directory.glob("*_test.go"))
        integration = []
        integration_root = ROOT / "internal" / "integration"
        if integration_root.is_dir():
            for candidate in sorted(integration_root.iterdir()):
                if not candidate.is_dir():
                    continue
                if any(APPLICATION_PREFIX + system in imports_of(path) for path in candidate.rglob("*.go")):
                    integration.append(candidate.name)
        scenarios = sorted(
            Path(scenario).name for scenario, mids in scenario_files.items()
            if mids & set(unique_mids)
        )

        system_records[system] = {
            "name": system,
            "mids": mid_rows,
            "pushes": pushes,
            "tables": {"owned": owned_tables, "read": read_tables, "written": written_tables},

            "decorated_by": sorted(decorated),
            "facts": {
                "emits": sorted(emitted_by_system.get(system, [])),
                "reads": sorted(system_read_facts(system, mission_map, adventure_events)),
                "consumers": {
                    kind: fact_consumer_map[kind]
                    for kind in sorted(emitted_by_system.get(system, []))
                    if kind in fact_consumer_map
                },
            },
            "login": sorted(login_sets.get(system, [])),
            "background": background.get(system, []),
            "locks": dict(lock_rows(system, system_texts[system], stores, lock_rank_constants), row_locks=system_row_locks.get(system, []), row_lock_methods=system_row_lock_methods.get(system, {}), unresolved_methods=sorted(unresolved_lock_methods[system])),
            "content": content_tables(read_tables),
            "dispatcher_files": sorted({entry["dispatcher_file"] for entry in system_entries if entry["dispatcher_file"]}),
            "stores": stores,
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
            "path": "internal/application/" + system,
            "purpose": package_purpose(system),
            "mids": len(record["mids"]),
            "tables": len(record["tables"]["owned"]),
            "callers": len(reverse_call_edges[system]),
            "callees": len(call_edges[system]),
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
        "login_composition": login_composition(),
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
        mode = modes.get(int(raw_mid), {})
        client_not_live.append({
            "mid": int(raw_mid),
            "name": client_entry["name"],
            "files": client_entry["files"],
            "family": mode.get("family"),
            "disposition": mode.get("disposition"),
            "stage": mode.get("target"),
        })
    unhandled_client_senders = client_senders_without_live_handler(client, grouped)

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
        "client_senders_without_live_handler": unhandled_client_senders,
        "facts_without_consumer": [
            {"fact": kind, "systems": sorted(system for system, kinds in emitted_by_system.items() if kind in kinds)}
            for kind in sorted(emitted_all) if kind not in fact_consumer_map
        ],
        "facts_without_emitter": [
            dict({"fact": kind}, **fact_consumer_map[kind])
            for kind in sorted(fact_consumer_map)
            if kind not in emitted_all and ("missions" in fact_consumer_map[kind] or "adventure" in fact_consumer_map[kind])
        ],
        "gaps": sorted(gap.replace(str(ROOT) + "/", "") for gap in typed.get("gaps", [])),
        "inactive_mids": {"count": len(inactive_mids), "mids": inactive_mids},
        "live_mids_not_covered": live_not_covered,
        "live_mids_without_client_caller": live_without_caller,
        "narrow_param_checks": narrow_param_checks(),
        "soft_refusals": soft_refusals(system_texts),
        "systems_not_wired": unwired,
        "tables_locked_by_many": [
            {"table": table, "systems": sorted(systems_lock)}
            for table, systems_lock in sorted({
                table: {system for system, tables in system_row_locks.items() if table in tables}
                for table in {table for tables in system_row_locks.values() for table in tables}
            }.items())
            if len(systems_lock) >= 3
        ],
        "tables_with_several_writers": several_writers,
        "tables_without_owner_row": without_owner,
        "unattributed_mids": unattributed,
        "unattributed_pushes": unattributed_pushes,
    }
    if coverage_note:
        findings["live_mids_not_covered_note"] = coverage_note

    composition_by_system = {
        system: sorted({
            entry.get("construction_file", "")
            for entry in system_entries_by_system[system]
        } - {""})
        for system in systems
    }
    edges_document = {
        "calls": call_edges,
        "called_by": reverse_call_edges,
        "composition": composition_by_system,
    }
    files = {"README.md": read_text(ROOT / "tools" / "system_map_readme.md"), "INDEX.json": json_text(index), "FINDINGS.json": findings_text(findings), "EDGES.json": json_text(edges_document)}
    for system, record in system_records.items():
        files["systems/" + system + ".json"] = json_text(record)
    return files


def findings_text(findings):
    return json.dumps(findings, indent=1, ensure_ascii=False) + "\n"


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


def partition_pushes(pushes, systems):
    grouped = {system: [] for system in systems}
    unattributed = []
    for push in pushes:
        owner = push_system(push, systems)
        if owner not in grouped:
            unattributed.append(push)
            continue
        grouped[owner].append({key: value for key, value in push.items() if key != "app_imports"})
    return grouped, sorted(unattributed, key=json_text)


def validate_generated(files):
    def require(relative_path, label):
        if not (ROOT / relative_path).exists():
            raise SystemExit("generated path missing: %s (%s)" % (relative_path, label))

    for name, content in files.items():
        if name == "README.md":
            continue
        data = json.loads(content)
        if name.startswith("systems/"):
            system = name[len("systems/"):-len(".json")]
            for relative_path in data.get("dispatcher_files", []):
                require(relative_path, "dispatcher_files")
            for push in data.get("pushes", []):
                require(push["file"], "pushes")
            for row in data.get("contracts", []):
                require(row["file"], "contracts")
            for unit in data["tests"]["unit"]:
                if not (APPLICATION_DIRECTORY / system / unit).is_file():
                    raise SystemExit("generated path missing: %s/%s (unit)" % (system, unit))
            for integration in data["tests"]["integration"]:
                if not (ROOT / "internal" / "integration" / integration).is_dir():
                    raise SystemExit("generated path missing: internal/integration/%s" % integration)
            for scenario in data["tests"]["scenarios_naming"]:
                if not (ROOT / "virtualclient" / "scenarios" / scenario).is_file():
                    raise SystemExit("generated path missing: virtualclient/scenarios/%s" % scenario)
        else:
            stack = [(data, "")]
            while stack:
                value, key = stack.pop()
                if isinstance(value, dict):
                    stack.extend((item, item_key) for item_key, item in value.items())
                elif isinstance(value, list):
                    stack.extend((item, key) for item in value)
                elif isinstance(value, str) and key in ("file", "migrations"):
                    require(value, key)
    campaign_owned = set(json.loads(files["systems/campaign.json"])["tables"]["owned"])
    for required in ("campaign_players", "campaign_nodes"):
        if required not in campaign_owned:
            raise SystemExit("campaign does not own %s" % required)
    for table in campaign_owned:
        if table.startswith(("arena_", "top_floor_")):
            raise SystemExit("campaign falsely owns %s" % table)
    clientlog_calls = json.loads(files["EDGES.json"])["calls"].get("clientlog", {})
    if "arena" in clientlog_calls:
        raise SystemExit("clientlog has a false arena edge")


TRACE_ANCHORS = {
    114: [
        "Mode.Result internal/application/campaign/mode.go:",
        "Service.SettleGrantTx internal/application/i5/service.go:",
        "mail_records",
        "player_item_stacks",
    ],
    161: [
        "MissionMaterializer.MaterializeTx internal/application/i5/missions.go:",
        "Store.LockMissionRootTx internal/adapters/postgres/i5store/missions.go:",
        "player_mission_roots",
        "FOR UPDATE",
    ],
    528: ["UNRESOLVED registered wrapper observing", "Mode.SP internal/application/workplace/mode.go:"],
    338: [
        "Mode.Result internal/application/march/settle.go:",
        "Service.AttestReportTx internal/application/combat/service.go:",
    ],
}


def missing_trace_anchors(output, anchors):
    return [anchor for anchor in anchors if anchor not in output]


FORBIDDEN_TRACE_ANCHORS = {
    1302: ["Service.Claim internal/application/achievement/"],
    1303: ["Service.Load internal/application/achievement/"],
}


def validate_trace_anchors():
    for mid in sorted(set(TRACE_ANCHORS) | set(FORBIDDEN_TRACE_ANCHORS)):
        anchors = TRACE_ANCHORS.get(mid, [])
        output = helper_trace(mid)
        missing = missing_trace_anchors(output, anchors)
        if missing:
            raise SystemExit("trace %d is missing %s" % (mid, missing[0]))
        for forbidden in FORBIDDEN_TRACE_ANCHORS.get(mid, []):
            if forbidden in output:
                raise SystemExit("trace %d falsely reaches %s" % (mid, forbidden))


def write_output(files):
    validate_generated(files)
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
    validate_generated(files)
    validate_trace_anchors()
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


SHOW_ALIASES = {"missions": "i5"}


def show_entry(key):
    index = json.loads(read_text(OUTPUT_DIRECTORY / "INDEX.json"))
    requested_key = key
    key = SHOW_ALIASES.get(key, key)
    if key == "unhandled":
        findings = json.loads(read_text(OUTPUT_DIRECTORY / "FINDINGS.json"))
        print(json.dumps(findings["client_senders_without_live_handler"], indent=1, ensure_ascii=False))
        return
    if key in {row["name"] for row in index["systems"]}:
        record = json.loads(read_text(SYSTEMS_DIRECTORY / (key + ".json")))
        edges = json.loads(read_text(OUTPUT_DIRECTORY / "EDGES.json"))
        record["calls"] = edges["calls"].get(key, {})
        record["called_by"] = edges["called_by"].get(key, {})
        record["composition"] = edges["composition"].get(key, [])
        if requested_key in SHOW_ALIASES:
            record = {
                "alias": requested_key,
                "system": key,
                "note": "no internal/application/missions package; mission ownership lives in " + key,
                "record": record,
            }
        print(json.dumps(record, indent=1, ensure_ascii=False))
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
        output["written"] = key in system_record["tables"]["written"]
    output["locked_by"] = sorted(
        path.stem for path in SYSTEMS_DIRECTORY.glob("*.json")
        if key in json.loads(read_text(path))["locks"].get("row_locks", [])
    )
    print(json.dumps(output, indent=1, ensure_ascii=False))


def main():
    self_check()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--refresh-client", metavar="SRC_64")
    parser.add_argument("--refresh-coverage", metavar="FILE")
    parser.add_argument("--full", action="store_true", help="show an unabridged trace")
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
        if len(words) == 2 and words[0] == "trace" and words[1].isdigit():
            trace = helper_trace(int(words[1]))
            sys.stdout.write(trace if arguments.full else compact_trace(trace))
            return 0
        if len(words) == 1:
            show_entry(words[0])
            return 0
    parser.print_help()
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main())
    except BrokenPipeError:
        sys.exit(0)
