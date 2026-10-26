"""I9-4 mission definitions; deferred producers stay explicit in immutable content."""

from collections import Counter


DELTA = {
    2: ('HERO_PROMOTED', 'I9-11'),
    17: ('SUMMON', ''),
    101: ('GOLDEN_HAND_USED', 'I9-11'),
    102: ('CAMPAIGN_NORMAL_WIN', ''),
    103: ('CAMPAIGN_SUPER_WIN', ''),
    104: ('COURSE_QUIZ', 'I9-10'),
    105: ('CAMPAIGN_TRIAL_WIN', ''),
    106: ('PVP_FIGHT', 'I9-4B'),
    107: ('HERO_SKILL_UPGRADED', 'I9-11'),
    108: ('EQUIPMENT_ENCHANTED', 'I9-11'),
    109: ('VENDING_JUICE_PURCHASED', ''),
    114: ('MARCH_FINISHED', 'I9-5'),
    115: ('WORKPLACE_TEAM_SENT', 'I9-5'),
    116: ('HERO_LENT', 'I9-9'),
    117: ('GUILD_ACTIVITY', 'I9-9'),
    119: ('INFINITY_BOSS_DEFEATED', 'I9-8'),
    120: ('SKY_CITY_BATTLE', 'I9-5'),
    121: ('PET_FED', 'I9-11'),
    123: ('TEA_PARTY_DONATED', 'I9-9'),
    124: ('INTIMACY_IMPROVED', 'I9-10'),
    125: ('VOYAGE_FINISHED', 'I9-10'),
    132: ('GODS_TRIAL_CLEARED', 'I9-6'),
}
HIGH_WATER = {15: 'CAMPAIGN_CLEARED', 16: 'PLAYER_LEVEL', 18: 'HERO_OWNED',
              19: 'CABINET_LEVEL', 20: 'BOOKS_COMPLETED', 21: 'BOUND_HERO_LEVEL',
              22: 'BOUND_HERO_COLOR', 126: 'DAILY_CRYSTAL_SPENT', 127: 'DAILY_CRYSTAL_SPENT'}
HIGH_WATER.update({kind: 'HERO_QUALITY_COUNT' for kind in (*range(3, 15), 23, 24)})
ENTITLEMENTS = {110: 'MONTHLY_CARD', 113: 'VIP_SWEEP_TICKETS', 129: 'WEEK_CARD',
                130: 'ENERGY_CARD', 131: 'PRIVILEGE_CARD', 111: 'MEAL_WINDOW', 118: 'MEAL_START'}


def numbers(raw):
    return [int(value) for value in raw.split('|') if value != '']


def rewards(row, suffix):
    lines = []
    for column, kind, key in (('money', 'SCALAR_CURRENCY', 'mana'),
                              ('diamond', 'SCALAR_CURRENCY', 'crystal'),
                              ('exp', 'PLAYER_EXP', ''), ('march_coin', 'SCALAR_CURRENCY', 'march_coin')):
        amount = int(row[column + suffix] or 0)
        if amount < 0:
            raise ValueError('Negative mission reward')
        if amount:
            lines.append(dict(Kind=kind, ResourceKey=key, Amount=amount))
    if any(int(row[column + suffix] or 0) for column in ('soul', 'badge')) or int(row['vip_exp'] or 0):
        raise ValueError('Unqualified mission reward owner')
    awards, amount = numbers(row['award_id' + suffix]), int(row['num' + suffix] or 0)
    if amount < 0:
        raise ValueError('Negative mission stack award')
    if len(awards) == 2 and awards[0] == 1 and amount == 0:
        if awards[1] <= 0:
            raise ValueError('Invalid mission energy award')
        lines.append(dict(Kind='TEMPORAL', ResourceKey='energy', Amount=awards[1]))
    elif len(awards) == 1 and awards[0] > 0:
        if amount > 0:
            lines.append(dict(Kind='STACK_ITEM', ItemID=awards[0], Amount=amount))
    elif awards not in ([], [0]) or amount:
        raise ValueError('Unsupported mission award vector')
    return dict(Source=dict(PolicyVersion='I9_MISSIONS_V1'), Lines=lines)


