#!/usr/bin/env python3
"""Extract the stock client's reply consumers for every MID the client sends.

The stock client decides wire shape, so this oracle reads it directly: for each
MID passed to ``Backend:request`` it records the reply callback (or the event
handler a callback-less reply is dispatched to) and every field path that
callback reads from the reply.  A path is *guarded* when the callback only
indexes it after a nil/truthiness check on that exact path; every unguarded
path is a REQUIRED obligation.

The walk is deliberately bounded.  It follows a reply into same-file helpers,
into ``import("app.model.X")``/``loadModel`` method bodies, one level of
storage in a module or instance field, and rows a model method returns from
such a field.  It never guesses: a callback it cannot resolve is UNKNOWN with
the reason and contributes no paths.

Every MID the gxb-api dispatcher table serves must also appear, because the
archguard coverage test fails on a served MID with no row.  A served MID that
has no stock-client request site is recorded ``"status": "UNKNOWN"`` with the
reason; it is never reported as checked.

REPAIR_PROGRAM R1 promised this checker as evidence, not as a schema.  A
confirmed REQUIRED path becomes a golden assertion in the MID's test; a false
positive or a path required only on one branch goes in WAIVERS.json with a
reason and the client file:line that shows the guard or the branch.

    tools/reply_consumers.py --source-archive ZIP --write
    tools/reply_consumers.py --source-archive ZIP --check

``--write`` regenerates docs/architecture/reply_consumers/REPLY_CONSUMERS.json,
copies it into the replyconformance package for go:embed, and creates
WAIVERS.json when it is absent (it is hand edited afterwards).
Sites are collapsed to one entry per (file, line) and encoded compactly:
``site_files`` interns every client path and a site row is
``[site_files index, line, guarded (0/1), sorted via values]``.

A MID in BRANCH_POLICIES keeps one obligation set per discriminator value: a
consumer site belongs to the value named by its Activity<table_id> window (the
client's own selection, ActivitiesWindow.lua:749-759) or by its request's static
activity id. Sites the extractor cannot attribute go to a branch marked
UNKNOWN, which the checker never selects.
"""
from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import os
import re
import sys
import zipfile
from dataclasses import dataclass, replace
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIRECTORY = ROOT / "docs/architecture/reply_consumers"
CONSUMERS_PATH = OUTPUT_DIRECTORY / "REPLY_CONSUMERS.json"
WAIVERS_PATH = OUTPUT_DIRECTORY / "WAIVERS.json"
EMBED_PATH = ROOT / "internal/protocol/replyconformance/reply_consumers.json"
LOCK_PATH = ROOT / "oracles.lock.json"
DEFAULT_ARCHIVE = ROOT / "inputs/assets/Older/all-assest-rechecked-1.zip"
SERVED_MIDS_PATH = ROOT / "docs/architecture/system_map/MID_CLASSES.json"
NO_CLIENT_REQUEST_REASON = "the stock client has no request site for this served MID"

SOURCE_PREFIX = "app-assets/output/assets/src_64/"
MID_LUA = "app/common/network/mid.lua"
ENUMS_LUA = "app/common/enums.lua"
MODEL_DEFINE_LUA = "data/tables/model_define.lua"
BACKEND_LUA = "app/common/network/Backend.lua"

KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
    "true", "until", "while",
}
LIBRARY_ROOTS = {
    "xyd", "table", "string", "math", "os", "io", "cc", "json", "print", "pairs",
    "ipairs", "next", "tonumber", "tostring", "type", "select", "unpack", "assert",
    "error", "pcall", "require", "import", "scheduleGlobal", "tolua",
}
# The R1 crash class this oracle must keep catching: (mid, required path).
SEED_PATHS = (
    ("work place award", 532, "award"),
    ("profile comments from_player_info", 1839, "comment_list[].from_player_info"),
    ("tournament A pet", 1292, "A_pet_info"),
    ("tournament B pet", 1292, "B_pet_info"),
    ("world boss pre_info", 628, "pre_info"),
    ("friend count", 176, "count"),
    ("friend list", 176, "list"),
    ("friend request player", 177, "player_id"),
    ("black list player profile", 185, "player_info"),
)
REQUIREMENT_CODES = {"REQUIRED": 1, "OPTIONAL": 0, "WAIVED": 2}
REQUIREMENT_NAMES = {code: name for name, code in REQUIREMENT_CODES.items()}
LUA_STANDARD_LIBRARIES = frozenset({"coroutine", "debug", "io", "math", "os", "package", "string", "table", "utf8"})


@dataclass(frozen=True)
class Token:
    kind: str
    value: str
    line: int
    offset: int


@dataclass
class Function:
    file: str
    start: int
    body_start: int
    end: int
    name: str | None
    params: list[str]
    parent: "Function | None" = None


@dataclass(frozen=True)
class Taint:
    path: tuple[str, ...] = ()
    wrapper: str | None = None
    followed: frozenset[str] = frozenset()
    branch: str | None = None
    # Length of the path prefix the client keeps as one entry of a keyed table (teams[team_id] = team_info).
    record: int | None = None
    # STATE_BRANCH guards the value was stored under (self.data = self.friendlist under windowState == FriendList).
    states: frozenset = frozenset()


@dataclass(frozen=True)
class Site:
    file: str
    line: int
    via: str
    guarded: bool
    branch: str | None = None


# A reply whose consumer depends on a client-side discriminator (the selected
# activity window, or a request field naming the entity) carries one obligation
# set per discriminator value instead of one union for the whole MID.
# Sol's A-091 evidence: ActivitiesWindow.lua:749-759 imports Activity<table_id>,
# so each Activity<id>.lua window consumes only its own activity reply.
@dataclass(frozen=True)
class BranchPolicy:
    reply_key: str
    request_keys: tuple[str, ...]
    window_pattern: str = r"app/windows/activities/Activity(\d+)\.lua"


BRANCH_POLICIES = {
    234: BranchPolicy(reply_key="table_id", request_keys=("activity_id", "table_id")),
}
# A MID consumed by more than one Activity<table_id> window that needs no branch
# split, with the evidence. branch_coverage_problems fails on a new split MID.
BRANCH_POLICY_EXEMPTIONS = {
    1: "RETRIEVE_TOKEN's detail is a per-MID map: Activity windows read their own entry and the request carries no activity discriminator, so the union is the batch model, not a selectable branch",
    231: "request-discriminated by activity_id at getActivityReward call sites; the reply carries no discriminator the edge checker can select, and the MID is inactive (fallback only)",
    629: "the NIAN_BOSS reply is one shape (the request carries no discriminator); Activity1038 and Activity1065 read the same shared NianBoss model fields, so their union is required and no per-branch set exists",
}
# Guard marker prefix for a body entered only when a field of a list element
# compares equal (or unequal) to something: elements are tagged records
# (createNoticeItemContent's notice_type), so that element's reads in the body
# are conditional. A top-level comparison (1292 `stage == 0`) marks nothing: the
# R1 crash A_pet_info sits under one.
VALUE_BRANCH = "<value branch>"
# Guard marker prefix for a condition chain this scan cannot resolve to a reply
# path (the variable is seeded only at its later reads): it guards reads of the
# same local variable and field path, never a same-named field of another one.
LOCAL_GUARD = "<local>"
# Guard marker for `self.field == CONSTANT` (SocialSystemWindow's windowState): a
# value stored under one constant never reaches a branch on another constant of
# the same field, so self.data's friend rows do not reach the notice builder.
STATE_BRANCH = "<state>"
UNKNOWN_BRANCH = "unknown"
BRANCH_UNKNOWN_REASON = "the consumer site is neither inside an Activity<table_id> window nor reachable from a request with a static activity id"


@dataclass
class FunctionIndex:
    tokens: list[Token]
    functions: list[Function]
    by_start: dict[int, Function]
    by_name: dict[str, Function]
    innermost: list[Function | None]


class Tokenizer:
    def __init__(self, text: str):
        self.text = text
        self.length = len(text)

    def tokens(self) -> list[Token]:
        text, length = self.text, self.length
        out: list[Token] = []
        index = 0
        line = 1
        while index < length:
            character = text[index]
            if character == "\n":
                line += 1
                index += 1
                continue
            if character in " \t\r":
                index += 1
                continue
            long_string = _long_bracket(text, index)
            if long_string is not None:
                content, index, line = long_string
                out.append(Token("string", content, line, index))
                continue
            if text.startswith("--", index):
                index, line = _skip_comment(text, index, line)
                continue
            if character in "\"'":
                token, index, line = _short_string(text, index, line)
                out.append(token)
                continue
            if character.isdigit() or (character == "." and index + 1 < length and text[index + 1].isdigit()):
                start = index
                index = _number_end(text, index)
                out.append(Token("number", text[start:index], line, start))
                continue
            if character.isalpha() or character == "_":
                start = index
                while index < length and (text[index].isalnum() or text[index] == "_"):
                    index += 1
                word = text[start:index]
                out.append(Token("kw" if word in KEYWORDS else "name", word, line, start))
                continue
            start = index
            for width in (3, 2):
                if text[index:index + width] in ("...", "..", "==", "~=", "<=", ">=", "//", "::", "<<", ">>"):
                    index += width
                    break
            else:
                index += 1
            out.append(Token("punct", text[start:index], line, start))
        return out


def _long_bracket(text: str, index: int) -> tuple[str, int, int] | None:
    match = re.match(r"\[(=*)\[", text[index:])
    if not match:
        return None
    close = "]" + match.group(1) + "]"
    content_start = index + match.end()
    close_at = text.find(close, content_start)
    if close_at < 0:
        return text[content_start:], len(text), text.count("\n", 0, content_start)
    return text[content_start:close_at], close_at + len(close), text.count("\n", 0, content_start)


def _skip_comment(text: str, index: int, line: int) -> tuple[int, int]:
    match = re.match(r"--\[(=*)\[", text[index:])
    if match:
        close = "]" + match.group(1) + "]"
        content_start = index + match.end()
        close_at = text.find(close, content_start)
        if close_at < 0:
            return len(text), line + text.count("\n", 0, len(text))
        after = close_at + len(close)
        return after, line + text.count("\n", 0, after)
    newline = text.find("\n", index)
    if newline < 0:
        return len(text), line
    return newline, line + 1


def _short_string(text: str, index: int, line: int) -> tuple[Token, int, int]:
    quote = text[index]
    start = index
    index += 1
    content_start = index
    while index < len(text):
        character = text[index]
        if character == "\\":
            index += 2
            continue
        if character == quote:
            return Token("string", text[content_start:index], line, start), index + 1, line
        if character == "\n":
            line += 1
        index += 1
    return Token("string", text[content_start:], line, start), len(text), line


def _number_end(text: str, index: int) -> int:
    match = re.match(r"0[xX][0-9a-fA-F]+|(?:\d+\.\d*|\.\d+|\d+)(?:[eE][+-]?\d+)?", text[index:])
    return index + (match.end() if match else 1)


def index_functions(file: str, tokens: list[Token]) -> FunctionIndex:
    matches: dict[int, int] = {}
    stack: list[int] = []
    for index, token in enumerate(tokens):
        if token.kind != "kw":
            continue
        if token.value == "function":
            stack.append(index)
        elif token.value in ("if", "do", "repeat"):
            stack.append(-index - 1)
        elif token.value in ("end", "until") and stack:
            opener = stack.pop()
            if opener >= 0:
                matches[opener] = index
    functions: list[Function] = []
    by_start: dict[int, Function] = {}
    for opener in sorted(matches):
        parsed = _parse_function(file, tokens, opener, matches[opener])
        if parsed is not None:
            functions.append(parsed)
            by_start[opener] = parsed
    innermost: list[Function | None] = [None] * len(tokens)
    active: list[Function] = []
    for index in range(len(tokens)):
        while active and index > active[-1].end:
            active.pop()
        parsed = by_start.get(index)
        if parsed is not None:
            parsed.parent = active[-1] if active else None
            active.append(parsed)
        innermost[index] = active[-1] if active else None
    return FunctionIndex(tokens, functions, by_start, _named_functions(tokens, by_start), innermost)


