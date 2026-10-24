#!/usr/bin/env python3
from pathlib import Path
from collections import defaultdict
import hashlib, itertools, json, sys
ROOT=Path(__file__).resolve().parents[1]
CATALOG=ROOT/'internal/content/builtin/generated/practice_catalog.json'
def source_like(applied, rows, family):
    awards={}
    for row in sorted(rows,key=lambda x:x['ordinal']):
        i=row['ordinal']-1
        if applied[i] >= row['need_value']:
            t=row['target_attr_type']; b=row['bonus_value']
            if family=='HERO': awards[t]=awards.get(t,0)+b
            elif family=='PET': awards[t]=b
            else: raise ValueError(family)
    out={1:applied[0],2:applied[1],3:applied[2]}
    for t,b in awards.items():
        if t>0: out[t]=out.get(t,0)+b
    return [(k,v) for k,v in sorted(out.items()) if k>0 and v!=0]
def candidate_like(applied, rows, family):
    if len(rows)!=3 or [r['ordinal'] for r in rows] != [1,2,3]: raise ValueError('bad ordinal set')
    awards={}
    for i,row in enumerate(rows):
        if applied[i] < row['need_value']: continue
        t,b=row['target_attr_type'],row['bonus_value']
        if t<=0 or b==0: continue
        if family=='HERO': awards[t]=awards.get(t,0)+b
        else: awards[t]=b
    totals={}
    for i,v in enumerate(applied,1):
        if v: totals[i]=v
    for t,b in awards.items(): totals[t]=totals.get(t,0)+b
    return sorted((k,v) for k,v in totals.items() if v)
def vals(n):
    out={0,200,n}
    if n>0: out.add(n-1)
    if n<200: out.add(n+1)
    return sorted(x for x in out if 0<=x<=200)
d=json.load(open(CATALOG)); checks=0; examples=[]
for key,fam,idkey in [('hero_thresholds','HERO','hero_table_id'),('pet_thresholds','PET','pet_table_id')]:
    by=defaultdict(list)
    for r in d[key]: by[r[idkey]].append(r)
    for tid,rows in sorted(by.items()):
        rows=sorted(rows,key=lambda r:r['ordinal'])
        for applied in itertools.product(*(vals(r['need_value']) for r in rows)):
            a=source_like(applied,rows,fam); b=candidate_like(applied,rows,fam)
            if a!=b: print('mismatch',fam,tid,applied,a,b); sys.exit(1)
            checks+=1
        if fam=='HERO' and tid==10001003:
            examples.append({'family':fam,'table_id':tid,'applied':[200,200,200],'result':candidate_like((200,200,200),rows,fam)})
synthetic=[{'ordinal':1,'need_value':10,'target_attr_type':1,'bonus_value':100},{'ordinal':2,'need_value':10,'target_attr_type':1,'bonus_value':250},{'ordinal':3,'need_value':10,'target_attr_type':4,'bonus_value':50}]
res=candidate_like((10,10,10),synthetic,'PET')
if res != [(1,260),(2,10),(3,10),(4,50)]: print('synthetic pet mismatch',res); sys.exit(1)
examples.append({'family':'PET','synthetic_duplicate':True,'result':res})
zero=[{'ordinal':1,'need_value':0,'target_attr_type':0,'bonus_value':0},{'ordinal':2,'need_value':0,'target_attr_type':0,'bonus_value':0},{'ordinal':3,'need_value':0,'target_attr_type':0,'bonus_value':0}]
if candidate_like((5,6,7),zero,'HERO') != [(1,5),(2,6),(3,7)]: sys.exit(1)
checks+=1
raw=json.dumps({'checks':checks,'examples':examples},sort_keys=True,separators=(',',':')).encode()
out={'status':'GREEN','boundary_vectors_checked':checks,'examples':examples,'result_sha256':hashlib.sha256(raw).hexdigest()}
print(json.dumps(out,indent=2))
if checks != 35615: sys.exit(1)
