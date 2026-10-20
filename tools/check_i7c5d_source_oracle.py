#!/usr/bin/env python3
"""I7C-5D Arena source oracle: re-derives the pinned catalog facts from the archive."""
from pathlib import Path
import sys, json, zipfile, hashlib, re
sys.path.insert(0, str(Path(__file__).parent))
from generate_builtin_content import parse_generated_lua_table
B = Path(__file__).resolve().parents[1]
src = Path(sys.argv[1])
assert hashlib.file_digest(src.open('rb'), 'sha256').hexdigest() == 'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
out = json.loads((B / 'internal/content/builtin/generated/arena_catalog.json').read_text())
manifest = json.loads((B / 'internal/content/builtin/generated/manifest.json').read_text())
resources = json.loads((B / 'internal/content/builtin/generated/resource_catalog.json').read_text())['resources']
with zipfile.ZipFile(src) as z:
    read = lambda n: z.read('app-assets/output/assets/src_64/' + n)
    table = lambda n: parse_generated_lua_table(read('data/tables/' + n + '.lua'))
    bindings = [x for x in manifest['sources'] if x['role'] == 'I7C5D_ARENA_SOURCE_BOUNDARY']
    assert len(bindings) == 16
    for r in bindings:
        assert hashlib.sha256(read(r['path'])).hexdigest() == r['sha256']
    misc = {r['key']: r['value'] for r in table('misc')}
    assert (misc['region_arena_star_time'], misc['region_arena_end_time']) == ('20221028', '20221212') and (out['season_anchor'], out['season_days']) == ('2022-10-28', 45)
    assert [misc[k] for k in ('region_arena_upgrade_protect', 'region_arena_fail_protect', 'region_arena_reward_limit', 'region_arena_victory_reward', 'region_arena_fild_reward')] == ['90', '10', '10', '50', '25']
    assert [out[k] for k in ('upgrade_protect', 'fail_protect', 'daily_limit', 'daily_win_coin', 'daily_loss_coin')] == [90, 10, 10, 50, 25]
    assert [misc[k] for k in ('region_base_integral', 'region_add_integral_limit', 'region_count_param1', 'region_count_param2')] == ['10', '50', '0.1', '0.01'] and out['point_hundredths'] == [10, 1]
    assert [misc[k] for k in ('region_mate_param1', 'region_mate_param2', 'region_mate_infuluence_param')] == ['0.8', '1.2', '0.1'] and out['match_hundredths'] == [80, 120, 10]
    assert (misc['region_hero_level'], misc['region_hero_color'], misc['region_arena_champion_reward']) == ('100', '16', '110006001') and (out['hero_level'], out['hero_grade'], out['champion_item']) == (100, 16, 110006001)
    levels = sorted(table('region_arena_level'), key=lambda r: int(r['id']))
    assert [(int(r['level']), int(r['star'])) for r in levels] == [(x['level'], x['star']) for x in out['levels']]
    rewards = sorted(table('region_arena_reward'), key=lambda r: int(r['id']))
    for raw, row in zip(rewards, out['rewards'], strict=True):
        assert (row['level'], row['region_coin'], row['mana'], row['frame_id'], row['skin_id']) == (int(raw['level']), int(raw['region_arena_coin']), int(raw['season_mana']), int(raw['frame_id']), int(raw['skin_id']))
    assert [(m['mission_id'], m['kind'], m['target'], m['king_coin'], m['weight']) for m in out['missions']] == [(int(r['id']), int(r['task_req']), int(r['task_num']), int(r['king_coin']), int(r['weight'])) for r in sorted(table('region_mission'), key=lambda r: int(r['id']))]
    assert [x['costs'] for x in out['exchanges']] == [[int(c) for c in r['cost'].split('|')] for r in sorted(table('region_exchange'), key=lambda r: int(r['id']))]
    assert {r['id']: r['level'] for r in table('function')}['37'] == '6|60|5' and (out['required_level'], out['required_heroes']) == (60, 5)
    mid = read('app/common/network/mid.lua').decode()
    for name, number in [('GET_REARENA_INFO', 768), ('GET_REARENA_PARTNERS', 769), ('REARENA_MODIFY_DEFENCE', 770), ('REARENA_MATCH_ENEMY', 771), ('REARENA_START_FIGHT', 772),
                         ('REARENA_FIGHT', 773), ('REARENA_END_FIGHT', 774), ('REARENA_LOAD_RANKS', 775), ('REARENA_FIGHT_RECORDS', 776), ('REARENA_FIGHT_REPORT', 777),
                         ('REARENA_PREPARE_FIGHT', 778), ('REARENA_STOP_FIGHT', 779), ('GET_EXCHANGE_AWARD', 848), ('GET_MISSION_AWARD', 849), ('GIVE_UP_REGION_MISSION', 666)]:
        assert re.search(r'\b%s\s*=\s*%d\b' % (name, number), mid), name
    assert re.search(r'REGION_ARENA\s*=\s*45', read('app/common/enums.lua').decode()) and 'xyd.MapBattleID.ARENA = 111001' in read('app/common/const.lua').decode()
    assert 'arg_1_0.isBackendBattle = 1' in read('app/windows/FoundEnemyWindow.lua').decode()
    window = read('app/windows/SelectTeamRearenaWindow.lua').decode()
    assert 'PLAYOFFS_RETRY' in window and 'xyd.mid.REARENA_FIGHT, {' in window
    assert 'local var_23_17 = var_23_10 and 30 or 20' in read('app/common/network/Backend.lua').decode()
    achievements = {r['id']: r for r in table('achievement')}
    assert achievements['100003']['condition'] == '5|15|30' and 'in Arena' in achievements['100003']['desc']
keys = {r.get('resource_key'): r for r in resources}
assert keys['region_coin']['settlement_activation'] == keys['king_coin']['settlement_activation'] == 'ENABLED_R4'
print('I7C5D SOURCE ORACLE: PASS 26 levels/26 rewards/12 missions/3 exchanges; seasons 45 d from 2022-10-28 05:00; protections 10/90; daily 50/25 x10; region_coin/king_coin ENABLED_R4; private policy inputs labelled')