def inscription_pool(row, inscriptions):
    family = int(row['inscription'] or 0)
    if (family > 0) != (row['show_award'] == 'inscript'):
        raise ValueError('Mission inscription award drift')
    if not family:
        return []
    items, weights = numbers(inscriptions[family]['item_id']), numbers(inscriptions[family]['rand'])
    if len(items) != len(weights) or any(value <= 0 for value in items + weights):
        raise ValueError('Mission inscription pool drift')
    return [dict(item_id=item, weight=weight) for item, weight in zip(items, weights)]


def build_missions(blobs, parse):
    rows = sorted(parse(blobs['data/tables/mission.lua'].data), key=lambda row: int(row['id']))
    if Counter(int(row['new_type']) for row in rows) != {1: 35, 2: 184, 4: 250, 6: 7}:
        raise ValueError('Mission family profile drift')
    functions = {int(row['id']): row for row in parse(blobs['data/tables/function.lua'].data)}
    if functions[84]['open_control'] != '1':
        raise ValueError('Mission reward column selection drift')
    inscriptions = {int(row['id']): row for row in parse(blobs['data/tables/inscription.lua'].data)}
    definitions = []
    for row in rows:
        family, kind = int(row['new_type']), int(row['task_req'])
        parameters, gate = numbers(row['task_num']), numbers(row['req'])
        if not parameters or any(value < 0 for value in parameters):
            raise ValueError('Invalid mission condition parameters')
        if gate != [0] and gate != [9] and (len(gate) != 2 or gate[0] not in (1, 2, 3, 4, 5, 6, 7, 8) or gate[1] <= 0):
            raise ValueError('Unknown mission gate')
        target = parameters[-1] if kind in (15, 19) else parameters[0]
        deferred = ''
        if kind in DELTA:
            strategy, (fact, deferred) = 'COMMITTED_DELTA', DELTA[kind]
        elif kind in HIGH_WATER:
            strategy, fact = 'HIGH_WATER', HIGH_WATER[kind]
            if kind in (126, 127):
                deferred = 'I9-4B'
        elif kind in ENTITLEMENTS:
            strategy, fact = 'TEMPORAL_ENTITLEMENT', ENTITLEMENTS[kind]
        else:
            raise ValueError('Unknown mission condition kind: %d' % kind)
        if kind in (18, 111, 118):
            target = 1
        if target <= 0 or (kind in (15, 19, 111) and len(parameters) != 2) or (kind not in (15, 19, 111) and len(parameters) != 1):
            raise ValueError('Mission condition arity/target drift')
        if kind in (110, 129, 130, 131):
            deferred = 'I10_COMMERCE_ACTIVE_ENTITLEMENTS'
        gate_deferred = 'I10_COMMERCE_ACTIVE_ENTITLEMENTS' if gate[0] in (4, 6, 7, 8) else ''
        unavailable = 'UNKNOWN_SOURCE_CAMPAIGN_200114' if gate == [2, 200114] else ''
        if int(row['march_coin_new'] or 0) > 0 and row['detail_type'] != '6':
            raise ValueError('Unqualified non-growth March Coin reward')
        previous, following = int(row['task_id']), int(row['next_task_id'])
        definitions.append(dict(program_id='mission:%d' % family, stock_family=family, objective_id=int(row['id']),
                                definition_revision='I9_MISSIONS_V1', strategy=strategy, accepted_fact_kind=fact, target=target,
                                generation_kind='DAY' if family == 1 else 'HERO' if family == 6 else 'LIFETIME',
                                prerequisite_policy=dict(gate=gate, previous=previous, deferred_until=gate_deferred, unavailable_reason=unavailable),
                                reward_plan=rewards(row, '_new'), huoyue=int(row['medal'] or 0),
                                presentation=dict(condition=kind, parameters=parameters, next=following, detail_type=int(row['detail_type']),
                                                  deferred_until=deferred, base_reward=rewards(row, ''),
                                                  battlepass_score=int(row['battlepass_score'] or 0),
                                                  vip_sweep_reward=kind == 113, vip_sweep_item_id=int(row['award_id_new']) if kind == 113 else 0,
                                                  inscription_pool=inscription_pool(row, inscriptions))))
    by_id = {row['objective_id']: row for row in definitions}
    if len(by_id) != 476:
        raise ValueError('Duplicate mission id')
    for row in definitions:
        for link in (row['prerequisite_policy']['previous'], row['presentation']['next']):
            if link and (link not in by_id or by_id[link]['stock_family'] != row['stock_family']):
                raise ValueError('Missing/cross-family mission chain target')
        visited, node = set(), row
        while node['prerequisite_policy']['previous']:
            if node['objective_id'] in visited:
                raise ValueError('Mission chain cycle')
            visited.add(node['objective_id'])
            node = by_id[node['prerequisite_policy']['previous']]
    vip = [dict(level=int(row['id']), sweep_card=int(row['sweep_card']))
           for row in parse(blobs['data/tables/vip.lua'].data)]
    if sorted(row['level'] for row in vip) != list(range(16)):
        raise ValueError('Mission VIP profile drift')
    by_id[10015]['presentation']['vip_sweep_by_level'] = [row['sweep_card'] for row in sorted(vip, key=lambda row: row['level'])]
    return dict(schema_version=1, status='I9_4_MISSION_CATALOG', definitions=definitions, activity_chests=build_activity(blobs, parse))


