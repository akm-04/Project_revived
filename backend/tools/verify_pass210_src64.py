#!/usr/bin/env python3
"""Pass210 Stage E effective-src_64 reality lock."""
from __future__ import annotations
import hashlib, json, re, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SRC=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else (ROOT.parent/'app-assets/output/assets/src_64').resolve()
EXPECTED={
 'app/windows/AwakeTwiceSelectTeamWindow.lua':'5c860b0211739fb80163b2fe174c60117bd178d824fc3a4755c792b629ba19c8',
 'app/scenes/BattleUnlimit.lua':'18379155319fee810eb645bccf0ec299c4fe720ae0380e6c222f596a452dc6be',
 'data/tables/bloodline_incubus.lua':'f94ddd675f3ba1d45f20d8c9df3e9ade37e5bc0bec50c30b66a033ffa1c79b10',
 'data/tables/bloodline_incubus_monster.lua':'c8c05e6799f896d2cbca9ccc21902963c540360da0458d73507427e6588106ec',
 'app/windows/TaskAwakeCell.lua':'ff133e4afc528f2c5a31e2ec51a88f3ac9e1d3ab6b137f8ddbdff3dec7671ff6',
 'app/common/network/Backend.lua':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840',
 'app/model/SelfPlayer.lua':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
 'app/model/NormalHero.lua':'125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9',
 'app/windows/SkillTipsWindow.lua':'0424173f752e7aacaddf7865459f225bfea784cc2121400b2bf33c892db08f66',
 'app/common/tables/HeroTable.lua':'5293207486e52a8dad959b48ea0c90680a335e9144c362d5e9b342b9fd6cef60',
 'data/tables/partner1.lua':'1ee6847a30ac2800f93c95c1556f8f25fd4e41a38c215332eeb75f45ea0af8ac',
 'lib/battle/fighters/Zhugeliang.lua':'506e438b549f65611e1b27c62e7e7cd1253e366f6dfca1e8cacb820704c29a44',
 'lib/battle/fighters/Zhugeliang_Awaken.lua':'7ce70841ba3da0c5f63562924c3b496d9641dee1ec223b8fbab498d34eb4fbca',
 'app/model/Task.lua':'d454ae7cb1e28d95d366aae30ba88d83432c974415f263991af6c4190d54bee5',
 'app/common/enums.lua':'15340bd89fe7c6f150ccfd4a5cd2a2f0e8e73c89dfae9ac3388376a4799901f3',
}
def need(c,m):
 if not c: raise AssertionError(m)
def text(rel): return (SRC/rel).read_text(encoding='utf-8-sig')
files=[p for p in SRC.rglob('*') if p.is_file()]
need(len(files)==4370,f'src_64 census {len(files)} != 4370')
for rel,want in EXPECTED.items():
 got=hashlib.sha256((SRC/rel).read_bytes()).hexdigest(); need(got==want,f'hash drift {rel}: {got}')

select=text('app/windows/AwakeTwiceSelectTeamWindow.lua')
need('twice_awake_mission = ' in select and 'incubus_id = ' in select,'MID866 request fields absent')
# The MID866 request uses an inline two-field table. Team/roster data is constructed only in the callback for local battle launch.
m=re.search(r'xyd\.Backend\.get\(\):request\(xyd\.mid\.UNLIMIT_START_FIGHT,\s*\{\s*twice_awake_mission\s*=\s*([^,}]+),\s*incubus_id\s*=\s*\1\s*\},\s*function',select,re.S)
need(m is not None,'MID866 request is not the recovered two-field mission/incubus envelope')
need(re.search(r'for\s+\w+\s*=\s*1,\s*20\s+do',select) is not None,'Blood UI no longer constructs 20 waves')

battle=text('app/scenes/BattleUnlimit.lua')
need('num = ' in battle and '- 2' in battle,'MID867 num=currentTimes-2 contract absent')
need('npc_ids = ' in battle and 'deadHeros_' in battle,'MID867 npc_ids contract absent')
need('twice_awake_mission = ' in battle,'MID867 win marker absent')
# Recovered Blood loss exits locally before request; winning branch adds marker.
need(re.search(r'if\s+[^\n]+isWin_\s+then\s+[^\n]+twice_awake_mission\s*=.*?else.*?return.*?Backend\.get\(\):request\([^\n]*mid\.UNLIMIT_FIGHT_RESULT', battle, re.S) is not None,'MID867 win-marker/loss-return/request ordering drift')

