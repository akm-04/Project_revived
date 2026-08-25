#!/usr/bin/env python3
"""Build Pass150 B4 synthetic EOL Recharge product metadata.

Synthetic charge/gift IDs and zero-cost distribution are compatibility policy.
Skin/item/model/skill and MID241 package capability are validated against the
already source-generated catalogs rebuilt from effective src_64.
"""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path

def sha(p:Path)->str:return hashlib.sha256(p.read_bytes()).hexdigest()
ELEMENTS=[
 (50001912,'ELEMENTAL_SELECT_ADV'),(50001913,'ELEMENTAL_SELECT_NOR'),
 (50009201,'ELEMENTAL_RANDOM_GENERAL_ADV'),(50009197,'ELEMENTAL_RANDOM_GENERAL_NOR'),
 (50009251,'ELEMENTAL_RANDOM_ADV_LIGHTNING'),(50009252,'ELEMENTAL_RANDOM_ADV_FIRE'),(50009253,'ELEMENTAL_RANDOM_ADV_WATER'),
 (50009254,'ELEMENTAL_RANDOM_NOR_LIGHTNING'),(50009255,'ELEMENTAL_RANDOM_NOR_FIRE'),(50009256,'ELEMENTAL_RANDOM_NOR_WATER'),
]
def main():
 ap=argparse.ArgumentParser(); ap.add_argument('--data-dir',type=Path,required=True); ap.add_argument('--output',type=Path,required=True); a=ap.parse_args()
 data=a.data_dir
 skins=json.loads((data/'skin_source_catalog.json').read_text())
 skin_by_item={int(r['skin_item_id']):r for r in skins['skins']}
 plan=json.loads((data/'recharge_eol_skin_plan.json').read_text())
 gifts=json.loads((data/'gift_opening_source_catalog.json').read_text())
 ops_by_item={}
 for op in gifts['operations']:ops_by_item.setdefault(int(op['item_id']),[]).append(op)
 if len(plan)!=262 or len(skin_by_item)!=262:raise RuntimeError('skin EOL census drift')
 skin_products=[]; charge_ids=set(); gift_ids=set()
 for row in plan:
  iid=int(row['skin_item_id']); src=skin_by_item.get(iid)
  if src is None:raise RuntimeError(f'planned skin item missing from canonical source {iid}')
  if int(row['girl_id']) not in {int(x) for x in src['accepted_hero_table_ids']} or int(row['model_id'])!=int(src['model_id']) or int(row['skin_skill_id'])!=int(src['skill_id']):
   raise RuntimeError(f'planned skin source drift {iid}')
  cid=int(row['charge_id']); gid=int(row['gift_id'])
  if not (97000001<=cid<=97000262 and 97100001<=gid<=97100262):raise RuntimeError('skin synthetic id range drift')
  if cid in charge_ids or gid in gift_ids:raise RuntimeError('duplicate synthetic skin id')
  charge_ids.add(cid);gift_ids.add(gid)
  skin_products.append({
   'product_kind':'SYNTHETIC_EOL_SKIN','charge_id':cid,'gift_id':gid,'page':3,'source_item_id':iid,
   'skin_partner_id':int(src['skin_partner_id']),'model_id':int(src['model_id']),'skin_skill_id':int(src['skill_id']),
   'display_name':str(row['display_name']),'charge_display':0,'original_charge_display':0,'diamond_display':0,
   'availability_policy':'OTA_1_631_9_PLUS_AND_IF_NOT_OWNED_NOT_TIMED_NOT_IN_BACKPACK_NOT_PREVIOUSLY_PURCHASED',
   'settlement_policy':'PHASE_C_ACTIVE_SKIN_AWARE_CANONICAL_COMMERCE_SETTLEMENT','price_policy':'ZERO_COST_NO_VIP_NO_CHARGE_NO_CRYSTAL_DELTA',
   'epistemic_class':'IMPLEMENTATION_COMPATIBILITY_DECISION',
  })
 element_products=[]
 for idx,(iid,family) in enumerate(ELEMENTS,1):
  ops=ops_by_item.get(iid,[])
  if not ops:raise RuntimeError(f'elemental package missing Gift Opening source {iid}')
  caps={str(o['capability']) for o in ops}; stats={str(o['status']) for o in ops}
  if not caps <= {'ORDINARY_CURRENT_OWNERS','ORDINARY_RANDOM_CURRENT_OWNERS'}:raise RuntimeError(f'elemental package deferred capability {iid}: {caps}')
  cid=97002000+idx;gid=97102000+idx
  if cid in charge_ids or gid in gift_ids:raise RuntimeError('synthetic EOL id collision')
  charge_ids.add(cid);gift_ids.add(gid)
  element_products.append({
   'product_kind':'SYNTHETIC_EOL_ELEMENTAL','charge_id':cid,'gift_id':gid,'page':2,'source_item_id':iid,'family':family,
   'gift_operation_count':len(ops),'gift_ids':[int(o['gift_id']) for o in ops],'gift_statuses':sorted(stats),'gift_capabilities':sorted(caps),
   'charge_display':0,'original_charge_display':0,'diamond_display':0,'availability_policy':'OTA_1_631_9_PLUS_REPEATABLE',
   'settlement_policy':'GRANT_ONE_SOURCE_PACKAGE_ITEM_THROUGH_CANONICAL_REWARD_OWNER','price_policy':'ZERO_COST_NO_VIP_NO_CHARGE_NO_CRYSTAL_DELTA',
   'epistemic_class':'IMPLEMENTATION_COMPATIBILITY_DECISION',
  })
 payload={'schema_version':1,'_meta':{'pass':'152.0','phase':'C_SYNTHETIC_EOL_RECHARGE_ACTIVE','activation':'RESOURCE_VERSION_GATED_AT_OTA_1_631_9_PLUS','skin_source_sha256':sha(data/'skin_source_catalog.json'),'skin_plan_sha256':sha(data/'recharge_eol_skin_plan.json'),'gift_opening_source_sha256':sha(data/'gift_opening_source_catalog.json')},'summary':{'skin_products':len(skin_products),'elemental_products':len(element_products),'total':len(skin_products)+len(element_products)},'skin_products':skin_products,'elemental_products':element_products}
 a.output.write_text(json.dumps(payload,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
 print(json.dumps(payload['summary'],indent=2))
if __name__=='__main__':main()