def _parse_function(file: str, tokens: list[Token], opener: int, end: int) -> Function | None:
    index = opener + 1
    name: str | None = None
    if index < len(tokens) and tokens[index].kind == "name":
        name = tokens[index].value
        index += 1
        while index + 1 < len(tokens) and tokens[index].value in (".", ":"):
            if tokens[index + 1].kind != "name":
                break
            name = tokens[index + 1].value
            index += 2
    while index < len(tokens) and tokens[index].value != "(":
        index += 1
    if index >= len(tokens):
        return None
    params: list[str] = []
    index += 1
    while index < len(tokens) and tokens[index].value != ")":
        if tokens[index].kind == "name":
            params.append(tokens[index].value)
        index += 1
    return Function(file, opener, index + 1, end, name, params)


def _named_functions(tokens: list[Token], by_start: dict[int, Function]) -> dict[str, Function]:
    by_name: dict[str, Function] = {}
    for index, token in enumerate(tokens):
        if token.value != "local" or index + 3 >= len(tokens):
            continue
        if tokens[index + 1].value == "function" and tokens[index + 1].kind == "kw":
            parsed = by_start.get(index + 1)
            if parsed is not None and tokens[index + 2].kind == "name":
                by_name[tokens[index + 2].value] = parsed
        elif (
            tokens[index + 1].kind == "name"
            and tokens[index + 2].value == "="
            and tokens[index + 3].value == "function"
            and tokens[index + 3].kind == "kw"
        ):
            parsed = by_start.get(index + 3)
            if parsed is not None:
                by_name[tokens[index + 1].value] = parsed
    for parsed in by_start.values():
        if parsed.name:
            by_name.setdefault(parsed.name, parsed)
    return by_name


def split_arguments(tokens: list[Token], open_index: int) -> tuple[list[tuple[int, int]], int]:
    depth = 0
    arguments: list[tuple[int, int]] = []
    start = open_index + 1
    index = open_index + 1
    while index < len(tokens):
        value = tokens[index].value
        if value in ("(", "{", "["):
            depth += 1
        elif value in (")", "}", "]"):
            if depth == 0:
                if index > start:
                    arguments.append((start, index))
                return arguments, index
            depth -= 1
        elif value == "," and depth == 0:
            arguments.append((start, index))
            start = index + 1
        index += 1
    return arguments, len(tokens) - 1


def matching_close(tokens: list[Token], open_index: int) -> int:
    depth = 0
    pairs = {"(": ")", "{": "}", "[": "]"}
    open_value = tokens[open_index].value
    close_value = pairs[open_value]
    for index in range(open_index, len(tokens)):
        if tokens[index].value == open_value:
            depth += 1
        elif tokens[index].value == close_value:
            depth -= 1
            if depth == 0:
                return index
    return len(tokens) - 1


def chain_at(tokens: list[Token], index: int) -> tuple[str, list[tuple[str, str]], int]:
    root = tokens[index].value
    segments: list[tuple[str, str]] = []
    index += 1
    while index < len(tokens):
        value = tokens[index].value
        if value == "." and index + 1 < len(tokens) and tokens[index + 1].kind == "name":
            segments.append(("field", tokens[index + 1].value))
            index += 2
            continue
        if value == ":" and index + 1 < len(tokens) and tokens[index + 1].kind == "name":
            segments.append(("method", tokens[index + 1].value))
            index += 2
            continue
        if value == "[":
            index = matching_close(tokens, index) + 1
            segments.append(("index", ""))
            continue
        break
    return root, segments, index


def extend_taint(taint: Taint, segments: list[tuple[str, str]]) -> Taint:
    parts = list(taint.path)
    for kind, name in segments:
        if kind == "field":
            parts.append(name)
        elif kind == "index":
            if not parts or parts[-1] != "[]":
                parts.append("[]")
        else:
            break
    return replace(taint, path=tuple(parts))


def element(taint: Taint) -> Taint:
    if taint.path and taint.path[-1] == "[]":
        return taint
    return replace(taint, path=taint.path + ("[]",))


def path_parts(taint: Taint, segments: list[tuple[str, str]]) -> list[tuple[str, ...]]:
    """A taint with a wrapper names a field of the value it is bound to (the
    event's params, or a table argument's field).  Only an access that reaches
    that field reads the reply; the field itself is not part of the path."""
    parts = list(taint.path)
    wrapper = taint.wrapper
    if wrapper is not None:
        stripped = False
        if parts and parts[0] == wrapper:
            parts = parts[1:]
            stripped = True
        if segments and segments[0] == ("field", wrapper):
            segments = segments[1:]
            stripped = True
        if not stripped:
            return []
    out: list[tuple[str, ...]] = []

    def emit() -> None:
        if parts:
            out.append(tuple(parts))

    emit()
    for kind, name in segments:
        if kind == "field":
            parts.append(name)
        elif kind == "index":
            if not parts or parts[-1] != "[]":
                parts.append("[]")
        else:
            break
        emit()
    return out


def path_string(parts) -> str:
    out = ""
    for part in parts:
        if part == "[]":
            out += "[]"
        else:
            out += ("." if out else "") + part
    return out


