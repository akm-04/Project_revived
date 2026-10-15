def build_element(blobs,parse,items):
 equipment=parse(blobs['data/tables/element_equip.lua'].data)
 strengthen=parse(blobs['data/tables/element_strth.lua'].data)
 ids={r['item_id']for r in equipment}|{'50001885','50001886'}|{str(i)for i in range(50000001,50000026)}
 return dict(schema_version=1,policy_id='C2G_ELEMENT_SOURCE_V1',tables=dict(equipment=equipment,strengthen=strengthen,items=[r for r in items if r['id']in ids]))
