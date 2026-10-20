"""1 on 1 (Peak, revised "legend") source tables plus the labelled C5C private policy inputs."""
import re
from decimal import Decimal

MAIL_KEYS = ('LEGEND_MAIL_TITLE', 'LEGEND_MAIL_TEXT', 'LEGEND_MAIL_SENDER', 'LEGEND_KUAFU_MAIL_TITLE', 'LEGEND_KUAFU_MAIL_TEXT', 'LEGEND_KUAFU_MAIL_SENDER')


def _ints(raw):
    return [int(x) for x in raw.split('|')]


def _hundredths(raw):
    value = Decimal(raw) * 100
    if value != value.to_integral_value():
        raise ValueError('1 on 1 match parameter precision drift: ' + raw)
    return int(value)


def _translations(data, keys):
    text = data.decode('utf-8-sig')
    found = {}
    for key in keys:
        match = re.search(r'\{\s*"' + key + r'",\s*"((?:[^"\\]|\\.)*)"\s*\}', text)
        if match is None:
            raise ValueError('translation missing ' + key)
        found[key] = match.group(1).replace('\\n', '\n')
    return found


def build_one_on_one(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    misc = {r['key']: r['value'] for r in table('misc')}
    functions = {r['id']: r for r in table('function')}
    if functions['16']['level'] != '6|55|15' or functions['16']['open_control'] != '1':
        raise ValueError('1 on 1 function gate drift')
    messages = {r['id']: r['content'] for r in table('message')}
    if not messages['30002'].startswith('1 on 1 opens from 8:00 to 22:00'):
        raise ValueError('1 on 1 opening message drift')
    levels = []
    for r in sorted(table('legend_arena_rank'), key=lambda r: int(r['id'])):
        levels.append(dict(level=int(r['id']), rank_type=int(r['rank_type']), bound=int(r['rank_bound']), teams=int(r['team_num']), hidden=int(r['team_hide']),
                           cooldown_seconds=int(r['cool_time']), promotion_entrants=int(r['challenge_num']), promotion_pool=int(r['match_num'])))
    shape = [(x['rank_type'], x['bound'], x['teams'], x['hidden']) for x in levels]
    if shape != [(1, 500, 7, 3), (1, 5000, 5, 2), (2, 4850, 3, 0), (2, 4650, 3, 0), (2, 0, 3, 0)]:
        raise ValueError('legend_arena_rank profile drift')
    rewards = []
    for r in sorted(table('legend_reward'), key=lambda r: int(r['id'])):
        items = [[i, n] for i, n in zip(_ints(r['daily_item']), _ints(r['daily_item_num'])) if i > 0 and n > 0]
        rewards.append(dict(id=int(r['id']), range=int(r['range']), crystal=int(r['daily_diamond']), mana=int(r['daily_mana']),
                            top_coin=int(r['daily_top_coin']), items=items, frame_id=int(r['frame_id'])))
    if [r['id'] for r in rewards] != list(range(1, 31)) or rewards[0]['frame_id'] != 120001005 or rewards[-1]['range'] != 100000:
        raise ValueError('legend_reward profile drift')
    vip = [dict(level=int(r['id']), purchases=int(r['num_top']), reset=int(r['top_reset'])) for r in sorted(table('vip'), key=lambda r: int(r['id']))]
    costs = [int(r['buy_top_cost']) for r in sorted(table('refresh_cost'), key=lambda r: int(r['id']))]
    weekday_time = lambda key: dict(zip(('weekday', 'seconds'), _ints(misc[key])))
    titles = []
    for r in sorted(table('title_system'), key=lambda r: int(r['id'])):
        if r['type'] == '2' and 100002 <= int(r['id']) <= 100005:
            bounds = _ints(r['condition'])
            titles.append(dict(title_id=int(r['id']), first=bounds[0], last=bounds[-1], seconds=int(r['time'])))
    if [(x['first'], x['last'], x['seconds']) for x in titles] != [(1, 1, 604800), (2, 100, 604800), (501, 501, 604800), (502, 600, 604800)]:
        raise ValueError('1 on 1 title profile drift')
    translations = _translations(blobs['data/tables/translation.lua'].data, MAIL_KEYS + ('PEAK_ARENA_RULE_TEXT_4',))
    if 'issued at 22:00(GMT+8) on Wednesdays and Sundays' not in translations.pop('PEAK_ARENA_RULE_TEXT_4'):
        raise ValueError('1 on 1 settlement schedule text drift')
    elo = [int(misc['legend_elo' + k]) for k in '1234']
    if elo != [400, 1, 10, 20] or misc['legend_truceday'] != '7':
        raise ValueError('legend score profile drift')
    return dict(schema_version=1, contract_id='C5C_ONE_ON_ONE_MODE_V1', policy_id='C5C_ONE_ON_ONE_PRIVATE_POLICY_V1',
                function_id=16, required_level=55, required_heroes=_ints(functions['16']['level'])[2], free_tries=int(misc['legend_free_num']),
                open_seconds=int(misc['legend_start']), close_seconds=int(misc['legend_stop']), settlement_weekdays=[3, 7], settlement_seconds=int(misc['legend_stop']),
                promotion_start=weekday_time('legend_promo_start_time'), promotion_end=weekday_time('legend_promo_end_time'),
                promotion_cooldown_seconds=int(misc['legend_promote_cool_time']), promotion_wins=int(misc['legend_promo_win']), promotion_chances=int(misc['legend_promo_chance']),
                elo_divisor=elo[0], elo_win=elo[1], elo_base=elo[2], elo_k=elo[3], points_floor=int(misc['legend_lower_limit']),
                entry_points=int(misc['legend_point_convert_min_point']), split_bound=int(misc['legend_rank_split_bound']),
                match_hundredths=[_hundredths(misc['legend_match_param_' + k]) for k in '1234'],
                match_new_rank=int(misc['legend_match_new_rank']), match_new_hundredths=[_hundredths(misc['legend_match_new_param_' + k]) for k in '1234'],
                candidates=int(misc['legend_match_num']), records_max=int(misc['legend_record_num']), reset_cost=int(misc['top_refresh_cost']),
                titles=titles, mail=translations, opening_message=messages['30002'],
                levels=levels, rewards=rewards, vip=vip, buy_costs=costs)
