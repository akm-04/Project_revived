#!/usr/bin/env python3
"""Catalogue every popup the stock client can show and whether the backend can trigger it.

The catalogue is generated from the stock client archive and the Go backend,
modelled on ``tools/reply_consumers.py``: its reply walk (request callback
resolution, same-file helpers, model methods and event handlers) is imported
from that module instead of copied.  Each popup site the walk reaches becomes
one row; every ``message.lua`` code the automatic error toast can show becomes
one ERROR_TOAST row.

Statuses (see ``tools/popup_catalog_readme.md``):

- PRODUCED          a code trigger with a backend producer on every served MID
- PRODUCED_UNPROVEN a success/field trigger on a served MID, no REVIEWED test
- GAP               served MID, code trigger the backend never produces
- UNBUILT           no served MID; carries the owner phase (forward catalogue)
- CLIENT_ONLY       a LOCAL popup with no server input (never checked)
- UNKNOWN           the walk could not decide; the reason is on the row
- WAIVED            a reviewed GAP the lead deferred to another owner phase

    tools/popup_catalog.py --source-archive ZIP --write
    tools/popup_catalog.py --source-archive ZIP --check
    tools/popup_catalog.py --source-archive ZIP show <mid|system|code|window>
    tools/popup_catalog.py --source-archive ZIP owed <system>

Client source is read from the archive only; nothing from inputs/ is executed.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import zipfile
from dataclasses import dataclass, field
from pathlib import Path

import reply_consumers as rc

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIRECTORY = ROOT / "docs/architecture/popup_catalog"
CATALOG_PATH = OUTPUT_DIRECTORY / "POPUP_CATALOG.json"
WAIVERS_PATH = OUTPUT_DIRECTORY / "WAIVERS.json"
REVIEWED_PATH = OUTPUT_DIRECTORY / "REVIEWED.json"
README_PATH = OUTPUT_DIRECTORY / "README.md"
README_SOURCE = ROOT / "tools/popup_catalog_readme.md"
SYSTEM_MAP_DIRECTORY = ROOT / "docs/architecture/system_map"
MODE_SURFACE_PATH = ROOT / "docs/i9/I9_MODE_SURFACE_V1.json"
STOCKRUNTIME_DIRECTORY = ROOT / "internal/adapters/stockruntime"
FAILURE_GO = "internal/adapters/stockruntime/failure.go"
WORKSPACE_ROOT = ROOT.parents[1]
SEED_POPUPS = WORKSPACE_ROOT / "work/audit/t34/popups_t34.json"
SEED_VERDICTS = WORKSPACE_ROOT / "work/audit/LEAD_VERDICTS.md"

MESSAGE_LUA = "data/tables/message.lua"

ALERT_RECEIVERS = {"CommonAlertWindow", "AlertWindow"}
WINDOW_OPEN_METHODS = {"openWindow", "openAnnotherWindow"}
TEXT_KEY_APIS = {"translation", "getContent"}
KIND_ORDER = ("ERROR_TOAST", "REPLY", "PUSH", "LOCAL")
REVIEWED_STATUSES = {"REACHABLE", "UNUSED_BACKEND_GAP", "CLIENT_ONLY"}
BALANCE_CONSTANTS = ("insufficientDiamondCode", "insufficientCoinCode", "insufficientStaminaCode")
REFUSAL_PATTERN = re.compile(r"refusal\w*\(\s*(?:int64\()?\s*([A-Za-z_]\w*|\d+)")
INLINE_ERROR_CODE_PATTERN = re.compile(r'"error_code"\s*:\s*(?:int64\()?\s*([A-Za-z_]\w*|\d+)')


@dataclass(frozen=True)
class PopupSiteInfo:
    file: str
    line: int
    offset: int
    window: str
    text: str | None
    api: str


@dataclass
class PopupSite:
    info: PopupSiteInfo
    mids: set[int] = field(default_factory=set)
    events: set[str] = field(default_factory=set)
    guard: dict | None = None
    guard_source: str = "unconditional"


# --------------------------------------------------------------- message rows
def parse_messages(text: str) -> list[dict]:
    """One row per message.lua code: code, name, content, type and row line."""
    tokens = rc.Tokenizer(text).tokens()
    rows: list[dict] = []
    for position, token in enumerate(tokens):
        if token.kind != "name" or token.value != "rows" or position + 2 >= len(tokens):
            continue
        if tokens[position + 1].value != "=" or tokens[position + 2].value != "{":
            continue
        close = rc.matching_close(tokens, position + 2)
        cursor = position + 3
        while cursor < close:
            if tokens[cursor].value != "{":
                cursor += 1
                continue
            entry_close = rc.matching_close(tokens, cursor)
            strings = [item for item in tokens[cursor + 1:entry_close] if item.kind == "string"]
            if len(strings) >= 4 and strings[0].value.isdigit():
                rows.append({
                    "code": int(strings[0].value),
                    "name": strings[1].value,
                    "content": strings[2].value,
                    "type": strings[3].value,
                    "line": tokens[cursor].line,
                })
            cursor = entry_close + 1
        break
    return rows


# ------------------------------------------------------------ popup discovery
def _receiver_words(root: str, segments: list[tuple[str, str]]) -> list[str]:
    return [root] + [name for kind, name in segments if kind in ("field", "method")]


def _is_popup_chain(root: str, segments: list[tuple[str, str]]) -> str | None:
    if not segments:
        return None
    words = _receiver_words(root, segments)
    last_kind, last_name = segments[-1]
    if last_kind in ("field", "method") and last_name in WINDOW_OPEN_METHODS and "WindowManager" in words:
        return "WindowManager." + last_name
    if last_kind in ("field", "method") and last_name == "open" and ALERT_RECEIVERS.intersection(words):
        return next(word for word in words if word in ALERT_RECEIVERS) + ".open"
    return None


def _literal_string(tokens: list, start: int, end: int) -> str | None:
    for position in range(start, min(end, len(tokens))):
        if tokens[position].kind == "string":
            return tokens[position].value
    return None


def _text_key(tokens: list, start: int, end: int) -> str | None:
    """The translation key or literal the popup shows."""
    for position in range(start, min(end, len(tokens))):
        if tokens[position].kind != "name" or tokens[position].value not in TEXT_KEY_APIS:
            continue
        if position + 1 < end and tokens[position + 1].value == "(":
            arguments, _ = rc.split_arguments(tokens, position + 1)
            if arguments:
                literal = _literal_string(tokens, *arguments[0])
                if literal is not None:
                    return literal
    return _literal_string(tokens, start, end)


def _window_name(tokens: list, argument: tuple[int, int]) -> str:
    start, end = argument
    values = [token.value for token in tokens[start:end]]
    if end - start == 1 and tokens[start].kind == "string":
        return values[0]
    if len(values) >= 5 and values[:4] == ["xyd", ".", "WindowName", "."]:
        return values[4]
    return "<dynamic>"


def _is_definition(tokens: list, position: int) -> bool:
    return any(tokens[index].kind == "kw" and tokens[index].value == "function"
               for index in range(max(0, position - 3), position))


def discover_sites(tokens: list, position: int) -> PopupSiteInfo | None:
    """A popup call whose chain starts at ``position`` (one per chain)."""
    if tokens[position].kind != "name":
        return None
    token = tokens[position]
    # xyd.WindowManager.get():openWindow(...) splits the chain at the get()
    # call, so the scanner reaches openWindow as its own token after ':'.
    if token.value in WINDOW_OPEN_METHODS and position + 1 < len(tokens) and tokens[position + 1].value == "(":
        if _is_definition(tokens, position):
            return None
        arguments, _ = rc.split_arguments(tokens, position + 1)
        if not arguments:
            return None
        api = "WindowManager." + token.value
        text = _text_key(tokens, *arguments[1]) if len(arguments) > 1 else None
        return PopupSiteInfo("", token.line, token.offset, _window_name(tokens, arguments[0]), text, api)
    if position > 0 and tokens[position - 1].value in (".", ":"):
        return None
    root, segments, after = rc.chain_at(tokens, position)
    if after >= len(tokens) or tokens[after].value != "(":
        return None
    api = _is_popup_chain(root, segments)
    if api is None:
        return None
    arguments, _ = rc.split_arguments(tokens, after)
    if not arguments:
        return None
    window = _window_name(tokens, arguments[0]) if api.startswith("WindowManager") else api.split(".")[0]
    text = _text_key(tokens, *arguments[1]) if len(arguments) > 1 else None
    return PopupSiteInfo("", token.line, token.offset, window, text, api)


# --------------------------------------------------------------- guard reading
def _then_and_end(tokens: list, if_index: int) -> tuple[int, int] | None:
    end = rc._block_end(tokens, if_index)
    then_index = rc._then_index(tokens, if_index, end)
    if then_index is None:
        return None
    return then_index, end


def enclosing_conditions(index, position: int) -> list[tuple[int, int]]:
    blocks = getattr(index, "_popup_if_blocks", None)
    if blocks is None:
        blocks = []
        tokens = index.tokens
        for candidate, token in enumerate(tokens):
            if token.kind != "kw" or token.value != "if":
                continue
            found = _then_and_end(tokens, candidate)
            if found is None:
                continue
            then_index, end = found
            blocks.append((candidate, end, candidate + 1, then_index))
        setattr(index, "_popup_if_blocks", blocks)
    inside = [block for block in blocks if block[0] < position < block[1]]
    return [(start, end) for start, end, _, _ in sorted(inside, key=lambda block: -block[0])]


def _comparison_value(tokens: list, position: int, constants: dict[str, int]) -> int | None:
    if position >= len(tokens):
        return None
    token = tokens[position]
    if token.kind == "number":
        try:
            return int(token.value, 0)
        except ValueError:
            return None
    if token.kind == "name":
        if token.value in constants:
            return constants[token.value]
        if position + 2 < len(tokens) and tokens[position + 1].value == "." and tokens[position + 2].kind == "name":
            return constants.get(tokens[position + 2].value)
    return None


def condition_text(tokens: list, start: int, end: int) -> str:
    text = " ".join(token.value for token in tokens[start:end])
    return text if len(text) <= 400 else text[:397] + "..."


def classify_condition(tokens: list, start: int, end: int, reply_roots: set[str],
                       constants: dict[str, int]) -> tuple[dict | None, dict | None]:
    """Return (reply guard, error-code comparison) found in one condition."""
    guard = None
    comparison = None
    position = start
    while position < end:
        token = tokens[position]
        if token.kind != "name" or (position > start and tokens[position - 1].value in (".", ":")):
            position += 1
            continue
        root, segments, after = rc.chain_at(tokens, position)
        names = [name for kind, name in segments if kind == "field"]
        target = None
        if after + 1 < end and tokens[after].value in ("==", "~="):
            target = _comparison_value(tokens, after + 1, constants)
        if target is not None and "error_code" in names:
            text = condition_text(tokens, start, end)
            comparison = {"code": target, "line": token.line}
            guard = {"type": "code", "code": target, "text": text, "line": token.line}
        elif names[-2:] == ["error", "OK"]:
            guard = guard or {"type": "success", "text": condition_text(tokens, start, end), "line": token.line}
        elif root in reply_roots:
            guard = guard or {"type": "field", "text": condition_text(tokens, start, end), "line": token.line}
        if position > start and tokens[position - 1].kind == "kw" and tokens[position - 1].value == "not" and root in reply_roots:
            guard = guard or {"type": "field", "text": condition_text(tokens, start, end), "line": token.line}
        position = max(after, position + 1)
    return guard, comparison


# ------------------------------------------------------------- reply popups
class PopupExtractor(rc.Extractor):
    """The reply walk from reply_consumers with a popup-site collector attached."""

    def __init__(self, blobs: dict[str, str], constants: dict[str, int]):
        super().__init__(blobs)
        self.constants = constants
        self.sites: dict[tuple[str, int], PopupSite] = {}
        self.event_mids: dict[str, set[int]] = {}
        self.comparisons: dict[int, list[dict]] = {}
        self.pending_guard: dict[tuple[str, int], dict | None] = {}
        self.current_event: str | None = None
        self.current_event_mids: set[int] = set()

    def prepare(self) -> None:
        for mid, event in self.mid_events.items():
            self.event_mids.setdefault(event, set()).add(mid)

    def walk_events(self) -> None:
        for event in sorted(self.event_mids):
            for file, function in self.event_handlers.get(event, []):
                previous_event, previous_mids = self.current_event, self.current_event_mids
                self.current_event, self.current_event_mids = event, set(self.event_mids[event])
                try:
                    self.analyze_reply(0, file, function, rc.Taint(wrapper="params"), f"event {event}")
                finally:
                    self.current_event, self.current_event_mids = previous_event, previous_mids

    def reply_roots(self, function, bindings) -> set[str]:
        roots = set(bindings)
        if len(function.params) > 1:
            roots.add(function.params[1])
        return roots

    def site_mids(self, mid: int, bindings, seeds) -> set[int]:
        mids: set[int] = set()
        for _, mid_set in bindings.values():
            mids.update(mid_set)
        if seeds:
            for entries in seeds.values():
                for _, seed_mids, _ in entries:
                    mids.update(seed_mids)
        if not mids and mid:
            mids.add(mid)
        return {value for value in mids if value}

    def inherited_guard(self, file: str, function) -> dict | None:
        return self.pending_guard.get((file, function.start))

    def local_guard(self, index, file: str, function, position: int, bindings) -> dict | None:
        tokens = index.tokens
        roots = self.reply_roots(function, bindings)
        for start, end in enclosing_conditions(index, position):
            guard, _ = classify_condition(tokens, start, end, roots, self.constants)
            if guard is not None:
                guard = dict(guard)
                guard["file"] = file
                guard["guard_line"] = tokens[start].line
                return guard
        return None

    def record_site(self, file: str, position: int, mid: int, function, bindings, seeds) -> None:
        tokens = self.index(file).tokens
        info = discover_sites(tokens, position)
        if info is None:
            return
        info = PopupSiteInfo(file, info.line, info.offset, info.window, info.text, info.api)
        key = (file, info.offset)
        site = self.sites.get(key)
        if site is None:
            site = PopupSite(info)
            self.sites[key] = site
        if self.current_event is not None:
            site.events.add(self.current_event)
            site.mids.update(self.current_event_mids)
        else:
            site.mids.update(self.site_mids(mid, bindings, seeds))
        local = self.local_guard(self.index(file), file, function, position, bindings)
        if local is not None:
            site.guard, site.guard_source = local, "local"
        elif site.guard is None:
            inherited = self.inherited_guard(file, function)
            if inherited is not None:
                site.guard, site.guard_source = inherited, "inherited"

    def handle_call(self, mid, file, function, position, root, segments, after, bindings, via, guards, seeds) -> int:
        self.record_site(file, position, mid, function, bindings, seeds)
        target = self.resolve_callee(file, function, root, segments)
        previous: tuple[bool, dict | None] = (False, None)
        inherited = None
        if target is not None:
            inherited = self.local_guard(self.index(file), file, function, position, bindings)
            if inherited is None:
                inherited = self.inherited_guard(file, function)
            key = (target[0], target[1].start)
            previous = (key in self.pending_guard, self.pending_guard.get(key))
            self.pending_guard[key] = inherited
        try:
            return super().handle_call(mid, file, function, position, root, segments, after, bindings, via, guards, seeds)
        finally:
            if target is not None:
                existed, value = previous
                if existed:
                    self.pending_guard[(target[0], target[1].start)] = value
                else:
                    self.pending_guard.pop((target[0], target[1].start), None)

    def handle_if(self, mid, file, function, position, bindings, via, guards, seeds) -> int:
        tokens = self.index(file).tokens
        roots = self.reply_roots(function, bindings)
        mids = self.current_event_mids if self.current_event is not None else self.site_mids(mid, bindings, seeds)
        end = rc._block_end(tokens, position)
        for _, condition, _, _ in rc._branches(tokens, position, end):
            _, comparison = classify_condition(tokens, condition[0], condition[1], roots, self.constants)
            if comparison is None:
                continue
            for compared_mid in mids:
                self.comparisons.setdefault(comparison["code"], []).append({
                    "mid": compared_mid,
                    "file": file,
                    "line": comparison["line"],
                })
        return super().handle_if(mid, file, function, position, bindings, via, guards, seeds)

    def analyze_event_reply(self, mid, file, line, callback_present: bool = False) -> None:
        return


# ------------------------------------------------------------------ backend scan
@dataclass(frozen=True)
class MidProfile:
    resolved: bool
    codes: dict[int, list[dict]]
    reason: str | None = None


def _brace_close(text: str, open_index: int) -> int:
    depth = 0
    for index in range(open_index, len(text)):
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
            if depth == 0:
                return index
    return len(text) - 1


def _line_of(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


class BackendProducers:
    def __init__(self, files: dict[str, str], systems_by_mid: dict[int, str]):
        self.files = files
        self.systems_by_mid = systems_by_mid
        self.constants = self.parse_constants()
        self.failure_tables = self.parse_failure_tables()
        self.functions = self.parse_functions()
        self.functions_by_file_name: dict[tuple[str, str], list[dict]] = {}
        for function in self.functions:
            self.functions_by_file_name.setdefault((function["file"], function["name"]), []).append(function)
        self.switches = self.parse_mid_switches()
        self._profiles: dict[int, MidProfile] = {}
        self._function_codes: dict[tuple[str, int], dict[int, list[dict]]] = {}

    def parse_constants(self) -> dict[str, int]:
        constants: dict[str, int] = {}
        pattern = re.compile(r"^\s*(?:const\s+)?([A-Za-z_]\w*)\s*(?:int64\s*)?=\s*(\d+)\s*$")
        for text in self.files.values():
            for line in text.splitlines():
                match = pattern.match(line)
                if match:
                    constants[match.group(1)] = int(match.group(2))
        return constants

    def parse_failure_tables(self) -> dict[str, list[dict]]:
        tables: dict[str, list[dict]] = {}
        for file, text in self.files.items():
            for match in re.finditer(r"var\s+([A-Za-z_]\w*)\s*=\s*\[\]failureRow\s*\{", text):
                open_index = match.end() - 1
                close = _brace_close(text, open_index)
                body = text[open_index:close]
                rows = []
                for entry in re.finditer(r"\{([^{}]*)\}", body):
                    content = entry.group(1)
                    code_match = re.search(r"code:\s*([A-Za-z_]\w*|\d+)", content)
                    code = None
                    if code_match:
                        raw = code_match.group(1)
                        code = int(raw) if raw.isdigit() else self.constants.get(raw)
                    rows.append({
                        "code": code,
                        "balance": bool(re.search(r"balance:\s*true", content)),
                        "file": file,
                        "line": _line_of(text, open_index + entry.start()),
                    })
                tables[match.group(1)] = rows
        return tables

    def parse_functions(self) -> list[dict]:
        functions: list[dict] = []
        pattern = re.compile(r"^func\s+(?:\([^)]*\)\s*)?([A-Za-z_]\w*)\(", re.MULTILINE)
        for file, text in self.files.items():
            for match in pattern.finditer(text):
                open_index = text.find("{", match.end())
                if open_index < 0:
                    continue
                close = _brace_close(text, open_index)
                functions.append({
                    "name": match.group(1),
                    "file": file,
                    "start_line": _line_of(text, match.start()),
                    "body": text[open_index:close],
                    "body_offset": open_index,
                    "text": text,
                })
        return functions

    def parse_mid_switches(self) -> list[dict]:
        switches: list[dict] = []
        pattern = re.compile(r"switch\s+(?:[A-Za-z_][\w.]*\.)?MID\s*\{|switch\s+mid\s*\{")
        for file, text in self.files.items():
            for match in pattern.finditer(text):
                open_index = match.end() - 1
                close = _brace_close(text, open_index)
                body = text[open_index + 1:close]
                base = open_index + 1
                labels = list(re.finditer(r"^\tcase\s+([0-9,\s]+):", body, re.MULTILINE))
                cases = []
                for index, label in enumerate(labels):
                    end = base + (labels[index + 1].start() if index + 1 < len(labels) else len(body))
                    cases.append({
                        "mids": {int(value) for value in re.findall(r"\d+", label.group(1))},
                        "start_offset": base + label.end(),
                        "end_offset": end,
                    })
                switches.append({"file": file, "cases": cases})
        return switches

    def code_constant_line(self, name: str) -> int:
        text = self.files.get(FAILURE_GO, "")
        match = re.search(r"^\s*" + re.escape(name) + r"\s*(?:int64\s*)?=", text, re.MULTILINE)
        return _line_of(text, match.start()) if match else 0

    def function_codes(self, function: dict, depth: int = 0) -> dict[int, list[dict]]:
        key = (function["file"], function["body_offset"])
        cached = self._function_codes.get(key)
        if cached is not None:
            return cached
        codes: dict[int, list[dict]] = {}
        text = function["text"]
        for pattern in (REFUSAL_PATTERN, INLINE_ERROR_CODE_PATTERN):
            for match in pattern.finditer(function["body"]):
                raw = match.group(1)
                code = int(raw) if raw.isdigit() else self.constants.get(raw)
                if code is not None:
                    codes.setdefault(code, []).append({
                        "file": function["file"],
                        "line": _line_of(text, function["body_offset"] + match.start()),
                        "via": function["name"],
                    })
        for table_match in re.finditer(r"failureFromRows\(\s*([A-Za-z_]\w*)", function["body"]):
            table_name = table_match.group(1)
            rows = self.failure_tables.get(table_name, [])
            for row in rows:
                if row["code"] is not None:
                    codes.setdefault(row["code"], []).append({
                        "file": row["file"], "line": row["line"], "via": table_name,
                    })
            if any(row["balance"] for row in rows):
                for name in BALANCE_CONSTANTS:
                    code = self.constants.get(name)
                    if code:
                        codes.setdefault(code, []).append({
                            "file": FAILURE_GO, "line": self.code_constant_line(name), "via": "shared balance classifier",
                        })
        if "failureFromRows(" in function["body"] or "classifyFailure(" in function["body"]:
            code = self.constants.get("unprovenRefusalCode", 35028)
            codes.setdefault(code, []).append({
                "file": FAILURE_GO, "line": self.code_constant_line("unprovenRefusalCode"), "via": "shared classifier",
            })
        for name, value in self.constants.items():
            if not name.endswith("Code") or not re.search(r"\b" + re.escape(name) + r"\b", function["body"]):
                continue
            codes.setdefault(value, []).append({
                "file": function["file"], "line": self.constant_use_line(function, name), "via": name,
            })
        if depth < 2:
            called = set(re.findall(r"\b([A-Za-z_]\w*)\s*\(", function["body"]))
            for name in called:
                for target in self.functions_by_file_name.get((function["file"], name), []):
                    if target["body_offset"] == function["body_offset"]:
                        continue
                    for code, evidence in self.function_codes(target, depth + 1).items():
                        codes.setdefault(code, []).extend(evidence)
        self._function_codes[key] = codes
        return codes

    def constant_use_line(self, function: dict, name: str) -> int:
        match = re.search(r"\b" + re.escape(name) + r"\b", function["body"])
        return _line_of(function["text"], function["body_offset"] + match.start()) if match else function["start_line"]

    def case_codes(self, file: str, case: dict) -> dict[int, list[dict]]:
        text = self.files[file]
        body = text[case["start_offset"]:case["end_offset"]]
        codes: dict[int, list[dict]] = {}
        for pattern in (REFUSAL_PATTERN, INLINE_ERROR_CODE_PATTERN):
            for match in pattern.finditer(body):
                raw = match.group(1)
                code = int(raw) if raw.isdigit() else self.constants.get(raw)
                if code is not None:
                    codes.setdefault(code, []).append({
                        "file": file, "line": _line_of(text, case["start_offset"] + match.start()), "via": "dispatcher case",
                    })
        for name, value in self.constants.items():
            if not name.endswith("Code") or not re.search(r"\b" + re.escape(name) + r"\b", body):
                continue
            use = re.search(r"\b" + re.escape(name) + r"\b", body)
            codes.setdefault(value, []).append({
                "file": file,
                "line": _line_of(text, case["start_offset"] + use.start()) if use else 0,
                "via": name,
            })
        called = set(re.findall(r"\b([A-Za-z_]\w*)\s*\(", body))
        for name in called:
            for function in self.functions_by_file_name.get((file, name), []):
                for code, evidence in self.function_codes(function).items():
                    codes.setdefault(code, []).extend(evidence)
        return codes

    def mid_profile(self, mid: int) -> MidProfile:
        cached = self._profiles.get(mid)
        if cached is not None:
            return cached
        cases = [(switch["file"], case) for switch in self.switches for case in switch["cases"] if mid in case["mids"]]
        if not cases:
            profile = MidProfile(False, {}, "no dispatcher case for this MID")
            self._profiles[mid] = profile
            return profile
        codes: dict[int, list[dict]] = {}
        for file, case in cases:
            for code, evidence in self.case_codes(file, case).items():
                codes.setdefault(code, []).extend(evidence)
        profile = MidProfile(True, codes)
        self._profiles[mid] = profile
        return profile

    def all_producers(self) -> dict[int, list[dict]]:
        producers: dict[int, list[dict]] = {}
        for mid, system in sorted(self.systems_by_mid.items()):
            profile = self.mid_profile(mid)
            if not profile.resolved:
                continue
            for code, evidence in profile.codes.items():
                for item in evidence:
                    producers.setdefault(code, []).append({
                        "system": system, "mid": mid, "file": item["file"],
                        "line": item["line"], "via": item.get("via", ""),
                    })
        for function in self.functions:
            for code, evidence in self.function_codes(function).items():
                for item in evidence:
                    item_system = self.systems_by_mid.get(item.get("mid") or 0)
                    if item_system is not None:
                        continue
                    producers.setdefault(code, []).append({
                        "system": "stockruntime", "mid": None, "file": item["file"],
                        "line": item["line"], "via": item.get("via", ""),
                    })
        for code, entries in producers.items():
            deduped = {}
            for entry in entries:
                deduped[(entry["system"], entry["mid"], entry["file"], entry["line"], entry["via"])] = entry
            producers[code] = sorted(deduped.values(), key=lambda item: (item["system"], item["mid"] or 0, item["file"], item["line"]))
        return producers


# --------------------------------------------------------------- ownership
class OwnerIndex:
    def __init__(self, index_document: dict, mid_classes_document: dict, mode_surface: dict):
        self.mid_to_system = {
            int(mid): system
            for mid, system in (index_document.get("lookups", {}).get("mid_to_system", {}) or {}).items()
        }
        self.served = set(self.mid_to_system)
        self.modes = {
            row["mid"]: row
            for row in mode_surface.get("mids", [])
            if isinstance(row.get("mid"), int)
        }

    def system_of(self, mid: int) -> str | None:
        return self.mid_to_system.get(mid)

    def is_served(self, mid: int) -> bool:
        return mid in self.served

    def unserved_owner(self, mid: int) -> str:
        row = self.modes.get(mid)
        if row is None:
            return "UNKNOWN"
        if row.get("target"):
            return str(row["target"])
        return "out_of_i9:" + str(row.get("disposition") or "UNKNOWN")


# ------------------------------------------------------------------ row building
def row_id(kind: str, file: str, line: int) -> str:
    return f"{kind}:{file}:{line}"


def owner_for(mids: set[int], owners: OwnerIndex) -> tuple[str, bool]:
    systems: set[str] = {
        system for mid in mids if owners.is_served(mid)
        for system in [owners.system_of(mid)] if isinstance(system, str)
    }
    unserved = sorted(mid for mid in mids if not owners.is_served(mid))
    if systems:
        return ",".join(sorted(systems)), bool(unserved)
    if unserved:
        return ",".join(sorted({owners.unserved_owner(mid) for mid in unserved})), False
    return "UNKNOWN", False


def popup_record(info: PopupSiteInfo) -> dict:
    record = {"window": info.window, "file": info.file, "line": info.line, "api": info.api}
    if info.text is not None:
        record["text_key"] = info.text
    return record


def trigger_record(site: PopupSite) -> dict:
    trigger = {"mids": sorted(mid for mid in site.mids if mid), "events": sorted(site.events)}
    if site.guard is not None:
        guard = {
            "type": site.guard.get("type", "condition"),
            "text": site.guard.get("text", ""),
            "file": site.guard.get("file", ""),
            "line": site.guard.get("guard_line", site.guard.get("line", 0)),
            "source": site.guard_source,
        }
        if "code" in site.guard:
            guard["code"] = site.guard["code"]
        trigger["guard"] = guard
    else:
        trigger["guard"] = {"type": "unconditional", "source": site.guard_source}
    return trigger


def code_status_for_mids(mids: set[int], code: int, producers: BackendProducers,
                         owners: OwnerIndex) -> tuple[str, list[dict], str | None]:
    evidence: list[dict] = []
    unresolved = []
    for mid in sorted(mids):
        if not owners.is_served(mid):
            continue
        profile = producers.mid_profile(mid)
        if not profile.resolved:
            unresolved.append(mid)
            continue
        for item in profile.codes.get(code, []):
            evidence.append({"mid": mid, "system": owners.system_of(mid) or "UNKNOWN",
                             "file": item["file"], "line": item["line"], "via": item.get("via", "")})
    if evidence:
        return "PRODUCED", evidence, None
    if unresolved:
        return "UNKNOWN", [], "dispatcher case unresolved for MID(s) " + ",".join(map(str, unresolved))
    return "GAP", [], f"no served MID produces code {code}"


def build_rows(extractor: PopupExtractor, blobs: dict[str, str], messages: list[dict],
               producers: BackendProducers, producer_index: dict[int, list[dict]],
               owners: OwnerIndex) -> list[dict]:
    rows: dict[str, dict] = {}
    walked = set(extractor.sites)

    def add(row: dict) -> None:
        existing = rows.get(row["id"])
        if existing is None:
            rows[row["id"]] = row
            return
        existing["trigger"]["mids"] = sorted(set(existing["trigger"]["mids"]) | set(row["trigger"]["mids"]))
        existing["trigger"]["events"] = sorted(set(existing["trigger"]["events"]) | set(row["trigger"]["events"]))
        if row["kind"] == "PUSH" and existing["kind"] == "REPLY":
            existing["kind"] = "PUSH"

    for key in sorted(walked, key=lambda item: (item[0], extractor.sites[item].info.line, extractor.sites[item].info.offset)):
        site = extractor.sites[key]
        if not site.mids and not site.events:
            add(local_row(site))
            continue
        kind = "PUSH" if site.events else "REPLY"
        add(site_row(kind, site, producers, owners))
    for file in sorted(blobs):
        if not file.startswith("app/"):
            continue
        index = extractor.index(file)
        for position in range(len(index.tokens)):
            info = discover_sites(index.tokens, position)
            if info is None:
                continue
            site_info = PopupSiteInfo(file, info.line, info.offset, info.window, info.text, info.api)
            if (file, info.offset) in walked:
                continue
            add(local_row(PopupSite(site_info)))
    for mid_text, callbacks in extractor.callbacks.items():
        for callback in callbacks:
            if callback.get("status") != "UNKNOWN":
                continue
            identifier = row_id("REPLY", callback["file"], callback["line"])
            if identifier in rows:
                continue
            mid = int(mid_text)
            owner, _ = owner_for({mid}, owners)
            add({
                "id": identifier,
                "kind": "REPLY",
                "popup": {"window": "<unresolved>", "file": callback["file"], "line": callback["line"], "api": "unresolved"},
                "trigger": {"mids": [mid], "events": [], "guard": {"type": "unresolved", "text": callback.get("reason", "")}},
                "owner": owner,
                "status": "UNKNOWN",
                "reason": callback.get("reason", "callback not resolvable"),
            })
    for message in messages:
        add(message_row(message, producer_index, owners))
    return [rows[key] for key in sorted(rows, key=lambda identifier: row_sort_key(rows[identifier]))]


def site_row(kind: str, site: PopupSite, producers: BackendProducers, owners: OwnerIndex) -> dict:
    info = site.info
    owner, has_unserved = owner_for(site.mids, owners)
    row = {
        "id": row_id(kind, info.file, info.line),
        "kind": kind,
        "popup": popup_record(info),
        "trigger": trigger_record(site),
        "owner": owner,
        "status": "UNKNOWN",
        "reason": None,
    }
    served = {mid for mid in site.mids if owners.is_served(mid)}
    if kind == "PUSH" and not served:
        row["reason"] = "push event with no served MID dispatch; backend emission not proven"
        return row
    if not served:
        row["status"] = "UNBUILT"
        row["reason"] = "no served MID opens this popup"
        return row
    guard = site.guard or {}
    if guard.get("type") == "code" and "code" in guard:
        status, evidence, reason = code_status_for_mids(served, int(guard["code"]), producers, owners)
        row["status"] = status
        row["reason"] = reason
        if evidence:
            row["producers"] = evidence
    else:
        row["status"] = "PRODUCED_UNPROVEN"
        row["reason"] = "success or field trigger; no REVIEWED test names it"
    if has_unserved:
        row["reason"] = (row["reason"] + "; " if row["reason"] else "") + "also triggered by an unserved MID"
    return row


def local_row(site: PopupSite) -> dict:
    info = site.info
    return {
        "id": row_id("LOCAL", info.file, info.line),
        "kind": "LOCAL",
        "popup": popup_record(info),
        "trigger": {"mids": [], "events": [], "guard": {"type": "client_only", "source": "client only"}},
        "owner": "CLIENT",
        "status": "CLIENT_ONLY",
        "reason": "client UI logic; no server input",
    }


def message_row(message: dict, producer_index: dict[int, list[dict]], owners: OwnerIndex) -> dict:
    code = message["code"]
    producer_rows = producer_index.get(code, [])
    row = {
        "id": row_id("ERROR_TOAST", MESSAGE_LUA, message["line"]),
        "kind": "ERROR_TOAST",
        "popup": {"window": "toast", "code": code, "text": message["content"], "file": MESSAGE_LUA, "line": message["line"]},
        "trigger": {"mids": sorted({item["mid"] for item in producer_rows if item["mid"] is not None}),
                    "events": [], "guard": {"type": "automatic_error_toast", "source": "Backend.lua:428-437"}},
        "owner": "UNKNOWN",
        "status": "PRODUCED" if producer_rows else "UNPRODUCED",
        "reason": None if producer_rows else "no backend producer",
    }
    if producer_rows:
        row["producers"] = producer_rows
    return row


def row_sort_key(row: dict) -> tuple:
    kind = KIND_ORDER.index(row["kind"]) if row["kind"] in KIND_ORDER else len(KIND_ORDER)
    return (kind, row["popup"]["file"], row["popup"]["line"], str(row["popup"].get("window") or ""))


# ------------------------------------------------------------- reviewed/waived
def apply_reviewed(rows: list[dict], reviewed: dict) -> None:
    for row in rows:
        entry = reviewed["entries"].get(row["id"])
        if entry is None:
            continue
        status = entry.get("status")
        if status == "UNUSED_BACKEND_GAP" and row["status"] in ("PRODUCED_UNPROVEN", "UNKNOWN"):
            row["status"] = "GAP"
            row["reason"] = "REVIEWED UNUSED_BACKEND_GAP" + (f" ({entry['finding']})" if entry.get("finding") else "")
        elif status == "CLIENT_ONLY" and row["kind"] == "LOCAL":
            row["status"] = "CLIENT_ONLY"
            row["owner"] = "CLIENT"
            row["reason"] = "REVIEWED CLIENT_ONLY"
        elif status == "REACHABLE" and row["status"] == "PRODUCED_UNPROVEN" and entry.get("test"):
            row["status"] = "PRODUCED"
            row["reason"] = f"REVIEWED test {entry['test']}"
        row["reviewed"] = {key: entry[key] for key in ("status", "finding", "evidence", "test") if entry.get(key)}


def apply_waivers(rows: list[dict], waivers: dict) -> None:
    for row in rows:
        entry = waivers["entries"].get(row["id"])
        if entry is None or row["status"] != "GAP":
            continue
        row["status"] = "WAIVED"
        row["waiver"] = entry
        row["reason"] = entry.get("reason", "")


def validate_inputs(rows: list[dict], blobs: dict[str, str], waivers: dict, reviewed: dict) -> list[str]:
    problems: list[str] = []
    by_id = {row["id"]: row for row in rows}
    for identifier, entry in sorted(waivers["entries"].items()):
        row = by_id.get(identifier)
        if row is None:
            problems.append(f"waiver {identifier}: popup id no longer exists")
            continue
        if row["status"] != "WAIVED":
            problems.append(f"waiver {identifier}: status {row['status']} no longer needs it")
        if not (entry.get("reason") or "").strip():
            problems.append(f"waiver {identifier}: reason is empty")
        if not (entry.get("owner_phase") or "").strip():
            problems.append(f"waiver {identifier}: owner phase is empty")
        client = (entry.get("client") or "").strip()
        file, _, line_text = client.rpartition(":")
        if not file or not line_text.isdigit() or file not in blobs:
            problems.append(f"waiver {identifier}: client evidence {client!r} is not a file:line in the archive")
    for identifier, entry in sorted(reviewed["entries"].items()):
        row = by_id.get(identifier)
        if row is None:
            problems.append(f"reviewed {identifier}: popup id no longer exists")
            continue
        status = entry.get("status")
        if status not in REVIEWED_STATUSES:
            problems.append(f"reviewed {identifier}: status {status!r} is not one of {sorted(REVIEWED_STATUSES)}")
            continue
        if status == "CLIENT_ONLY" and row["kind"] != "LOCAL":
            problems.append(f"reviewed {identifier}: CLIENT_ONLY on a non-LOCAL row")
        if status == "UNUSED_BACKEND_GAP" and row["status"] not in ("GAP", "WAIVED", "UNKNOWN", "UNBUILT"):
            problems.append(f"reviewed {identifier}: UNUSED_BACKEND_GAP but status is {row['status']}")
    return problems


# -------------------------------------------------------------------- assemble
def build_catalog(blobs: dict[str, str], backend_files: dict[str, str], index_document: dict,
                  mid_classes_document: dict, mode_surface: dict, reviewed: dict, waivers: dict,
                  source_sha256: str) -> dict:
    constants = _client_constants(blobs)
    messages = parse_messages(blobs.get(MESSAGE_LUA, ""))
    owners = OwnerIndex(index_document, mid_classes_document, mode_surface)
    producers = BackendProducers(backend_files, dict(owners.mid_to_system))
    extractor = PopupExtractor(blobs, constants)
    extractor.prepare()
    extractor.run()
    extractor.walk_events()
    producer_index = producers.all_producers()
    rows = build_rows(extractor, blobs, messages, producers, producer_index, owners)
    compared = _comparison_rows(extractor.comparisons, owners)
    for row in rows:
        if row["kind"] != "ERROR_TOAST":
            continue
        code = row["popup"]["code"]
        if code in compared:
            row["compared_by"] = compared[code]
        owner_systems = {item["system"] for item in compared.get(code, [])}
        owner_systems.update(item["system"] for item in row.get("producers", []))
        owner_systems = sorted({system for system in owner_systems if isinstance(system, str) and system and system != "stockruntime"})
        row["owner"] = ",".join(owner_systems) if owner_systems else "UNKNOWN"
    payload = {
        "schema_version": 1,
        "contract": "I9_11_POPUP_CATALOGUE_V1",
        "source": "current src_64 Lua popup sites and message.lua codes",
        "source_archive_sha256": source_sha256,
        "rows": rows,
    }
    return finalise_payload(payload, reviewed, waivers)


def finalise_payload(payload: dict, reviewed: dict, waivers: dict) -> dict:
    rows = payload["rows"]
    apply_reviewed(rows, reviewed)
    apply_waivers(rows, waivers)
    rows.sort(key=row_sort_key)
    status_counts: dict[str, int] = {}
    kind_counts: dict[str, int] = {}
    for row in rows:
        status_counts[row["status"]] = status_counts.get(row["status"], 0) + 1
        kind_counts[row["kind"]] = kind_counts.get(row["kind"], 0) + 1
    payload["status_counts"] = status_counts
    payload["kind_counts"] = kind_counts
    return payload


def _client_constants(blobs: dict[str, str]) -> dict[str, int]:
    constants: dict[str, int] = {}
    pattern = re.compile(r"xyd\.([A-Za-z_]\w*)\s*=\s*(\d+)")
    for text in blobs.values():
        for match in pattern.finditer(text):
            constants.setdefault(match.group(1), int(match.group(2)))
    return constants


def _comparison_rows(comparisons: dict[int, list[dict]], owners: OwnerIndex) -> dict[int, list[dict]]:
    rows: dict[int, list[dict]] = {}
    for code, entries in comparisons.items():
        seen = set()
        for entry in entries:
            key = (entry["mid"], entry["file"], entry["line"])
            if key in seen:
                continue
            seen.add(key)
            rows.setdefault(code, []).append({
                "mid": entry["mid"],
                "system": owners.system_of(entry["mid"]) or "UNKNOWN",
                "file": entry["file"],
                "line": entry["line"],
            })
        rows[code].sort(key=lambda item: (item["system"], item["mid"], item["file"], item["line"]))
    return rows


def serialise(payload: dict) -> str:
    return json.dumps(payload, indent=1, sort_keys=True, ensure_ascii=False) + "\n"


def readme_text() -> str:
    return README_SOURCE.read_text(encoding="utf-8")


# ------------------------------------------------------------ seeded P3 inputs
def load_seed_popups(path: Path = SEED_POPUPS) -> list[dict]:
    if not path.is_file():
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def load_later_findings(path: Path = SEED_VERDICTS) -> dict[str, str]:
    """Finding id -> owner phase for adjudications the lead marked LATER."""
    later: dict[str, str] = {}
    if not path.is_file():
        return later
    text = path.read_text(encoding="utf-8")
    for match in re.finditer(r"^- (A-\d+) [^\n]*as LATER[^\n]*(?:\n(?:  [^\n]*\n)*)", text, re.MULTILINE):
        owner = re.search(r"owner ([A-Za-z0-9./-]+)", match.group(0))
        later[match.group(1)] = owner.group(1) if owner else "UNKNOWN"
    return later


def evidence_refs(entry: dict) -> list[tuple[str, int, int]]:
    refs = []
    for line in entry.get("evidence") or []:
        match = re.search(r"src_64/([^\s:]+\.lua):(\d+)(?:[–-](\d+))?", line)
        if not match:
            continue
        start = int(match.group(2))
        refs.append((match.group(1), start, int(match.group(3) or start)))
    return refs


def normalise_window(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def match_seed_row(seed_entry: dict, rows: list[dict]) -> dict | None:
    refs = evidence_refs(seed_entry)
    window = normalise_window(str(seed_entry.get("window") or ""))
    candidates = [row for row in rows if row["kind"] != "ERROR_TOAST"]
    best = None
    for file, start, end in refs:
        for row in candidates:
            if row["popup"]["file"] != file:
                continue
            if start <= row["popup"]["line"] <= end:
                return row
            if window and normalise_window(Path(file).stem) == window:
                distance = abs(row["popup"]["line"] - start)
                if best is None or distance < best[0]:
                    best = (distance, row)
    return best[1] if best else None


def seed_reviewed(rows: list[dict], seed_entries: list[dict]) -> tuple[dict, list[tuple[dict, str]]]:
    entries: dict[str, dict] = {}
    unmatched: list[tuple[dict, str]] = []
    for seed in seed_entries:
        status = seed.get("status")
        if status not in REVIEWED_STATUSES:
            continue
        row = match_seed_row(seed, rows)
        if row is None:
            unmatched.append((seed, "no catalogue row at the cited client file:line"))
            continue
        if status == "CLIENT_ONLY" and row["kind"] != "LOCAL":
            unmatched.append((seed, f"CLIENT_ONLY matched a {row['kind']} row"))
            continue
        if status == "UNUSED_BACKEND_GAP" and row["kind"] == "LOCAL":
            unmatched.append((seed, "UNUSED_BACKEND_GAP matched a LOCAL popup"))
            continue
        if status == "UNUSED_BACKEND_GAP" and row["status"] == "PRODUCED":
            unmatched.append((seed, "stale finding: every served MID produces the code"))
            continue
        entry = entries.setdefault(row["id"], {
            "status": status,
            "finding": seed.get("finding") or "",
            "evidence": list(seed.get("evidence") or []),
            "test": "",
        })
        if status == "UNUSED_BACKEND_GAP":
            entry["status"] = status
    return {"schema_version": 1, "note": "seeded from work/audit/t34/popups_t34.json; lead reviews", "entries": entries}, unmatched


def seed_waivers(rows: list[dict], reviewed: dict, later: dict[str, str]) -> tuple[dict, list[str]]:
    entries: dict[str, dict] = {}
    skipped: list[str] = []
    by_id = {row["id"]: row for row in rows}
    for identifier, reviewed_entry in sorted(reviewed["entries"].items()):
        if reviewed_entry.get("status") != "UNUSED_BACKEND_GAP":
            continue
        finding = reviewed_entry.get("finding") or ""
        if finding not in later:
            skipped.append(f"{identifier}: REVIEWED UNUSED_BACKEND_GAP without a LATER verdict ({finding or 'no finding'})")
            continue
        row = by_id.get(identifier)
        if row is None or row["status"] in ("PRODUCED", "CLIENT_ONLY", "UNBUILT"):
            skipped.append(f"{identifier}: not a GAP ({row['status'] if row else 'missing'})")
            continue
        entries[identifier] = {
            "reason": f"{finding} adjudicated LATER in work/audit/LEAD_VERDICTS.md; reported, not fixed",
            "client": f"{row['popup']['file']}:{row['popup']['line']}",
            "owner_phase": later[finding],
        }
    return {"schema_version": 1, "note": "seeded only for GAP rows adjudicated LATER; lead reviews", "entries": entries}, skipped


def load_entries(path: Path) -> dict:
    if not path.is_file():
        return {"schema_version": 1, "entries": {}}
    document = json.loads(path.read_text(encoding="utf-8"))
    document.setdefault("entries", {})
    return document


# ------------------------------------------------------------------------ CLI
def load_system_documents() -> tuple[dict, dict, dict]:
    index_document = json.loads((SYSTEM_MAP_DIRECTORY / "INDEX.json").read_text(encoding="utf-8"))
    mid_classes_document = json.loads((SYSTEM_MAP_DIRECTORY / "MID_CLASSES.json").read_text(encoding="utf-8"))
    mode_surface = json.loads(MODE_SURFACE_PATH.read_text(encoding="utf-8"))
    return index_document, mid_classes_document, mode_surface


def backend_source_files() -> dict[str, str]:
    files: dict[str, str] = {}
    for path in sorted(STOCKRUNTIME_DIRECTORY.glob("*.go")):
        if path.name.endswith("_test.go"):
            continue
        files[str(path.relative_to(ROOT))] = path.read_text(encoding="utf-8")
    return files


def build_from_archive(archive: Path, reviewed: dict, waivers: dict) -> tuple[dict, dict[str, str]]:
    with zipfile.ZipFile(archive) as bundle:
        blobs = rc.lua_blobs(bundle)
    index_document, mid_classes_document, mode_surface = load_system_documents()
    payload = build_catalog(blobs, backend_source_files(), index_document, mid_classes_document,
                            mode_surface, reviewed, waivers, rc.archive_sha())
    return payload, blobs


def gap_rows(payload: dict) -> list[dict]:
    return [row for row in payload["rows"] if row["status"] == "GAP"]


def check_problems(payload: dict, blobs: dict[str, str], reviewed: dict, waivers: dict) -> list[str]:
    problems = validate_inputs(payload["rows"], blobs, waivers, reviewed)
    problems.extend(f"GAP {row['id']} has no WAIVERS.json entry" for row in gap_rows(payload))
    return problems


def write_outputs(payload: dict, reviewed: dict, waivers: dict) -> None:
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    if not WAIVERS_PATH.exists():
        WAIVERS_PATH.write_text(json.dumps(waivers, indent=1, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
    if not REVIEWED_PATH.exists():
        REVIEWED_PATH.write_text(json.dumps(reviewed, indent=1, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
    CATALOG_PATH.write_text(serialise(payload), encoding="utf-8")
    README_PATH.write_text(readme_text(), encoding="utf-8")


def generated_outputs(payload: dict) -> dict[Path, str]:
    return {CATALOG_PATH: serialise(payload), README_PATH: readme_text()}


def show(key: str) -> None:
    payload = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    rows = payload["rows"]
    if key.isdigit():
        number = int(key)
        mid_rows = [row for row in rows if number in (row.get("trigger") or {}).get("mids", [])]
        if mid_rows:
            print(json.dumps({"mid": number, "popups": mid_rows}, indent=1, ensure_ascii=False))
            return
        code_rows = [row for row in rows if row["popup"].get("code") == number]
        if code_rows:
            print(json.dumps({"code": number, "popups": code_rows}, indent=1, ensure_ascii=False))
            return
        raise SystemExit(f"MID or code {key} has no popup row")
    system_rows = [row for row in rows if key in row["owner"].split(",")]
    if system_rows:
        print(json.dumps({"system": key, "popups": system_rows}, indent=1, ensure_ascii=False))
        return
    window_rows = [row for row in rows if row["popup"].get("window") == key]
    if window_rows:
        print(json.dumps({"window": key, "popups": window_rows}, indent=1, ensure_ascii=False))
        return
    raise SystemExit(f"system or window {key} has no popup row")


def owed(system: str) -> None:
    payload = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    rows = [
        row for row in payload["rows"]
        if system in row["owner"].split(",") and row["status"] not in ("PRODUCED", "CLIENT_ONLY")
    ]
    print(json.dumps({"system": system, "owed": rows}, indent=1, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-archive", type=Path)
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--write", action="store_true")
    action.add_argument("--check", action="store_true")
    parser.add_argument("words", nargs="*")
    arguments = parser.parse_args(argv)
    if arguments.write or arguments.check:
        if arguments.words:
            parser.error("--write/--check take no positional words")
        archive = arguments.source_archive or rc.resolve_archive(None)
        rc.verify_archive(archive)
        reviewed = load_entries(REVIEWED_PATH)
        waivers = load_entries(WAIVERS_PATH)
        payload, blobs = build_from_archive(archive, reviewed, waivers)
        if arguments.write:
            write_inputs = False
            if not REVIEWED_PATH.exists():
                reviewed, unmatched = seed_reviewed(payload["rows"], load_seed_popups())
                for seed, reason in unmatched:
                    print(f"unmatched T34 row: {seed.get('finding')} {seed.get('window')}: {reason}", file=sys.stderr)
                REVIEWED_PATH.parent.mkdir(parents=True, exist_ok=True)
                REVIEWED_PATH.write_text(json.dumps(reviewed, indent=1, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
                write_inputs = True
            if not WAIVERS_PATH.exists():
                waivers, skipped = seed_waivers(payload["rows"], reviewed, load_later_findings())
                for note in skipped:
                    print(f"waiver not seeded: {note}", file=sys.stderr)
                WAIVERS_PATH.write_text(json.dumps(waivers, indent=1, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")
                write_inputs = True
            if write_inputs:
                payload = finalise_payload(payload, reviewed, waivers)
        problems = [problem for problem in check_problems(payload, blobs, reviewed, waivers)
                    if arguments.check or "no WAIVERS.json entry" not in problem]
        for path, content in generated_outputs(payload).items():
            if arguments.check and (not path.exists() or path.read_text(encoding="utf-8") != content):
                problems.append(f"{path.relative_to(ROOT)} is stale; rerun with --write")
        if problems:
            for problem in problems:
                print(problem, file=sys.stderr)
            return 1
        if arguments.check:
            return 0
        for row in gap_rows(payload):
            print(f"GAP {row['id']}", file=sys.stderr)
        write_outputs(payload, reviewed, waivers)
        print(f"wrote {CATALOG_PATH.relative_to(ROOT)} rows={len(payload['rows'])} gaps={len(gap_rows(payload))}")
        return 0
    words = arguments.words
    if len(words) == 2 and words[0] == "show":
        show(words[1])
        return 0
    if len(words) == 2 and words[0] == "owed":
        owed(words[1])
        return 0
    parser.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