class Extractor:
    def __init__(self, blobs: dict[str, str]):
        self.blobs = blobs
        self.mid_symbols = parse_mid_symbols(blobs.get(MID_LUA, ""))
        self.activity_symbols = parse_activity_symbols(blobs.get(ENUMS_LUA, ""))
        self.model_types = parse_model_types(blobs.get(ENUMS_LUA, ""))
        self.model_classes = parse_model_define(blobs.get(MODEL_DEFINE_LUA, ""))
        self.classes = parse_classes(blobs)
        self.file_indexes: dict[str, FunctionIndex] = {}
        self.file_aliases: dict[str, dict[str, str]] = {}
        self.file_imports: dict[str, dict[str, str]] = {}
        self.file_lazy_models: dict[str, dict[str, str]] = {}
        self.class_files: dict[tuple[str, str | None], list[str]] = {}
        self.paths: dict[str, dict[str, dict[tuple[str, int, str, bool, str | None], Site]]] = {}
        self.callbacks: dict[str, list[dict]] = {}
        self.stores: dict[tuple[str, str | None, tuple[tuple[str, str], ...]], dict[Taint, set[int]]] = {}
        self.file_stores: dict[tuple[str, tuple[tuple[str, str], ...]], dict[Taint, set[int]]] = {}
        self.return_methods: dict[tuple[str, str | None, str], dict[Taint, set[int]]] = {}
        self.event_handlers, self.event_handler_unresolved = parse_event_handlers(blobs)
        self.mid_events = parse_mid_events(blobs.get(BACKEND_LUA, ""), self.mid_symbols)
        self.replay: set[tuple] = set()

    # ---------------------------------------------------------------- indexes
    def index(self, file: str) -> FunctionIndex:
        cached = self.file_indexes.get(file)
        if cached is None:
            cached = index_functions(file, Tokenizer(self.blobs[file]).tokens())
            self.file_indexes[file] = cached
            self.file_aliases[file] = parse_aliases(self.blobs[file], self.model_types, self.model_classes)
        return cached

    def aliases(self, file: str) -> dict[str, str]:
        cached = self.file_aliases.get(file)
        if cached is None:
            cached = parse_aliases(self.blobs[file], self.model_types, self.model_classes)
            self.file_aliases[file] = cached
        return cached

    def import_aliases(self, file: str) -> dict[str, str]:
        cached = self.file_imports.get(file)
        if cached is None:
            cached = parse_import_aliases(self.blobs[file])
            self.file_imports[file] = cached
        return cached

    def lazy_model_aliases(self, file: str) -> dict[str, str]:
        cached = self.file_lazy_models.get(file)
        if cached is None:
            cached = parse_lazy_model_aliases(self.blobs[file], self.model_types, self.model_classes)
            self.file_lazy_models[file] = cached
        return cached

    def wrapper_receiver_class(self, file: str, function: Function | None, root: str,
                               segments: list[tuple[str, str]]) -> str | None:
        resolved = _alias_receiver_class(root, segments, self.aliases(file), self.import_aliases(file),
                                         self.lazy_model_aliases(file))
        if resolved is not None:
            return resolved
        seen = {self.file_class(file)}
        parent = self.class_parent(self.file_class(file))
        while parent and parent not in seen:
            seen.add(parent)
            parent_file = self.class_file(parent)
            if parent_file and parent_file != file:
                resolved = _alias_receiver_class(root, segments, self.aliases(parent_file),
                                                 self.import_aliases(parent_file), self.lazy_model_aliases(parent_file))
                if resolved is not None:
                    return resolved
            parent = self.class_parent(parent)
        if not segments:
            return enclosing_self_class(self.file_class(file), function, root)
        if root == "var_0_0" and segments[0] == ("field", "super"):
            return self.class_parent(self.file_class(file))
        return None

    def files_for_class(self, class_name: str, definition_file: str | None = None) -> list[str]:
        cache_key = (class_name, definition_file)
        cached = self.class_files.get(cache_key)
        if cached is not None:
            return cached
        files = []
        for file, text in self.blobs.items():
            if not file.startswith("app/"):
                continue
            if "loadModel" not in text and "import(" not in text:
                continue
            defines = file_class_name(text) == class_name
            if definition_file is not None and defines and file != definition_file:
                continue
            aliases = self.aliases(file)
            if class_name in aliases.values() or defines:
                files.append(file)
        self.class_files[cache_key] = files
        return files

    def class_file(self, class_name: str | None) -> str | None:
        entry = self.classes.get(class_name or "")
        return entry[0] if entry else None

    def class_parent(self, class_name: str | None) -> str | None:
        entry = self.classes.get(class_name or "")
        return entry[1] if entry else None

    def file_class(self, file: str) -> str | None:
        return file_class_name(self.blobs[file])

    def resolve_method(self, class_name: str | None, method: str) -> tuple[str, Function] | None:
        seen: set[str] = set()
        while class_name and class_name not in seen:
            seen.add(class_name)
            file = self.class_file(class_name)
            if file is None or file not in self.blobs:
                return None
            parsed = self.index(file).by_name.get(method)
            if parsed is not None:
                return file, parsed
            class_name = self.class_parent(class_name)
        return None

    # -------------------------------------------------------------- collection
    def run(self) -> None:
        self.collect_requests()
        normalise_store_rows(self.stores)
        normalise_store_rows(self.file_stores)
        for _ in range(3):
            before = self._counts()
            self.resolve_stored_fields()
            self.resolve_return_methods()
            if self._counts() == before:
                break

    def _counts(self) -> tuple[int, int]:
        stores = sum(len(taints) for taints in self.stores.values()) + sum(
            len(taints) for taints in self.file_stores.values())
        returns = sum(len(taints) for taints in self.return_methods.values())
        return stores, returns

    def add_site(self, mid: int, path: str, site: Site) -> None:
        if not path or path.startswith("[]") or path.endswith("[]."):
            return
        sites = self.paths.setdefault(str(mid), {}).setdefault(path, {})
        sites[(site.file, site.line, site.via, site.guarded, site.branch)] = site

    def branch_for_site(self, mid: int, file: str, branch: str | None) -> str | None:
        policy = BRANCH_POLICIES.get(mid)
        if policy is None:
            return None
        match = re.fullmatch(policy.window_pattern, file)
        if match:
            return match.group(1)
        return branch

    def collect_requests(self) -> None:
        for file in sorted(self.blobs):
            if not file.startswith("app/"):
                continue
            tokens = self.index(file).tokens
            for position, token in enumerate(tokens):
                if token.kind == "name" and token.value == "request" and _is_request_call(tokens, position):
                    self.analyze_request(file, tokens, position)

    def analyze_request(self, file: str, tokens: list[Token], position: int) -> None:
        arguments, _ = split_arguments(tokens, position + 1)
        if not arguments:
            return
        mid = self.request_mid(tokens, arguments[0])
        if mid is None:
            return
        line = tokens[position].line
        callback_present = len(arguments) >= 3 and tokens[arguments[2][0]].value != "nil"
        if callback_present:
            self.analyze_callback(mid, file, tokens, arguments, position, line)
        self.analyze_event_reply(mid, file, line, callback_present)

    def analyze_callback(self, mid, file, tokens, arguments, position, line) -> None:
        callback_start, callback_end = arguments[2]
        branch = self.argument_branch(mid, file, tokens, arguments[1], position)
        if tokens[callback_start].value == "function" and tokens[callback_start].kind == "kw":
            parsed = self.index(file).by_start.get(callback_start)
            if parsed is None:
                self.record_callback(mid, _unknown(file, line, "unterminated inline callback"))
                return
            self.record_callback(mid, _checked(file, line))
            self.analyze_reply(mid, file, parsed, Taint(branch=branch), "callback")
            enclosing = parsed.parent
            if enclosing is not None and enclosing.name and _forwards_reply(tokens, parsed, enclosing):
                callbacks, unresolved = resolve_wrapper_callbacks(self, mid, enclosing.name, file, enclosing)
                for caller_file, caller_function, body, caller_branch in callbacks:
                    self.analyze_reply(mid, caller_file, caller_function, Taint(branch=caller_branch), f"{enclosing.name} call site", body)
                if unresolved:
                    self.record_callback(mid, _unknown(file, line, _unresolved_receiver_reason(enclosing.name, unresolved)))
            return
        if callback_end - callback_start == 1 and tokens[callback_start].kind == "name":
            name = tokens[callback_start].value
            parsed = self.index(file).by_name.get(name)
            if parsed is not None:
                self.record_callback(mid, _checked(file, line))
                self.analyze_reply(mid, file, parsed, Taint(branch=branch), "callback")
                return
            enclosing = self.index(file).innermost[callback_start]
            if enclosing is not None and name in enclosing.params:
                self.analyze_forwarded_callback(mid, file, line, enclosing, name)
                return
            self.record_callback(mid, _unknown(file, line, f"callback symbol {name} is not a resolvable local function"))
            return
        expression = " ".join(token.value for token in tokens[callback_start:callback_end])
        wrapped = _wrapper_callback(tokens, callback_start, callback_end)
        if wrapped is not None:
            self.record_callback(mid, _checked(file, line, "wrapper callback"))
            self.analyze_reply(mid, file, wrapped, Taint(branch=branch), "callback")
            return
        self.record_callback(mid, _unknown(file, line, f"callback expression {expression[:80]!r} is not resolvable statically"))

    def request_mid(self, tokens: list[Token], argument: tuple[int, int]) -> int | None:
        start, end = argument
        values = [token.value for token in tokens[start:end]]
        if len(values) == 5 and values[1:4] == [".", "mid", "."]:
            return self.mid_symbols.get(values[4])
        if len(values) == 3 and values[0] == "mid" and values[1] == ".":
            return self.mid_symbols.get(values[2])
        if len(values) == 1 and tokens[start].kind == "number":
            try:
                return int(values[0], 0)
            except ValueError:
                return None
        return None

    def analyze_forwarded_callback(self, mid, file, line, enclosing, parameter) -> None:
        method = enclosing.name
        if not method:
            self.record_callback(mid, _unknown(file, line, f"callback forwards to parameter {parameter} of an unnamed function"))
            return
        callbacks, unresolved = resolve_wrapper_callbacks(self, mid, method, file, enclosing)
        if not callbacks:
            reason = _unresolved_receiver_reason(method, unresolved) if unresolved else f"no {method} call site resolves"
            self.record_callback(mid, _unknown(file, line, f"callback forwards to parameter {parameter}; {reason}"))
            return
        if unresolved:
            self.record_callback(mid, _unknown(file, line, _unresolved_receiver_reason(method, unresolved)))
        else:
            self.record_callback(mid, _checked(file, line, f"forwarded to {method} call sites"))
        for caller_file, caller_function, body, branch in callbacks:
            self.analyze_reply(mid, caller_file, caller_function, Taint(branch=branch), f"{method} call site", body)

    def call_branch(self, mid, file, tokens, arguments, position) -> str | None:
        policy = BRANCH_POLICIES.get(mid)
        if policy is None:
            return None
        for argument in arguments:
            value = self.expression_branch(policy, file, tokens, argument, position)
            if value is not None:
                return value
        return UNKNOWN_BRANCH

    def argument_branch(self, mid, file, tokens, argument, position) -> str | None:
        policy = BRANCH_POLICIES.get(mid)
        if policy is None:
            return None
        expression = self.expression_branch(policy, file, tokens, argument, position)
        if expression is None:
            return UNKNOWN_BRANCH
        return expression

    def expression_branch(self, policy, file, tokens, argument, position, depth=0) -> str | None:
        if depth > 2:
            return None
        start, end = argument
        if start >= end:
            return None
        if tokens[start].value == "{":
            return self.table_branch(policy, file, tokens, start, position, depth)
        if tokens[start].kind == "number" and end - start == 1:
            return tokens[start].value
        if end - start == 1 and tokens[start].kind == "name":
            return self.local_branch(policy, file, tokens, tokens[start].value, position, depth)
        return None

    def table_branch(self, policy, file, tokens, open_index, position, depth) -> str | None:
        close = matching_close(tokens, open_index)
        cursor = open_index + 1
        while cursor + 2 < close:
            if tokens[cursor].kind == "name" and tokens[cursor].value in policy.request_keys and tokens[cursor + 1].value == "=":
                value_end = _expression_end(tokens, cursor + 2, close)
                return self.scalar_branch(policy, file, tokens, cursor + 2, value_end, position, depth)
            cursor += 1
        return None

    def scalar_branch(self, policy, file, tokens, start, end, position, depth) -> str | None:
        if start >= end or depth > 2:
            return None
        if tokens[start].kind == "number" and end - start == 1:
            return tokens[start].value
        values = [token.value for token in tokens[start:end]]
        if len(values) == 5 and values[:4] == ["xyd", ".", "Activities", "."]:
            value = self.activity_symbols.get(values[4])
            return str(value) if value is not None else None
        if end - start == 1 and tokens[start].kind == "name":
            return self.local_branch(policy, file, tokens, tokens[start].value, position, depth + 1)
        return None

    def local_branch(self, policy, file, tokens, name, position, depth) -> str | None:
        """Resolve a local table or scalar defined earlier in the same function."""
        index = self.index(file)
        function = index.innermost[position]
        start = function.body_start if function is not None else 0
        value_start = None
        cursor = start
        while cursor < position:
            token = tokens[cursor]
            if token.kind == "name" and token.value == name:
                previous = tokens[cursor - 1].value if cursor > start else ""
                if previous not in (".", ":"):
                    found = _assignment_value_start(tokens, cursor, position)
                    if found is not None:
                        value_start = found
            cursor += 1
        if value_start is None:
            return None
        value_end = _expression_end(tokens, value_start, position)
        return self.expression_branch(policy, file, tokens, (value_start, value_end), position, depth + 1)

    def analyze_event_reply(self, mid, file, line, callback_present: bool = False) -> None:
        if mid & 36864 == 32768:
            if not callback_present:
                self.record_callback(mid, _unknown(file, line, "chat-room transport: reply is a socket push, not an HTTP reply"))
            return
        event = self.mid_events.get(mid)
        if event is None:
            if not callback_present:
                self.record_callback(mid, _unknown(file, line, "no callback and no mid-to-event mapping"))
            return
        handlers = self.event_handlers.get(event, [])
        unresolved = self.event_handler_unresolved.get(event, [])
        if unresolved:
            self.record_callback(mid, _unknown(file, line, f"dispatch of xyd.event.{event} has an unresolvable listener: {unresolved[0]}"))
        elif handlers:
            self.record_callback(mid, _checked(file, line, f"dispatched as xyd.event.{event}"))
        else:
            self.record_callback(mid, _checked(file, line, f"dispatched as xyd.event.{event}; the client registers no listener"))
        for handler_file, handler in handlers:
            self.analyze_reply(mid, handler_file, handler, Taint(wrapper="params"), f"event {event}")

    def record_callback(self, mid, entry) -> None:
        self.callbacks.setdefault(str(mid), []).append(entry)

    # ----------------------------------------------------------- reply scanning
    def analyze_reply(self, mid, file, function, binding, via, body=None) -> None:
        if len(function.params) < 2 and binding.wrapper != "params":
            return
        bindings: dict[str, tuple[Taint, frozenset[int]]] = {}
        if binding.wrapper == "params":
            parameter = function.params[1] if len(function.params) > 1 else (function.params[0] if function.params else None)
            if parameter:
                bindings[parameter] = (binding, frozenset({mid}))
        elif len(function.params) > 1:
            bindings[function.params[1]] = (binding, frozenset({mid}))
        start, end = body if body else (function.body_start, function.end)
        self.scan(mid, file, function, start, end, bindings, via, frozenset(), None, None)

    def scan(self, mid, file, function, start, end, bindings, via, guards, seeds, returned) -> None:
        index = self.index(file)
        tokens = index.tokens
        position = start
        while position < end:
            token = tokens[position]
            if seeds and position in seeds:
                local = chain_at(tokens, position) if token.kind == "name" else None
                # A stored field seeded at an assignment target is written, not read.
                assigned = local is not None and local[2] < end and tokens[local[2]].value == "="
                for taint, mids, via_seed in [] if assigned else seeds[position]:
                    self.record_read(file, token.line, taint, [], via_seed, guards, mids, local=local[:2] if local else None)
            if token.kind == "kw":
                if token.value == "local":
                    position = self.handle_local(file, position, end, bindings, seeds)
                    continue
                if token.value == "for":
                    position = self.handle_for(mid, file, function, position, end, bindings, via, guards, seeds)
                    continue
                if token.value == "if":
                    position = self.handle_if(mid, file, function, position, bindings, via, guards, seeds)
                    continue
                if token.value == "function":
                    parsed = index.by_start.get(position)
                    if parsed is not None and parsed.end < end:
                        inner = dict(bindings)
                        if parsed.params and parsed.name is None:
                            inner[parsed.params[0]] = (Taint(), mid_set(mid))
                        self.scan(mid, file, parsed, parsed.body_start, parsed.end, inner, via, guards, seeds, returned)
                        position = parsed.end + 1
                        continue
                if token.value == "return" and returned is not None:
                    found = self.expression_taint(file, position + 1, bindings, seeds)
                    if found is not None:
                        returned.append(found)
                    position += 1
                    continue
                position += 1
                continue
            if token.kind != "name":
                position += 1
                continue
            root, segments, after = chain_at(tokens, position)
            if root == "table" and segments[:1] == [("field", "insert")] and after < end and tokens[after].value == "(":
                self.handle_insert(mid, file, function, position, after, bindings, via, guards, seeds)
                position = after
                continue
            if after < end and tokens[after].value == "=":
                position = self.handle_assignment(mid, file, function, root, segments, after, bindings, seeds, via, guards)
                continue
            if after < end and tokens[after].value == "(":
                self.handle_call(mid, file, function, position, root, segments, after, bindings, via, guards, seeds)
                position = after
                continue
            if root in bindings:
                taint, mids = bindings[root]
                fallback = after < end and tokens[after].value == "or"
                self.record_read(file, token.line, taint, segments, via, guards, mids, fallback, (root, segments))
            position = after

    def record_read(self, file, line, taint, segments, via, guards, mids, fallback=False, local=None) -> None:
        emitted = path_parts(taint, segments)
        local_guards: set[tuple[str, ...]] = set()
        base = 0
        if local is not None and emitted:
            local_guards = {guard[2:] for guard in guards if guard[:2] == (LOCAL_GUARD, local[0])}
            base = len(emitted[-1]) - len(_segment_parts(local[1]))
        for parts in emitted:
            path = path_string(parts)
            if not path:
                continue
            guarded = fallback or parts in guards or base >= 0 and parts[base:] in local_guards or any(
                guard[0] == VALUE_BRANCH and parts[:len(guard) - 1] == guard[1:] for guard in guards
            )
            for mid in mids:
                self.add_site(mid, path, Site(file, line, via, guarded, self.branch_for_site(mid, file, taint.branch)))

    # ------------------------------------------------------------- statements
    def handle_local(self, file, position, end, bindings, seeds) -> int:
        tokens = self.index(file).tokens
        index = position + 1
        names: list[str] = []
        while index < end and (tokens[index].kind == "name" or tokens[index].value == ","):
            if tokens[index].kind == "name":
                names.append(tokens[index].value)
            index += 1
        for name in names:
            bindings.pop(name, None)
        if index >= end or tokens[index].value != "=":
            return index
        value_start = index + 1
        found = self.expression_taint(file, value_start, bindings, seeds)
        if found is not None and names:
            bindings[names[0]] = found
        return value_start

    def handle_assignment(self, mid, file, function, root, segments, after, bindings, seeds, via, guards) -> int:
        value_start = after + 1
        found = self.expression_taint(file, value_start, bindings, seeds)
        if any(kind == "field" for kind, _ in segments):
            if found is not None:
                self.record_store(mid, file, function, root, segments, found, guards)
            return value_start
        previous = bindings.get(root)
        if found is None:
            bindings.pop(root, None)
            return value_start
        bindings[root] = found
        if previous is None:
            return value_start
        tokens = self.index(file).tokens
        if value_start >= len(tokens) or tokens[value_start].kind != "name":
            return value_start
        rhs_root, rhs_segments, rhs_end = chain_at(tokens, value_start)
        if rhs_root != root:
            return value_start
        fallback = rhs_end < len(tokens) and tokens[rhs_end].value == "or"
        self.record_read(file, tokens[value_start].line, previous[0], rhs_segments, via, guards, previous[1], fallback)
        return rhs_end

    def record_store(self, mid, file, function, receiver_root, segments, found, guards) -> None:
        taint, mids = found
        states = frozenset(guard for guard in guards if guard[0] == STATE_BRANCH)
        if states:
            taint = replace(taint, states=taint.states | states)
        store_path = tuple(segments)
        if taint.wrapper is not None:
            if not taint.path or taint.path[0] != taint.wrapper:
                return
            taint = replace(taint, path=taint.path[1:], wrapper=None, record=None)
        owner = None
        owner_file = None
        if function.params and receiver_root == function.params[0]:
            owner = self.file_class(file)
            owner_file = file
        if owner is None:
            owner = enclosing_self_class(self.file_class(file), function, receiver_root)
            if owner is not None:
                owner_file = file
        if owner is None:
            alias_component = next((name for kind, name in segments if kind == "field"), None)
            owner = self.aliases(file).get(receiver_root) or self.aliases(file).get(alias_component or "")
            if owner is not None:
                owner_file = self.class_file(owner) or file
        if owner:
            self.stores.setdefault((owner, owner_file, store_path), {}).setdefault(taint, set()).update(mids)
        self.file_stores.setdefault((file, store_path), {}).setdefault(taint, set()).update(mids)

    def handle_insert(self, mid, file, function, position, after, bindings, via, guards, seeds) -> None:
        del position
        tokens = self.index(file).tokens
        arguments, _ = split_arguments(tokens, after)
        if len(arguments) < 2:
            return
        container_start = arguments[0][0]
        value = self.expression_taint(file, arguments[1][0], bindings, seeds)
        if value is None:
            return
        taint, mids = value
        if container_start < len(tokens) and tokens[container_start].kind == "name":
            root, segments, _ = chain_at(tokens, container_start)
            if any(kind == "field" for kind, _ in segments):
                self.record_store(mid, file, function, root, segments, (element(taint), mids), guards)
            else:
                bindings[root] = (element(taint), mids)
        del via

    def handle_for(self, mid, file, function, position, end, bindings, via, guards, seeds) -> int:
        tokens = self.index(file).tokens
        do_index = _loop_do(tokens, position, end)
        if do_index is None:
            return position + 1
        loop_end = _block_end(tokens, do_index)
        names: list[str] = []
        cursor = position + 1
        while cursor < do_index and tokens[cursor].value not in ("in", "="):
            if tokens[cursor].kind == "name":
                names.append(tokens[cursor].value)
            cursor += 1
        if cursor < do_index and tokens[cursor].value == "in" and names:
            value_start = cursor + 1
            if tokens[value_start].value in ("pairs", "ipairs") and tokens[value_start + 1].value == "(":
                arguments, _ = split_arguments(tokens, value_start + 1)
                if arguments:
                    root, segments, _ = chain_at(tokens, arguments[0][0])
                    if root in bindings:
                        taint, mids = bindings[root]
                        value_taint = extend_taint(taint, segments)
                        self.record_read(file, tokens[value_start].line, taint, segments, via, guards, mids)
                        bindings[names[-1]] = (element(value_taint), mids)
        self.scan(mid, file, function, do_index + 1, loop_end, bindings, via, guards, seeds, None)
        return loop_end + 1

    def handle_if(self, mid, file, function, position, bindings, via, guards, seeds) -> int:
        tokens = self.index(file).tokens
        if_end = _block_end(tokens, position)
        branches = _branches(tokens, position, if_end)
        if not branches:
            return position + 1
        exiting: list[tuple[str, frozenset[tuple[str, ...]], frozenset[tuple[str, ...]]]] = []
        value_branch = frozenset(
            (VALUE_BRANCH,) + path[:len(path) - path[::-1].index("[]")]
            for kind, condition, _, _ in branches if kind != "else"
            for path in self.reply_paths(_compared_chains(tokens, *condition), bindings, seeds)
            if "[]" in path and path[0] != LOCAL_GUARD
        ) | frozenset(
            guard for kind, condition, _, _ in branches if kind != "else"
            for guard in self.record_branches(_compared_chains(tokens, *condition), bindings, seeds)
        )
        for kind, condition, body_start, body_end in branches:
            positive, negative = (self.reply_paths(chains, bindings, seeds) for chains in condition_paths(tokens, *condition))
            self.scan(mid, file, function, condition[0], condition[1], bindings, via,
                      guards | positive | negative, seeds, None)
            branch_guards = guards | (negative if kind == "else" else positive)
            branch_guards = branch_guards | value_branch
            states = frozenset() if kind == "else" else state_guards(tokens, *condition, file, function)
            branch_seeds = seeds_for_states(seeds, states, body_start, body_end)
            self.scan(mid, file, function, body_start, body_end, bindings, via, frozenset(branch_guards | states), branch_seeds, None)
            if kind != "else":
                exiting.append((kind, positive, negative))
        has_else = any(kind == "else" for kind, _, _, _ in branches)
        if not has_else:
            for kind, positive, negative in exiting:
                if branch_exits(tokens, *_branch_body(tokens, position, if_end, kind)):
                    guards = guards | negative
                    break
        return if_end + 1

    @staticmethod
    def record_branches(chains, bindings, seeds) -> frozenset[tuple[str, ...]]:
        """A value comparison on an entry of a client keyed table branches per
        entry, like one on a list element."""
        taints = []
        for position, root, _ in chains:
            if seeds and position in seeds:
                taints.extend(taint for taint, _, _ in seeds[position])
            elif root in bindings:
                taints.append(bindings[root][0])
        return frozenset((VALUE_BRANCH,) + taint.path[:taint.record]
                         for taint in taints if taint.record is not None and taint.wrapper is None)

    @staticmethod
    def reply_paths(chains, bindings, seeds) -> frozenset[tuple[str, ...]]:
        """A condition names a reply path only through a variable bound to the
        reply or a seeded stored-field read (self.info.dialog); a same-named
        field of anything else (self.flag) guards nothing."""
        resolved = []
        for position, root, segments in chains:
            if seeds and position in seeds:
                resolved.extend(path_parts(taint, []) for taint, _, _ in seeds[position])
            elif root in bindings:
                resolved.append(path_parts(bindings[root][0], list(segments)))
            else:
                resolved.append([(LOCAL_GUARD, root) + _segment_parts(segments)])
        return frozenset(parts[-1] for parts in resolved if parts)

    # ------------------------------------------------------------------- calls
    def handle_call(self, mid, file, function, position, root, segments, after, bindings, via, guards, seeds) -> None:
        del position
        tokens = self.index(file).tokens
        arguments, _ = split_arguments(tokens, after)
        target = self.resolve_callee(file, function, root, segments)
        if target is None:
            return
        target_file, target_function, offset = target
        bound: dict[str, tuple[Taint, frozenset[int]]] = {}
        for index, argument in enumerate(arguments):
            parameter = index + offset
            if parameter >= len(target_function.params):
                break
            found = self.expression_taint(file, argument[0], bindings, seeds)
            if found is None:
                found = self.table_argument_taint(file, argument, bindings, seeds)
            if found is not None:
                bound[target_function.params[parameter]] = found
        if not bound:
            return
        inherited = frozenset(guard for guard in guards if guard[:1] == (VALUE_BRANCH,))
        key = (target_file, target_function.start, tuple(sorted((name, value[0].path, value[0].wrapper or "") for name, value in bound.items())), inherited)
        if key in self.replay:
            return
        self.replay.add(key)
        for taint, mids in bound.values():
            self.record_read(file, tokens[after].line, taint, [], via, guards, mids)
        self.scan(mid, target_file, target_function, target_function.body_start, target_function.end, bound,
                  f"{root}:{segments[-1][1] if segments else target_function.name or ''}", inherited, None, None)

    def resolve_callee(self, file, function, root, segments) -> tuple[str, Function, int] | None:
        if segments and segments[-1][0] == "method":
            receiver_class = self.receiver_class(file, function, root, segments[:-1])
            resolved = self.resolve_method(receiver_class, segments[-1][1])
            if resolved is not None:
                return resolved[0], resolved[1], 1
            return None
        if segments and segments[-1][0] == "field":
            method = segments[-1][1]
            receiver_class = self.receiver_class(file, function, root, segments[:-1])
            resolved = self.resolve_method(receiver_class, method)
            if resolved is not None:
                return resolved[0], resolved[1], 0
            local = self.index(file).by_name.get(root)
            if local is not None:
                return file, local, 0
            return None
        local = self.index(file).by_name.get(root)
        if local is not None:
            return file, local, 0
        return None

    def receiver_class(self, file, function, root, segments) -> str | None:
        aliases = self.aliases(file)
        for kind, name in reversed(segments):
            if kind == "field" and name in aliases:
                return aliases[name]
        if root in aliases:
            return aliases[root]
        if root == "var_0_0" and segments and segments[0] == ("field", "super"):
            return self.class_parent(self.file_class(file))
        return enclosing_self_class(self.file_class(file), function, root)

    def expression_taint(self, file, start, bindings, seeds) -> tuple[Taint, frozenset[int]] | None:
        if seeds and start in seeds:
            groups: dict[Taint, set[int]] = {}
            for taint, mids, _ in seeds[start]:
                groups.setdefault(taint, set()).update(mids)
            taint = max(groups, key=lambda item: (len(groups[item]), item.path))
            return taint, frozenset(groups[taint])
        tokens = self.index(file).tokens
        if start >= len(tokens):
            return None
        if tokens[start].kind != "name":
            return None
        root, segments, _ = chain_at(tokens, start)
        binding = bindings.get(root)
        if binding is None:
            return None
        return extend_taint(binding[0], segments), binding[1]

    def table_argument_taint(self, file, argument, bindings, seeds):
        tokens = self.index(file).tokens
        start, end = argument
        if start >= end or tokens[start].value != "{":
            return None
        close = matching_close(tokens, start)
        for position in range(start + 1, close):
            if tokens[position].kind != "name" or tokens[position + 1].value != "=":
                continue
            found = self.expression_taint(file, position + 2, bindings, seeds)
            if found is not None:
                return replace(found[0], wrapper=tokens[position].value, record=None), found[1]
        return None

    # ------------------------------------------------------- stored field pass
    def resolve_stored_fields(self) -> None:
        for (owner, owner_file, store_path), taints in sorted(self.stores.items()):
            for file in self.files_for_class(owner, owner_file):
                if not _store_field_in_text(self.blobs[file], store_path):
                    continue
                self.scan_field_accesses(file, "class", owner, owner_file, store_path, taints)
        for (owner, store_path), taints in sorted(self.file_stores.items()):
            if not _store_field_in_text(self.blobs[owner], store_path):
                continue
            self.scan_field_accesses(owner, "file", owner, owner, store_path, taints)

    def scan_field_accesses(self, file, kind, owner, owner_file, store_path, taints) -> None:
        binding = _binding_id(owner_file or owner, store_path)
        ambiguous = len({stored.branch for stored in taints}) > 1
        keyed = store_path[-1][0] == "index"
        index = self.index(file)
        tokens = index.tokens
        aliases = self.aliases(file)
        file_class = self.file_class(file)
        reads: list[tuple[int, list[tuple[str, str]]]] = []
        for position, token in enumerate(tokens):
            if token.kind != "name" or position + 2 >= len(tokens):
                continue
            root, segments, _ = chain_at(tokens, position)
            match = _segments_match(segments, store_path)
            if match is None:
                continue
            if kind == "file":
                function = index.innermost[position]
                if function is None or not function.params or root != function.params[0]:
                    continue
                if match != 0:
                    continue
            else:
                receiver = self.field_receiver_class(file_class, aliases, index, position, root, segments, match)
                if receiver != owner:
                    continue
            reads.append((position, segments[match + len(store_path):]))
        # One scan per stored taint: a read that two models both feed must
        # contribute every model's reply paths, not just the largest one.
        for stored, mids in list(taints.items()):
            if binding in stored.followed:
                continue
            seeds: dict[int, list[tuple[Taint, frozenset[int], str]]] = {}
            record = len(stored.path) if keyed else None
            for position, remainder in reads:
                seed = extend_taint(stored, remainder)
                followed = seed.followed | {binding}
                branch = UNKNOWN_BRANCH if ambiguous else seed.branch
                seeds.setdefault(position, []).append((replace(seed, followed=followed, branch=branch, record=record), frozenset(mids), "stored field"))
            for function in index.functions:
                local_seeds = {position: value for position, value in seeds.items()
                               if function.body_start <= position <= function.end}
                if not local_seeds:
                    continue
                self.scan(0, file, function, function.body_start, function.end, {}, "stored field", frozenset(), local_seeds, None)

    def field_receiver_class(self, file_class, aliases, index, position, root, segments, match) -> str | None:
        if match >= 1:
            return aliases.get(segments[match - 1][1])
        function = index.innermost[position]
        if function is not None and function.params and root == function.params[0]:
            return file_class
        return aliases.get(root)

    # ------------------------------------------------------ return-value pass
    def resolve_return_methods(self) -> None:
        for (class_name, class_file, store_path), taints in sorted(self.stores.items()):
            file = class_file
            if file is None or not _store_field_in_text(self.blobs[file], store_path):
                continue
            index = self.index(file)
            for stored, mids in list(taints.items()):
                for function in index.functions:
                    if function.parent is not None or not function.name:
                        continue
                    returned: list[tuple[Taint, frozenset[int]]] = []
                    seeds = self.field_seeds(file, function, class_name, class_file, store_path, {stored: mids})
                    if seeds:
                        self.scan(0, file, function, function.body_start, function.end, {}, "return", frozenset(), seeds, returned)
                    for taint, returned_mids in returned:
                        self.return_methods.setdefault((class_name, file, function.name), {}).setdefault(taint, set()).update(returned_mids)
        for (class_name, class_file, method), retrieved in sorted(self.return_methods.items()):
            for file in self.files_for_class(class_name, class_file):
                if ":" + method not in self.blobs[file]:
                    continue
                self.apply_return_call_sites(file, class_name, class_file, method, retrieved)

    def field_seeds(self, file, function, class_name, class_file, store_path, taints) -> dict[int, list[tuple[Taint, frozenset[int], str]]]:
        index = self.index(file)
        tokens = index.tokens
        if not function.params:
            return {}
        self_parameter = function.params[0]
        seeds: dict[int, list[tuple[Taint, frozenset[int], str]]] = {}
        binding = _binding_id(class_file or class_name, store_path)
        ambiguous = len({stored.branch for stored in taints}) > 1
        keyed = store_path[-1][0] == "index"
        for position in range(function.body_start, function.end):
            if tokens[position].kind != "name" or tokens[position].value != self_parameter:
                continue
            _, segments, _ = chain_at(tokens, position)
            match = _segments_match(segments, store_path)
            if match != 0:
                continue
            remainder = segments[match + len(store_path):]
            for stored, mids in taints.items():
                if binding in stored.followed:
                    continue
                seed = extend_taint(stored, remainder)
                followed = seed.followed | {binding}
                branch = UNKNOWN_BRANCH if ambiguous else seed.branch
                record = len(stored.path) if keyed else None
                seeds.setdefault(position, []).append((replace(seed, followed=followed, branch=branch, record=record), frozenset(mids), "returned rows"))
        return seeds

    def apply_return_call_sites(self, file, class_name, class_file, method, returned) -> None:
        index = self.index(file)
        tokens = index.tokens
        seeds: dict[int, list[tuple[Taint, frozenset[int], str]]] = {}
        for position, token in enumerate(tokens):
            if token.kind != "name":
                continue
            root, segments, after = chain_at(tokens, position)
            if not segments or segments[-1] != ("method", method):
                continue
            if after >= len(tokens) or tokens[after].value != "(":
                continue
            function = index.innermost[position]
            receiver = self.receiver_class(file, function, root, segments[:-1])
            if receiver != class_name:
                continue
            binding = f"call:{class_file or class_name}:{method}"
            ambiguous = len({taint.branch for taint in returned}) > 1
            close = matching_close(tokens, after)
            indexed = close + 1 < len(tokens) and tokens[close + 1].value == "["
            for taint, mids in returned.items():
                if binding in taint.followed:
                    continue
                followed = taint.followed | {binding}
                branch = UNKNOWN_BRANCH if ambiguous else taint.branch
                seed = element(taint) if indexed else taint
                seeds.setdefault(position, []).append((replace(seed, followed=followed, branch=branch), frozenset(mids), f"{class_name}:{method} return"))
        if not seeds:
            return
        for function in index.functions:
            local_seeds = {position: value for position, value in seeds.items()
                           if function.body_start <= position <= function.end}
            if not local_seeds:
                continue
            self.scan(0, file, function, function.body_start, function.end, {}, f"{class_name}:{method} return",
                      frozenset(), local_seeds, None)


