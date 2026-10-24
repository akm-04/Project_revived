#!/usr/bin/env python3
"""Compile the I7C-5A combat rules corpus from the pinned source archive.

The corpus holds exact Lua module bytes and the decoded table rows that the
missing server TableParser hands to table-class callbacks. No data Lua is
executed. The output is deterministic; --check re-derives it and compares.
"""
from __future__ import annotations

import argparse
import base64
import gzip
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_builtin_content import (  # noqa: E402
    EXPECTED_SOURCE_ARCHIVE_SHA256,
    SOURCE_PREFIX,
    CompileError,
    canonical_json_bytes,
    parse_base64_indexed_lua_table,
    parse_generated_lua_table,
    sha256_bytes,
    sha256_file,
)

SCHEMA_VERSION = 1
CORPUS_COMPILER_VERSION = "i7c5a-combat-corpus-v1"
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / "internal/content/combatcorpus/generated"

SINGLETON_MODULES = [
    "app/common/enums.lua",
    "app/common/const.lua",
    "app/common/utils.lua",
    "app/common/list.lua",
    "framework/functions.lua",
    "app/model/Hero.lua",
    "app/model/NormalHero.lua",
    "app/model/SuperHero.lua",
    "app/model/Pet.lua",
    "app/model/Item.lua",
    "app/scenes/BattleCreateReport.lua",
    "app/common/tables/tables.lua",
]
# utils.lua is a client helper library; its table references are UI paths and
# do not seed the closure. A combat path reaching one fails closed in the VM.
CLOSURE_EXCLUDED_ROOTS = {"app/common/utils.lua"}
# TableParser is supplied by the resolver seam; BaseFighter.shake returns before
# reading tables.shake when battleType is CreateReport (BaseFighter.lua:3237).
ALLOWED_UNBOUND_ALIASES = {"TableParser", "shake"}
# Client TableParser.lua dispatch: per-row (row, keys) for these indexed files,
# tab-separated text for these, generated named tables otherwise.
INDEXED_TABLES = {"monster", "partner", "super_partner", "activity_partner", "pet"}
TEXT_TABLES = {"item", "model_points", "battle_config", "skill", "buff"}
# FIGHTER_CLASS_REACHABILITY_ADJUDICATION: Fazheng_Awaken uses 80000229 only as
# a presentation HeroAnimation outside CreateReport; it is never a fighter.
PRESENTATION_ONLY_SUMMONS = {80000229}
LUA_SPACE = " \t\n\v\f\r"


def module_name(path: str) -> str:
    return path[: -len(".lua")].replace("/", ".")


def read_archive(archive: Path) -> dict[str, bytes]:
    actual = sha256_file(archive)
    if actual != EXPECTED_SOURCE_ARCHIVE_SHA256:
        raise CompileError(f"source archive SHA-256 mismatch: {actual}")
    out = {}
    with zipfile.ZipFile(archive) as zf:
        for member in zf.namelist():
            if member.startswith(SOURCE_PREFIX) and not member.endswith("/"):
                out[member[len(SOURCE_PREFIX):]] = zf.read(member)
    return out


def text(data: bytes) -> str:
    return data.decode("utf-8-sig")


def decoded_base64(data: bytes) -> str:
    m = re.fullmatch(r'\s*return\s*"([A-Za-z0-9+/=]+)"\s*', text(data))
    if not m:
        raise CompileError("table is not a single base64 return string")
    return base64.b64decode(m.group(1), validate=True).decode("utf-8")


def parse_text_table(data: bytes) -> list[dict[str, str]]:
    """TableParser.decryptParse: lines via ([^\\r\\n]*)[\\r\\n]+ (unterminated tail and
    blank lines are skipped), xyd.trimString per line, fields via ([^\\t]*)\\t."""
    rows, headers = [], []
    for number, match in enumerate(re.finditer(r"([^\r\n]*)[\r\n]+", decoded_base64(data)), start=1):
        line = match.group(1).strip(LUA_SPACE)
        fields = (line + "\t").split("\t")[:-1]
        if number == 1:
            continue
        if number == 2:
            headers = fields
            continue
        if len(fields) > len(headers):
            raise CompileError("text table row has more fields than headers")
        rows.append({headers[i]: v.replace("::", "\n") for i, v in enumerate(fields)})
    return rows


