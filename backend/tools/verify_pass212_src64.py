#!/usr/bin/env python3
"""Pass212 Stage G final P2 effective-src64 reality verifier."""
from __future__ import annotations
import argparse,hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
EXPECTED_FILES=4370
EXPECTED={
'app/model/Task.lua':'d454ae7cb1e28d95d366aae30ba88d83432c974415f263991af6c4190d54bee5',
'app/windows/BackpackWindow.lua':'48b18493fed4186541fc989a8ef60d6338d444c4e8a0fc986903a57e52ff19c1',
'app/model/SelfPlayer.lua':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
'app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
'app/windows/TaskAwakeCell.lua':'ff133e4afc528f2c5a31e2ec51a88f3ac9e1d3ab6b137f8ddbdff3dec7671ff6',
'app/windows/ItemComposeWindow.lua':'ec5c0d3eb769b512e3bfa98db2f3c41a88c9c40d8a2eb85f146da53acf6b092e',
'app/model/Occult.lua':'748c6b2606fdbd0ee434f87b6761a8391df9c5236ccee110e302281651ab2b47',
'app/windows/OccultWindow.lua':'b26e7a420045e5e2ad3ebf1c7464fe312ce10b9813199367dd6b517f2a2e78d7',
}
def require(v,m):
    if not v:raise AssertionError(m)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--src-root',type=Path,required=True);ap.add_argument('--data-root',type=Path,default=ROOT/'data');ns=ap.parse_args()
    src=ns.src_root.resolve();data=ns.data_root.resolve();files=[p for p in src.rglob('*') if p.is_file()]
    require(len(files)==EXPECTED_FILES,f'src64 census {len(files)} != {EXPECTED_FILES}')
    for rel,h in EXPECTED.items():require(sha(src/rel)==h,f'hash drift {rel}')
    task=(src/'app/model/Task.lua').read_text(encoding='utf-8-sig');bag=(src/'app/windows/BackpackWindow.lua').read_text(encoding='utf-8-sig');sp=(src/'app/model/SelfPlayer.lua').read_text(encoding='utf-8-sig');mids=(src/'app/common/network/mid.lua').read_text(encoding='utf-8-sig');occ=(src/'app/model/Occult.lua').read_text(encoding='utf-8-sig')
    require(re.search(r'xyd\.mid\.GET_AWAKE_ITEM\s*=\s*171',mids),'MID171 id drift')
    require('item_num = 1' in task and 'xyd.mid.GET_AWAKE_ITEM' in task and 'getBackpack():removeItem' in task,'Task MID171 callback drift')
    require('xyd.mid.GET_AWAKE_ITEM' in bag and 'arg_39_1.item_id' in bag and 'arg_39_1.item_num' in bag and 'addItemsByID' in bag,'Backpack MID171 response consumer drift')
    require('getGiveUpDelItems' in task and ':delItem(iter_18_1)' in task,'Give Up full-stack client deletion drift')
    require(re.search(r'xyd\.mid\.POWERUP_HERO\s*=\s*51',mids) and re.search(r'xyd\.mid\.ONE_CLICK_JINJIE\s*=\s*57',mids),'MID51/57 ids drift')
    require('xyd.mid.POWERUP_HERO' in sp and 'xyd.mid.ONE_CLICK_JINJIE' in sp,'MID51/57 client callers drift')
    require(re.search(r'xyd\.mid\.OPEN_PET_AWAKE_MISSION\s*=\s*165',mids) and re.search(r'xyd\.mid\.GIVE_UP_PET_AWAKE_MISSION\s*=\s*166',mids),'Pet Awake source surfaces drift')
    require(re.search(r'xyd\.mid\.OCCULT_SWEEP\s*=\s*2385',mids) and 'xyd.mid.OCCULT_SWEEP' in occ,'minimal Occult sweep source drift')
    aw=json.loads((data/'awakening_source_catalog.json').read_text());comp=json.loads((data/'awakening_compatibility_policy.json').read_text());contracts=json.loads((data/'mutation_contract_registry.json').read_text())
    require(aw['counts']['ordinary_stage1']==164 and aw['counts']['blood_stage1']==81,'Awakening root census drift')
    require((aw['counts']['ordinary_route_campaign'],aw['counts']['ordinary_route_occult'],aw['counts']['ordinary_route_event_outlier'])==(131,22,11),'ordinary route partition drift')
    require((aw['counts']['blood_route_campaign'],aw['counts']['blood_route_event_outlier'])==(74,7),'Blood route partition drift')
    ordinary=aw['ordinary_stage1_routes'];blood=aw['blood_stage1_routes']
    require(sum(not v.get('delete_items') for v in ordinary.values())==12 and sum(not v.get('delete_items') for v in blood.values())==7,'Give Up no-list census drift')
    require({int(k):v['delete_items'] for k,v in ordinary.items() if int(k) in {1038001,1109001,1125001,1197001}}=={
      1038001:[50001164,60001099],1109001:[50001185,60001102],1125001:[50001452,20001291],1197001:[50001544,60001202]},'Give Up anomaly drift')
    require(len(comp['event_entitlements'])==18 and len(comp['wish_bottle']['blacklisted_intermediate_items'])==11,'compatibility policy census drift')
    c171=next(r for r in contracts['contracts'] if int(r['mid'])==171);require(c171['enforcement']=='ALLOW_DURABLE' and c171['backend_capability']=='DURABLE_MUTATION','MID171 Stage-G fence retirement drift')
    for pmid in (165,166,823):
      row=next(r for r in contracts['contracts'] if int(r['mid'])==pmid);require(row['enforcement']=='BLOCK_PHASE1' and row['backend_capability']=='EXPLICIT_FAIL_CLOSED',f'Pet fence drift {pmid}')
    report={'pass':'212.0','stage':'P2_STAGE_G_FINAL_REALITY','status':'PASS','effective_src64':str(src),'effective_src64_file_count':len(files),'source_hashes':EXPECTED,'route_census':{'ordinary':164,'blood':81,'ordinary_campaign':131,'ordinary_occult':22,'ordinary_event':11,'blood_campaign':74,'blood_event':7},'giveup':{'no_list_ordinary':12,'no_list_blood':7,'source_anomalies':4},'fence_reality':{'mid171':'ALLOW_DURABLE','mid51_mid57':'ACTIVE_SOURCE_CALLERS_NO_P2_FIREWALL','pet_awake':'PRESERVE_FAIL_CLOSED','full_occult':'PRESERVE_MINIMAL_ONLY'},'evidence':{'mid171_callback':'SOURCE_FACT','giveup_full_stack':'SOURCE_FACT','nonce_less_mid171_exactly_once':'PROTOCOL_LIMIT','event_entitlements':'COMPATIBILITY_POLICY','occult_fragment_yield':'COMPATIBILITY_POLICY'}}
    (ROOT/'PASS212_SRC64_REALITY_CHECK.json').write_text(json.dumps(report,indent=2,sort_keys=True)+'\n')
    print('PASS Pass212 final src_64 reality:',json.dumps({'files':len(files),'ordinary':164,'blood':81,'no_delete':19,'mid171':'ALLOW_DURABLE'},sort_keys=True))
if __name__=='__main__':main()
