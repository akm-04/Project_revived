#!/usr/bin/env python3
"""I7C-5B Top Floor source oracle: re-derives the pinned catalog facts from the archive."""
from pathlib import Path
import sys, json, zipfile, hashlib, re
sys.path.insert(0, str(Path(__file__).parent))
from generate_builtin_content import parse_generated_lua_table
from decimal import Decimal
B = Path(__file__).resolve().parents[1]
src = Path(sys.argv[1])
assert hashlib.file_digest(src.open('rb'), 'sha256').hexdigest() == 'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
out = json.loads((B / 'internal/content/builtin/generated/top_floor_catalog.json').read_text())
manifest = json.loads((B / 'internal/content/builtin/generated/manifest.json').read_text())
resources = json.loads((B / 'internal/content/builtin/generated/resource_catalog.json').read_text())['resources']
with zipfile.ZipFile(src) as z:
    read = lambda n: z.read('app-assets/output/assets/src_64/' + n)
    table = lambda n: parse_generated_lua_table(read('data/tables/' + n + '.lua'))
    bindings = [x for x in manifest['sources'] if x['role'] == 'I7C5B_TOP_FLOOR_SOURCE_BOUNDARY']
    assert len(bindings) == 10
    for r in bindings:
        assert hashlib.sha256(read(r['path'])).hexdigest() == r['sha256']
    misc = {r['key']: r['value'] for r in table('misc')}
    assert (misc['arena_cooldown'], misc['arena_buy_num'], misc['arena_refresh_cost'], misc['arena_gift_time1'], misc['arena_gift_time2']) == ('300', '5', '50', '75600', '77400')
    assert [out['cooldown_seconds'], out['buy_restore'], out['reset_cost'], out['cutoff_seconds'], out['freeze_end_seconds'], out['match_hundredths']] == [300, 5, 50, 75600, 77400, [30, 50, 98]]
    assert out['mail_title'] == misc['arena_mail_title'] and out['mail_text'] == misc['arena_mail_text'] and '%d' in out['mail_text']
    rewards = sorted(table('arena_reward'), key=lambda r: int(r['id']))
    for raw, row in zip(rewards, out['rewards'], strict=True):
        assert row['range'] == int(raw['range']) and row['daily_crystal'] == int(raw['daily_diamond']) and row['daily_arena_coin'] == int(raw['daily_arena_coin'])
        assert Decimal(row['best_rank_rate']) / 10000 == Decimal(raw['rank_reward_diamond_new'])
    assert out['rewards'][0]['frame_id'] == 120001004 and all(r['frame_id'] == 0 for r in out['rewards'][1:])
    vip = sorted(table('vip'), key=lambda r: int(r['id']))
    assert [v['purchases'] for v in out['vip']] == [int(r['num_arena']) for r in vip] and [v['reset'] for v in out['vip']] == [int(r['arena_reset']) for r in vip]
    assert out['buy_costs'][:5] == [50, 100, 200, 300, 400] and len(table('robot')) == len(out['robots']) == 10325
    assert out['robots'][0]['level'] == 6 and out['robots'][-1]['level'] == 79
    model = read('app/model/Arena.lua').decode()
    assert 'getRankReward' in model and 'math.ceil' in model and 'rank_reward' not in model
    assert 'rankRewardCrystalNew_' in read('app/common/tables/ArenaRewardTable.lua').decode()
    window = read('app/windows/ArenaWindow.lua').decode()
    assert 'lastMatchTime + 300' in window and 'table_id <= 25000' in window
    mid = read('app/common/network/mid.lua').decode()
    for name, number in [('LOAD_ARENA', 272), ('START_FIGHT', 280), ('ARENA_BUY_TICKET', 281), ('ARENA_RESET_TIMER', 288), ('LOAD_ARENA_FIGHT_RECORDS', 289), ('LOAD_ARENA_FIGHT_REPORT', 290), ('ARENA_PRE_FIGHT', 294)]:
        assert re.search(r'\b%s\s*=\s*%d\b' % (name, number), mid), name
    assert re.search(r'FRONT_ARENA_BATTLE\s*=\s*false', read('config.lua').decode())
assert next(r for r in resources if r.get('resource_key') == 'arena_coin')['settlement_activation'] == 'ENABLED_R4'
print('I7C5B SOURCE ORACLE: PASS 30 reward rows/16 vip/10325 robots; cooldown300 freeze75600-77400; arena_coin ENABLED_R4; private policy inputs labelled')
