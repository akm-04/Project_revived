"""Top Floor source tables plus the labelled C5B private ladder policy inputs."""
from decimal import Decimal

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