inc=text('data/tables/bloodline_incubus.lua'); mons=text('data/tables/bloodline_incubus_monster.lua')
ids=re.findall(r'\n\s*\{\s*\n\s*"(\d{7})",\s*\n\s*"180",\s*\n\s*"6",',inc)
wave_ids=re.findall(r'\n\s*\{\s*\n\s*"(\d{10})",',mons)
need(len(ids)==81 and len(set(ids))==81,f'Blood ritual config census {len(ids)}')
need(len(wave_ids)==1620,f'Blood wave census {len(wave_ids)}')
by={mid:0 for mid in ids}
for wid in wave_ids:
 root=wid[:-3]
 if root in by: by[root]+=1
need(set(by.values())=={20},f'Blood waves-per-mission drift {set(by.values())}')

cell=text('app/windows/TaskAwakeCell.lua')
# Ordinary terminal callback must resolve old identity before local table-ID swap.
old_lookup=cell.find('beforeAwakenID')
set_id=cell.find(':setTableID',old_lookup)
need(old_lookup>=0 and set_id>old_lookup,'ordinary MID161 callback ordering drift')

backend=text('app/common/network/Backend.lua')
need('extra_drops_' in backend and 'twice_awake_stage_' in backend,'global Stage-E response channels absent')

selfp=text('app/model/SelfPlayer.lua')
need('AWAKE_MISSION_LIST' in selfp and 'TaskType.AWAKE' in selfp and ':initData' in selfp,'MID2561 Awake bootstrap drift')
need('onUpdateTwiceAwakeStage' in selfp,'twice_awake_stage_ consumer absent')

task=text('app/model/Task.lua')
need('function var_0_0.initData' in task,'Task initData absent')

skilltips=text('app/windows/SkillTipsWindow.lua')
for field in ('skill_index','skill_item','partner_id'):
 need(field in skilltips,f'MID2144 request field missing {field}')
need('CHANGE_PARTNER_SKILL' in skilltips and 'skill_ids' in skilltips,'MID2144 caller/callback drift')
need('getItemNumByID' in skilltips and 'getItemID' in skilltips,'Book-V ownership gate drift')

hero_table=text('app/common/tables/HeroTable.lua')
need('getSkillTable' in hero_table and '["skill" .. arg_122_2]' in hero_table,'HeroTable skill picker source drift')
partner=text('data/tables/partner1.lua')
need(partner.count('60010144|60020144|60030144')>=2,'KongMing stock slot-5 picker is no longer the recovered three-choice vector')
need('60040144' not in partner and '60050144' not in partner,'Fire/Thunder unexpectedly became stock partner picker choices')

normal=text('app/model/NormalHero.lua')
need('10001144' in normal and '11001144' in normal and 'checkIsZhuge' in normal,'KongMing lineage check drift')
for book in range(50000001,50000026): need(str(book) in normal,f'Zhuge persistent book ownership census missing {book}')
need('skillIDs_' in normal and 'selfSkillIDs_' in normal,'KongMing raw skill override hydration drift')

fighter=text('lib/battle/fighters/Zhugeliang.lua')+text('lib/battle/fighters/Zhugeliang_Awaken.lua')
for sid in (60010144,60020144,60030144,60040144,60050144): need(str(sid) in fighter,f'KongMing battle skill mapping missing {sid}')

enums=text('app/common/enums.lua')
need('xyd.SKILL_INDEX.Awake = 5' in enums,'Awake skill slot no longer index 5')

print(json.dumps({
 'pass':'210.0','status':'PASS','src64_files':4370,'locked_files':len(EXPECTED),
 'blood_ritual_configs':81,'blood_wave_rows':1620,'waves_per_ritual':20,
 'mid866_sends_roster':False,'mid867_terminal_num':20,'mid867_terminal_npc_ids':[],
 'kongming_awake_slot':5,'kongming_stock_picker_skills':[60010144,60020144,60030144],
 'kongming_additional_source_valid_battle_skills':[60040144,60050144],
 'kongming_persistent_book_ids':[50000005,50000010,50000015,50000020,50000025],
},indent=2,sort_keys=True))