def build_activity(blobs, parse):
    gifts = {int(row['id']): row for row in parse(blobs['data/tables/gift.lua'].data)}
    rules, needed = [], set()
    for period, path, expected in [('DAY', 'mission_reward_daily.lua', [30, 60, 90, 120, 150]),
                                    ('WEEK', 'mission_reward_week.lua', [500, 1000])]:
        rows = sorted(parse(blobs['data/tables/' + path].data), key=lambda row: int(row['id']))
        if [int(row['id']) for row in rows] != list(range(1, len(expected) + 1)) or [int(row['medal']) for row in rows] != expected:
            raise ValueError('Activity chest source profile drift')
        for row in rows:
            first, second = (int(row['gift_exp']), int(row['gift_march_coin'])) if period == 'DAY' else (int(row['gift']), int(row['gift']))
            needed.update((first, second))
            rules.append(dict(period=period, index=int(row['id']), medal=int(row['medal']), gift_exp=first, gift_march=second))
    definitions = []
    allowed = {'id', 'name', 'desc', 'items', 'item_nums', 'exp', 'march_coin', 'badge', 'vip', 'ex_badge'}
    for gift_id in sorted(needed):
        row = gifts[gift_id]
        if any(value not in ('', '0') for key, value in row.items() if key not in allowed):
            raise ValueError('Unqualified activity gift field')
        lines = []
        items, counts = numbers(row['items']), numbers(row['item_nums'])
        if len(items) != len(counts) or any(value <= 0 for value in items + counts):
            raise ValueError('Activity gift item vector drift')
        lines.extend(dict(Kind='STACK_ITEM', ItemID=item, Amount=count) for item, count in zip(items, counts))
        for column, kind, resource in [('exp', 'PLAYER_EXP', None), ('march_coin', 'SCALAR_CURRENCY', 'march_coin'), ('badge', 'SCALAR_CURRENCY', 'guild_coin')]:
            value = int(row[column] or 0)
            if value < 0:
                raise ValueError('Negative activity reward')
            if value:
                line = dict(Kind=kind, Amount=value)
                if resource:
                    line['ResourceKey'] = resource
                lines.append(line)
        threshold, bonus = int(row['vip'] or 0), int(row['ex_badge'] or 0)
        if threshold < 0 or threshold > 15 or bonus < 0 or bonus and threshold == 0:
            raise ValueError('Activity gift VIP profile drift')
        definitions.append(dict(id=gift_id, plan=dict(Source=dict(PolicyVersion='I9_ACTIVITY_CHESTS_V1'), Lines=lines), vip_threshold=threshold, vip_bonus=bonus))
    if len(definitions) != 12:
        raise ValueError('Activity fixed gift count drift')
    return dict(rules=rules, gifts=definitions)
