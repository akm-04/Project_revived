"""Conquer School mode (1568-1573, 2790) source tables plus the labelled C5E private policy inputs."""
import re

MAIL_KEYS = ('CONQUER_SCHOOL_MAIL_TITLE', 'CONQUER_SCHOOL_MAIL_TEXT', 'CONQUER_SCHOOL_MAIL_NAME')
RULE_PHRASES = ('Lv100 players can challenge Conquest', 'You have 10 chances to challenge each mission every day, the chance resets at 5:00am',
                'Each defeat will grant you 1 encourage buff, stacks up to 10', 'you may reset the mission and challenge it again',
                'the girls you used in the fight which you successfully defeated the squad will be unusable in this mission')
MISC_KEYS = dict(challenge_num='conquer_school_challenge_num', buff_limit='conquer_buff_lev_limit', buy_limit='conquer_buy_limit',
                 max_loop='conquer_school_max_loop', report_limit='conquer_school_battle_report_num_limit',
                 report_reward='conquer_school_battle_report_reward', report_reward_limit='conquer_school_battle_report_reward_limit',
                 report_rank_ratio='conquer_report_rank_ratio')
EXPECTED_MISC = dict(challenge_num=10, buff_limit=10, buy_limit=10, max_loop=8, report_limit=3, report_reward=50000, report_reward_limit=10,
                     report_rank_ratio=1000000000)


def _translations(data, keys):
    text = data.decode('utf-8-sig')
    found = {}
    for key in keys:
        match = re.search(r'\{\s*"' + key + r'",\s*"((?:[^"\\]|\\.)*)"\s*\}', text)
        if match is None:
            raise ValueError('translation missing ' + key)
        found[key] = match.group(1).replace('\\n', '\n')
    return found


def _teams(row):
    present = [row['team' + str(i)] not in ('0', '') for i in range(1, 6)]
    count = sum(present)
    if present != [True] * count + [False] * (5 - count) or count < 1:
        raise ValueError('conquer team layout drift ' + row['id'])
    return count


def build_conquer_mode(blobs, parse):
    table = lambda name: parse(blobs['data/tables/' + name + '.lua'].data)
    misc = {r['key']: r['value'] for r in table('misc')}
    values = {name: int(misc[key]) for name, key in MISC_KEYS.items()}
    if values != EXPECTED_MISC:
        raise ValueError('conquer misc drift')
    functions = {r['id']: r for r in table('function')}
    if functions['48']['level'] != '1|100' or functions['48']['open_control'] != '1':
        raise ValueError('Conquer function gate drift')
    missions = []
    for r in sorted(table('conquer_school_campaign'), key=lambda r: int(r['id'])):
        missions.append(dict(id=int(r['id']), lev=int(r['lev']), region=int(r['region']), next_id=int(r['next_id']), teams=_teams(r),
                             reward=[int(r['reward_item']), int(r['reward_item_num'])]))
    if any(r['is_open'] != '1' for r in table('conquer_school_campaign')):
        raise ValueError('conquer closed mission')
    if [m['lev'] for m in missions] != list(range(1, 57)) or [m['next_id'] for m in missions if m['next_id'] == 0] != [0] or missions[-1]['next_id'] != 0:
        raise ValueError('conquer campaign chain drift')
    loops = [dict(loop_id=int(r['loop_id']), reward=[int(r['reward_item']), int(r['reward_item_num'])])
             for r in sorted(table('conquer_school_loop'), key=lambda r: int(r['loop_id']))]
    if [x['loop_id'] for x in loops] != list(range(1, values['max_loop'] + 1)):
        raise ValueError('conquer loop drift')
    costs = {int(r['id']): int(r['buy_conquer_cost']) for r in table('refresh_cost') if r.get('buy_conquer_cost')}
    buy_costs = [costs[n] for n in range(1, values['buy_limit'] + 1)]
    window = blobs['app/windows/ConquerSchoolWindow.lua'].data.decode('utf-8-sig')
    if 'getBuyConquerTimes() < 10' not in window or 'privilegeLeftCardDay <= 0' not in window:
        raise ValueError('Conquer buy gate drift')
    translations = _translations(blobs['data/tables/translation.lua'].data, MAIL_KEYS + ('CONQUER_SCHOOL_RULE_TEXT',))
    rules = translations.pop('CONQUER_SCHOOL_RULE_TEXT')
    if any(phrase not in rules for phrase in RULE_PHRASES):
        raise ValueError('Conquer rule text drift')
    return dict(schema_version=1, contract_id='C5E_CONQUER_SCHOOL_MODE_V1', policy_id='C5E_CONQUER_PRIVATE_POLICY_V1',
                function_id=48, required_level=int(functions['48']['level'].split('|')[1]), day_start_seconds=18000,
                max_formation=6, **values, buy_costs=buy_costs, missions=missions, loops=loops, mail=translations)
