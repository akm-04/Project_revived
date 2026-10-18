"""Source achievement tier definitions; producer coverage is explicit, never inferred from visibility."""
def build_achievement(blobs,parse):
 rows=[]
 for r in parse(blobs['data/tables/achievement.lua'].data):
  rows.append(dict(id=int(r['id']),thresholds=[int(x) for x in r['condition'].split('|')],points=[int(x) for x in r['points'].split('|')],daily=int(r['is_daily_update']),hidden=int(r['is_hide']),stamp=int(r['stamp'])))
 rows.sort(key=lambda r:r['id'])
 if [r['id']for r in rows]!=list(range(100001,100034)):raise ValueError('achievement source ids drift')
 if next(r for r in rows if r['id']==100014)['thresholds']!=[1,10,20]:raise ValueError('selected achievement thresholds drift')
 return dict(schema_version=1,policy_id='C4B_MARRIED_POPULATION_TIER_FACTS_V1',selected_id=100014,rows=rows)
