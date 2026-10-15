def build_inscription(blobs,parse,items):
 names={'inscription':'inscription','suits':'inscription_suit','positions':'inscription_pos','rates':'inscription_rate'}
 tables={k:parse(blobs['data/tables/'+n+'.lua'].data)for k,n in names.items()}
 ids={i for r in tables['inscription']for i in r['item_id'].split('|')}
 tables['items']=[r for r in items if r['id']in ids]
 keys={'remove_inscript_cost','treasure_inscript_param','treasure_inscript_item1','treasure_inscript_item2','treasure_inscript_item3','inscript_cost_items','drop_suit_inscript_lev','inscript_drop_suit_id','inscript_drop_suit_rate'}
 tables['misc']=[r for r in parse(blobs['data/tables/misc.lua'].data)if r['key']in keys]
 tables['exchange_materials']=[r for r in items if r['id']in ['50001343','50001344','50001345']]
 assert len(tables['items'])==240 and len(tables['inscription'])==23
 return dict(schema_version=1,policy_id='C2F_RECONSTRUCTION_V1',tables=tables)
