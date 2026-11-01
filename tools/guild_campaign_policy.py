#!/usr/bin/env python3
"""Build/check the immutable Guild Campaign policy (I9_GUILD_CAMPAIGN_V1).

The timing rows are client misc.lua values, so they are read from the
hash-bound source archive and must match the contract. The notice mail exists
only in docs/i9/I9_GUILD_POLICY_V1.json (C13): no code carries a title or body.
"""
from __future__ import annotations
import argparse, hashlib, json, re, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/i9/I9_GUILD_POLICY_V1.json'
OUT = ROOT / 'internal/content/guildcampaignpolicy/generated/guild_campaign_policy.json'
LOCK = ROOT / 'oracles.lock.json'
MISC = 'app-assets/output/assets/src_64/data/tables/misc.lua'
MISC_SHA = '058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a'


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


def pipe_ints(raw: str) -> list[int]:
    return [int(value) for value in raw.split('|')]


def build(archive: Path) -> dict:
    doc = json.loads(SOURCE.read_text())
    campaign = doc['guild_campaign']
    rows = misc_rows(archive)
    rest = pipe_ints(rows['team_time_limit'])
    if rest != campaign['rest_seconds_of_day']:
        raise SystemExit(f"rest window {campaign['rest_seconds_of_day']} disagrees with misc team_time_limit {rest}")
    if int(rows['team_timeout1']) != campaign['prepare_seconds']:
        raise SystemExit('prepare_seconds disagrees with misc team_timeout1')
    if int(rows['team_timeout2']) != campaign['battle_seconds']:
        raise SystemExit('battle_seconds disagrees with misc team_timeout2')
    notice = campaign['notice_mail']
    for key in ('open_title', 'open_body', 'reset_title', 'reset_body'):
        if not isinstance(notice[key], str) or not notice[key].strip():
            raise SystemExit(f'notice mail {key} missing')
    if campaign['attempts_per_chapter_day'] <= 0 or campaign['applications_per_day'] <= 0:
        raise SystemExit('attempt and application counts must be positive')
    if campaign['boss_damage_rank_multiplier'] != 2:
        raise SystemExit('boss damage rank multiplier must be 2')
    if campaign['guild_log_retention_days'] <= 0:
        raise SystemExit('guild log retention must be positive')
    return {
        'policy_id': doc['policy_id'],
        'policy_version': doc['version'],
        'attempts_per_chapter_day': campaign['attempts_per_chapter_day'],
        'prepare_seconds': campaign['prepare_seconds'],
        'battle_seconds': campaign['battle_seconds'],
        'rest_seconds_of_day': campaign['rest_seconds_of_day'],
        'applications_per_day': campaign['applications_per_day'],
        'boss_damage_rank_multiplier': campaign['boss_damage_rank_multiplier'],
        'notice_mail': {
            'enabled': notice['enabled'],
            'open_title': notice['open_title'],
            'open_body': notice['open_body'],
            'reset_title': notice['reset_title'],
            'reset_body': notice['reset_body'],
        },
        'guild_log_retention_days': campaign['guild_log_retention_days'],
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
