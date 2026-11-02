"""Source Champion catalog plus explicitly versioned preservation policy."""
import hashlib
import json
from pathlib import Path

POLICY = Path(__file__).resolve().parents[1] / 'docs/i9/I9_MARCH_PRIVATE_POLICY_V1.json'


def build_march(blobs, parse, parse_indexed, field, resources):
    table = lambda n: parse(blobs['data/tables/' + n + '.lua'].data)
    raw_policy = POLICY.read_bytes()
    policy = json.loads(raw_policy)
    if policy['contract_id'] != 'I9_MARCH_PRIVATE_POLICY_V1' or policy['classification'] != 'PRIVATE_POLICY':
        raise ValueError('March policy identity')
    summons = {int(r['id']): r for r in table('summon')}
    if (summons[5]['dropbox'], summons[5]['super_dropbox'], summons[12]['dropbox'], summons[12]['super_dropbox'], summons[12]['summon_cost'], summons[12]['summon_num']) != ('200012', '200013', '200015', '200016', '50', '3'):
        raise ValueError('March source summon rows drift')
    wanted = {200012, 200013, 200015, 200016, 130001, 130002, 130003, 130004}
    pools = {str(k): [] for k in sorted(wanted)}
    for row in table('dropbox'):
        key = row['dropbox_id']
        if key in pools:
            pools[key].append([int(row['item_id']), int(row['item_num']), int(row['drop_rate'])])
    if [len(pools[str(k)]) for k in sorted(wanted)] != [1, 1, 1, 1, 226, 64, 165, 40] or any(sum(x[2] for x in rows) != 10000 for rows in pools.values()):
        raise ValueError('March pool profile drift')
    heroes = set()
    for n in ['partner', 'super_partner']:
        keys, rows = parse_indexed(blobs['data/tables/' + n + '.lua'].data)
        heroes.update(int(field(keys, vals, 'id', row_id=key)) for key, vals in rows.items())
    items = {r['item_id'] for r in resources if r['class'] == 'STACK_ITEM' and r['settlement_activation'] == 'ENABLED_R4'}
    for rows in pools.values():
        for item, num, weight in rows:
            if item not in heroes | items or num <= 0 or weight < 0:
                raise ValueError('March unresolved reward %d' % item)
    advances = []
    for r in table('march_advance'):
        advances.append(dict(level=int(r['college_level']), rates=[int(x) for x in r['rate_fight'].split('|')], counts=[[int(x) for x in group.split(',')] for group in r['clean_numb'].split('|')]))
    roads = table('march_road')
    recommend = table('march_recommend_hero')[0]
    groups = [[int(x) for x in recommend[k].split('|')] for k in sorted(recommend) if k.startswith('recommend_hero')]
    if len(roads) != 15 or len(advances) != 36 or len(groups) != 6 or any(h not in heroes for group in groups for h in group):
        raise ValueError('March road/advance/recommendation profile')
    misc = {r['key']: r['value'] for r in table('misc') if r['key'].startswith('expedition_')}
    return dict(schema_version=1, contract_id='I9_MARCH_V1', policy_id=policy['contract_id'], policy_sha256=hashlib.sha256(raw_policy).hexdigest(),
                source_sha256={name: hashlib.sha256(blobs['data/tables/' + name + '.lua'].data).hexdigest() for name in ['march_road','march_advance','march_recommend_hero','summon','dropbox','misc']},
                advances=advances, recommendations=groups, pools=pools, misc=misc, milestones=[600,780,960,1140], policy=policy['parameters'])
