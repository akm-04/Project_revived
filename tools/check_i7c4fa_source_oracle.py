"""Independent source facts/caller oracle, not an oracle for private algorithms."""
from pathlib import Path
import hashlib,json,re,sys,zipfile
sys.path.insert(0,str(Path(__file__).parent))
from generate_builtin_content import parse_generated_lua_table as parse
B=Path(__file__).resolve().parents[1];src=Path(sys.argv[1]);assert hashlib.file_digest(src.open('rb'),'sha256').hexdigest()=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
c=json.loads((B/'internal/content/builtin/generated/achievement_catalog.json').read_text());m=json.loads((B/'internal/content/builtin/generated/manifest.json').read_text())
assert m['compiler_version']=='i7c4fa-achievement-ap' and 'ACHIEVEMENT_CATALOG_I7C4FA' in json.dumps(m)
with zipfile.ZipFile(src)as z:
 read=lambda p:z.read('app-assets/output/assets/src_64/'+p)
 text=lambda p:read(p).decode('utf-8-sig')
 table=lambda n:parse(read('data/tables/'+n+'.lua'))
 rows=sorted(table('achievement'),key=lambda r:int(r['id']))
 assert [int(r['id'])for r in rows]==list(range(100001,100034))==[r['id']for r in c['rows']]
 for r,got in zip(rows,c['rows']):
  assert got['thresholds']==[int(x)for x in r['condition'].split('|')] and got['points']==[int(x)for x in r['points'].split('|')] and got['hidden']==int(r['is_hide'])
 assert sum(sum(r['points'])for r in c['rows'])==99000
 levels=sorted(table('achievement_level'),key=lambda r:int(r['id']));assert len(levels)==10==len(c['levels'])
 for r,got in zip(levels,c['levels']):
  assert got['point_condition']==int(r['point_condition']) and got['items']==[[int(i),int(n)]for i,n in zip(r['items'].split('|'),r['item_nums'].split('|'),strict=True)if int(i)!=0]
 mid=text('app/common/network/mid.lua');assert re.search(r'\bLOAD_ACHIEVEMENT_INFO\s*=\s*1302\b',mid) and re.search(r'\bGET_ACHIEVEMENT_AWARD\s*=\s*1303\b',mid)
 enums=text('app/common/enums.lua');assert re.search(r'NoticeType\.ACHIEVEMENT\s*=\s*17\b',enums) and re.search(r'\bACHIEVEMENT_POINT\s*=\s*15\b',enums)
 player=text('app/model/SelfPlayer.lua');assert 'notice_type == xyd.NoticeType.ACHIEVEMENT'in player and 'handleNewAchievementNotice(var_177_0.params)'in player
 model=text('app/model/Achievement.lua')
 for k in ['achieve_id','complete_time','progress','point_level','total_points','rank']:assert 'var_6_0.'+k in model
 window=text('app/windows/AchievementWindow.lua');assert 'xyd.SubRankType.ACHIEVEMENT_POINT'in window and 'loadRankList'in window
 assert 'arg_20_2.point'in text('app/windows/NewRankWindow.lua')
 rank={r['id']:r for r in table('rank')};assert rank['2001']['sub_type']=='8'
 titles={int(r['id']):r for r in table('title_system')};assert titles[100001]['time']=='604800' and titles[100001]['type']=='1'
print('I7C4FA SOURCE ORACLE: PASS 33 achievement rows/99000 points, 10 point levels with items, MIDs 1302/1303, notice 17 params, rank 2001 subtype 8, trophy list subtype 15, title 100001 (604800 s). Private AP, ranking, backfill and notice policies are not asserted as recovered server algorithms.')
