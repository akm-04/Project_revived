"""Arena (Region Arena, 768-779) source tables plus the labelled C5D private policy inputs."""
import re
from datetime import date
from decimal import Decimal

MAIL_KEYS = ('REGION_ARENA_MAIL_TITLE', 'REGION_ARENA_MAIL_TEXT', 'REGION_ARENA_MAIL_SENDER')
RULE_PHRASES = ('each season has 45 days', 'Each victory earns 1 Gem, before LV20,you may earn 2 gems for each victory after having a 4 times win-streak',
                'Extra Arena coins will be issued by first 10 challenges daily', 'Practice mode counts no rewards or punishment',
                'Successfully defend 3 challenges consecutively earns you 1 Gem. Fail to defend 3 challenges consecutively loses 3 Gems of yours')


def _ints(raw):
    return [int(x) for x in raw.split('|')]


def _hundredths(raw):
    value = Decimal(raw) * 100
    if value != value.to_integral_value():
        raise ValueError('Arena parameter precision drift: ' + raw)
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


def _day(raw):
    return date(int(raw[:4]), int(raw[4:6]), int(raw[6:8]))


def build_arena(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    misc = {r['key']: r['value'] for r in table('misc')}
    functions = {r['id']: r for r in table('function')}
    if functions['37']['level'] != '6|60|5' or functions['37']['open_control'] != '1':
        raise ValueError('Arena function gate drift')
    levels = [dict(level=int(r['level']), star=int(r['star']), level_star=int(r['level_star']), name=r['name'])
              for r in sorted(table('region_arena_level'), key=lambda r: int(r['id']))]
    if [x['level'] for x in levels] != list(range(1, 27)) or levels[0]['star'] != 2 or levels[-1]['star'] != 95:
        raise ValueError('region_arena_level profile drift')
    rewards = []
    for r in sorted(table('region_arena_reward'), key=lambda r: int(r['id'])):
        items = [[i, n] for i, n in zip(_ints(r['daily_item']), _ints(r['daily_item_num'])) if i > 0 and n > 0]
        rewards.append(dict(level=int(r['level']), region_coin=int(r['region_arena_coin']), mana=int(r['season_mana']), items=items,
                            frame_id=int(r['frame_id']), skin_id=int(r['skin_id'])))
    if sorted(x['level'] for x in rewards) != list(range(1, 27)) or [x['level'] for x in rewards if x['frame_id']] != [26]:
        raise ValueError('region_arena_reward profile drift')
    missions = [dict(mission_id=int(r['id']), kind=int(r['task_req']), target=int(r['task_num']), king_coin=int(r['king_coin']), weight=int(r['weight']))
                for r in sorted(table('region_mission'), key=lambda r: int(r['id']))]
    if sorted({x['kind'] for x in missions}) != [1, 2, 3, 4] or any(x['weight'] <= 0 for x in missions):
        raise ValueError('region_mission profile drift')
    exchanges = [dict(exchange_type=int(r['id']), costs=_ints(r['cost'])) for r in sorted(table('region_exchange'), key=lambda r: int(r['id']))]
    if [x['exchange_type'] for x in exchanges] != [1, 2, 3]:
        raise ValueError('region_exchange profile drift')
    notices = [int(r['notice_item']) for r in sorted(table('region_arena_notice'), key=lambda r: int(r['order']))]
    champion = int(misc['region_arena_champion_reward'])
    if notices[0] != champion:
        raise ValueError('Arena champion notice drift')
    start, end = _day(misc['region_arena_star_time']), _day(misc['region_arena_end_time'])
    if (end - start).days != 45:
        raise ValueError('Arena season length drift')
    window = blobs['app/windows/RegionArenaWindow.lua'].data.decode('utf-8-sig')
    if 'local var_0_9 = 72000' not in window or 'arg_63_0.missionTime + var_0_9' not in window:
        raise ValueError('Arena mission refill interval drift')
    translations = _translations(blobs['data/tables/translation.lua'].data, MAIL_KEYS + ('REGION_ARENA_RULE3',))
    rules = translations.pop('REGION_ARENA_RULE3')
    if any(phrase not in rules for phrase in RULE_PHRASES):
        raise ValueError('Arena rule text drift')
    return dict(schema_version=1, contract_id='C5D_ARENA_SEASON_MODE_V1', policy_id='C5D_ARENA_PRIVATE_POLICY_V1',
                function_id=37, required_level=_ints(functions['37']['level'])[1], required_heroes=_ints(functions['37']['level'])[2],
                season_anchor=start.isoformat(), season_days=(end - start).days, season_open_seconds=18000, season_close_seconds=0,
                levels=levels, rewards=rewards, champion_item=champion, upgrade_protect=int(misc['region_arena_upgrade_protect']),
                fail_protect=int(misc['region_arena_fail_protect']), streak_bonus_below_level=20, streak_bonus_after=4,
                daily_limit=int(misc['region_arena_reward_limit']), daily_win_coin=int(misc['region_arena_victory_reward']), daily_loss_coin=int(misc['region_arena_fild_reward']),
                point_base=int(misc['region_base_integral']), point_limit=int(misc['region_add_integral_limit']),
                point_hundredths=[_hundredths(misc['region_count_param1']), _hundredths(misc['region_count_param2'])],
                match_hundredths=[_hundredths(misc['region_mate_param1']), _hundredths(misc['region_mate_param2']), _hundredths(misc['region_mate_infuluence_param'])],
                hero_level=int(misc['region_hero_level']), hero_grade=int(misc['region_hero_color']),
                mission_refill_seconds=72000, missions=missions, exchanges=exchanges, mail=translations)
