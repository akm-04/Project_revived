#!/usr/bin/env python3
"""Build/check the immutable guild rental policy from docs/i9/I9_GUILD_POLICY_V1.json.

The rental arithmetic is private policy; the VIP lending caps and rent level-up
are the client vip.lua columns, so they are read from the hash-bound source
archive and must match the contract. The generated copy is what the Go content
package embeds, so a policy edit is always a reproducible build step.
"""
from __future__ import annotations
import argparse, hashlib, json, re, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/i9/I9_GUILD_POLICY_V1.json'
OUT = ROOT / 'internal/content/guildrentalpolicy/generated/guild_rental_policy.json'
LOCK = ROOT / 'oracles.lock.json'
VIP = 'app-assets/output/assets/src_64/data/tables/vip.lua'
VIP_SHA = '18b76d7fa82964f57082aeb2092a80c231f69e86958b4b567aebabf30d626270'


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def oracle_sha() -> str:
    lock = json.loads(LOCK.read_text())
    return next(row['sha256'] for row in lock['oracles'] if row['id'] == 'current_src64')


def vip_rows(archive: Path) -> dict[int, dict[str, int]]:
    data = archive.read_bytes()
    if sha(data) != oracle_sha():
        raise SystemExit(f'source archive hash drift: {sha(data)}')
    with zipfile.ZipFile(archive) as bundle:
        vip = bundle.read(VIP)
    if sha(vip) != VIP_SHA:
        raise SystemExit(f'vip.lua hash drift: {sha(vip)}')
    text = vip.decode('utf-8-sig').replace('\r\n', '\n')
    keys_block = re.search(r'keys\s*=\s*\{(.*?)\}', text, re.S)
    rows_start = text.find('rows = {')
    if not keys_block or rows_start < 0:
        raise SystemExit('vip.lua shape drift')
    keys = re.findall(r'"([^"]+)"', keys_block.group(1))
    rows: dict[int, dict[str, int]] = {}
    for body in re.findall(r'\{\s*\n((?:\s*"[^"]*",?\s*\n)+)\s*\}', text[rows_start:]):
        values = re.findall(r'"([^"]*)"', body)
        if len(values) != len(keys):
            raise SystemExit(f'vip.lua row width {len(values)} != {len(keys)}')
        row = dict(zip(keys, values))
        rows[int(row['id'])] = {'lend': int(row['num_mercenary']), 'level_up': int(row['rent_level_up'])}
    return rows


def build(archive: Path) -> dict:
    doc = json.loads(SOURCE.read_text())
    rental, modes = doc['rental'], doc['borrow_modes']
    if rental['guild_share_percent'] != 0:
        raise SystemExit('guild_share_percent must be 0')
    if [row['vip'] for row in rental['vip_limits']] != list(range(16)):
        raise SystemExit('vip_limits must cover 0-15 in order')
    pinned = vip_rows(archive)
    for row in rental['vip_limits']:
        source = pinned.get(row['vip'])
        if source is None or source['lend'] != row['lend'] or source['level_up'] != row['level_up']:
            raise SystemExit(f"vip {row['vip']} disagrees with vip.lua {source}")
    compiled = []
    for mode in modes:
        if not mode['campaign_types']:
            raise SystemExit(f"borrow mode {mode['key']} has no campaign types")
        compiled.append({
            'key': mode['key'], 'campaign_types': mode['campaign_types'],
            'enabled': mode['enabled'],
            'star_cap': mode['star_cap'] if mode['star_cap'] is not None else -1,
        })
    return {
        'policy_id': doc['policy_id'],
        'policy_version': doc['version'],
        'money': {
            'price_force_divisor': rental['price_mana_per_force_divisor'],
            'price_floor_mana': rental['price_floor_mana'],
            'hourly_interest_force_divisor': rental['hourly_interest_force_divisor'],
            'recall_minimum_seconds': rental['recall_minimum_seconds'],
            'level_up_ceiling': rental['level_up_ceiling'],
            'guild_share_percent': rental['guild_share_percent'],
        },
        'vip_limits': [{'vip': row['vip'], 'lend': row['lend'], 'level_up': row['level_up']} for row in rental['vip_limits']],
        'modes': compiled,
        'departure_mail': {
            'sender': rental['departure_mail']['sender'],
            'title': rental['departure_mail']['title'],
            'body': rental['departure_mail']['body'],
        },
        'source_vip_sha256': VIP_SHA,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--source-archive', type=Path, required=True)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    payload = json.dumps(build(args.source_archive), sort_keys=True, separators=(',', ':')) + '\n'
    if args.check:
        if not OUT.exists() or OUT.read_text() != payload:
            print(f'{OUT} is stale; rerun without --check', file=sys.stderr)
            return 1
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(payload)
    print(f'wrote {OUT} sha256={sha(payload.encode())}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
