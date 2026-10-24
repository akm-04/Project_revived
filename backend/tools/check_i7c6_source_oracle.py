"""Independent source facts oracle for C6_SELECTED_COSMETIC_ORIGINS_V1, not an oracle for private algorithms."""
from pathlib import Path
import hashlib,json,re,sys,zipfile
sys.path.insert(0,str(Path(__file__).parent))
from generate_builtin_content import parse_generated_lua_table as parse
B=Path(__file__).resolve().parents[1];src=Path(sys.argv[1]);assert hashlib.file_digest(src.open('rb'),'sha256').hexdigest()=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
m=json.loads((B/'internal/content/builtin/generated/manifest.json').read_text())
assert m['compiler_version']=='i7c6-cosmetic-origins' and 'COSMETIC_TITLE_CONDITION_I7C6' in m['enabled_capabilities']
display=json.loads((B/'internal/content/builtin/generated/player_display_catalog.json').read_text())
rows={(r['family'],r['id']):r for r in display['cosmetics']}
arena=json.loads((B/'internal/content/builtin/generated/arena_catalog.json').read_text())
with zipfile.ZipFile(src)as z:
 read=lambda p:z.read('app-assets/output/assets/src_64/'+p)
 text=lambda p:read(p).decode('utf-8-sig')
 table=lambda n:parse(read('data/tables/'+n+'.lua'))
 for r in table('title_system'):
  got=rows[('title',int(r['id']))]
  assert got['condition']==[int(x)for x in r['condition'].split('|')]
 expected={100022:(5,[30]),100023:(5,[50]),100024:(6,[50]),100025:(6,[80]),100026:(7,[30]),100027:(7,[60]),100028:(7,[100])}
 for title,(kind,condition) in expected.items():
  got=rows[('title',title)];assert (got['type'],got['condition'],got['days'])==(kind,condition,-1),title
 assert all('condition' not in r for r in display['cosmetics'] if r['family']!='title')
 enums=text('app/common/enums.lua')
 assert re.search(r'xyd\.DormType = \{[^}]*VILLA = 4',enums) and 'xyd.EventCentreBuildingType.BOOKSHELF = 4' in enums
 avatar=rows[('avatar',110006001)];assert avatar['days']==60 and arena['champion_item']==110006001
 avatars={int(r['id']):r for r in table('avatar')};assert avatars[110006001]['time']=='60' and 'No.1 in Arena when the season ends' in text('data/tables/avatar.lua')
print('I7C6 SOURCE ORACLE: PASS title conditions compiled for every title_system row; marriage 30/50 (type 5), Bookshelf lv.50/80 (type 6, building 4), villas 30/60/100 (type 7, DormType.VILLA=4); avatar 110006001 lasts 60 days and is the Arena champion item. Keep-once-earned, settlement start and legacy backfill are private policy, not recovered server algorithms.')