def resolve_wrapper_callbacks(
        extractor: Extractor, mid: int, method: str, owner_file: str, owner_function: Function
) -> tuple[list[tuple[str, Function, tuple[int, int], str | None]], list[tuple[str, int]]]:
    found: list[tuple[str, Function, tuple[int, int], str | None]] = []
    unresolved: list[tuple[str, int]] = []
    owner = (owner_file, owner_function.start)
    for candidate in sorted(extractor.blobs):
        if not candidate.startswith("app/") or ":" + method not in extractor.blobs[candidate]:
            continue
        index = extractor.index(candidate)
        tokens = index.tokens
        for position, token in enumerate(tokens):
            if token.kind != "name" or token.value != method:
                continue
            if position == 0 or tokens[position - 1].value not in (":", "."):
                continue
            if position + 1 >= len(tokens) or tokens[position + 1].value != "(":
                continue
            arguments, _ = split_arguments(tokens, position + 1)
            callback = _callback_argument(tokens, arguments)
            if callback is None:
                continue
            receiver = _receiver_chain(tokens, position)
            if receiver is not None and receiver[1] in LUA_STANDARD_LIBRARIES:
                continue
            if receiver is not None and _is_function_name(tokens, receiver[0]):
                continue
            enclosing = index.innermost[position]
            target = None
            if enclosing is not None:
                receiver_class = _receiver_class_at(extractor, candidate, tokens, position, enclosing, receiver)
                target = extractor.resolve_method(receiver_class, method)
            if target is None:
                unresolved.append((candidate, tokens[position].line))
                continue
            if (target[0], target[1].start) != owner:
                continue
            start, end = callback
            parsed = index.by_start.get(start) or index.by_name.get(tokens[start].value)
            if parsed is not None:
                branch = extractor.call_branch(mid, candidate, tokens, arguments, position)
                found.append((candidate, parsed, (start + 1 if tokens[start].value == "function" else parsed.body_start, end), branch))
    return found, unresolved


