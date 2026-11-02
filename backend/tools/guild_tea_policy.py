#!/usr/bin/env python3
"""Build/check the immutable Tea Party policy from docs/i9/I9_GUILD_POLICY_V1.json.

The request counts and donor friend-medal amount are misc.lua rows, so they are
read from the hash-bound source archive and must match the contract. The
generated copy is what the Go content package embeds, so a policy edit is always
a reproducible build step.
"""
from __future__ import annotations
import argparse, hashlib, json, re, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/i9/I9_GUILD_POLICY_V1.json'
OUT = ROOT / 'internal/content/guildteapolicy/generated/guild_tea_policy.json'
LOCK = ROOT / 'oracles.lock.json'
MISC = 'app-assets/output/assets/src_64/data/tables/misc.lua'
MISC_SHA = '058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a'
SOURCE_KEYS = {
    'normal_need': 'guild_normal_scroll_request_num',
    'sx_need': 'guild_sx_scroll_request_num',
    'donor_friend_medal_per_scroll': 'guild_donate_scroll_reward',
}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def oracle_sha() -> str:
    lock = json.loads(LOCK.read_text())
    return next(row['sha256'] for row in lock['oracles'] if row['id'] == 'current_src64')


def misc_rows(archive: Path) -> dict[str, str]:
    data = archive.read_bytes()
    if sha(data) != oracle_sha():
        raise SystemExit(f'source archive hash drift: {sha(data)}')
    with zipfile.ZipFile(archive) as bundle:
        misc = bundle.read(MISC)
    if sha(misc) != MISC_SHA:
        raise SystemExit(f'misc.lua hash drift: {sha(misc)}')
    rows: dict[str, str] = {}
    for key, value in re.findall(r'\{\s*"([^"]+)"\s*,\s*"([^"]*)"\s*,', misc.decode('utf-8-sig'), re.S):
        if key in rows:
            raise SystemExit(f'duplicate misc key: {key}')
        rows[key] = value
    return rows


def build(archive: Path) -> dict:
    doc = json.loads(SOURCE.read_text())
    tea = doc['tea']
    rows = misc_rows(archive)
    for name, key in SOURCE_KEYS.items():
        try:
            pinned = int(rows[key])
        except (KeyError, ValueError):
            raise SystemExit(f'invalid misc value {key}={rows.get(key)!r}')
        if tea[name] != pinned:
            raise SystemExit(f'contract {name}={tea[name]!r} disagrees with misc {key}={pinned}')
    return {
        'policy_id': doc['policy_id'],
        'policy_version': doc['version'],
        'requests_per_day': tea['requests_per_day'],
        'normal_need': tea['normal_need'],
        'sx_need': tea['sx_need'],
        'donor_friend_medal_per_scroll': tea['donor_friend_medal_per_scroll'],
        'source_misc_sha256': MISC_SHA,
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
