#!/usr/bin/env python3
"""Build source-bounded Campaign ownership metadata for Pass75.

This preserves the effective-client distinction between chapter NORMAL plot rows
and their SUPER/Elite counterparts.  The misleading campaign.lua `campaign_type`
column is retained as `node_type` because MapWindow uses it for node geometry;
wire CampaignType NORMAL/SUPER comes from chapter.lua normal/super lists and the
campaign.relate_campaign_id graph.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from gxb_backend.content.source_resolver import EffectiveSourceResolver
from tools.build_campaign_economy_meta import _flat_table, _int


def _split_ints(raw: str) -> list[int]:
    out: list[int] = []
    for token in str(raw or '').split('|'):
        value = _int(token, 0)
        if value > 0:
            out.append(value)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--apk-root', required=True, type=Path)
    ap.add_argument('--writable-root', type=Path, default=None)
    ap.add_argument('--output', type=Path, default=Path('data/pass75_campaign_ownership_meta.json'))
    args = ap.parse_args()

    resolver = EffectiveSourceResolver(args.apk_root, args.writable_root)
    campaign_src = resolver.resolve('data/tables/campaign.lua')
    chapter_src = resolver.resolve('data/tables/chapter.lua')

    ckeys, crows = _flat_table(campaign_src.path)
    cidx = {k: ckeys.index(k) for k in ckeys}
    campaigns: dict[str, dict] = {}
    for ordinal, row in enumerate(crows, 1):
        cid = _int(row[cidx['campaign_id']], 0)
        if cid <= 0:
            continue
        campaigns[str(cid)] = {
            'campaign_id': cid,
            'row_ordinal': ordinal,
            'node_type': _int(row[cidx['campaign_type']], 0),
            'chapter': _int(row[cidx['chapter']], 0),
            'open_lv': _int(row[cidx['open_lv']], 0),
            'energy_cost': _int(row[cidx['energy_cost']], 0),
            'defeat_cost': _int(row[cidx['defeat_cost']], 0),
            'partner_exp': _int(row[cidx['partner_exp']], 0),
            'is_open': _int(row[cidx['is_open']], 0),
            'star_gift': _int(row[cidx['star_gift']], 0),
            'mana_gain': _int(row[cidx['mana_gain']], 0),
            'daily_limit': _int(row[cidx['daily_limit']], 0),
            'last_campaign_id': _int(row[cidx['last_campaign_id']], 0),
            'relate_campaign_id': _int(row[cidx['relate_campaign_id']], 0),
            'next_campaign_id': _int(row[cidx['next_campaign_id']], 0),
            'is_boss': _int(row[cidx['is_boss']], 0),
        }

    hkeys, hrows = _flat_table(chapter_src.path)
    hidx = {k: hkeys.index(k) for k in hkeys}
    chapters: dict[str, dict] = {}
    normal_ids: list[int] = []
    super_ids: list[int] = []
    for ordinal, row in enumerate(hrows, 1):
        chapter_id = _int(row[hidx['id']], 0)
        if chapter_id <= 0:
            continue
        normal = _split_ints(row[hidx['normal']])
        super_rows = _split_ints(row[hidx['super']])
        chapters[str(chapter_id)] = {
            'chapter_id': chapter_id,
            'row_ordinal': ordinal,
            'normal': normal,
            'super': super_rows,
            'next_id': _int(row[hidx['next_id']], 0),
        }
        normal_ids.extend(normal)
        super_ids.extend(super_rows)

    # Audit the live MapWindow relation contract: each chapter SUPER row should
    # be the relate_campaign_id of a NORMAL plot row from the same chapter.
    relation_mismatches: list[dict] = []
    for chapter_id, chapter in chapters.items():
        expected = [
            int(campaigns[str(cid)]['relate_campaign_id'])
            for cid in chapter['normal']
            if str(cid) in campaigns and int(campaigns[str(cid)]['relate_campaign_id']) > 0
        ]
        if expected != chapter['super']:
            relation_mismatches.append({
                'chapter_id': int(chapter_id),
                'chapter_super': chapter['super'],
                'normal_relations': expected,
            })

    payload = {
        'schema_version': 1,
        '_meta': {
            'pass': '75.0',
            'evidence_class': 'SOURCE_FACT',
            'source_resolution': 'effective_merged',
            'source_precedence': 'downloaded-assets/output/src_64 over app-assets/output/assets/src_64',
            'resolved_inputs': {
                'data/tables/campaign.lua': campaign_src.layer,
                'data/tables/chapter.lua': chapter_src.layer,
            },
            'mapwindow_contract': 'chapter.normal supplies NORMAL plot IDs; SUPER resolves via campaign.relate_campaign_id; chapter.super is the relation audit set',
        },
        'campaigns': campaigns,
        'chapters': chapters,
        'normal_campaign_ids': normal_ids,
        'super_campaign_ids': super_ids,
        'audit': {
            'campaign_rows': len(campaigns),
            'chapters': len(chapters),
            'normal_ids': len(normal_ids),
            'super_ids': len(super_ids),
            'relation_mismatches': relation_mismatches,
        },
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    print(json.dumps(payload['audit'], indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
