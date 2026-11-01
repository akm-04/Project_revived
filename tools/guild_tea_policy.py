#!/usr/bin/env python3
"""Build/check the immutable Tea Party policy from docs/i9/I9_GUILD_POLICY_V1.json.

The request counts are client-table values (misc.lua:3418-3428); the donor
friend-medal amount is PRIVATE_POLICY (D406). The generated copy is what the Go
content package embeds, so a policy edit is always a reproducible build step.
"""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/i9/I9_GUILD_POLICY_V1.json'
OUT = ROOT / 'internal/content/guildteapolicy/generated/guild_tea_policy.json'


def build() -> dict:
    doc = json.loads(SOURCE.read_text())
    tea = doc['tea']
    return {
        'policy_id': doc['policy_id'],
        'policy_version': doc['version'],
        'requests_per_day': tea['requests_per_day'],
        'normal_need': tea['normal_need'],
        'sx_need': tea['sx_need'],
        'donor_friend_medal_per_scroll': tea['donor_friend_medal_per_scroll'],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    payload = json.dumps(build(), sort_keys=True, separators=(',', ':')) + '\n'
    if args.check:
        if not OUT.exists() or OUT.read_text() != payload:
            print(f'{OUT} is stale; rerun without --check', file=sys.stderr)
            return 1
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(payload)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