def parse_research_indexed(decoded: str) -> tuple[dict[str, int], dict[int, list[str]]]:
    """Positional indexed grammar for the unwrapped monster rows; differential-checked
    against the source TableParser under Lua (MONSTER_DECODER_SOURCE_DIFFERENTIAL)."""
    keys_match = re.search(r"table\.keys\s*=\s*\{(.*?)\}\s*table\.rows", decoded, re.S)
    if not keys_match:
        raise CompileError("indexed table keys missing")
    keys = {}
    for name, index in re.findall(r"([A-Za-z0-9_]+)\s*=\s*(\d+)", keys_match.group(1)):
        if name in keys or int(index) <= 0:
            raise CompileError("indexed table key invalid")
        keys[name] = int(index)
    position = re.search(r"table\.rows\s*=\s*\{", decoded).end()
    rows: dict[int, list[str]] = {}
    size = len(decoded)

    def skip(i: int) -> int:
        while i < size and (decoded[i].isspace() or decoded[i] == ","):
            i += 1
        return i

    def value(i: int) -> tuple[str, int]:
        i = skip(i)
        if decoded[i] == '"':
            j, chars, escaped = i + 1, [], False
            while j < size:
                c = decoded[j]
                if escaped:
                    chars.append("\\" + c)
                    escaped = False
                elif c == "\\":
                    escaped = True
                elif c == '"':
                    return json.loads('"' + "".join(chars) + '"'), j + 1
                else:
                    chars.append(c)
                j += 1
            raise CompileError("unterminated indexed quoted value")
        long_match = re.compile(r"\[(=*)\[").match(decoded, i)
        if long_match:
            close = "]" + long_match.group(1) + "]"
            end = decoded.find(close, long_match.end())
            if end < 0:
                raise CompileError("unterminated indexed long string")
            return decoded[long_match.end():end], end + len(close)
        token = re.compile(r"[^,}\s]+").match(decoded, i)
        if not token:
            raise CompileError("indexed token missing")
        return token.group(0), token.end()

    row_pattern = re.compile(r"\[(\d+)\]\s*=\s*\{")
    while True:
        position = skip(position)
        if decoded[position] == "}":
            position += 1
            break
        row_match = row_pattern.match(decoded, position)
        if not row_match:
            raise CompileError("indexed row prefix missing")
        row_id = int(row_match.group(1))
        if row_id in rows:
            raise CompileError("duplicate indexed row")
        position = row_match.end()
        values = []
        while True:
            position = skip(position)
            if decoded[position] == "}":
                position += 1
                break
            item, position = value(position)
            values.append(item)
        rows[row_id] = values
    if decoded[position:].strip() != "return table":
        raise CompileError("unexpected executable indexed-table tail")
    return keys, rows


def parse_monster(data: bytes) -> tuple[dict[str, int], dict[int, list[str]]]:
    decoded = decoded_base64(data)
    if not set(re.findall(r"\\(.)", decoded)) <= {'"', "'"}:
        raise CompileError("monster table has unexpected escapes")
    unwrapped = 0

    def unwrap(match: re.Match) -> str:
        nonlocal unwrapped
        prefix, body, suffix = match.groups()
        body = re.sub(r"\\([\"'])", r"\1", body)
        if not body.startswith("return {") or not body.rstrip().endswith("}"):
            raise CompileError("monster row is not a quoted return table")
        unwrapped += 1
        return prefix + body[len("return "):] + suffix

    normalized = re.sub(r"^(\[\d+\] = )'((?:\\.|[^'\\])*)'(,?\s*)$", unwrap, decoded, flags=re.M)
    if unwrapped != len(re.findall(r"^\[\d+\] =", decoded, re.M)):
        raise CompileError("monster rows not all unwrapped")
    return parse_research_indexed(normalized)


def table_payload(name: str, data: bytes) -> dict:
    if name in INDEXED_TABLES:
        keys, rows = parse_monster(data) if name == "monster" else parse_base64_indexed_lua_table(data)
        width = max(keys.values())
        if any(len(values) < width for values in rows.values()):
            raise CompileError(f"indexed table {name} row shorter than keys")
        return {"kind": "INDEXED", "keys": keys, "rows": [rows[i] for i in sorted(rows)]}
    if name in TEXT_TABLES:
        return {"kind": "NAMED", "rows": parse_text_table(data)}
    rows = parse_generated_lua_table(data)
    return {"kind": "NAMED", "rows": [{k: v.replace("::", "\n") for k, v in row.items()} for row in rows]}


TABLE_ACCESS = re.compile(r"\b(?:xyd|var_\d+_\d+)\.tables\.(\w+)")
TABLE_MODULE = re.compile(r'(?:import|require)\(\s*"app\.common\.tables\.(\w+)"\s*\)')


def table_closure(files: dict[str, bytes], module_paths: list[str]) -> tuple[list[str], list[str]]:
    binding = dict(re.findall(r'var_0_0\.(\w+)\s*=\s*"([^"]+)"', text(files["app/common/tables/tables.lua"])))
    by_module = {module: alias for alias, module in binding.items()}
    pending = set()
    for path in module_paths:
        if path not in CLOSURE_EXCLUDED_ROOTS:
            source = text(files[path])
            pending |= set(TABLE_ACCESS.findall(source))
            pending |= {by_module.get(f"app.common.tables.{m}", m) for m in TABLE_MODULE.findall(source)}
    classes, data_names, seen = set(), set(), set()
    while pending:
        alias = pending.pop()
        if alias in seen:
            continue
        seen.add(alias)
        if alias not in binding:
            if alias not in ALLOWED_UNBOUND_ALIASES:
                raise CompileError(f"unbound table alias {alias}")
            continue
        path = binding[alias].replace(".", "/") + ".lua"
        source = text(files[path])
        classes.add(path)
        data_names |= {n.removesuffix(".lua") for n in re.findall(r'\.parse\(\s*"([^"]+)"', source)}
        pending |= set(TABLE_ACCESS.findall(source)) - seen
        pending |= {by_module.get(f"app.common.tables.{m}", m) for m in TABLE_MODULE.findall(source)} - seen
    return sorted(classes), sorted(data_names)


