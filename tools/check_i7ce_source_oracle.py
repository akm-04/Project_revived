"""Independent source facts oracle for I7C-E: 1829 HISTORY wire shape and the Element colour-16 gate, not an oracle for private display policy."""
from pathlib import Path
import hashlib,re,sys,zipfile
B=Path(__file__).resolve().parents[1];src=Path(sys.argv[1]);assert hashlib.file_digest(src.open('rb'),'sha256').hexdigest()=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
go=lambda p:(B/p).read_text()
with zipfile.ZipFile(src)as z:
 text=lambda p:z.read('app-assets/output/assets/src_64/'+p).decode('utf-8-sig')
 assert '\nxyd.MAX_HERO_COLOR = 16' in text('app/common/const.lua').replace('\r','')
 hero=text('app/windows/HeroMainWindow.lua');assert 'getColor() == xyd.MAX_HERO_COLOR' in hero and 'maxHeroColor' not in hero.split('getColor() == xyd.MAX_HERO_COLOR')[0][-400:]
 model=text('app/model/PersonDisplay.lua')
 for key in ['arena_performance','region_arena_performance','super_arena_performance']:assert f'arg_17_1.{key}' in model
 assert re.search(r'ARENA then\s+return arg_42_0:getArena\(\).*SUPER_ARENA then\s+return arg_42_0:getSuperArena\(\).*REGION_ARENA then\s+return arg_42_0:getRegionArena\(\)',model,re.S)
 window=text('app/windows/PersonDisplayWindow.lua')
 for fact in ['var_84_1.partners_info or var_84_1.partner_info','var_84_2.win_fight or var_84_2.win_times','var_84_2.rank or var_84_2.king_coin','var_84_2.total_fight','PERSON_HISTORY_TIPS_8','xyd.formatRegionArenaHeros','iter_90_1.total_kill / iter_90_1.total_fight','iter_90_1.total_damage / iter_90_1.total_fight']:assert fact in window,fact
 callers=[n for n in z.namelist() if n.endswith('.lua') and n.startswith('app-assets/output/assets/src_64/app/') and ':getRecordInfo(' in z.read(n).decode('utf-8-sig','ignore')]
 assert callers==[],callers
element=go('internal/application/elementequipment/transitions.go')+go('internal/application/elementequipment/service.go')
assert 'h.Color != 16' in element and 'max_hero_color' not in element and 'MaxHeroColor' not in element
records=go('internal/application/publicprofile/rich_records.go')
for fact in ['"arena_performance"','"super_arena_performance"','"region_arena_performance"','"partners_info"','"partner_info"','"king_coin"','"win_fight"','"win_times"','"total_kill"','"total_damage"','sub != 2']:assert fact in records,fact
print('I7C-E SOURCE ORACLE: PASS MAX_HERO_COLOR=16 and the Element gate reads hero colour 16 (product drops max_color); 1829 HISTORY ARENA/SUPER_ARENA/REGION_ARENA keys, rank|king_coin, win_fight|win_times, partners_info|partner_info and per-partner kill/damage averages match the product; getRecordInfo has no caller so BATTLE_RECORD stays fail closed. Omitted unranked rank, dropped unowned partners and season Lord points are private display policy.')
