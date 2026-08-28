#!/usr/bin/env python3
"""Generate Pass186 P1 immutable source catalogs from effective src_64.

Usage:
  python tools/build_p1_source_catalogs.py /path/to/app-assets/output/assets/src_64 [data_dir]
"""
from __future__ import annotations
import base64, hashlib, json, re, sys
from pathlib import Path

SCHEMA_VERSION = 1
SOURCE_ARCHIVE_SHA256 = "89f0f830508b92e5fff6ad53c6a9dae961a14042dbfdf5649008efb8353f5608"


def parse_lua_table(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8-sig")
    km = re.search(r"keys\s*=\s*\{(.*?)\}\s*,?\s*rows\s*=", text, re.S)
    if not km:
        raise ValueError(f"missing keys in {path}")
    keys = re.findall(r'"((?:\\.|[^"\\])*)"', km.group(1))
    rm = re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$", text, re.S)
    if not rm:
        raise ValueError(f"missing rows in {path}")
    body = rm.group(1)
    rows: list[dict[str, str]] = []
    depth = 0
    start = None
    inq = False
    esc = False
    for i, ch in enumerate(body):
        if inq:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                inq = False
            continue
        if ch == '"':
            inq = True
        elif ch == "{":
            if depth == 0:
                start = i + 1
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start is not None:
                vals = re.findall(r'"((?:\\.|[^"\\])*)"', body[start:i])
                vals = [bytes(v, "utf-8").decode("unicode_escape") if "\\" in v else v for v in vals]
                if len(vals) != len(keys):
                    raise ValueError(f"row width drift in {path}: {len(vals)} != {len(keys)}")
                rows.append(dict(zip(keys, vals)))
                start = None
    return rows



def parse_encoded_tsv(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8-sig").strip()
    m = re.match(r'return\s+"(.*)"$', text, re.S)
    if not m:
        raise ValueError(f"missing encoded TSV payload in {path}")
    decoded = base64.b64decode(m.group(1)).decode("utf-8", errors="strict")
    lines = decoded.splitlines()
    if not lines:
        return []
    keys = lines[0].split("\t")
    rows: list[dict[str, str]] = []
    for line in lines[1:]:
        values = line.split("\t")
        if len(values) < len(keys):
            values.extend([""] * (len(keys) - len(values)))
        if len(values) != len(keys):
            raise ValueError(f"encoded TSV row width drift in {path}: {len(values)} != {len(keys)}")
        rows.append(dict(zip(keys, values)))
    return rows


def misc_values(rows: list[dict[str, str]], names: set[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for row in rows:
        name = row.get("name") or row.get("key") or next(iter(row.values()), "")
        if name in names:
            values = list(row.values())
            out[name] = values[1] if len(values) > 1 else ""
    missing = names - set(out)
    if missing:
        raise ValueError(f"missing misc keys: {sorted(missing)}")
    return out

def write(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def metadata(src: Path, files: list[str]) -> dict:
    return {
        "schema_version": SCHEMA_VERSION,
        "source_resolution": "effective_src64",
        "epistemic_class": "SOURCE_FACT_ONLY",
        "source_archive_sha256": SOURCE_ARCHIVE_SHA256,
        "effective_src64_root": "app-assets/output/assets/src_64",
        "source_files": files,
        "source_file_sha256": {
            name: hashlib.sha256((src / name).read_bytes()).hexdigest() for name in files
        },
    }


def main() -> int:
    if len(sys.argv) < 2:
        raise SystemExit("source src_64 path required")
    src = Path(sys.argv[1]).resolve()
    data = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else Path(__file__).resolve().parents[1] / "data"
    data.mkdir(parents=True, exist_ok=True)

    course_files = [
        "data/tables/object_subject.lua", "data/tables/object_class.lua",
        "data/tables/object_book.lua", "data/tables/object_book_color.lua",
        "data/tables/misc.lua", "data/tables/item.lua",
    ]
    misc_rows = parse_lua_table(src / course_files[4])
    misc = misc_values(misc_rows, {
        "object_class_forget", "object_classroom_time",
        "object_classroom_knowledge", "object_classroom_money",
        "object_classroom_log_limit", "object_box_books",
    })
    encoded_items = parse_encoded_tsv(src / course_files[5])
    exp_item_ids = [int(v) for v in misc["object_box_books"].split("|") if v]
    exp_items: list[dict[str, int]] = []
    for item_id in exp_item_ids:
        row = next((r for r in encoded_items if r.get("物品ID") == str(item_id)), None)
        if row is None:
            raise ValueError(f"missing Course proficiency item {item_id}")
        exp_items.append({"item_id": item_id, "proficiency": int(row.get("熟練度") or 0)})
    course = {
        "_meta": metadata(src, course_files),
        "fixed_study_seconds": int(misc["object_classroom_time"]),
        "misc": {
            "forget_crystal": int(misc["object_class_forget"]),
            "study_knowledge_coefficient": float(misc["object_classroom_knowledge"]),
            "speed_money": int(misc["object_classroom_money"]),
            "study_log_limit": int(misc["object_classroom_log_limit"]),
        },
        "proficiency_items": exp_items,
        "tables": {
            "subjects": parse_lua_table(src / course_files[0]),
            "classes": parse_lua_table(src / course_files[1]),
            "books": parse_lua_table(src / course_files[2]),
            "book_colors": parse_lua_table(src / course_files[3]),
        },
    }
    write(data / "p1_course_source_catalog.json", course)

    album_files = ["data/tables/collect_normal.lua", "data/tables/collect_special.lua"]
    album = {
        "_meta": metadata(src, album_files),
        "tables": {
            "normal": parse_lua_table(src / album_files[0]),
            "special": parse_lua_table(src / album_files[1]),
        },
    }
    write(data / "p1_white_album_source_catalog.json", album)

    workshop_files = [
        "data/tables/event_centre_bookshelf.lua", "data/tables/event_centre_cabinet.lua",
        "data/tables/event_centre_cabinetbook.lua", "data/tables/event_centre_cabinetskill.lua",
        "data/tables/event_centre_skillcost.lua", "data/tables/item.lua",
    ]
    cabinet_books = parse_lua_table(src / workshop_files[2])
    cabinet_book_ids = {int(row["id"]) for row in cabinet_books}
    item_rows = parse_encoded_tsv(src / workshop_files[5])
    book_compose: list[dict[str, int]] = []
    for row in item_rows:
        try:
            item_id = int(row.get("物品ID") or 0)
        except (TypeError, ValueError):
            continue
        if item_id not in cabinet_book_ids:
            continue
        compose = str(row.get("合成需求") or "").strip()
        compose_num = str(row.get("合成需求量") or "").strip()
        if compose in {"", "0"} or compose_num in {"", "0"}:
            continue
        parts = [int(v) for v in compose.split("|") if v and v != "0"]
        nums = [int(v) for v in compose_num.split("|") if v and v != "0"]
        if len(parts) != 1 or len(nums) != 1:
            raise ValueError(f"unexpected Cabinet book compose vector for {item_id}: {parts}/{nums}")
        book_compose.append({
            "id": item_id,
            "book_id": item_id,
            "fragment_id": parts[0],
            "fragment_num": nums[0],
            "compose_mana": int(row.get("合成金幣") or 0),
        })
    if len(book_compose) != 40:
        raise ValueError(f"Cabinet craftable-book census drift: {len(book_compose)} != 40")
    workshop = {
        "_meta": metadata(src, workshop_files),
        "building_types": {"cabinet": 1, "bookshelf": 4},
        "tables": {
            "bookshelf": parse_lua_table(src / workshop_files[0]),
            "cabinet": parse_lua_table(src / workshop_files[1]),
            "cabinet_books": cabinet_books,
            "cabinet_skills": parse_lua_table(src / workshop_files[3]),
            "skill_costs": parse_lua_table(src / workshop_files[4]),
            "book_compose": book_compose,
        },
    }
    write(data / "p1_workshop_source_catalog.json", workshop)

    element_files = ["data/tables/element_equip.lua", "data/tables/element_strth.lua"]
    element = {
        "_meta": metadata(src, element_files),
        "equip_types": {"normal": 1, "core": 2, "sp_core": 3},
        "tables": {
            "element_equip": parse_lua_table(src / element_files[0]),
            "element_strth": parse_lua_table(src / element_files[1]),
        },
    }
    write(data / "p1_element_source_catalog.json", element)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
