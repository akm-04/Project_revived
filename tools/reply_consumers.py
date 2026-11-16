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
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIRECTORY = ROOT / "docs/architecture/reply_consumers"
CONSUMERS_PATH = OUTPUT_DIRECTORY / "REPLY_CONSUMERS.json"
WAIVERS_PATH = OUTPUT_DIRECTORY / "WAIVERS.json"
EMBED_PATH = ROOT / "internal/protocol/replyconformance/reply_consumers.json"
LOCK_PATH = ROOT / "oracles.lock.json"
DEFAULT_ARCHIVE = ROOT / "inputs/assets/Older/all-assest-rechecked-1.zip"

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


@dataclass(frozen=True)
class Site:
    file: str
    line: int
    via: str
    guarded: bool


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
    return Taint(tuple(parts), taint.wrapper, taint.followed)


def element(taint: Taint) -> Taint:
    if taint.path and taint.path[-1] == "[]":
        return taint
    return Taint(taint.path + ("[]",), taint.wrapper, taint.followed)


def path_parts(taint: Taint, segments: list[tuple[str, str]]) -> list[tuple[str, ...]]:
    parts = list(taint.path)
    wrapper = taint.wrapper
    out: list[tuple[str, ...]] = []

    def visible() -> tuple[str, ...]:
        shown = list(parts)
        if wrapper and shown and shown[0] == wrapper:
            shown = shown[1:]
        return tuple(shown)

    if visible():
        out.append(visible())
    for kind, name in segments:
        if kind == "field":
            parts.append(name)
        elif kind == "index":
            if not parts or parts[-1] != "[]":
                parts.append("[]")
        else:
            break
        if visible():
            out.append(visible())
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
        self.model_types = parse_model_types(blobs.get(ENUMS_LUA, ""))
        self.model_classes = parse_model_define(blobs.get(MODEL_DEFINE_LUA, ""))
        self.classes = parse_classes(blobs)
        self.file_indexes: dict[str, FunctionIndex] = {}
        self.file_aliases: dict[str, dict[str, str]] = {}
        self.class_files: dict[tuple[str, str | None], list[str]] = {}
        self.paths: dict[str, dict[str, dict[tuple[str, int, str, bool], Site]]] = {}
        self.callbacks: dict[str, list[dict]] = {}
        self.stores: dict[tuple[str, str | None, tuple[tuple[str, str], ...]], dict[Taint, set[int]]] = {}
        self.file_stores: dict[tuple[str, tuple[tuple[str, str], ...]], dict[Taint, set[int]]] = {}
        self.return_methods: dict[tuple[str, str | None, str], dict[Taint, set[int]]] = {}
        self.event_handlers = parse_event_handlers(blobs)
        self.mid_events = parse_mid_events(blobs.get(BACKEND_LUA, ""))
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
        sites[(site.file, site.line, site.via, site.guarded)] = site

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
        if len(arguments) < 3:
            self.analyze_event_reply(mid, file, line)
            return
        callback_start, callback_end = arguments[2]
        if tokens[callback_start].value == "nil":
            self.analyze_event_reply(mid, file, line)
            return
        if tokens[callback_start].value == "function" and tokens[callback_start].kind == "kw":
            parsed = self.index(file).by_start.get(callback_start)
            if parsed is None:
                self.record_callback(mid, _unknown(file, line, "unterminated inline callback"))
                return
            self.record_callback(mid, _checked(file, line))
            self.analyze_reply(mid, file, parsed, Taint(), "callback")
            enclosing = parsed.parent
            if enclosing is not None and enclosing.name and _forwards_reply(tokens, parsed, enclosing):
                for caller_file, caller_function, body in resolve_wrapper_callbacks(self, enclosing.name):
                    self.analyze_reply(mid, caller_file, caller_function, Taint(), f"{enclosing.name} call site", body)
            return
        if callback_end - callback_start == 1 and tokens[callback_start].kind == "name":
            name = tokens[callback_start].value
            parsed = self.index(file).by_name.get(name)
            if parsed is not None:
                self.record_callback(mid, _checked(file, line))
                self.analyze_reply(mid, file, parsed, Taint(), "callback")
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
            self.analyze_reply(mid, file, wrapped, Taint(), "callback")
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
        callbacks = resolve_wrapper_callbacks(self, method)
        if not callbacks:
            self.record_callback(mid, _unknown(file, line, f"callback forwards to parameter {parameter}; no {method} call site resolves"))
            return
        self.record_callback(mid, _checked(file, line, f"forwarded to {method} call sites"))
        for caller_file, caller_function, body in callbacks:
            self.analyze_reply(mid, caller_file, caller_function, Taint(), f"{method} call site", body)

    def analyze_event_reply(self, mid, file, line) -> None:
        if mid & 36864 == 32768:
            self.record_callback(mid, _unknown(file, line, "chat-room transport: reply is a socket push, not an HTTP reply"))
            return
        event = self.mid_events.get(mid)
        if event is None:
            self.record_callback(mid, _unknown(file, line, "no callback and no mid-to-event mapping"))
            return
        handlers = self.event_handlers.get(event, [])
        if not handlers:
            self.record_callback(mid, _unknown(file, line, f"dispatch of xyd.event.{event} has no resolvable handler"))
            return
        self.record_callback(mid, _checked(file, line, f"dispatched as xyd.event.{event}"))
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
                for taint, mids, via_seed in seeds[position]:
                    self.record_read(file, token.line, taint, [], via_seed, guards, mids)
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
                        if parsed.params:
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
                self.record_read(file, token.line, taint, segments, via, guards, mids, fallback)
            position = after

    def record_read(self, file, line, taint, segments, via, guards, mids, fallback=False) -> None:
        for parts in path_parts(taint, segments):
            path = path_string(parts)
            if not path:
                continue
            guarded = fallback or parts in guards
            for mid in mids:
                self.add_site(mid, path, Site(file, line, via, guarded))

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
                self.record_store(mid, file, function, root, segments, found)
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

    def record_store(self, mid, file, function, receiver_root, segments, found) -> None:
        taint, mids = found
        store_path = tuple(segments)
        if taint.wrapper is not None:
            return
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
        del position, guards
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
                self.record_store(mid, file, function, root, segments, (element(taint), mids))
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
        for kind, condition, body_start, body_end in branches:
            positive, negative = condition_paths(tokens, *condition)
            if kind == "else":
                branch_guards = guards | negative
            else:
                branch_guards = guards | positive
            self.scan(mid, file, function, body_start, body_end, bindings, via, frozenset(branch_guards), seeds, None)
            if kind != "else":
                exiting.append((kind, positive, negative))
        has_else = any(kind == "else" for kind, _, _, _ in branches)
        if not has_else:
            for kind, positive, negative in exiting:
                if branch_exits(tokens, *_branch_body(tokens, position, if_end, kind)):
                    guards = guards | negative
                    break
        return if_end + 1

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
        key = (target_file, target_function.start, tuple(sorted((name, value[0].path, value[0].wrapper or "") for name, value in bound.items())))
        if key in self.replay:
            return
        self.replay.add(key)
        for taint, mids in bound.values():
            self.record_read(file, tokens[after].line, taint, [], via, guards, mids)
        self.scan(mid, target_file, target_function, target_function.body_start, target_function.end, bound,
                  f"{root}:{segments[-1][1] if segments else target_function.name or ''}", frozenset(), None, None)

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
                return Taint(found[0].path, wrapper=tokens[position].value), found[1]
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
        index = self.index(file)
        tokens = index.tokens
        aliases = self.aliases(file)
        file_class = self.file_class(file)
        seeds: dict[int, list[tuple[Taint, frozenset[int], str]]] = {}
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
            remainder = segments[match + len(store_path):]
            for stored, mids in taints.items():
                if binding in stored.followed:
                    continue
                seed = extend_taint(stored, remainder)
                followed = seed.followed | {binding}
                seeds.setdefault(position, []).append((Taint(seed.path, seed.wrapper, followed), frozenset(mids), "stored field"))
        if not seeds:
            return
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
            for function in index.functions:
                if function.parent is not None or not function.name:
                    continue
                returned: list[tuple[Taint, frozenset[int]]] = []
                seeds = self.field_seeds(file, function, class_name, class_file, store_path, taints)
                if seeds:
                    self.scan(0, file, function, function.body_start, function.end, {}, "return", frozenset(), seeds, returned)
                for taint, mids in returned:
                    self.return_methods.setdefault((class_name, file, function.name), {}).setdefault(taint, set()).update(mids)
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
                seeds.setdefault(position, []).append((Taint(seed.path, seed.wrapper, followed), frozenset(mids), "returned rows"))
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
            for taint, mids in returned.items():
                if binding in taint.followed:
                    continue
                followed = taint.followed | {binding}
                seeds.setdefault(position, []).append((Taint(taint.path, taint.wrapper, followed), frozenset(mids), f"{class_name}:{method} return"))
        if not seeds:
            return
        for function in index.functions:
            local_seeds = {position: value for position, value in seeds.items()
                           if function.body_start <= position <= function.end}
            if not local_seeds:
                continue
            self.scan(0, file, function, function.body_start, function.end, {}, f"{class_name}:{method} return",
                      frozenset(), local_seeds, None)


