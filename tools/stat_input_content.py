"""Source numeric inputs only; no owner or public-output qualification."""
def build_stat_inputs(blobs,parse,indexed,field,items,skills):
 tables={}
 tables['item']=[{k:r.get(k,'')for k in ['id','attr_ids','attr_values','is_awaken_item','fumo','fumo_value1','fumo_value2','fumo_value3','fumo_value4','fumo_value5']}for r in items(blobs['data/tables/item.lua'].data)]
 colors=['white','green','green1','blue','blue1','blue2','purple','purple1','purple2','purple3','purple4','orange','orange1','orange2','red','red1']
 for n in ['partner','super_partner','pet']:
  keys,rows=indexed(blobs['data/tables/'+n+'.lua'].data)
  fields=['id','first_table_id','skill0']+(['equipment']if n=='super_partner'else colors)
  tables[n]=[{k:field(keys,v,k,row_id=i)if k in keys else ''for k in fields}for i,v in sorted(rows.items())]
 tables['skill']=[{k:r.get(k,'')for k in ['id','pet_star_type','desc4_num_step']}for i,r in sorted(skills(blobs['data/tables/skill.lua'].data).items())]
 tables['enhance']=[{k:r[k]for k in ['id','attr_incr_ratio']}for r in parse(blobs['data/tables/super_equip_enhance.lua'].data)]
 return dict(schema_version=1,policy_id='C3B_SRC64_NUMERIC_INPUT_V1',tables=tables)