def _receiver_chain(tokens, method_position) -> tuple[int, str, list[tuple[str, str]]] | None:
    end = method_position - 2
    if end < 0 or tokens[end].kind != "name":
        return None
    start = end
    while start >= 2 and tokens[start - 1].value in (".", ":") and tokens[start - 2].kind == "name":
        start -= 2
    root, segments, _ = chain_at(tokens, start)
    if not segments or segments[-1][1] != tokens[method_position].value or segments[-1][0] not in ("field", "method"):
        return None
    return start, root, segments[:-1]


def _is_function_name(tokens, start: int) -> bool:
    return start > 0 and tokens[start - 1].kind == "kw" and tokens[start - 1].value == "function"


def _receiver_class_at(extractor: Extractor, file: str, tokens, position: int,
                       enclosing: Function, receiver) -> str | None:
    if receiver is not None:
        _, root, segments = receiver
        receiver_class = extractor.wrapper_receiver_class(file, enclosing, root, segments)
        if receiver_class is not None:
            return receiver_class
    return _load_model_receiver_class(extractor, tokens, position)


def _load_model_receiver_class(extractor: Extractor, tokens, method_position: int) -> str | None:
    close = method_position - 2
    if close < 0 or tokens[close].value != ")":
        return None
    open_index = _matching_open(tokens, close)
    if open_index is None or open_index < 1 or tokens[open_index - 1].value != "loadModel":
        return None
    arguments, _ = split_arguments(tokens, open_index)
    if len(arguments) != 1:
        return None
    start, end = arguments[0]
    values = [token.value for token in tokens[start:end]]
    if len(values) != 5 or values[:4] != ["xyd", ".", "ModelType", "."]:
        return None
    type_number = extractor.model_types.get(values[4])
    return extractor.model_classes.get(type_number) if type_number is not None else None