def resolve_wrapper_callbacks(extractor: Extractor, method: str) -> list[tuple[str, Function, tuple[int, int]]]:
    found: list[tuple[str, Function, tuple[int, int]]] = []
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
            start, end = callback
            parsed = index.by_start.get(start) or index.by_name.get(tokens[start].value)
            if parsed is not None:
                found.append((candidate, parsed, (start + 1 if tokens[start].value == "function" else parsed.body_start, end)))
    return found


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


def condition_paths(tokens, start, end) -> tuple[frozenset[tuple[str, ...]], frozenset[tuple[str, ...]]]:
    positive: set[tuple[str, ...]] = set()
    negative: set[tuple[str, ...]] = set()
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
        parts = _segment_parts(segments)
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


def _not_paths(tokens, start, end) -> set[tuple[str, ...]]:
    paths: set[tuple[str, ...]] = set()
    for position in range(start, end - 1):
        if tokens[position].kind == "kw" and tokens[position].value == "not" and tokens[position + 1].kind == "name":
            _, segments, _ = chain_at(tokens, position + 1)
            paths.add(_segment_parts(segments))
    return paths


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
            rows = Taint(container.path + ("[]",), container.wrapper)
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


def parse_event_handlers(blobs: dict[str, str]) -> dict[str, list[tuple[str, Function]]]:
    handlers: dict[str, list[tuple[str, Function]]] = {}
    for file in sorted(blobs):
        if "registerEvent" not in blobs[file]:
            continue
        tokens = Tokenizer(blobs[file]).tokens()
        index = index_functions(file, tokens)
        for position, token in enumerate(tokens):
            if token.kind != "name" or token.value != "registerEvent":
                continue
            if position + 1 >= len(tokens) or tokens[position + 1].value != "(":
                continue
            arguments, _ = split_arguments(tokens, position + 1)
            if len(arguments) < 2:
                continue
            event = _event_name(tokens, arguments[0])
            handler = _handler_method(tokens, arguments[1])
            if event and handler and index.by_name.get(handler):
                handlers.setdefault(event, []).append((file, index.by_name[handler]))
    return handlers


