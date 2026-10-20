#!/usr/bin/env python3
"""I7C-5C 1 on 1 source oracle: re-derives the pinned catalog facts from the archive."""
from pathlib import Path
import sys, json, zipfile, hashlib, re
sys.path.insert(0, str(Path(__file__).parent))
from generate_builtin_content import parse_generated_lua_table
B = Path(__file__).resolve().parents[1]
src = Path(sys.argv[1])
assert hashlib.file_digest(src.open('rb'), 'sha256').hexdigest() == 'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
out = json.loads((B / 'internal/content/builtin/generated/one_on_one_catalog.json').read_text())
manifest = json.loads((B / 'internal/content/builtin/generated/manifest.json').read_text())
resources = json.loads((B / 'internal/content/builtin/generated/resource_catalog.json').read_text())['resources']
with zipfile.ZipFile(src) as z:
    read = lambda n: z.read('app-assets/output/assets/src_64/' + n)
    table = lambda n: parse_generated_lua_table(read('data/tables/' + n + '.lua'))
    bindings = [x for x in manifest['sources'] if x['role'] == 'I7C5C_ONE_ON_ONE_SOURCE_BOUNDARY']
    assert len(bindings) == 11
    for r in bindings:
        assert hashlib.sha256(read(r['path'])).hexdigest() == r['sha256']
    misc = {r['key']: r['value'] for r in table('misc')}
    assert [misc['legend_elo' + k] for k in '1234'] == ['400', '1', '10', '20'] and [out['elo_divisor'], out['elo_win'], out['elo_base'], out['elo_k']] == [400, 1, 10, 20]
    assert (misc['legend_start'], misc['legend_stop'], misc['legend_free_num'], misc['legend_record_num'], misc['legend_lower_limit']) == ('28800', '79200', '10', '20', '3000')
    assert [out['open_seconds'], out['close_seconds'], out['free_tries'], out['records_max'], out['points_floor']] == [28800, 79200, 10, 20, 3000]
    assert (misc['legend_promo_start_time'], misc['legend_promo_end_time'], misc['legend_promote_cool_time'], misc['legend_promo_win'], misc['legend_promo_chance']) == ('5|75600', '6|75600', '3600', '2', '3')
    assert out['match_hundredths'] == [30, 50, 98, 100] and out['match_new_hundredths'] == [50, 75, 95, 100] and out['match_new_rank'] == 200
    assert out['entry_points'] == int(misc['legend_point_convert_min_point']) == 4300 and out['split_bound'] == 5000 and out['reset_cost'] == int(misc['top_refresh_cost']) == 50
    levels = sorted(table('legend_arena_rank'), key=lambda r: int(r['id']))
    for raw, row in zip(levels, out['levels'], strict=True):
        assert (row['teams'], row['hidden'], row['cooldown_seconds'], row['bound']) == (int(raw['team_num']), int(raw['team_hide']), int(raw['cool_time']), int(raw['rank_bound']))
    rewards = sorted(table('legend_reward'), key=lambda r: int(r['id']))
    for raw, row in zip(rewards, out['rewards'], strict=True):
        assert row['range'] == int(raw['range']) and row['crystal'] == int(raw['daily_diamond']) and row['mana'] == int(raw['daily_mana']) and row['top_coin'] == int(raw['daily_top_coin'])
    assert out['rewards'][0]['frame_id'] == 120001005 and all(r['frame_id'] == 0 for r in out['rewards'][1:])
    vip = sorted(table('vip'), key=lambda r: int(r['id']))
    assert [v['purchases'] for v in out['vip']] == [int(r['num_top']) for r in vip] and [v['reset'] for v in out['vip']] == [int(r['top_reset']) for r in vip]
    assert out['buy_costs'][:5] == [50, 100, 200, 300, 400]
    assert {r['id']: r['content'] for r in table('message')}['30002'] == out['opening_message']
    assert {r['id']: r['level'] for r in table('function')}['16'] == '6|55|15' and out['required_level'] == 55 and out['required_heroes'] == 15
    assert [t['title_id'] for t in out['titles']] == [100002, 100003, 100004, 100005]
    model = read('app/model/PeakArena.lua').decode()
    assert 'checkBattleResult' in model and 'promote_end_time' in model and 'formations = var_9_0' in model
    assert 'error_code == 30002' in read('app/windows/SelectPeakTeamWindow.lua').decode()
    assert 'return true' in read('app/windows/PeakArenaWindow.lua').decode().split('function var_0_0.dealWrongTimeChallenge')[1][:80]
    mid = read('app/common/network/mid.lua').decode()
    for name, number in [('LOAD_PEAK_ARENA', 2480), ('PEAK_CHANGE_TEAMS', 2481), ('MATCH_ENEMIES', 2482), ('GET_ENEMY_TEAM', 2483), ('PEAK_START_FIGHT', 2484), ('PEAK_RECORDS', 2485),
                         ('BUY_PEAK_TIMES', 2486), ('PEAK_RECORDS_LIST', 2487), ('RESET_PEAK_TIME', 2488), ('PEAK_RECORDS_DETAIL', 2489)]:
        assert re.search(r'\b%s\s*=\s*%d\b' % (name, number), mid), name
    assert 'PEAK_FIGHT_RESULT' not in mid
    assert re.search(r'SUPER_ARENA\s*=\s*65', read('app/common/enums.lua').decode()) and 'getSuperArenaBattleStar' in read('app/scenes/BattleCreateReport.lua').decode()
assert next(r for r in resources if r.get('resource_key') == 'top_coin')['settlement_activation'] == 'ENABLED_R4'
print('I7C5C SOURCE ORACLE: PASS 5 levels/30 reward rows/16 vip/4 titles; open 08:00-22:00 (30002); Elo 400/1/10/20; promotion Fri-Sat 21:00; top_coin ENABLED_R4; private policy inputs labelled')