def _matching_open(tokens, close_index: int) -> int | None:
    depth = 0
    for index in range(close_index, -1, -1):
        if tokens[index].value == ")":
            depth += 1
        elif tokens[index].value == "(":
            depth -= 1
            if depth == 0:
                return index
    return None


def _unresolved_receiver_reason(method: str, unresolved: list[tuple[str, int]]) -> str:
    first = unresolved[0]
    return f"{len(unresolved)} {method} call site(s) have an unresolved owner; first at {first[0]}:{first[1]}"


def _callback_argument(tokens, arguments):
    for start, end in reversed(arguments):
        if tokens[start].value == "function" and tokens[start].kind == "kw":
            close = _inline_end(tokens, start)
            if close is not None:
                return start, close + 1
    for start, end in reversed(arguments):
        if end - start == 1 and tokens[start].kind == "name":
            return start, end
    return None


def _inline_end(tokens, start):
    depth = 0
    for index in range(start, len(tokens)):
        if tokens[index].kind != "kw":
            continue
        if tokens[index].value in ("function", "if", "do", "repeat"):
            depth += 1
        elif tokens[index].value in ("end", "until"):
            depth -= 1
            if depth == 0:
                return index
    return None


def _is_request_call(tokens, position) -> bool:
    if position + 1 >= len(tokens) or tokens[position + 1].value != "(":
        return False
    for cursor in range(max(0, position - 3), position):
        if tokens[cursor].kind == "kw" and tokens[cursor].value == "function":
            return False
    return True


def _wrapper_callback(tokens, start, end) -> Function | None:
    del end
    values = [token.value for token in tokens[start:start + 4]]
    if values not in (["xyd", ".", "scb", "("], ["xyd", ".", "backendCallbackWrapper", "("]):
        return None
    arguments, _ = split_arguments(tokens, start + 3)
    for argument_start, _ in reversed(arguments):
        if tokens[argument_start].value == "function" and tokens[argument_start].kind == "kw":
            return _parse_inline(tokens, argument_start)
    return None


def _parse_inline(tokens, start) -> Function | None:
    close = _inline_end(tokens, start)
    if close is None:
        return None
    parsed = _parse_function("", tokens, start, close)
    return parsed


def _forwards_reply(tokens, callback: Function, enclosing: Function) -> bool:
    if len(callback.params) < 2:
        return False
    reply = callback.params[1]
    parameters = set(enclosing.params[1:])
    for position in range(callback.body_start, callback.end):
        token = tokens[position]
        if token.kind != "name" or token.value not in parameters:
            continue
        if position + 1 >= callback.end or tokens[position + 1].value != "(":
            continue
        arguments, _ = split_arguments(tokens, position + 1)
        if any(tokens[start].value == reply for start, _ in arguments):
            return True
    return False


def _loop_do(tokens, position, end) -> int | None:
    depth = 0
    for index in range(position + 1, end):
        value = tokens[index].value if tokens[index].kind == "kw" else ""
        if value in ("function", "if", "do", "repeat"):
            if value == "do" and depth == 0:
                return index
            depth += 1
        elif value in ("end", "until"):
            if depth == 0:
                return None
            depth -= 1
    return None


def _block_end(tokens, opener) -> int:
    depth = 0
    for index in range(opener, len(tokens)):
        if tokens[index].kind != "kw":
            continue
        value = tokens[index].value
        if value in ("function", "if", "do", "repeat"):
            depth += 1
        elif value in ("end", "until"):
            depth -= 1
            if depth == 0:
                return index
    return len(tokens) - 1


def _branches(tokens, if_index, if_end):
    then_index = _then_index(tokens, if_index, if_end)
    if then_index is None:
        return []
    branches = []
    kind = "if"
    condition_start = if_index + 1
    body_start = then_index + 1
    depth = 0
    index = body_start
    while index < if_end:
        token = tokens[index]
        value = token.value if token.kind == "kw" else ""
        if value in ("function", "if", "do", "repeat"):
            depth += 1
        elif value in ("end", "until"):
            depth -= 1
        elif depth == 0 and value in ("elseif", "else"):
            branches.append((kind, (condition_start, then_index), body_start, index))
            if value == "else":
                branches.append(("else", (index + 1, index), index + 1, if_end))
                return branches
            condition_start = index + 1
            then_index = _then_index(tokens, index, if_end)
            if then_index is None:
                return branches
            body_start = then_index + 1
            kind = "elseif"
        index += 1
    branches.append((kind, (condition_start, then_index), body_start, if_end))
    return branches


def _then_index(tokens, if_index, end) -> int | None:
    depth = 0
    for index in range(if_index + 1, end):
        value = tokens[index].value
        if value in ("(", "{", "["):
            depth += 1
        elif value in (")", "}", "]"):
            depth -= 1
        elif depth == 0 and tokens[index].kind == "kw" and value == "then":
            return index
    return None


def _branch_body(tokens, if_index, if_end, kind):
    for branch_kind, _, body_start, body_end in _branches(tokens, if_index, if_end):
        if branch_kind == kind:
            return body_start, body_end
    return if_end, if_end


def branch_exits(tokens, start, end) -> bool:
    depth = 0
    for index in range(start, end):
        token = tokens[index]
        if token.kind != "kw":
            continue
        if token.value in ("function", "if", "do", "repeat"):
            depth += 1
        elif token.value in ("end", "until"):
            depth -= 1
        elif depth == 0 and token.value in ("return", "break"):
            return True
    return False


def condition_paths(tokens, start, end) -> tuple[frozenset, frozenset]:
    """Chains (root, segments) the condition proves present (positive) or that
    its failure proves present (negative)."""
    positive: set = set()
    negative: set = set()
    if _has_top_level_or(tokens, start, end):
        return frozenset(), frozenset(_not_paths(tokens, start, end))
    for conjunct_start, conjunct_end in _split_top_level(tokens, start, end, "and"):
        _conjunct_paths(tokens, conjunct_start, conjunct_end, positive, negative)
    return frozenset(positive), frozenset(negative)


def _conjunct_paths(tokens, start, end, positive, negative) -> None:
    position = start
    while position < end:
        token = tokens[position]
        if token.kind != "name" or position > start and tokens[position - 1].value in (".", ":"):
            position += 1
            continue
        root, segments, after = chain_at(tokens, position)
        if root in LIBRARY_ROOTS:
            position += 1
            continue
        parts = (position, root, tuple(segments))
        negated = position > start and tokens[position - 1].kind == "kw" and tokens[position - 1].value == "not"
        if after + 1 < end and tokens[after].value == "==" and tokens[after + 1].value == "nil":
            negative.add(parts)
        elif after + 1 < end and tokens[after].value == "~=" and tokens[after + 1].value == "nil":
            positive.add(parts)
        elif negated:
            negative.add(parts)
        elif after >= end or tokens[after].value in (")", "and", "then", ",", "]"):
            positive.add(parts)
        elif tokens[after].value not in ("==", "~="):
            positive.add(parts)
        position = max(after, position + 1)


def _not_paths(tokens, start, end) -> set:
    paths = set()
    for position in range(start, end - 1):
        if tokens[position].kind == "kw" and tokens[position].value == "not" and tokens[position + 1].kind == "name":
            root, segments, _ = chain_at(tokens, position + 1)
            paths.add((position + 1, root, tuple(segments)))
    return paths


def _compared_chains(tokens, start, end) -> set:
    """Chains compared (== or ~=) with anything but nil."""
    chains = set()
    position = start
    while position < end:
        token = tokens[position]
        if token.kind != "name" or position > start and tokens[position - 1].value in (".", ":"):
            position += 1
            continue
        root, segments, after = chain_at(tokens, position)
        if after + 1 < end and tokens[after].value in ("==", "~=") and tokens[after + 1].value != "nil":
            chains.add((position, root, tuple(segments)))
        position = max(after, position + 1)
    return chains


def state_guards(tokens, start, end, file, function) -> frozenset[tuple[str, ...]]:
    """`self.field == CONSTANT` comparisons a branch condition implies (none
    under `or` or `not`); the constant is file-local text, so the guard names
    the file."""
    if not function.params or any(tokens[position].value in ("or", "not") for position in range(start, end)):
        return frozenset()
    found = set()
    for position, root, segments in _compared_chains(tokens, start, end):
        if root != function.params[0] or not segments or any(kind != "field" for kind, _ in segments):
            continue
        _, _, after = chain_at(tokens, position)
        if tokens[after].value != "==" or tokens[after + 1].kind not in ("name", "string", "number"):
            continue
        if tokens[after + 1].kind == "name":
            constant_root, constant_segments, _ = chain_at(tokens, after + 1)
            constant = ".".join([constant_root] + [name for _, name in constant_segments])
        else:
            constant = tokens[after + 1].value
        found.add((STATE_BRANCH, file, ".".join(name for _, name in segments), constant))
    return frozenset(found)


def seeds_for_states(seeds, states, start, end):
    """Drops seeds stored under another constant of a field this branch fixes."""
    if not seeds or not states:
        return seeds
    fixed = {guard[:3]: guard[3] for guard in states}

    def reaches(taint) -> bool:
        return all(fixed.get(state[:3], state[3]) == state[3] for state in taint.states)

    filtered = {}
    for position, entries in seeds.items():
        if start <= position < end:
            entries = [entry for entry in entries if reaches(entry[0])]
        if entries:
            filtered[position] = entries
    return filtered


def _segment_parts(segments) -> tuple[str, ...]:
    parts = []
    for kind, name in segments:
        if kind == "field":
            parts.append(name)
        elif kind == "index":
            if not parts or parts[-1] != "[]":
                parts.append("[]")
    return tuple(parts)


def _split_top_level(tokens, start, end, keyword) -> list[tuple[int, int]]:
    depth = 0
    parts = []
    part_start = start
    for index in range(start, end):
        value = tokens[index].value
        if value in ("(", "{", "["):
            depth += 1
        elif value in (")", "}", "]"):
            depth -= 1
        elif depth == 0 and tokens[index].kind == "kw" and value == keyword:
            parts.append((part_start, index))
            part_start = index + 1
    parts.append((part_start, end))
    return parts


def _has_top_level_or(tokens, start, end) -> bool:
    depth = 0
    for index in range(start, end):
        value = tokens[index].value
        if value in ("(", "{", "["):
            depth += 1
        elif value in (")", "}", "]"):
            depth -= 1
        elif depth == 0 and tokens[index].kind == "kw" and value == "or":
            return True
    return False


def _segments_match(segments, store_path) -> int | None:
    width = len(store_path)
    if not width:
        return None
    for index in range(len(segments) - width + 1):
        if tuple(segments[index:index + width]) == store_path:
            return index
    return None


def _binding_id(owner: str, store_path) -> str:
    # A storage binding is one location: the class/file that owns it plus the
    # full field path. Following the same location twice for one taint is a cycle.
    return f"{owner}:{path_string(_segment_parts(store_path))}"


def _store_field_in_text(text: str, store_path) -> bool:
    for kind, name in store_path:
        if kind == "field":
            return "." + name in text
    return False


