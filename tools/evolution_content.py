def build_evolution(blobs,parse,parse_indexed,field):
 heroes=[]
 for name,kind in [('partner','NORMAL'),('super_partner','SUPER')]:
  keys,rows=parse_indexed(blobs['data/tables/'+name+'.lua'].data)
  for row_id,values in sorted(rows.items()):
   r={key:field(keys,values,key,row_id=row_id)for key in ['id','stone_id','stone_ticket']}
   r['kind']=kind;heroes.append(r)
 return dict(schema_version=1,policy_id='C2I_STONE_SOURCE_V1',tables=dict(stages=parse(blobs['data/tables/stone_evolution.lua'].data),tickets=parse(blobs['data/tables/stone_ticket.lua'].data),heroes=heroes))
