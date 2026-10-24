def build_spirit(blobs,parse,items):
 t={new:parse(blobs['data/tables/'+old+'.lua'].data)for new,old in [('models','spirit'),('equipment','spirit_equip'),('strengthen','spirit_strth'),('suits','spirit_suit'),('campaign','spirit_campaign')]}
 t['misc']=[r for r in parse(blobs['data/tables/misc.lua'].data)if 'spirit' in r['key'].lower()or 'hunqi' in r['key'].lower()]
 t['function']=[r for r in parse(blobs['data/tables/function.lua'].data)if r['id']=='99']
 ids={r['item_id']for r in t['equipment']};t['items']=[r for r in items if r['id']in ids]
 return dict(schema_version=1,policy_id='C2H_SPIRIT_SOURCE_V1',tables=t)
