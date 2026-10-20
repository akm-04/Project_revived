#!/usr/bin/env python3
"""I7C-5E Conquer School source oracle: re-derives the pinned mode catalog facts from the archive."""
from pathlib import Path
import sys, json, zipfile, hashlib, re
sys.path.insert(0, str(Path(__file__).parent))
from generate_builtin_content import parse_generated_lua_table
B = Path(__file__).resolve().parents[1]
src = Path(sys.argv[1])
assert hashlib.file_digest(src.open('rb'), 'sha256').hexdigest() == 'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
out = json.loads((B / 'internal/content/builtin/generated/conquer_mode_catalog.json').read_text())
manifest = json.loads((B / 'internal/content/builtin/generated/manifest.json').read_text())
resources = {str(r.get('item_id')): r for r in json.loads((B / 'internal/content/builtin/generated/resource_catalog.json').read_text())['resources']}
with zipfile.ZipFile(src) as z:
    read = lambda n: z.read('app-assets/output/assets/src_64/' + n)
    table = lambda n: parse_generated_lua_table(read('data/tables/' + n + '.lua'))
    bindings = [x for x in manifest['sources'] if x['role'] in ('I7C5E_CONQUER_SOURCE_BOUNDARY', 'I7C2J_CONQUER_SOURCE_BOUNDARY')]
    assert len(bindings) == 11
    for r in bindings:
        assert hashlib.sha256(read(r['path'])).hexdigest() == r['sha256']
    misc = {r['key']: r['value'] for r in table('misc')}
    assert [misc['conquer_school_' + k] for k in ('challenge_num', 'max_loop', 'battle_report_reward', 'battle_report_reward_limit', 'battle_report_num_limit', 'hurt_param')] == ['10', '8', '50000', '10', '3', '0.01']
    assert [misc[k] for k in ('conquer_buff_lev_limit', 'conquer_buy_limit', 'conquer_report_rank_ratio')] == ['10', '10', '1000000000']
    assert [out[k] for k in ('challenge_num', 'max_loop', 'report_reward', 'report_reward_limit', 'report_limit', 'buff_limit', 'buy_limit', 'report_rank_ratio')] == [10, 8, 50000, 10, 3, 10, 10, 1000000000]
    assert out['buy_costs'] == [int(r['buy_conquer_cost']) for r in sorted(table('refresh_cost'), key=lambda r: int(r['id'])) if r.get('buy_conquer_cost')][:10] == [20, 30, 50, 70, 80, 100, 100, 200, 200, 200]
    campaigns = sorted(table('conquer_school_campaign'), key=lambda r: int(r['id']))
    assert len(campaigns) == 56 and all(r['is_open'] == '1' for r in campaigns)
    for raw, row in zip(campaigns, out['missions'], strict=True):
        teams = sum(raw['team' + str(i)] not in ('0', '') for i in range(1, 6))
        assert (row['id'], row['lev'], row['region'], row['next_id'], row['teams'], row['reward']) == (int(raw['id']), int(raw['lev']), int(raw['region']), int(raw['next_id']), teams, [int(raw['reward_item']), int(raw['reward_item_num'])])
    loops = sorted(table('conquer_school_loop'), key=lambda r: int(r['loop_id']))
    assert [(x['loop_id'], x['reward']) for x in out['loops']] == [(int(r['loop_id']), [int(r['reward_item']), int(r['reward_item_num'])]) for r in loops]
    rewards = {m['reward'][0] for m in out['missions']} | {x['reward'][0] for x in out['loops']}
    assert all(resources[str(i)]['class'] == 'STACK_ITEM' and resources[str(i)]['settlement_activation'] == 'ENABLED_R4' for i in rewards)
    assert {r['id']: r['level'] for r in table('function')}['48'] == '1|100' and (out['function_id'], out['required_level']) == (48, 100)
    mid = read('app/common/network/mid.lua').decode()
    for name, number in [('GET_CONQUER_SCHOOL_INFO', 1568), ('START_CONQUER_SCHOOL_FIGHT', 1569), ('CONQUER_SCHOOL_FIGHT_RESULT', 1570), ('GET_CONQUER_SCHOOL_REPORT_LIST', 1571),
                         ('GET_CONQUER_SCHOOL_REPORT', 1572), ('RESET_CONQUER_SCHOOL', 1573), ('BUY_CONQUER_TIMES', 2790)]:
        assert re.search(r'\b%s\s*=\s*%d\b' % (name, number), mid), name
    battle = read('app/scenes/BattleCreate.lua').decode()
    for field in ('campaign_id = arg_203_0.campaignID', 'team_id = arg_203_0.conquerSchoolTeamID', 'is_win = var_203_1', 'formation = arg_203_0.formation', 'report = var_203_2',
                  'report_invalid = arg_203_0:checkBattleReport()', 'total_damage = var_203_0', 'alive_num = var_203_3'):
        assert field in battle, field
    model = read('app/model/ConquerSchool.lua').decode()
    assert 'arg_25_0.leftTimes = arg_25_0.leftTimes - 1' in model and 'if arg_30_1.conquer_lev then' in model and 'arg_3_0.teamStatus = arg_3_1.team_status' in model
    assert 'json.decode(arg_16_1.report)' in read('app/windows/ConquerSchoolReportWindow.lua').decode()
    assert 'getBuyConquerTimes() < 10' in read('app/windows/ConquerSchoolWindow.lua').decode()
print('I7C5E SOURCE ORACLE: PASS 56 missions/8 loops exact; 10 chances, buff 10, 8 loops, 10 buys (20..200 crystal), 3 reports x 1e9 rank ratio, 50000 view reward x10; function 48 Lv100; MIDs 1568-1573/2790; RESULT shape; private policy inputs labelled')