def mid_set(mid: int) -> frozenset[int]:
    return frozenset({mid})


def normalise_store_rows(stores) -> None:
    for taints in stores.values():
        for container in [taint for taint in taints if not taint.path or taint.path[-1] != "[]"]:
            rows = replace(container, path=container.path + ("[]",), record=None)
            if rows not in taints:
                continue
            taints[rows].update(taints.pop(container))


def enclosing_self_class(file_class: str | None, function: Function | None, root: str) -> str | None:
    if not file_class:
        return None
    while function is not None:
        if function.params and function.params[0] == root:
            return file_class
        function = function.parent
    return None


def _checked(file: str, line: int, detail: str | None = None) -> dict:
    entry = {"file": file, "line": line, "status": "CHECKED"}
    if detail:
        entry["detail"] = detail
    return entry


def _unknown(file: str, line: int, reason: str) -> dict:
    return {"file": file, "line": line, "status": "UNKNOWN", "reason": reason}


# ------------------------------------------------------------------- parsing
def parse_activity_symbols(text: str) -> dict[str, int]:
    return {
        match.group(1): int(match.group(2))
        for match in re.finditer(r"xyd\.Activities\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(\d+)", text)
    }


def _expression_end(tokens, start, limit) -> int:
    if start >= limit:
        return start
    if tokens[start].value == "{":
        return min(matching_close(tokens, start) + 1, limit)
    if tokens[start].kind == "name":
        _, _, after = chain_at(tokens, start)
        return min(after, limit)
    return min(start + 1, limit)


def _assignment_value_start(tokens, name_index, limit) -> int | None:
    if name_index + 1 >= limit or tokens[name_index + 1].value != "=":
        return None
    return name_index + 2


def parse_mid_symbols(text: str) -> dict[str, int]:
    return {
        match.group(1): int(match.group(2))
        for match in re.finditer(r"xyd\.mid\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(\d+)", text)
    }


def parse_model_types(text: str) -> dict[str, int]:
    return {
        match.group(1): int(match.group(2))
        for match in re.finditer(r"xyd\.ModelType\.([A-Za-z0-9_]+)\s*=\s*(\d+)", text)
    }


def parse_model_define(text: str) -> dict[int, str]:
    return {
        int(match.group(1)): match.group(2)
        for match in re.finditer(r'"(\d+)"\s*,\s*"([A-Za-z0-9_]+)"', text)
    }


def parse_classes(blobs: dict[str, str]) -> dict[str, tuple[str, str | None]]:
    classes: dict[str, tuple[str, str | None]] = {}
    for file, text in blobs.items():
        for match in re.finditer(r'class\(\s*"([A-Za-z0-9_]+)"\s*(?:,\s*import\(\s*"([^"]+)"\s*\))?', text):
            parent = match.group(2).split(".")[-1] if match.group(2) else None
            classes.setdefault(match.group(1), (file, parent))
    return classes


def file_class_name(text: str) -> str | None:
    match = re.search(r'class\(\s*"([A-Za-z0-9_]+)"', text)
    return match.group(1) if match else None


def parse_aliases(text: str, model_types: dict[str, int], model_classes: dict[int, str]) -> dict[str, str]:
    aliases: dict[str, str] = {}
    for match in re.finditer(r"([A-Za-z0-9_]+)\s*=\s*xyd\.ModelManager\.get\(\):loadModel\(xyd\.ModelType\.([A-Za-z0-9_]+)\)", text):
        type_number = model_types.get(match.group(2))
        class_name = model_classes.get(type_number) if type_number is not None else None
        if not class_name:
            continue
        components = match.group(1).split(".")
        aliases[components[-1]] = class_name
        if len(components) > 1:
            aliases.setdefault(components[-2], class_name)
    for match in re.finditer(r'([A-Za-z0-9_]+)\s*=\s*import\(\s*"([^"]+)"\s*\)\.new\(\)', text):
        aliases[match.group(1).split(".")[-1]] = match.group(2).split(".")[-1]
    return aliases


def parse_import_aliases(text: str) -> dict[str, str]:
    return {
        match.group(1): match.group(2).split(".")[-1]
        for match in re.finditer(r'([A-Za-z0-9_]+)\s*=\s*import\(\s*"([^"]+)"\s*\)', text)
    }


def parse_lazy_model_aliases(text: str, model_types: dict[str, int], model_classes: dict[int, str]) -> dict[str, str]:
    aliases: dict[str, str] = {}
    pattern = r"([A-Za-z0-9_.]+)\s*=\s*(?:[A-Za-z0-9_.]+\s+or\s+)?xyd\.ModelManager\.get\(\):loadModel\(xyd\.ModelType\.([A-Za-z0-9_]+)\)"
    for match in re.finditer(pattern, text):
        type_number = model_types.get(match.group(2))
        class_name = model_classes.get(type_number) if type_number is not None else None
        if class_name:
            aliases[match.group(1).split(".")[-1]] = class_name
    return aliases


def _alias_receiver_class(root: str, segments: list[tuple[str, str]], aliases: dict[str, str],
                          imports: dict[str, str], lazy_models: dict[str, str]) -> str | None:
    for kind, name in reversed(segments):
        if kind == "field" and name in aliases:
            return aliases[name]
    if root in aliases:
        return aliases[root]
    for kind, name in reversed(segments):
        if kind == "field" and (name in imports or name in lazy_models):
            return imports.get(name) or lazy_models.get(name)
    if root in imports or root in lazy_models:
        return imports.get(root) or lazy_models.get(root)
    return None


def parse_event_handlers(blobs: dict[str, str]) -> tuple[dict[str, list[tuple[str, Function]]], dict[str, list[str]]]:
    """Every registered xyd.event listener, plus the registrations that cannot
    be resolved.  BaseModel:registerEvent and the dispatcher's addEventListener
    are the only two ways the client subscribes to an xyd.event."""
    handlers: dict[str, list[tuple[str, Function]]] = {}
    unresolved: dict[str, list[str]] = {}
    for file in sorted(blobs):
        if "registerEvent" not in blobs[file] and "addEventListener" not in blobs[file]:
            continue
        tokens = Tokenizer(blobs[file]).tokens()
        index = index_functions(file, tokens)
        for position, token in enumerate(tokens):
            if token.kind != "name" or token.value not in ("registerEvent", "addEventListener"):
                continue
            if position + 1 >= len(tokens) or tokens[position + 1].value != "(":
                continue
            arguments, _ = split_arguments(tokens, position + 1)
            if len(arguments) < 2:
                continue
            event = _event_name(tokens, arguments[0])
            if not event:
                continue
            handler = _registered_handler(tokens, arguments[1], index)
            if handler is None:
                unresolved.setdefault(event, []).append(f"{file}:{tokens[arguments[1][0]].line}")
                continue
            handlers.setdefault(event, []).append((file, handler))
    return handlers, unresolved


def _event_name(tokens, argument) -> str | None:
    start, end = argument
    values = [token.value for token in tokens[start:end]]
    if len(values) == 5 and values[:4] == ["xyd", ".", "event", "."]:
        return values[4]
    return None


def _registered_handler(tokens, argument, index: FunctionIndex) -> Function | None:
    start, _ = argument
    if tokens[start].kind == "kw" and tokens[start].value == "function":
        return index.by_start.get(start)
    method = _handler_method(tokens, argument)
    if method is None:
        return None
    return index.by_name.get(method)


def _handler_method(tokens, argument) -> str | None:
    start, end = argument
    values = [token.value for token in tokens[start:end]]
    if len(values) >= 3 and values[-2] == "." and tokens[end - 1].kind == "name":
        return values[-1]
    if len(values) >= 6 and values[-1] == ")" and values[-3] == "." and tokens[end - 2].kind == "name":
        return values[-2]
    return None


def parse_mid_events(text: str, symbols: dict[str, int]) -> dict[int, str]:
    return {
        symbols[match.group(1)]: match.group(2)
        for match in re.finditer(r"mid2EventNames_\[xyd\.mid\.([A-Za-z0-9_]+)\]\s*=\s*xyd\.event\.([A-Za-z0-9_]+)", text)
        if match.group(1) in symbols
    }


# -------------------------------------------------------------------- output
def site_entries(sites_by_path: dict) -> list[dict]:
    path_entries = []
    for path, sites in sorted(sites_by_path.items()):
        ordered_sites = sorted(sites.values(), key=lambda item: (item.file, item.line, item.via))
        site_list = [
            {"file": site.file, "line": site.line, "via": site.via, "guarded": site.guarded}
            for site in ordered_sites
        ]
        requirement = "OPTIONAL" if all(site.guarded for site in ordered_sites) else "REQUIRED"
        path_entries.append({"path": path, "requirement": requirement, "sites": site_list})
    return path_entries


def split_branches(sites_by_path: dict) -> tuple[dict, dict]:
    unconditional: dict = {}
    branches: dict = {}
    for path, sites in sites_by_path.items():
        for site in sites.values():
            if site.branch is None:
                unconditional.setdefault(path, {})[(site.file, site.line, site.via, site.guarded)] = site
            else:
                branches.setdefault(site.branch, {}).setdefault(path, {})[(site.file, site.line, site.via, site.guarded)] = site
    return unconditional, branches


def branch_record(sites_by_path: dict, policy: BranchPolicy) -> dict:
    _, branches = split_branches(sites_by_path)
    values = {}
    for value in sorted(branches, key=lambda item: (item == UNKNOWN_BRANCH, item)):
        record = {"status": "UNKNOWN" if value == UNKNOWN_BRANCH else "CHECKED", "paths": site_entries(branches[value])}
        if value == UNKNOWN_BRANCH:
            record["reason"] = BRANCH_UNKNOWN_REASON
        values[value] = record
    return {policy.reply_key: values}


def build(blobs: dict[str, str], collapse: bool = True) -> dict:
    extractor = Extractor(blobs)
    extractor.run()
    mids: dict[str, dict] = {}
    for mid, callbacks in sorted(extractor.callbacks.items(), key=lambda item: int(item[0])):
        sites_by_path = extractor.paths.get(mid, {})
        policy = BRANCH_POLICIES.get(int(mid))
        record = {
            "name": mid_name(extractor, int(mid)),
            "callbacks": sorted(callbacks, key=lambda entry: (entry["file"], entry["line"], entry["status"])),
        }
        if policy is None:
            record["paths"] = site_entries(sites_by_path)
        else:
            record["paths"] = site_entries(split_branches(sites_by_path)[0])
            record["branches"] = branch_record(sites_by_path, policy)
        mids[mid] = record
    for mid in served_mid_numbers():
        if str(mid) in mids:
            continue
        mids[str(mid)] = {
            "name": mid_name(extractor, mid),
            "callbacks": [],
            "paths": [],
            "status": "UNKNOWN",
            "reason": NO_CLIENT_REQUEST_REASON,
        }
    unknown = sum(1 for entry in mids.values() for callback in entry["callbacks"] if callback["status"] == "UNKNOWN")
    unknown_branches = sum(
        1
        for record in mids.values()
        for values in record.get("branches", {}).values()
        for branch in values.values()
        if branch.get("status") == "UNKNOWN"
    )
    payload = {
        "schema_version": 3,
        "source": "current src_64 Lua reply callbacks",
        "source_archive_sha256": archive_sha(),
        "status": "UNKNOWN" if unknown or unknown_branches else "CHECKED",
        "unknown_callbacks": unknown,
        "unknown_branches": unknown_branches,
        "mid_count": len(mids),
        "mids": mids,
    }
    return compact_payload(collapse_sites(payload)) if collapse else payload


