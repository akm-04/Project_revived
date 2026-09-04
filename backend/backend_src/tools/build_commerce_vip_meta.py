#!/usr/bin/env python3
"""Build source-bounded Commerce/VIP metadata from effective src_64 Lua tables.

Pass87+ use generated JSON at runtime; the backend never executes raw Lua.
This builder intentionally extracts only source-owned static facts. Purchase
settlement and native SDK behavior are separate private-server policies.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def extract_table(text: str, start: int) -> str:
    depth = 0
    quote = None
    escape = False
    for i in range(start, len(text)):
        ch = text[i]
        if quote:
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == quote:
                quote = None
            continue
        if ch in ('"', "'"):
            quote = ch
        elif ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    raise ValueError('unterminated Lua row table')


def string_values(table_text: str) -> list[str]:
    values: list[str] = []
    i = 0
    while i < len(table_text):
        if table_text[i] != '"':
            i += 1
            continue
        i += 1
        out: list[str] = []
        escape = False
        while i < len(table_text):
            ch = table_text[i]
            i += 1
            if escape:
                out.append(ch)
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == '"':
                break
            else:
                out.append(ch)
        values.append(''.join(out))
    return values


def flat_table_rows(path: Path) -> tuple[list[str], list[list[str]]]:
    text = path.read_text(encoding='utf-8-sig')
    km = re.search(r'keys\s*=\s*\{(.*?)\}\s*,\s*rows\s*=', text, re.S)
    rm = re.search(r'rows\s*=\s*\{(.*)\}\s*\}\s*$', text, re.S)
    if not km or not rm:
        raise ValueError(f'unrecognized flat Lua table: {path}')
    keys = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', km.group(1))
    body = rm.group(1)
    rows: list[list[str]] = []
    cursor = 0
    while True:
        start = body.find('{', cursor)
        if start < 0:
            break
        table = extract_table(body, start)
        rows.append(string_values(table))
        cursor = start + len(table)
    return keys, rows


def as_number(value: str) -> Any:
    s = str(value).strip()
    if not s:
        return ''
    if re.fullmatch(r'-?\d+', s):
        return int(s)
    if re.fullmatch(r'-?\d+\.\d+', s):
        return float(s)
    return value


def rows_as_dicts(path: Path) -> list[dict[str, Any]]:
    keys, rows = flat_table_rows(path)
    out = []
    for row in rows:
        padded = row + [''] * max(0, len(keys) - len(row))
        out.append({key: as_number(padded[i]) for i, key in enumerate(keys)})
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('source_root', type=Path, help='effective src_64 root containing data/tables')
    ap.add_argument('--commerce-output', type=Path, default=Path('data/commerce_source_meta.json'))
    ap.add_argument('--vip-output', type=Path, default=Path('data/vip_source_meta.json'))
    ap.add_argument('--vip-award-output', type=Path, default=Path('data/vip_award_meta.json'))
    args = ap.parse_args()

    charge_path = args.source_root / 'data/tables/charge.lua'
    vip_path = args.source_root / 'data/tables/vip.lua'
    gift_path = args.source_root / 'data/tables/gift.lua'
    charge_rows = rows_as_dicts(charge_path)
    vip_rows = rows_as_dicts(vip_path)
    gift_rows = rows_as_dicts(gift_path)

    direct = []
    for row in charge_rows:
        if int(row.get('show_type') or 0) != 0:
            continue
        if int(row.get('is_privilege') or 0) != 0:
            continue
        if int(row.get('month_card') or 0) != 0:
            continue
        if int(row.get('is_show') or 0) != 1:
            continue
        direct.append({
            'charge_id': int(row['charge_id']),
            'display_price': row.get('charge'),
            'base_crystal': int(row.get('diamond') or 0),
            'first_extra_crystal': int(row.get('first_extra_diamond') or 0),
            'repeat_extra_crystal': int(row.get('extra_diamond') or 0),
            'ios_product_id': str(row.get('ios_product_id') or ''),
            'buy_limit': int(row.get('buy_limit') or -1),
            'source_show_type': int(row.get('show_type') or 0),
            'source_is_show': int(row.get('is_show') or 0),
            'source_month_card': int(row.get('month_card') or 0),
            'source_is_privilege': int(row.get('is_privilege') or 0),
            # Pass85/86 design decision: historical server formula is missing.
            # For direct charge.lua crystal packs, private preservation policy
            # uses the base diamond quantity as cumulative recharge progression.
            'vip_progression_delta': int(row.get('diamond') or 0),
            'vip_progression_classification': 'PRIVATE_SERVER_POLICY_SOURCE_BOUNDED',
        })

    commerce = {
        '_meta': {
            'schema_version': 1,
            'pass': '88.0',
            'source_resolution': 'effective_merged',
            'charge_source': 'data/tables/charge.lua',
            'charge_source_sha256': sha256(charge_path),
            'runtime_rule': 'Advertise only direct Crystal packs; cards/giftbags remain deferred.',
            'native_boundary': 'xyd.androidPurchase/xyd.sdkPurchase remains outside game MID transport; Pass88 exposes an authenticated preservation PurchaseIntent bridge and returns a post-commit MID36857 completion event.',
        },
        'direct_crystal_products': direct,
    }

    vip_by_id: dict[str, dict[str, Any]] = {}
    for row in vip_rows:
        level = int(row.get('id') or 0)
        vip_by_id[str(level)] = row
    vip = {
        '_meta': {
            'schema_version': 1,
            'pass': '88.0',
            'source_resolution': 'effective_merged',
            'vip_source': 'data/tables/vip.lua',
            'vip_source_sha256': sha256(vip_path),
            'canonical_rule': 'VIP level is derived from cumulative PlayerState.charge using charge_req thresholds.',
        },
        'rows': vip_by_id,
        'thresholds': [
            {'vip': level, 'charge_req': int(vip_by_id[str(level)].get('charge_req') or 0)}
            for level in sorted(int(k) for k in vip_by_id)
        ],
    }

    gift_by_id = {int(row.get('id') or 0): row for row in gift_rows if int(row.get('id') or 0) > 0}
    vip_award_tiers: dict[str, dict[str, Any]] = {}
    supported_gift_scalar_fields = {'crystal'}
    ignored_identity_fields = {'id', 'desc', 'items', 'item_nums'}
    for level in range(1, 16):
        vip_row = vip_by_id.get(str(level))
        if not isinstance(vip_row, dict):
            raise RuntimeError(f'missing VIP{level} row')
        gift_id = int(vip_row.get('reward_item') or 0)
        gift = gift_by_id.get(gift_id)
        if not isinstance(gift, dict):
            raise RuntimeError(f'VIP{level} reward_item {gift_id} missing from gift.lua')
        item_ids = [int(v) for v in str(gift.get('items') or '').split('|') if str(v).strip()]
        item_nums = [int(v) for v in str(gift.get('item_nums') or '').split('|') if str(v).strip()]
        if len(item_ids) != len(item_nums):
            raise RuntimeError(f'VIP{level} gift {gift_id} item/item_num length mismatch')
        unsupported_nonzero = {}
        for key, value in gift.items():
            if key in ignored_identity_fields or key in supported_gift_scalar_fields:
                continue
            if value not in ('', 0, '0', None):
                unsupported_nonzero[key] = value
        if unsupported_nonzero:
            raise RuntimeError(f'VIP{level} gift {gift_id} has unsupported nonzero fields: {unsupported_nonzero}')
        vip_award_tiers[str(level)] = {
            'vip_level': level,
            'gift_id': gift_id,
            'items': [
                {'item_id': item_id, 'item_num': item_num}
                for item_id, item_num in zip(item_ids, item_nums)
            ],
            'crystal': max(0, int(gift.get('crystal') or 0)),
            'response_crystal_table_id': -1,
        }
    vip_awards = {
        '_meta': {
            'schema_version': 1,
            'pass': '91.0',
            'source_resolution': 'effective_merged',
            'vip_source': 'data/tables/vip.lua',
            'vip_source_sha256': sha256(vip_path),
            'gift_source': 'data/tables/gift.lua',
            'gift_source_sha256': sha256(gift_path),
            'asset_crystal_table_id': -1,
            'runtime_rule': 'MID657 one-time VIP1..VIP15 gifts; items settle as Backpack stacks, Crystal through EconomyLedger, and vip_awards claim marker in the same PlayerUnitOfWork.',
        },
        'tiers': vip_award_tiers,
    }

    for path, payload in ((args.commerce_output, commerce), (args.vip_output, vip), (args.vip_award_output, vip_awards)):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
        print(f'wrote {path}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
