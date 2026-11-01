#!/usr/bin/env python3
"""Build/check the Guild Campaign catalog from the hash-bound client tables.

Chapters are team_dungeon_select rows (open cost and the reward rows the client
renders); copies are the campaign_type 7 rows of team_campaign, one per mission,
each with three monster waves. Waves are seeded at full health: the client
encodes full HP as health=0 with no hp (GuildMapDetailWindow.lua:264).

Nothing here has a Go literal: the generated JSON is what the runtime embeds.
"""
from __future__ import annotations
import argparse, hashlib, json, re, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'internal/content/guildcampaigncatalog/generated/guild_campaign_catalog.json'
LOCK = ROOT / 'oracles.lock.json'
SELECT = 'app-assets/output/assets/src_64/data/tables/team_dungeon_select.lua'
SELECT_SHA = 'ace19f22d58d5d04915fc7cad3bb25a96a2d869933987c5857dcdfb065b6b8fc'
CAMPAIGN = 'app-assets/output/assets/src_64/data/tables/team_campaign.lua'
CAMPAIGN_SHA = '1015ec9d4e171365ef454bb2f38f9ff4d4d0b2195d27ba159681770395edab41'
MISC = 'app-assets/output/assets/src_64/data/tables/misc.lua'
MISC_SHA = '058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a'
GUILD_CAMPAIGN_TYPE = 7


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def oracle_sha() -> str:
    return next(row['sha256'] for row in json.loads(LOCK.read_text())['oracles'] if row['id'] == 'current_src64')


def parse_lua_table(text: bytes) -> list[dict[str, str]]:
    text = text.decode('utf-8-sig').replace('\r\n', '\n')
    keys_block = re.search(r'keys\s*=\s*\{(.*?)\}', text, re.S)
    if not keys_block:
        raise SystemExit('table has no keys block')
    keys = re.findall(r'"([^"]+)"', keys_block.group(1))
    rows_start = text.find('rows = {')
    if rows_start < 0:
        raise SystemExit('table has no rows block')
    out = []
    for body in re.findall(r'\{\s*\n((?:\s*"[^"]*",?\s*\n)+)\s*\}', text[rows_start:]):
        values = re.findall(r'"([^"]*)"', body)
        if len(values) != len(keys):
            raise SystemExit(f'table row width {len(values)} != {len(keys)}')
        out.append(dict(zip(keys, values)))
    return out


def pipe(raw: str) -> list[int]:
    return [] if not raw or raw == '0' else [int(value) for value in raw.split('|')]


def misc_rows(text: bytes) -> dict[str, str]:
    rows: dict[str, str] = {}
    for key, value in re.findall(r'\{\s*"([^"]+)"\s*,\s*"([^"]*)"\s*,', text.decode('utf-8-sig'), re.S):
        rows.setdefault(key, value)
    return rows


def column(raw: str) -> list[int]:
    return [int(value) for value in raw.split('|') if value not in ('', '0')]


def at(values: list[int], index: int) -> int:
    # The stock columns are ragged (a trailing empty cell, or one value fewer
    # than the display list); the client indexes by display position, so a
    # missing cell repeats the last present value.
    if not values:
        raise SystemExit('empty monster column')
    return values[index] if index < len(values) else values[-1]


def wave_enemies(table: dict[str, str], wave: int) -> list[dict]:
    display = column(table[f'monster_display_{wave}'])
    stars = column(table[f'monster_star_{wave}'])
    qualities = column(table[f'monster_quality_{wave}'])
    levels = column(table[f'monster_level_{wave}'])
    if not display:
        raise SystemExit(f"campaign {table['campaign_id']} wave {wave} has no monster")
    enemies = []
    for index, table_id in enumerate(display):
        if table_id <= 0:
            raise SystemExit(f"campaign {table['campaign_id']} wave {wave} blank monster")
        enemies.append({
            'table_id': table_id,
            'lev': at(levels, index),
            'star': at(stars, index),
            'color': at(qualities, index),
            'health': 0,
        })
    return enemies


def build(archive: Path) -> dict:
    data = archive.read_bytes()
    if sha(data) != oracle_sha():
        raise SystemExit(f'source archive hash drift: {sha(data)}')
    with zipfile.ZipFile(archive) as bundle:
        select_raw = bundle.read(SELECT)
        campaign_raw = bundle.read(CAMPAIGN)
        misc_raw = bundle.read(MISC)
    for raw, want, name in ((select_raw, SELECT_SHA, 'team_dungeon_select.lua'), (campaign_raw, CAMPAIGN_SHA, 'team_campaign.lua'), (misc_raw, MISC_SHA, 'misc.lua')):
        if sha(raw) != want:
            raise SystemExit(f'{name} hash drift: {sha(raw)}')
    selects = parse_lua_table(select_raw)
    campaigns = [row for row in parse_lua_table(campaign_raw) if int(row['campaign_type']) == GUILD_CAMPAIGN_TYPE]
    misc = misc_rows(misc_raw)

    copies: dict[int, list[dict]] = {}
    for row in sorted(campaigns, key=lambda r: int(r['campaign_id'])):
        chapter = int(row['chapter'])
        copies.setdefault(chapter, []).append({
            'copy_id': int(row['campaign_id']),
            'fight_id': int(row['fight_id']),
            'waves': {str(wave): wave_enemies(row, wave) for wave in (1, 2, 3)},
        })

    chapters = []
    for index, row in enumerate(sorted(selects, key=lambda r: int(r['id']))):
        chapter = int(row['id'])
        if chapter not in copies:
            raise SystemExit(f'chapter {chapter} has no team_campaign copies')
        previous = int(selects[index - 1]['id']) if index > 0 else 0
        chapters.append({
            'chapter_id': chapter,
            'previous': previous,
            'open_cost': int(row['dungeon_open']),
            'coin_reward': int(row['coin_reward']),
            'addition_reward': int(row['addition_reward']),
            'items': pipe(row['item_display']),
            'copies': copies[chapter],
        })
    if [chapter['chapter_id'] for chapter in chapters] != list(range(7, 23)):
        raise SystemExit('chapter census drift')

    return {
        'schema_version': 1,
        'campaign_type': GUILD_CAMPAIGN_TYPE,
        'chapters': chapters,
        'reward_hurt_rank': pipe(misc['reward_hurt_rank']),
        'dist_reward_time': pipe(misc['dist_reward_time']),
        'reward_param_per_mille': int(round(float(misc['reward_param']) * 1000)),
        'reward_time_limit_seconds': int(misc['reward_time_limit']),
        'first_reward_diamond': int(misc['team_frist_reward_diamond']),
        'first_reward_coin': int(misc['team_frist_reward_cost']),
        'source_select_sha256': SELECT_SHA,
        'source_campaign_sha256': CAMPAIGN_SHA,
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
