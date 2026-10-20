"""Independent source facts/caller oracle, not an oracle for private algorithms."""
from pathlib import Path
import hashlib,json,re,sys,zipfile
sys.path.insert(0,str(Path(__file__).parent))
from generate_builtin_content import parse_generated_lua_table as parse
B=Path(__file__).resolve().parents[1];src=Path(sys.argv[1]);assert hashlib.file_digest(src.open('rb'),'sha256').hexdigest()=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
c=json.loads((B/'internal/content/builtin/generated/league_catalog.json').read_text());m=json.loads((B/'internal/content/builtin/generated/manifest.json').read_text())
with zipfile.ZipFile(src)as z:
 read=lambda p:z.read('app-assets/output/assets/src_64/'+p)
 table=lambda n:parse(read('data/tables/'+n+'.lua'))
 bindings=[r for r in m['sources']if r['role']=='I7C5F_LEAGUE_SOURCE_BOUNDARY'];assert len(bindings)==19
 for r in bindings:assert hashlib.sha256(read(r['path'])).hexdigest()==r['sha256']
 misc={r['key']:r['value']for r in table('misc')}
 for n,k in [('initial_points','original_points'),('point_max','point_param1'),('point_min','floor_points'),('normal_protection','protect_time'),('frenzy_protection','protect_time_2'),('opponent_radius','opponents_show'),('day_start','first_win_time')]:assert c[n]==int(misc['cross_arena_'+k])
 assert c['levels']==[70,90,100]and len(c['schedule'])==50 and c['schedule'][-1]=='2024-06-19'
 for group in range(1,4):
  daily=sorted(table('cross_arena_daily_reward'+str(group)),key=lambda r:int(r['range']))
  assert [(r['rank'],r['gift_id'])for r in c['daily']if r['group']==group]==[(int(r['range']),int(r['gift']))for r in daily]
  final=sorted(table('cross_arena_final_reward'+str(group)),key=lambda r:int(r['range']))
  assert [(r['rank'],r['bubble_id'],r['crystal'])for r in c['final']if r['group']==group]==[(int(r['range']),int(r['bubble_id']or'0'),int(r['crystal']))for r in final]
 assert read('data/tables/cross_arena_daily_reward.lua')==b'\xef\xbb\xbf'
 gift={int(r['id']):r for r in table('gift')}
 for g in c['gifts']:
  r=gift[g['id']];assert g['items']==[[int(i),int(n)]for i,n in zip(r['items'].split('|'),r['item_nums'].split('|'),strict=True)if int(i)>0 and int(n)>0];assert g['crystal']==int(r['crystal'])and g['mana']==int(r['mana'])
 bubbles={int(r['id']):r for r in table('chat_bubble')};assert all(int(bubbles[i]['time'])==c['bubble_seconds']==2592000 for i in range(10002,10008))
 titles={int(r['id']):r for r in table('title_system')};assert c['title_ids']==[100104,100111,*range(100114,100122)]and all(titles[i]['time']=='-1'for i in c['title_ids'])
 assert '兩次' in titles[100111]['desc']and '十次' in titles[100121]['desc']and '第二季'in titles[100087]['desc']
 mid=read('app/common/network/mid.lua').decode('utf-8-sig');names=['CHAMPIONS_LEAGUE_GET_INFO','CHAMPIONS_LEAGUE_GET_ENEMY','CHAMPIONS_LEAGUE_FIGHT','CHAMPIONS_GET_FIGHT_RECORD','CHAMPIONS_GET_DAILY_AWARD','CHAMPIONS_SET_DEFENSE_INFO','CHAMPIONS_SELECT_AWARD_GROUP','CHAMPIONS_GET_SEASON_TOP']
 for i,n in enumerate(names):assert re.search(r'\b'+n+r'\s*=\s*'+str(2800+i)+r'\b',mid)
 selection=read('app/windows/ChampionsLeagueSelectTeamWindow.lua').decode('utf-8-sig');assert 'request(xyd.mid.CHAMPIONS_LEAGUE_FIGHT'in selection and '.self_formation'in selection and '.report_key'in selection
 rank=read('app/windows/ChampionsLeagueRankWinodw.lua').decode('utf-8-sig');assert 'campaignType = xyd.CampaignType.ARENA'in rank
 form=read('app/windows/BaseSelectTeamNewWindow.lua').decode('utf-8-sig');assert 'iter_98_1:getHeroID()'in form
 for name in ['NormalHero','SuperHero']:
  text=read('app/model/'+name+'.lua').decode('utf-8-sig');assert 'heroID_ = arg_3_1.partner_id'in text
 rules=read('app/windows/ChampionsRuleWindow.lua').decode('utf-8-sig');assert ':time(arg_10_0.champions.seasonCount + 1) - 3'in rules
 assert read('app/common/tables/CrossArenaScheduleTable.lua').decode('utf-8-sig').count('return arg_3_0.time_[arg_3_1] or 0')==1
 assert {r['id']:r['level']for r in table('function')}['91']=='1|70'
print('I7C5F SOURCE ORACLE: PASS active2802/ARENA, owned-instance formations, numbered rewards/gifts/bubbles/titles,50 dates, rest/date limitation. Private score/rest-inclusive/promotion policies are not asserted as recovered server algorithms.')