def _event_name(tokens, argument) -> str | None:
    start, end = argument
    values = [token.value for token in tokens[start:end]]
    if len(values) == 5 and values[:4] == ["xyd", ".", "event", "."]:
        return values[4]
    return None


def _handler_method(tokens, argument) -> str | None:
    start, end = argument
    values = [token.value for token in tokens[start:end]]
    if len(values) >= 3 and values[-2] == "." and tokens[end - 1].kind == "name":
        return values[-1]
    if len(values) >= 3 and values[-2] == "," and tokens[end - 1].kind == "name":
        return values[-1]
    return None


def parse_mid_events(text: str) -> dict[int, str]:
    body = re.search(r"setupMidToEventNameMappings_\(.*?\nend", text, re.S)
    if not body:
        return {}
    symbols = parse_mid_symbols(text)
    return {
        symbols[match.group(1)]: match.group(2)
        for match in re.finditer(r"mid2EventNames_\[xyd\.mid\.([A-Za-z0-9_]+)\]\s*=\s*xyd\.event\.([A-Za-z0-9_]+)", body.group(0))
        if match.group(1) in symbols
    }


# -------------------------------------------------------------------- output
def build(blobs: dict[str, str], collapse: bool = True) -> dict:
    extractor = Extractor(blobs)
    extractor.run()
    mids: dict[str, dict] = {}
    for mid, callbacks in sorted(extractor.callbacks.items(), key=lambda item: int(item[0])):
        path_entries = []
        for path, sites in sorted(extractor.paths.get(mid, {}).items()):
            ordered_sites = sorted(sites.values(), key=lambda item: (item.file, item.line, item.via))
            site_list = [
                {"file": site.file, "line": site.line, "via": site.via, "guarded": site.guarded}
                for site in ordered_sites
            ]
            requirement = "OPTIONAL" if all(site.guarded for site in ordered_sites) else "REQUIRED"
            path_entries.append({"path": path, "requirement": requirement, "sites": site_list})
        mids[mid] = {
            "name": mid_name(extractor, int(mid)),
            "callbacks": sorted(callbacks, key=lambda entry: (entry["file"], entry["line"], entry["status"])),
            "paths": path_entries,
        }
    unknown = sum(1 for entry in mids.values() for callback in entry["callbacks"] if callback["status"] == "UNKNOWN")
    payload = {
        "schema_version": 2,
        "source": "current src_64 Lua reply callbacks",
        "source_archive_sha256": archive_sha(),
        "status": "UNKNOWN" if unknown else "CHECKED",
        "unknown_callbacks": unknown,
        "mid_count": len(mids),
        "mids": mids,
    }
    return compact_payload(collapse_sites(payload)) if collapse else payload


def collapse_sites(payload: dict) -> dict:
    mids: dict[str, dict] = {}
    for mid, record in payload["mids"].items():
        paths = []
        for entry in record["paths"]:
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
            paths.append(collapsed)
        mids[mid] = {"name": record["name"], "callbacks": record["callbacks"], "paths": paths}
    return {**payload, "mids": mids}


def compact_payload(payload: dict) -> dict:
    files = sorted({
        site["file"]
        for record in payload["mids"].values()
        for entry in record["paths"]
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
        paths = []
        for entry in record["paths"]:
            sites = [[index[site["file"]], site["line"], 1 if site["guarded"] else 0, list(site["via"])]
                     for site in entry["sites"]]
            path = [entry["path"], REQUIREMENT_CODES[entry["requirement"]], sites]
            if "waiver" in entry:
                path.append(entry["waiver"])
            paths.append(path)
        mids[mid] = {"name": record["name"], "callbacks": callbacks, "paths": paths}
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
