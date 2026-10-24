#!/usr/bin/env python3
"""Exact source provenance + complete-vector negative compiler fixtures."""
import sys,json,copy,hashlib
from pathlib import Path
import generate_builtin_content as compiler
source=Path(sys.argv[1])/'all-assest-rechecked-1.zip'
if hashlib.sha256(source.read_bytes()).hexdigest()!='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf':raise SystemExit('source identity mismatch')
b=compiler.SourceArchive(source).read_verified()
g=compiler.parse_generated_lua_table(b['data/tables/gift.lua'].data);d=compiler.parse_generated_lua_table(b['data/tables/friend_dailygift.lua'].data)
out=compiler.build_social_gift(g,d,10,10)
checked=json.loads((Path(__file__).resolve().parents[1]/'internal/content/builtin/generated/social_gift_catalog.json').read_text());assert out==checked
fixtures=[]
for label in ['one_amount','uniform_amount','side_currency','missing_dimension','unknown_dimension','missing_level','duplicate_level','duplicate_mapping','cap']:
 gg=copy.deepcopy(g);dd=copy.deepcopy(d);sc=10
 selected={r['gift_id'] for r in d}
 if label=='one_amount':next(r for r in gg if r['id'] in selected)['friendship_coin']='6'
 if label=='uniform_amount':
  for r in gg:
   if r['id'] in selected:r['friendship_coin']='6'
 if label=='side_currency':next(r for r in gg if r['id'] in selected)['mana']='1'
 if label=='missing_dimension':next(r for r in gg if r['id'] in selected).pop('drops')
 if label=='unknown_dimension':next(r for r in gg if r['id'] in selected)['guess']='0'
 if label=='missing_level':dd.pop()
 if label=='duplicate_level':dd[-1]['level']=dd[0]['level']
 if label=='duplicate_mapping':dd[-1]['gift_id']=dd[0]['gift_id']
 if label=='cap':sc=11
 try:compiler.build_social_gift(gg,dd,sc,10)
 except compiler.CompileError:fixtures.append(label)
 else:raise AssertionError('mutation accepted: '+label)
print(json.dumps({'status':'PASS','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'full_vectors':100,'negative_fixtures':fixtures,'evidence_class':'EXACT_STATIC_SOURCE_AND_COMPILER_MUTATION_NOT_ORIGINAL_SERVER_OR_PHYSICAL_CLIENT'},indent=2))
