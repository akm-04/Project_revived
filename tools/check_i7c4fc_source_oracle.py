"""Independent source facts oracle for I7C-4 full stage C, not an oracle for private count or ranking algorithms."""
from pathlib import Path
import hashlib,re,sys,zipfile
sys.path.insert(0,str(Path(__file__).parent))
from generate_builtin_content import parse_generated_lua_table as parse
B=Path(__file__).resolve().parents[1];src=Path(sys.argv[1]);assert hashlib.file_digest(src.open('rb'),'sha256').hexdigest()=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
board=(B/'internal/domain/ranking/board.go').read_text()
assert re.search(r'SkinsBoard = Board\{[^}]*FieldID: 1003[^}]*SubType: 38[^}]*TitleType: 9[^}]*TitledRanks: 20[^}]*Titles: \[\]int64\{100063, 100064, 100065, 100066\}',board)
assert re.search(r'SkinsID\s+int64 = 100016',(B/'internal/domain/achievement/catalog.go').read_text())
with zipfile.ZipFile(src)as z:
 read=lambda p:z.read('app-assets/output/assets/src_64/'+p)
 text=lambda p:read(p).decode('utf-8-sig')
 table=lambda n:parse(read('data/tables/'+n+'.lua'))
 enums=text('app/common/enums.lua')
 for name,id in {'SKIN_NUM':1003,'ACHIEVE_NUM':1004,'AVATAR_FRAME_NUM':1005,'AVATAR_NUM':1006}.items():assert re.search(r'\b'+name+r'\s*=\s*'+str(id)+r'\b',enums),name
 skins=[r for r in table('rank')if r['sub_type']=='38'];assert len(skins)==1 and skins[0]['id']=='16002' and skins[0]['type']=='3' and skins[0]['is_realtime']=='1' and skins[0]['title']=='Skins'
 titles={int(r['id']):r for r in table('title_system')}
 for id,condition in {100063:'1',100064:'2',100065:'3',100066:'4|20'}.items():
  r=titles[id];assert (r['type'],r['condition'],r['time'])==('9',condition,'604800') and 'Ranking of Skins'in r['desc'],id
 achievement={int(r['id']):r for r in table('achievement')}[100016];assert achievement['condition']=='1|10|20' and achievement['desc']=='Own %d skins'
print('I7C4FC SOURCE ORACLE: PASS show types SKIN_NUM 1003/ACHIEVE_NUM 1004/AVATAR_FRAME_NUM 1005/AVATAR_NUM 1006; rank 16002 Skins subtype 38 type 3 realtime; titles 100063..100066 type 9 ranks 1/2/3/4-20 for 604800 s bound by SkinsBoard; achievement 100016 Own %d skins 1|10|20. Skin collection, cosmetic counts, trophy count, Skins ranking and full11 omission are private policy, not recovered server algorithms.')
