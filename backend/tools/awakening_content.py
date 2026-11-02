"""Source-shaped awakening missions; policy is separated from recovered rows."""

from collections import Counter, defaultdict


def numbers(value):
    return [int(v) for v in value.split('|') if v and int(v) > 0]


def build_awakening(blobs, parse):
    definitions = []
    profiles = [(1, 'awaken_mission', {1: 164, 2: 164, -1: 137}),
                (2, 'bloodline_mission', {1: 81, 2: 81}),
                (3, 'pet_awaken_mission', {1: 20, 2: 20})]
    for kind, name, expected in profiles:
        rows = parse(blobs['data/tables/' + name + '.lua'].data)
        if Counter(int(row['stage']) for row in rows) != expected:
            raise ValueError('Awakening stage census drift: ' + name)
        for r in rows:
            definitions.append(dict(id=int(r['id']), type=kind, stage=int(r['stage']),
                                    before=int(r['table_id']), after=int(r['awaken_table_id']),
                                    previous=int(r['task_id']), next=int(r['next_task_id']),
                                    target=int(r['task_num']), goal=int(r.get('copy_challenge', r.get('trial_challenge', '0'))) if kind == 3 or kind == 1 and r['stage'] == '2' else 0,
                                    goal_target=int(r.get('challenge_num', '0')),
                                    item=int(r['item']), material=int(r['awaken_material']),
                                    routes=numbers(r['go_id']), delete_items=numbers(r['delete_item']),
                                    display=r['display'] == '1'))
    definitions.sort(key=lambda row: row['id'])
    by_id = {r['id']: r for r in definitions}
    if len(by_id) != 667:
        raise ValueError('Duplicate awakening mission identity')
    missing_previous = {r['id'] for r in definitions if r['previous'] and r['previous'] not in by_id}
    if missing_previous != {2105001, 2166001, 2232001, 2258001}:
        raise ValueError('Historical Blood predecessor profile drift')
    for r in definitions:
        if r['stage'] == 1:
            n = by_id.get(r['next'])
            if not n or n['type'] != r['type'] or n['stage'] != 2 or n['before'] != r['before']:
                raise ValueError('Broken awakening chain')
    blood = parse(blobs['data/tables/bloodline_incubus.lua'].data)
    waves = parse(blobs['data/tables/bloodline_incubus_monster.lua'].data)
    final_ids = {r['id'] for r in definitions if r['type'] == 2 and r['stage'] == 2}
    if {int(r['id']) for r in blood} != final_ids or len(blood) != 81:
        raise ValueError('Blood source battle identity drift')
    # Stock has two duplicated wave10 IDs in place of wave19; preserve, do not repair source.
    expected_waves = Counter(mission * 1000 + wave for mission in final_ids for wave in range(1, 21))
    for mission in (2010002, 2148002):
        del expected_waves[mission * 1000 + 19]
        expected_waves[mission * 1000 + 10] += 1
    if Counter(int(r['id']) for r in waves) != expected_waves:
        raise ValueError('Blood source twenty-wave profile drift')
    boxes = defaultdict(list)
    for r in parse(blobs['data/tables/campaign_dropbox.lua'].data):
        boxes[int(r['dropbox_id'])].append(r)
    drops = []
    for r in parse(blobs['data/tables/campaign.lua'].data):
        for kind, prefix in [(1, 'awaken'), (2, 'bloodline')]:
            missions, dropboxes = numbers(r[prefix + '_mission_id']), numbers(r[prefix + '_dropbox'])
            if len(missions) != len(dropboxes):
                raise ValueError('Awakening campaign reference arity drift')
            for mission, box in zip(missions, dropboxes):
                d = by_id.get(mission)
                if not d or d['type'] != kind or d['stage'] != 1:
                    raise ValueError('Awakening campaign mission missing')
                campaign = int(r['campaign_id'])
                if kind == 1 and campaign not in d['routes']:
                    # Source1122001 is an event-only mission with stale Campaign references.
                    if mission != 1122001:
                        raise ValueError('Unexpected dangling awakening campaign mapping')
                    continue
                if len(boxes[box]) != 1 or int(r['campaign_type']) not in (1, 2, 3):
                    raise ValueError('Invalid awakening campaign dropbox')
                drop = boxes[box][0]
                rate = int(drop['increase_rate'])
                if rate != (6666 if kind == 1 else 2650):
                    raise ValueError('Awakening source drop rate drift')
                drops.append(dict(mission=mission, campaign=campaign,
                                  type=2 if r['campaign_type'] == '3' else 1,
                                  box=box, item=int(drop['item_id']), rate=rate))
    if len({d['mission'] for d in drops if by_id[d['mission']]['type'] == 1}) != 131 or len({d['mission'] for d in drops if by_id[d['mission']]['type'] == 2}) != 74:
        raise ValueError('Awakening campaign route census drift')
    misc = {r['key']: r['value'] for r in parse(blobs['data/tables/misc.lua'].data)}
    if [misc[k] for k in ('awaken_open_level', 'bloodline_open_level', 'bloodline_open_quality')] != ['90','100','15']:
        raise ValueError('Awakening source eligibility drift')
    if misc['awake_item_wish'] != '50005037':
        raise ValueError('Wish item drift')
    return dict(definitions=definitions, drops=sorted(drops, key=lambda r: (r['mission'], r['campaign'])),
                wish_item=int(misc['awake_item_wish']),
                wish_excluded_items=numbers(misc['awake_item_wish_not']),
                wish_excluded_missions=numbers(misc['awake_partner_wish_not']),
                private_policy=dict(policy_id='I9_AWAKENING_MISSIONS_V1', version=1,
                                    first_clear_delay_days=1, blood_result_window_seconds=3600,
                                    guard_witness_only=True))
