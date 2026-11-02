"""Vending (gacha) source tables (I9_GACHA_V1) plus the labelled V1 private policy (I9_GACHA_PRIVATE_POLICY_V1)."""
import hashlib
import json
from pathlib import Path

POLICY_PATH = Path(__file__).resolve().parents[1] / 'docs/i9/I9_GACHA_PRIVATE_POLICY_V1.json'
# summon.lua rows served by MID50 (type = row id) and MID70 (row 33); the rest belong to events (D138).
BUTTON_ROWS = {1: 'small', 2: 'medium_paid', 3: 'medium_free', 4: 'sx', 6: 'ticket', 7: 'ticket', 10: 'ticket', 11: 'ticket', 33: 'magic'}
COUNTER_ROWS = {1: 'small', 2: 'medium_paid', 3: 'medium_free'}


def _ids(raw):
    return [int(x) for x in raw.split('|') if x not in ('', '0')]


def _numbers(raw):
    return [int(x) for x in raw.split('|') if x != '']


def build_summon(blobs, parse, parse_indexed, field):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    raw_policy = POLICY_PATH.read_bytes()
    policy = json.loads(raw_policy)
    if policy['contract_id'] != 'I9_GACHA_PRIVATE_POLICY_V1' or policy['classification'] != 'PRIVATE_POLICY':
        raise ValueError('Gacha private policy identity drift')
    misc = {r['key']: r['value'] for r in table('misc')}
    free = dict(mana_period=int(misc['summon_mana_free_period']), mana_num=int(misc['summon_mana_free_num']),
                crystal_period=int(misc['summon_crystal_free_period']), sx_guarantee=int(misc['sx_summon_guarantee_times']))
    vows = dict(essence_item_id=int(misc['taitan_stone_item_id']), super_scroll_cost=int(misc['taitan_exchange_super_hero']))
    if free != dict(mana_period=600, mana_num=5, crystal_period=165600, sx_guarantee=25) or vows != dict(essence_item_id=50001666, super_scroll_cost=100):
        raise ValueError('Vending misc profile drift')

    heroes = {}
    # super_partner rows are the Vows heroes (Magic targets, MID306 scrolls); they carry no is_sx.
    for name in ('partner', 'super_partner'):
        keys, rows = parse_indexed(blobs['data/tables/' + name + '.lua'].data)
        for row_id, vals in rows.items():
            table_id = int(field(keys, vals, 'id', row_id=row_id))
            if table_id >= 11000000:
                continue
            heroes[table_id] = dict(table_id=table_id, initial_star=int(field(keys, vals, 'ini_star', row_id=row_id) or 1),
                                    stone_item_id=int(field(keys, vals, 'stone_id', row_id=row_id) or 0),
                                    sx=name == 'partner' and field(keys, vals, 'is_sx', row_id=row_id) == '1')
            if name == 'super_partner':
                vows.setdefault('table_ids', []).append(table_id)
    vows['table_ids'].sort()

    summons = {int(r['id']): r for r in table('summon')}
    buttons, counters, wanted = [], {}, set()
    for row_id, family in sorted(BUTTON_ROWS.items()):
        r = summons[row_id]
        costs, nums = _numbers(r['summon_cost']) or [0], _numbers(r['summon_num'])
        if len(costs) != len(nums):
            raise ValueError('summon.lua cost/num drift: %d' % row_id)
        cost_type, item = int(r['cost_type'] or 0), int(r['summon_item'] or 0)
        for index, (cost, pulls) in enumerate(zip(costs, nums), 1):
            button = dict(type=row_id, index=index, family=family, pulls=pulls, free=cost == 0, mana=0, crystal=0, item_id=0, item_num=0,
                          reward_item_id=int(r['summon_reward'] or 0))
            if cost_type == 1 and cost:
                button['mana'] = cost
            if cost_type == 2 and cost:
                button['crystal'] = cost
            if cost_type == 8:
                button.update(item_id=item, item_num=cost)
            if cost_type == 9:
                button.update(item_id=item, item_num=1, crystal=cost)
            buttons.append(button)
        wanted.update(_ids(r['dropbox']) + _ids(r['super_dropbox']) + _ids(r['special_dropbox']))
        if row_id in COUNTER_ROWS:
            counters[COUNTER_ROWS[row_id]] = dict(milestones=_ids(r['summon_special']), pools=_ids(r['special_dropbox']))
    for family in ('small', 'medium'):
        wanted.update((policy['classic'][family]['base_pool'], policy['classic'][family]['super_pool']))

    boxes = {}
    for r in table('dropbox'):
        boxes.setdefault(int(r['dropbox_id']), []).append((int(r['id']), int(r['item_id']), int(r['item_num']), int(r['drop_rate'])))
    pools, missing = [], sorted(b for b in wanted if b not in boxes)
    for pool_id in sorted(b for b in wanted if b in boxes):
        source = sorted(boxes[pool_id])
        hero_rows = [row for row in source if row[1] in heroes]
        if hero_rows and len(hero_rows) != len(source):
            raise ValueError('Vending pool mixes heroes and items: %d' % pool_id)
        if sum(row[3] for row in source) <= 0:
            raise ValueError('Vending pool has no weight: %d' % pool_id)
        pools.append(dict(id=pool_id, kind='hero' if hero_rows else 'item', rows=[[item, num, rate] for _, item, num, rate in source]))
    if missing != [200001]:
        raise ValueError('Vending missing pool drift: %r' % missing)

    cohorts = policy['cohorts']
    referenced = {row[0] for p in pools if p['kind'] == 'hero' for row in p['rows']}
    referenced.update(cohorts['medium_featured'] + cohorts['medium_extension'] + cohorts['sx'] + [policy['tutorial']['birth_companion']] + list(policy['display'].values()))
    duplicates = policy['classic']['duplicate_fragments_by_initial_star']
    for hero_id in referenced:
        hero = heroes.get(hero_id)
        if hero is None or hero['stone_item_id'] <= 0 or str(hero['initial_star']) not in duplicates:
            raise ValueError('Vending hero lacks a summonable template: %d' % hero_id)
    if any(not heroes[h]['sx'] for h in cohorts['sx']):
        raise ValueError('SX cohort contains a non-SX hero')

    caskets = [dict(id=int(r['id']), partner_id=int(r['partner_id']), type=int(r['type']), roll_nums=_numbers(r['roll_num']),
                    num_rates=_numbers(r['num_rate']), weight=int(r['weight'])) for r in sorted(table('soul_casket'), key=lambda r: int(r['id']))]
    magic_list = _ids(table('magic_summon_list')[0]['get_hero_id'])
    magic_rates = [[int(r['num']), int(r['rate'])] for r in sorted(table('magic_drop_rate'), key=lambda r: int(r['id']))]
    sx_pools, magic_pool = _ids(summons[4]['dropbox']), _ids(summons[33]['dropbox'])
    if magic_rates != [[5, 87], [10, 10], [25, 2], [50, 1]] or len(buttons) != 14 or len(pools) != 18:
        raise ValueError('Vending button/pool/magic profile drift: %d buttons %d pools' % (len(buttons), len(pools)))
    if sx_pools != [200007, 200008, 200009, 200010, 200011] or magic_pool != [700008]:
        raise ValueError('SX/Magic pool drift: %r %r' % (sx_pools, magic_pool))
    if any(b['reward_item_id'] <= 0 for b in buttons):
        raise ValueError('Vending button lacks a summon_reward juice')
    if any(heroes.get(h, {}).get('stone_item_id', 0) <= 0 for h in magic_list):
        raise ValueError('Magic target lacks a fragment item')
    return dict(schema_version=1, contract_id='I9_GACHA_V1', policy_id=policy['contract_id'],
                policy_sha256=hashlib.sha256(raw_policy).hexdigest(), free=free, reward=dict(item_id=int(summons[1]['summon_reward']), item_num=policy['tutorial']['first_small_slot_reward_num']),
                buttons=buttons, counters=counters, pools=pools, heroes=[heroes[h] for h in sorted(heroes)],
                policy={k: policy[k] for k in ('classic', 'tutorial', 'display', 'rotation', 'sx', 'magic', 'cohorts', 'juice')},
                soul_caskets=caskets, magic_heroes=magic_list, magic_rates=magic_rates, vows=vows,
                sx_pools=sx_pools, magic_pool=magic_pool[0])
