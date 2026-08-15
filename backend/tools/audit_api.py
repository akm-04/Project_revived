#!/usr/bin/env python3
"""
audit_api.py -- walk the decompiled GXB Lua tree and catalogue every
xyd.Backend:request(mid, params, callback, ...) call site.

For each call site we record:
  - mid (resolved name + numeric value where known)
  - file:line
  - request param field names (best-effort, top-level only)
  - response field names the callback actually reads off `data`
    (arg_25_1.foo style accesses, top-level only)

This is static analysis, not execution -- it is a *lower bound* on what a
handler needs to support (fields only touched via bracket-string access,
computed keys, or deep-copied into other tables before use won't show up).
"""
import json
import os
import sys
import threading
from collections import defaultdict

from luaparser import ast, astnodes

sys.setrecursionlimit(100000)

SRC_ROOT = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/work/merged_src"
OUT_JSON = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/work/api_audit.json"


def src_of(node, src):
    """Raw source text for a node via its token span."""
    try:
        return src[node._first_token.start:node._last_token.stop + 1]
    except Exception:
        return None


def mid_to_str(node, src):
    """Render the mid argument as 'xyd.mid.NAME' or a literal number/string."""
    if isinstance(node, astnodes.Number):
        return str(node.n)
    if isinstance(node, astnodes.Index):
        # dot-chain: reconstruct left.right.right...
        parts = []
        cur = node
        while isinstance(cur, astnodes.Index):
            idx = cur.idx
            if isinstance(idx, str):
                parts.append(idx)
            elif hasattr(idx, "id"):
                parts.append(idx.id)
            elif isinstance(idx, astnodes.String):
                parts.append(idx.s)
            else:
                parts.append(src_of(idx, src) or "?")
            cur = cur.value
        if hasattr(cur, "id"):
            parts.append(cur.id)
        else:
            parts.append(src_of(cur, src) or "?")
        return ".".join(reversed(parts))
    if hasattr(node, "id"):
        return node.id  # bare variable holding a mid
    return src_of(node, src) or "?"


def table_top_level_keys(table_node, src):
    keys = []
    if not isinstance(table_node, astnodes.Table):
        return None  # not an inline table -- caller records raw source instead
    for f in table_node.fields:
        if f.key is None:
            keys.append("<array-item>")
        elif hasattr(f.key, "id"):
            keys.append(f.key.id)
        elif isinstance(f.key, astnodes.String):
            keys.append(f.key.s)
        else:
            keys.append(src_of(f.key, src) or "?")
    return keys


def collect_field_accesses(fn_node, data_var_name, src):
    """Walk a callback function body for `data_var.field` / `data_var['field']` accesses."""
    fields = set()
    if data_var_name is None or fn_node is None:
        return fields
    for node in ast.walk(fn_node):
        if isinstance(node, astnodes.Index):
            base = node.value
            if hasattr(base, "id") and base.id == data_var_name:
                idx = node.idx
                if isinstance(idx, str):
                    fields.add(idx)
                elif hasattr(idx, "id"):
                    fields.add(idx.id)
                elif isinstance(idx, astnodes.String):
                    fields.add(idx.s)
    return fields


def process_file(path, src, records, parse_errors):
    try:
        tree = ast.parse(src)
    except Exception as e:
        parse_errors.append((path, str(e)))
        return

    try:
        nodes = list(ast.walk(tree))
    except RecursionError:
        parse_errors.append((path, "RecursionError during walk"))
        return

    for node in nodes:
        if not isinstance(node, astnodes.Invoke):
            continue
        if not hasattr(node.func, "id") or node.func.id != "request":
            continue

        args = node.args
        line = node._first_token.line if node._first_token else -1

        try:
            mid_str = mid_to_str(args[0], src) if len(args) > 0 else "?"

            req_fields = None
            req_raw = None
            if len(args) > 1:
                keys = table_top_level_keys(args[1], src)
                if keys is not None:
                    req_fields = keys
                else:
                    req_raw = src_of(args[1], src)
                    if req_raw and len(req_raw) > 80:
                        req_raw = req_raw[:80] + "..."

            resp_fields = []
            if len(args) > 2 and isinstance(args[2], astnodes.AnonymousFunction):
                fn = args[2]
                params = [p.id for p in fn.args if hasattr(p, "id")]
                data_var = params[1] if len(params) > 1 else None
                resp_fields = sorted(collect_field_accesses(fn, data_var, src))
        except RecursionError:
            parse_errors.append((f"{path}:{line}", "RecursionError during field extraction"))
            continue

        records.append({
            "mid": mid_str,
            "file": path,
            "line": line,
            "request_fields": req_fields,
            "request_raw": req_raw,
            "response_fields": resp_fields,
        })


def main():
    records = []
    parse_errors = []
    n_files = 0
    n_candidates = 0
    for dirpath, _, filenames in os.walk(SRC_ROOT):
        # data/tables/* are static config (some are 30MB+) -- never contain
        # Backend:request() calls, and parsing them is what caused the
        # previous run to blow past the time limit. Skip the whole subtree.
        if os.path.basename(dirpath) == "tables" and "data" in dirpath.split(os.sep):
            continue
        for fn in filenames:
            if not fn.endswith(".lua"):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, SRC_ROOT)
            n_files += 1
            with open(full, "r", encoding="utf-8-sig", errors="replace") as f:
                src = f.read()
            # Cheap pre-filter: skip the ANTLR parse entirely unless the
            # literal substring is present.
            if ":request(" not in src:
                continue
            n_candidates += 1
            process_file(rel, src, records, parse_errors)
            print(f"[{n_candidates}] {rel}: {len(records)} records so far", file=sys.stderr)

    print(f"Scanned {n_files} files, {len(records)} request() call sites, "
          f"{len(parse_errors)} files failed to parse", file=sys.stderr)

    # Group by resolved mid name for the summary report
    by_mid = defaultdict(list)
    for r in records:
        by_mid[r["mid"]].append(r)

    with open(OUT_JSON, "w") as f:
        json.dump({
            "records": records,
            "parse_errors": parse_errors,
        }, f, indent=1)

    print(f"Wrote {OUT_JSON}", file=sys.stderr)
    print(f"Unique mid expressions referenced: {len(by_mid)}", file=sys.stderr)


if __name__ == "__main__":
    threading.stack_size(256 * 1024 * 1024)
    t = threading.Thread(target=main)
    t.start()
    t.join()
