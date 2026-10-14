from decimal import Decimal
RESOURCE_KEYS={1:'mana',11:'magic_dust',12:'magic_liquid',13:'magic_energy',14:'magic_exp'}
def build_book(blobs,parse,items):
 items={int(x['id']):x for x in items}
 def rows(n):return parse(blobs['data/tables/event_centre_'+n+'.lua'].data)
 def vec(s):return [int(x)for x in s.split('|')if x and x!='0']
 def costs(ids,nums):
  out={};pages=0
  a=[int(x)for x in ids.split('|')];b=[int(x)for x in nums.split('|')];assert len(a)==len(b)
  for rid,num in zip(a,b):
   if num==0:continue
   assert num>0
   if rid==-1:pages+=num
   else:out[RESOURCE_KEYS[rid]]=out.get(RESOURCE_KEYS[rid],0)+num
  return out,pages
 buildings=[]
 for name,typ in [('cabinet',1),('recycle',3),('bookshelf',4)]:
  for r in rows(name):
   cost,page=costs(r['resources_id'],r['resources_num']);assert page==0
   attr=r.get('attribute','0|0|0').split('|');assert len(attr)==3
   buildings.append(dict(Type=typ,Level=int(r['id']),Duration=int(r['time']),RequiresType=int(r.get('type_request',r.get('function_request','0'))),RequiresLevel=int(r['function_request_level']),CutTime=int(r.get('cut_time','0')),UpperLimit=int(r.get('upper_limit','0')),Resources=cost,Attributes=attr))
 books=[]
 for r in rows('cabinetbook'):
  item=items[int(r['id'])];pieces=int(r['piece']);count=0
  if pieces:
   if item['compose']==r['piece']:
    count=int(item['compose_num']);assert count>0
   else:
    assert int(r['id']) in (130001020,130001021) and item['compose']=='0' and item['compose_num']=='0'
    # User-qualified C2D_FRAGMENT_RECIPES_V1 resolves the two missing book recipes.
    fragment=items[int(r['piece'])];assert fragment['compose_item']==r['id']
    count=int(fragment['item_num']);assert count=={130001020:40,130001021:45}[int(r['id'])]
  books.append(dict(ID=int(r['id']),Star=int(r['star']),Type=int(r['type']),Piece=pieces,PieceCount=count,SkillPage=int(r['skillpage']),Skills=vec(r['skill_id'])))
 skills=[]
 for r in rows('cabinetskill'):
  assert Decimal(r['attr_values']).is_finite()
  skills.append(dict(ID=int(r['id']),Book=int(r['skillbook']),Partner=int(r['partner']),CostClass=int(r['cost_res_type']),AttrID=int(r['attr_ids']),ActionType=int(r['action_type']),Value=r['attr_values'],Times=[int(x)for x in r['time'].split('|')],Prerequisites=vec(r['last_skill'])))
 costrows=[]
 for r in rows('skillcost'):
  for cls in range(1,5):
   costs0,page=costs(r['cost_res_type'+str(cls)],r['cost_res_num'+str(cls)])
   costrows.append(dict(Level=int(r['id']),Class=cls,Resources=costs0,Pages=page))
 return dict(schema_version=1,recipe_policy_id='C2D_FRAGMENT_RECIPES_V1',policy_id='C2D_V1_BUILDING_SEEDS_AND_JOB_REFUNDS_V1',buildings=buildings,books=books,skills=skills,costs=costrows)
