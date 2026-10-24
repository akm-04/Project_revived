"""Closed compiler for selected stat arithmetic; no Lua runtime or guessed imports."""
import ast,re,base64,csv,io

def build_stat_rules(blobs,parse,parse_indexed,field):
 def text(n):return blobs[n].data.decode('utf-8-sig').replace('\r\n','\n')
 constants={k:float(v)for k,v in re.findall(r'xyd\.(\w+)\s*=\s*(-?[\d.]+)',text('app/common/const.lua'))}
 enums={k:int(v)for k,v in re.findall(r'xyd.AttributeType\.(\w+)\s*=\s*(\d+)',text('app/common/enums.lua'))}
 models={}
 for model in ['NormalHero','SuperHero','Pet']:
  src=text('app/model/'+model+'.lua');fs={n:(sig,body)for n,sig,body in re.findall(r'^function var_0_3\.(\w+)\(([^\n]*)\)\n(.*?)(?=^function |\Z)',src,re.M|re.S)}
  def compile_expr(raw,env):
   raw=re.sub(r'var_0_\d+\.AttributeType\.(\w+)',lambda m:str(enums[m[1]]),raw)
   raw=re.sub(r'var_0_\d+\.([A-Z][A-Z_]+)',lambda m:str(constants[m[1]]),raw)
   raw=re.sub(r'(?:math|var_0_14)\.(floor|ceil|max)\(',r'\1(',raw)
   raw=re.sub(r'arg_\d+_0:', '',raw)
   raw=re.sub(r'var_0_\d+:getInitialAttr\(getTableID\(\),\s*', 'getInitialAttr(',raw)
   raw=re.sub(r'var_0_\d+:getHeroMainAttr\(getTableID\(\),\s*([^,]+),\s*getStar\(\),\s*getLevel\(\)\)',r'getBaseGrowth(\1)',raw)
   raw=re.sub(r'getGrowAttr\(getTableID\(\),\s*([^,]+),\s*getStar\(\),\s*getLevel\(\)\)',r'getGrowAttr(\1)',raw)
   raw=re.sub(r'var_0_\d+\.tables\.attr:attrScore\(', 'attrScore(',raw)
   def node(x):
    if isinstance(x,ast.Constant)and type(x.value)in [int,float]:return dict(op='number',value=x.value)
    if isinstance(x,ast.Name):
     if x.id not in env:raise ValueError('Unbound '+x.id+' in '+raw)
     return env[x.id]
    if isinstance(x,ast.BinOp):return dict(op={ast.Add:'add',ast.Sub:'sub',ast.Mult:'mul',ast.Div:'div'}[type(x.op)],args=[node(x.left),node(x.right)])
    if isinstance(x,ast.UnaryOp)and isinstance(x.op,ast.USub):return dict(op='sub',args=[dict(op='number',value=0),node(x.operand)])
    if isinstance(x,ast.Call)and isinstance(x.func,ast.Name):return dict(op='call',name=x.func.id,args=[node(a)for a in x.args])
    raise ValueError('Unsupported '+ast.dump(x)+' in '+raw)
   return node(ast.parse(raw,mode='eval').body)
  def method(n,attr):
   sig,body=fs[n];env={};params=sig.split(', ')
   if len(params)>1:env[params[1]]=dict(op='number',value=attr)
   conditional=False;active=True;matched=False
   for line in body.splitlines():
    line=line.strip()
    if not line or line=='end':continue
    if line.startswith(('if ','elseif ')):
     cond=line.split(' ',1)[1].removesuffix(' then');cond=re.sub(r'arg_\d+_1',str(attr),cond);cond=re.sub(r'var_0_\d+\.AttributeType\.(\w+)',lambda m:str(enums[m[1]]),cond)
     if not re.fullmatch(r'[\d\s<>=.]+',cond):raise ValueError('Unsupportedcondition '+cond)
     active=not matched and eval(cond,{'__builtins__':{}});matched=matched or active;conditional=True;continue
    if line=='else':active=not matched;continue
    if not active:continue
    m=re.fullmatch(r'local (var_\d+_\d+) = (.*)',line)
    if m:env[m[1]]=compile_expr(m[2],env);continue
    if line.startswith('return '):return compile_expr(line[7:],env)
    raise ValueError(model+' '+n+' unsupportedline '+line)
   return dict(op='number',value=0)
  names=['getMainAttr','getMaxHP','getAD','getAP','getHujia','getMokang','getADBaoji','skillAttr2HP','skillAttr2AD','skillAttr2AP','skillAttr2Hujia','skillAttr2Mokang','skillAttr2Baoji','getSkill2Attr','getTotalAttr','getZhandouli']
  if model!='Pet':names+=['getTotalAttrWithOutBook']
  # Pet lacks the sixth secondary skill helper: source getSkill2Attr explicitly returns0 for9.
  names=[n for n in names if n in fs]
  rules={n:[method(n,a)for a in range(1,50)]for n in names}
  if model=='SuperHero':
   assert re.search(r'return 0\s+end',fs['getEquipFumoAttr'][1])
   rules['getEquipFumoAttr']=[dict(op='number',value=0)for _ in range(49)]
  force={}
  for n in ['getEquipForce','getStoneEvolutionForce','getBookSkillForce','getConquerSchoolForce']:
   if n not in fs:continue
   body=fs[n][1];bound=22 if model=='Pet' else 49
   expr=re.search(r'var_\d+_0 = var_\d+_0 \+ (.*)',body)[1]
   it=re.search(r'for (iter_\d+_\d+) =',body)[1]
   terms=[compile_expr(expr,{it:dict(op='number',value=a)})for a in range(1,bound+1)]
   x=dict(op='number',value=0)
   for term in terms:x=dict(op='add',args=[x,term])
   force[n]=x
  models[model]=dict(rules=rules,force=force,basic_force_limit=22 if model=='Pet' else 49)
 templates=[]
 htext=text('app/common/tables/HeroTable.lua')
 amap=re.findall(r'\[var_0_1.AttributeType\.(\w+)\] = tonumber\(arg_117_1\[arg_117_2\.(\w+)\]\) or ([\d.]+)',htext)
 assert len(amap)==34,len(amap)
 for table,model in [('partner','NormalHero'),('super_partner','SuperHero'),('pet','Pet')]:
  keys,rows=parse_indexed(blobs['data/tables/'+table+'.lua'].data)
  for rid,values in sorted(rows.items()):
   def f(k):return field(keys,values,k,row_id=rid) if k in keys else ''
   initial=[0.0]*49
   for en,k,default in amap:initial[enums[en]-1]=float(f(k) or default)
   growth=[]
   if model=='SuperHero':
    for star in range(1,11):growth.append([float(v or 0)for v in f('star'+str(star)).split('|')])
   else:
    for star in range(1,6):growth.append([float(f(k+'_star'+str(star)) or 0)for k in ['liliang','zhili','minjie']])
   templates.append(dict(model=model,id=rid,hero_type=int(f('type')) if 'type' in keys else 0,initial=initial,growth=growth,init_power=float(f('init_power') or 0)if'init_power'in keys else 0,buff_skill=[int(v)for v in f('buff_skill').split('|')if v],slot_skills=[int((f('skill'+str(i)).split('|')[0])or 0)for i in range(1,7)]))
 raw=base64.b64decode(re.fullmatch(r'return\s+"([A-Za-z0-9+/=]+)"',text('data/tables/buff.lua').strip(),re.S)[1],validate=True).decode('utf-8').splitlines()
 headers=raw[1].split('\t');assert len(headers)==len(set(headers))
 buffs=[]
 for values in csv.reader(io.StringIO('\n'.join(raw[2:])),delimiter='\t'):
  assert len(values)==len(headers)
  row=dict(zip(headers,values));buffs.append(dict(id=row['id'],attr=row['attr'],init=row['init'],step=row['step_attr']))
 raw_skill=base64.b64decode(re.fullmatch(r'return\s+"([A-Za-z0-9+/=]+)"',text('data/tables/skill.lua').strip(),re.S)[1],validate=True).decode('utf-8').splitlines()
 skeys=raw_skill[1].split('\t');skills=[]
 for values in csv.reader(io.StringIO('\n'.join(raw_skill[2:])),delimiter='\t'):
  assert len(values)==len(skeys)
  r=dict(zip(skeys,values));skills.append({k:r[k]for k in ['id','skill_type','buffs','init_power','step_power']})
 artifact=dict(schema_version=1,policy_id='C3A_SRC64_MATERIALIZED_STAT_V1',models=models,constants=constants,templates=templates,attributes=parse(blobs['data/tables/attr.lua'].data),buffs=buffs,skills=skills,adapter_scope='STAT_ONLY_NO_ORIGINAL_SERVER_OR_COMBAT_PARITY')

 def canonical(x):
  if isinstance(x,float)and x.is_integer():return int(x)
  if isinstance(x,list):return[canonical(v)for v in x]
  if isinstance(x,dict):return{k:canonical(v)for k,v in x.items()}
  return x
 return canonical(artifact)
