"""Top Floor source tables plus the labelled C5B private ladder policy inputs."""
from decimal import Decimal
from one_on_one_content import _translations

TEAM_COLUMNS = ('robot1', 'robot2', 'robot3', 'robot4', 'robot5')


def _ints(raw):
    return [int(x) for x in raw.split('|')]


def _ten_thousandths(raw):
    value = Decimal(raw) * 10000
    if value != value.to_integral_value() or value < 0:
        raise ValueError('arena reward rate precision drift: ' + raw)
    return int(value)


def build_top_floor(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    misc = {r['key']: r['value'] for r in table('misc')}
    functions = {r['id']: r for r in table('function')}
    if functions['84']['open_control'] != '1' or functions['4']['level'] != '1|10':
        raise ValueError('Top Floor function gate drift')
    rewards = []
    for r in sorted(table('arena_reward'), key=lambda r: int(r['id'])):
        items = [[i, n] for i, n in zip(_ints(r['daily_item']), _ints(r['daily_item_num'])) if i > 0 and n > 0]
        rewards.append(dict(id=int(r['id']), range=int(r['range']), daily_crystal=int(r['daily_diamond']), daily_mana=int(r['daily_mana']),
                            daily_arena_coin=int(r['daily_arena_coin']), items=items, frame_id=int(r['frame_id']),
                            best_rank_rate=_ten_thousandths(r['rank_reward_diamond_new'])))
    if [r['id'] for r in rewards] != list(range(1, 31)) or rewards[0]['frame_id'] != 120001004 or rewards[-1]['range'] != 100000:
        raise ValueError('arena_reward profile drift')
    vip = [dict(level=int(r['id']), purchases=int(r['num_arena']), reset=int(r['arena_reset'])) for r in sorted(table('vip'), key=lambda r: int(r['id']))]
    costs = [int(r['buy_arena_cost']) for r in sorted(table('refresh_cost'), key=lambda r: int(r['id']))]
    heroes = {r['id']: r for r in table('robot_hero')}
    robot_heroes = [dict(id=int(r['id']), level=int(r['lev']), partner_id=int(r['partner_id']), quality=int(r['quality']), star=int(r['star']), equip_flags=_ints(r['equips']))
                    for r in sorted(heroes.values(), key=lambda r: int(r['id']))]
    robots = []
    dropped = 0
    for index, r in enumerate(sorted(table('robot'), key=lambda r: int(r['team_id']))):
        if int(r['team_id']) != index + 1:
            raise ValueError('robot team ids are not contiguous')
        members = [r[c] for c in TEAM_COLUMNS if r[c]]
        kept = [int(m) for m in members if m in heroes]
        dropped += len(members) - len(kept)
        if not kept:
            raise ValueError('robot team without source heroes')
        robots.append(dict(level=int(r['team_level']), heroes=kept))
    if len(robots) != 10325 or dropped != 72:
        raise ValueError('robot ladder profile drift')
    names = {}
    for r in sorted(table('random_name'), key=lambda r: int(r['id'])):
        names.setdefault(r['name_type'], []).append(r['text'])
    return dict(schema_version=1, contract_id='C5B_TOP_FLOOR_MODE_V1', policy_id='C5B_TOP_FLOOR_PRIVATE_POLICY_V1',
                function_id=4, required_level=10, free_tickets=5, buy_restore=int(misc['arena_buy_num']), cooldown_seconds=int(misc['arena_cooldown']),
                reset_cost=int(misc['arena_refresh_cost']), match_hundredths=[int(Decimal(misc['arena_match_param_' + k]) * 100) for k in '123'],
                cutoff_seconds=int(misc['arena_gift_time1']), freeze_end_seconds=int(misc['arena_gift_time2']), records_max=int(misc['arena_defense_list_max']),
                mail_title=misc['arena_mail_title'], mail_text=misc['arena_mail_text'], mail_sender=misc['arena_mail_sender'],
                robot_avatar_id=110001001, robot_frame_id=120001001, rewards=rewards, vip=vip, buy_costs=costs,
                robots=robots, robot_heroes=robot_heroes, first_names=names['0'], last_names=names['1'])


def build_task_modes(blobs, parse, parse_indexed, indexed_field):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    rules = []
    for row in sorted(table('arena_mode'), key=lambda row: int(row['id'])):
        raw_buffs = row['buffs']
        groups = []
        if raw_buffs != '0':
            groups = [_ints(raw_buffs)] if int(row['id']) != 6 else [
                [int(value) for value in group.split(',')] for group in raw_buffs.split('|')]
        rules.append(dict(id=int(row['id']), title=row['title'], description=row['desc'], rule_text=row['rule_text'],
                          hero_slots=int(row['partner_num']), pet_allowed=row['can_pet_join'] == '1',
                          leader_allowed=row['can_leader_join'] == '1', reset_defense=row['team_reset'] == '1',
                          banned_tables=[] if row['banned_partner'] == '0' else _ints(row['banned_partner']), buff_groups=groups))
    schedule = [dict(date=row['id'], mode=int(row['mode']), submode=int(row['submode']))
                for row in sorted(table('arena_mode_schedule'), key=lambda row: row['id'])]
    rewards = []
    for row in sorted(table('arena_mode_reward'), key=lambda row: int(row['id'])):
        item_ids, quantities = _ints(row['daily_item']), _ints(row['daily_item_num'])
        if len(item_ids) != len(quantities) or any(
                item < 0 or quantity < 0 or (item == 0) != (quantity == 0)
                for item, quantity in zip(item_ids, quantities)):
            raise ValueError('arena_mode_reward item vector drift')
        rewards.append(dict(id=int(row['id']), range=int(row['range']), daily_crystal=int(row['daily_diamond']),
                            daily_mana=int(row['daily_mana']), daily_arena_coin=int(row['daily_arena_coin']),
                            items=[[item, quantity] for item, quantity in zip(item_ids, quantities) if item > 0],
                            frame_id=0, best_rank_rate=0))
    if [rule['id'] for rule in rules] != list(range(1, 7)) or len(schedule) != 91 or len(rewards) != 17:
        raise ValueError('arena task mode source profile drift')
    mail = _translations(blobs['data/tables/translation.lua'].data, ('ARENA_MODE_MAIL_TITLE', 'ARENA_MODE_MAIL_TEXT', 'ARENA_MODE_MAIL_SENDER'))
    camps = {}
    for name in ('partner', 'super_partner'):
        keys, rows = parse_indexed(blobs['data/tables/' + name + '.lua'].data)
        for identity, values in sorted(rows.items()):
            camp = int(indexed_field(keys, values, 'from', row_id=identity))
            if camp not in (1, 2, 3, 4) or str(identity) in camps:
                raise ValueError('arena task mode Hero camp drift')
            camps[str(identity)] = camp
    misc = {row['key']: row['value'] for row in table('misc')}
    return dict(schema_version=1, contract_id='I9_TOP_FLOOR_TASK_MODE_V1', policy_id='I9_TOP_FLOOR_TASK_POLICY_V1',
                rules=rules, schedule=schedule, rewards=rewards, hero_camps=camps,
                mail_title=mail['ARENA_MODE_MAIL_TITLE'], mail_text=mail['ARENA_MODE_MAIL_TEXT'], mail_sender=mail['ARENA_MODE_MAIL_SENDER'],
                entry_rank=int(misc['arena_mode_enter_rank_req']), entry_challenges=int(misc['arena_mode_enter_battle_req']),
                server_level=int(misc['arena_mode_open_lv_req']), attacking_leader_buff=int(misc['arena_mode_attack_leader_buff']),
                defending_leader_buff=int(misc['arena_mode_defence_leader_buff']))