def fighter_classes(files: dict[str, bytes], tables: dict[str, dict]) -> dict:
    present = sorted(Path(p).stem for p in files if re.fullmatch(r"lib/battle/fighters/[^/]+\.lua", p))
    present_set = set(present)

    def classes_of(name: str) -> dict[str, str]:
        table = tables[name]
        column = table["keys"]["class_name"] - 1
        return {values[0]: values[column] for values in table["rows"]}

    by_table = {}
    for name in ("partner", "super_partner", "pet", "activity_partner", "monster"):
        by_table[name] = classes_of(name)
    monster = by_table["monster"]
    for row in tables["skill"]["rows"]:
        for target in filter(lambda v: v not in ("", "0"), row.get("summon_monster", "").split("|")):
            if int(target) in PRESENTATION_ONLY_SUMMONS:
                continue
            if monster.get(target) not in present_set:
                raise CompileError(f"skill {row['id']} summons {target} without a fighter class")
    return {"present": present, "by_table": by_table, "presentation_only_summons": sorted(PRESENTATION_ONLY_SUMMONS)}


def build(archive: Path) -> dict[str, bytes]:
    files = read_archive(archive)
    battle = sorted(p for p in files if p.startswith("lib/battle/") and p.endswith(".lua"))
    roots = battle + SINGLETON_MODULES
    classes, data_names = table_closure(files, roots)
    module_paths = sorted(set(roots) | set(classes))
    modules = {module_name(p): text(files[p]) for p in module_paths}
    if len(modules) != len(module_paths):
        raise CompileError("module name collision")
    out: dict[str, bytes] = {"modules.json": canonical_json_bytes(modules)}
    tables, table_rows = {}, []
    for name in data_names:
        path = f"data/tables/{name}.lua"
        if path not in files:
            raise CompileError(f"missing table data {path}")
        payload = table_payload(name, files[path])
        tables[name] = payload
        blob = canonical_json_bytes(payload)
        out[f"tables/{name}.json"] = blob
        table_rows.append({"name": name, "kind": payload["kind"], "rows": len(payload["rows"]), "source_path": path,
                           "source_sha256": sha256_bytes(files[path]), "payload": f"tables/{name}.json", "payload_sha256": sha256_bytes(blob)})
    classes_blob = canonical_json_bytes(fighter_classes(files, tables))
    out["fighter_classes.json"] = classes_blob
    manifest = {
        "schema_version": SCHEMA_VERSION,
        "compiler_version": CORPUS_COMPILER_VERSION,
        "source_archive_sha256": EXPECTED_SOURCE_ARCHIVE_SHA256,
        "modules": [{"name": module_name(p), "source_path": p, "source_sha256": sha256_bytes(files[p])} for p in module_paths],
        "modules_payload_sha256": sha256_bytes(out["modules.json"]),
        "tables": table_rows,
        "fighter_classes_sha256": sha256_bytes(classes_blob),
    }
    out["manifest.json"] = canonical_json_bytes(manifest)
    return out


def stored_name(name: str) -> str:
    return name if name == "manifest.json" else name + ".gz"


def write(out: dict[str, bytes], output: Path) -> None:
    (output / "tables").mkdir(parents=True, exist_ok=True)
    for stale in output.rglob("*"):
        if stale.is_file() and stale.relative_to(output).as_posix() not in {stored_name(n) for n in out}:
            stale.unlink()
    for name, blob in out.items():
        data = blob if name == "manifest.json" else gzip.compress(blob, compresslevel=9, mtime=0)
        (output / stored_name(name)).write_bytes(data)


def check(out: dict[str, bytes], output: Path) -> list[str]:
    errors = []
    present = {p.relative_to(output).as_posix() for p in output.rglob("*") if p.is_file()}
    expected = {stored_name(n) for n in out}
    if present != expected:
        errors.append(f"file set differs: extra={sorted(present - expected)} missing={sorted(expected - present)}")
    for name, blob in out.items():
        path = output / stored_name(name)
        if not path.exists():
            continue
        data = path.read_bytes()
        if name != "manifest.json":
            data = gzip.decompress(data)
        if data != blob:
            errors.append(f"{name} differs from source re-derivation")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    out = build(args.source_archive)
    manifest = json.loads(out["manifest.json"])
    summary = f"modules={len(manifest['modules'])} tables={len(manifest['tables'])} corpus_id={sha256_bytes(out['manifest.json'])}"
    if args.check:
        errors = check(out, args.output)
        if errors:
            print("COMBAT CORPUS: FAIL")
            for e in errors:
                print(" -", e)
            return 1
        print("COMBAT CORPUS: PASS", summary)
        return 0
    write(out, args.output)
    print("COMBAT CORPUS: WRITTEN", summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