def collapse_path_entries(paths: list[dict]) -> list[dict]:
    collapsed_entries = []
    for entry in paths:
        groups: dict[tuple[str, int], dict] = {}
        for site in entry["sites"]:
            group = groups.setdefault(
                (site["file"], site["line"]),
                {"file": site["file"], "line": site["line"], "guarded": True, "via": set()},
            )
            group["guarded"] = group["guarded"] and site["guarded"]
            group["via"].add(site["via"])
        sites = [
            {"file": key[0], "line": key[1], "guarded": group["guarded"], "via": sorted(group["via"])}
            for key, group in sorted(groups.items())
        ]
        collapsed = {"path": entry["path"], "requirement": entry["requirement"], "sites": sites}
        if "waiver" in entry:
            collapsed["waiver"] = entry["waiver"]
        collapsed_entries.append(collapsed)
    return collapsed_entries


def collapse_sites(payload: dict) -> dict:
    mids: dict[str, dict] = {}
    for mid, record in payload["mids"].items():
        row = row_with_optional_status(record, collapse_path_entries(record["paths"]))
        if "branches" in record:
            row["branches"] = {
                key: {
                    value: {**branch, "paths": collapse_path_entries(branch["paths"])}
                    for value, branch in values.items()
                }
                for key, values in record["branches"].items()
            }
        mids[mid] = row
    return {**payload, "mids": mids}


def row_with_optional_status(record: dict, paths: list, callbacks=None) -> dict:
    row = {"name": record["name"], "callbacks": record["callbacks"] if callbacks is None else callbacks, "paths": paths}
    for field in ("status", "reason"):
        if field in record:
            row[field] = record[field]
    return row


def branch_path_lists(record: dict) -> list[list[dict]]:
    return [branch["paths"] for values in record.get("branches", {}).values() for branch in values.values()]


def compact_paths(entries: list[dict], index: dict[str, int]) -> list[list]:
    paths = []
    for entry in entries:
        sites = [[index[site["file"]], site["line"], 1 if site["guarded"] else 0, list(site["via"])]
                 for site in entry["sites"]]
        path = [entry["path"], REQUIREMENT_CODES[entry["requirement"]], sites]
        if "waiver" in entry:
            path.append(entry["waiver"])
        paths.append(path)
    return paths


def compact_payload(payload: dict) -> dict:
    files = sorted({
        site["file"]
        for record in payload["mids"].values()
        for paths in [record["paths"], *branch_path_lists(record)]
        for entry in paths
        for site in entry["sites"]
    } | {
        callback["file"]
        for record in payload["mids"].values()
        for callback in record["callbacks"]
    })
    index = {name: position for position, name in enumerate(files)}
    mids: dict[str, dict] = {}
    for mid, record in payload["mids"].items():
        callbacks = []
        for callback in record["callbacks"]:
            row = {"file": index[callback["file"]], "line": callback["line"], "status": callback["status"]}
            if "reason" in callback:
                row["reason"] = callback["reason"]
            if "detail" in callback:
                row["detail"] = callback["detail"]
            callbacks.append(row)
        row = row_with_optional_status(record, compact_paths(record["paths"], index), callbacks)
        if "branches" in record:
            row["branches"] = {
                key: {
                    value: {**branch, "paths": compact_paths(branch["paths"], index)}
                    for value, branch in values.items()
                }
                for key, values in record["branches"].items()
            }
        mids[mid] = row
    return {
        **payload,
        "site_encoding": "site = [site_files index, line, guarded (0/1), sorted via values]; callbacks use the same file index",
        "path_encoding": "path = [path, requirement (1 REQUIRED, 0 OPTIONAL, 2 WAIVED), sites, waiver when waived]",
        "site_files": files,
        "mids": mids,
    }


def mid_name(extractor: Extractor, mid: int) -> str:
    names = sorted(symbol for symbol, number in extractor.mid_symbols.items() if number == mid)
    return names[0] if names else ""


def served_mid_numbers(path: Path = SERVED_MIDS_PATH) -> list[int]:
    """The dispatcher table's registered MIDs, as the system map classifies them."""
    document = json.loads(path.read_text(encoding="utf-8"))
    rows = document.get("mids")
    if not isinstance(rows, list):
        raise SystemExit("served MID classes have no mids: %s" % path)
    return sorted({row["mid"] for row in rows if isinstance(row.get("mid"), int)})


def archive_sha() -> str:
    lock = json.loads(LOCK_PATH.read_text())
    return next(row["sha256"] for row in lock["oracles"] if row["id"] == "current_src64")


def lua_blobs(bundle: zipfile.ZipFile) -> dict[str, str]:
    blobs: dict[str, str] = {}
    for name in bundle.namelist():
        if not name.startswith(SOURCE_PREFIX) or not name.endswith(".lua"):
            continue
        relative = name[len(SOURCE_PREFIX):]
        if relative.startswith("app/") or relative.startswith("data/tables/"):
            blobs[relative] = bundle.read(name).decode("utf-8-sig")
    return blobs


def path_name(entry) -> str:
    return entry[0] if isinstance(entry, list) else entry["path"]


def path_requirement(entry) -> str:
    if isinstance(entry, list):
        return REQUIREMENT_NAMES.get(entry[1], "OPTIONAL")
    return entry["requirement"]


def seed_problems(payload: dict) -> list[str]:
    problems = []
    for label, mid, path in SEED_PATHS:
        record = payload.get("mids", {}).get(str(mid))
        required = {
            path_name(entry) for entry in record.get("paths", []) if path_requirement(entry) == "REQUIRED"
        } if record else set()
        if path not in required:
            problems.append(f"seed {label}: MID {mid} does not come out required for {path}")
    return problems


def branch_coverage_problems(payload: dict) -> list[str]:
    """Every MID whose reply is consumed by two or more Activity<table_id>
    windows must carry a branch policy or a reasoned exemption, so a new
    discriminator-split MID cannot stay folded into one union obligation set."""
    names = payload.get("site_files")
    if names is None:
        return []
    pattern = re.compile(BRANCH_POLICIES[234].window_pattern)
    problems = []
    for mid, record in payload.get("mids", {}).items():
        entries = list(record.get("paths", []))
        for values in record.get("branches", {}).values():
            for branch in values.values():
                entries.extend(branch.get("paths", []))
        windows = set()
        for entry in entries:
            for site in entry[2]:
                match = pattern.fullmatch(names[site[0]])
                if match:
                    windows.add(match.group(1))
        if len(windows) >= 2 and int(mid) not in BRANCH_POLICIES and int(mid) not in BRANCH_POLICY_EXEMPTIONS:
            problems.append(
                f"MID {mid} is consumed by Activity windows {sorted(windows)} but has no branch policy or exemption"
            )
    return problems


def validate_waivers(waivers: dict, payload: dict, blobs: dict[str, str]) -> list[str]:
    problems: list[str] = []
    known = {
        (int(mid), path_name(entry))
        for mid, record in payload.get("mids", {}).items()
        for entry in record.get("paths", [])
        if path_requirement(entry) == "REQUIRED"
    }
    for waiver in waivers.get("waivers", []):
        mid = waiver.get("mid")
        path = waiver.get("path")
        reason = (waiver.get("reason") or "").strip()
        client = (waiver.get("client") or "").strip()
        if not isinstance(mid, int) or not path:
            problems.append(f"waiver {mid} {path}: mid must be a number and path a string")
            continue
        if not reason:
            problems.append(f"waiver {mid} {path}: reason is empty")
        if not client:
            problems.append(f"waiver {mid} {path}: client site is empty")
            continue
        file, _, line_text = client.rpartition(":")
        if not file or not line_text.isdigit():
            problems.append(f"waiver {mid} {path}: client {client!r} is not file:line")
            continue
        if file not in blobs:
            problems.append(f"waiver {mid} {path}: client file {file} is not in the source archive")
            continue
        if int(line_text) < 1 or int(line_text) > blobs[file].count("\n") + 2:
            problems.append(f"waiver {mid} {path}: client line {line_text} is outside {file}")
            continue
        if (mid, path) not in known:
            problems.append(f"waiver {mid} {path}: no REQUIRED path with that MID and path")
    return problems


def apply_waivers(waivers: dict, payload: dict) -> dict:
    for waiver in waivers.get("waivers", []):
        record = payload.get("mids", {}).get(str(waiver["mid"]))
        if record is None:
            continue
        for entry in record.get("paths", []):
            if path_name(entry) != waiver["path"] or path_requirement(entry) != "REQUIRED":
                continue
            applied = {"reason": waiver["reason"], "client": waiver["client"]}
            if isinstance(entry, list):
                entry[1] = REQUIREMENT_CODES["WAIVED"]
                if len(entry) == 3:
                    entry.append(applied)
                else:
                    entry[3] = applied
            else:
                entry["requirement"] = "WAIVED"
                entry["waiver"] = applied
    return payload


def resolve_archive(argument: Path | None) -> Path:
    if argument is not None:
        return argument
    if DEFAULT_ARCHIVE.exists():
        return DEFAULT_ARCHIVE
    oracle_root = Path(os.environ.get("GXB_ORACLE_ROOT", "/mnt/data"))
    if oracle_root.is_dir():
        patterns = next(
            row["filename_patterns"] for row in json.loads(LOCK_PATH.read_text())["oracles"] if row["id"] == "current_src64")
        for candidate in sorted(oracle_root.glob("*.zip")):
            if not any(fnmatch.fnmatch(candidate.name, pattern) for pattern in patterns):
                continue
            if hashlib.sha256(candidate.read_bytes()).hexdigest() == archive_sha():
                return candidate
    raise SystemExit(f"source archive not found at {DEFAULT_ARCHIVE} or GXB_ORACLE_ROOT; pass --source-archive")


def verify_archive(path: Path) -> str:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    expected = archive_sha()
    if digest != expected:
        raise SystemExit(f"source archive hash drift: {digest} != {expected}")
    return digest


def serialise(payload: dict) -> str:
    return json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n"


def serialise_waivers(waivers: dict) -> str:
    return json.dumps(waivers, indent=1, sort_keys=True) + "\n"


def written_outputs(payload: dict) -> dict[Path, str]:
    rendered = serialise(payload)
    return {CONSUMERS_PATH: rendered, EMBED_PATH: rendered}


def read_waivers() -> dict:
    if WAIVERS_PATH.exists():
        return json.loads(WAIVERS_PATH.read_text())
    return {"schema_version": 1, "waivers": []}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-archive", type=Path)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--write", action="store_true")
    action.add_argument("--check", action="store_true")
    arguments = parser.parse_args(argv)
    archive = resolve_archive(arguments.source_archive)
    verify_archive(archive)
    with zipfile.ZipFile(archive) as bundle:
        blobs = lua_blobs(bundle)
    payload = build(blobs)
    problems = seed_problems(payload)
    problems.extend(branch_coverage_problems(payload))
    waivers = read_waivers()
    problems.extend(validate_waivers(waivers, payload, blobs))
    if problems:
        for problem in problems:
            print(problem, file=sys.stderr)
        return 1
    payload = apply_waivers(waivers, payload)
    outputs = written_outputs(payload)
    if arguments.check:
        for path, content in outputs.items():
            if not path.exists() or path.read_text() != content:
                print(f"{path} is stale; rerun with --write", file=sys.stderr)
                return 1
        return 0
    for path, content in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
    if not WAIVERS_PATH.exists():
        WAIVERS_PATH.write_text(serialise_waivers(waivers))
    print(f"wrote {CONSUMERS_PATH} and {EMBED_PATH} mids={payload['mid_count']} unknown={payload['unknown_callbacks']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
