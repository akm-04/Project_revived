#!/usr/bin/env python3
from __future__ import annotations
import argparse,hashlib,json
from pathlib import Path
EXPECTED={
'app/model/NormalHero.lua':'125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9',
'app/windows/EquipConfirmWindow.lua':'f2f6c388d61ee1afdbf3bcebb8bc8e5c424742b176ece1ebfdb8c10a1ad8bfe9',
'app/windows/TaskAwakeCell.lua':'ff133e4afc528f2c5a31e2ec51a88f3ac9e1d3ab6b137f8ddbdff3dec7671ff6',
'app/model/Task.lua':'d454ae7cb1e28d95d366aae30ba88d83432c974415f263991af6c4190d54bee5',
'app/common/network/Backend.lua':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840',
'app/common/tables/HeroTable.lua':'5293207486e52a8dad959b48ea0c90680a335e9144c362d5e9b342b9fd6cef60',
'data/tables/item.lua':'59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc',
'data/tables/awaken_mission.lua':'fdbcaf96386a7aa775c23b071bfe9952ef6acfc57982d17300b8308417fdb123',
'data/tables/bloodline_mission.lua':'b773cd8ebb0936c76c7ad0727a5d9efa67e87b748f508c3cd66147f075b81299',
}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def req(c,m):
    if not c:raise AssertionError(m)
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--src-root',type=Path,required=True);ap.add_argument('--data-root',type=Path,default=Path(__file__).resolve().parents[1]/'data');a=ap.parse_args();root=a.src_root
    req(sum(1 for p in root.rglob('*') if p.is_file())==4370,'src64 census')
    for rel,h in EXPECTED.items():req(sha(root/rel)==h,f'hash drift {rel}')
    normal=(root/'app/model/NormalHero.lua').read_text(errors='replace');confirm=(root/'app/windows/EquipConfirmWindow.lua').read_text(errors='replace');cell=(root/'app/windows/TaskAwakeCell.lua').read_text(errors='replace');backend=(root/'app/common/network/Backend.lua').read_text(errors='replace')
    req('isInAwakingPeriod() or arg_149_0:isAwaken()' in normal and 'isAwakeTwiceItem(arg_149_0:getEquipByIndex(iter_150_0):getTableID()) == 0' in normal,'MID51 special preserve source')
    req('isInAwakingPeriod() or arg_151_0:isAwaken()' in normal and 'isAwakeTwiceItem(arg_151_0:getEquipByIndex(iter_152_0):getTableID()) == 0' in normal,'MID57 special preserve source')
    req('awakeTwiceStage() > var_0_2.AwakeTwiceStage.STAGE_ONE' in normal,'canonical Blood gear stage boundary')
    req('awakeTwiceStage_ > var_0_2.AwakeTwiceStage.UNSTART' in normal,'Blood display substitution stage boundary')
    eq_start=normal.index('function var_0_3.equipItems');eq_end=normal.index('function var_0_3.isHasItem',eq_start);eq=normal[eq_start:eq_end]
    req('getEquipByIndex(arg_157_1):setCollected()' in eq and 'var_158_0:removeItem(var_158_2)' in eq,'MID54 canonical callback/remove behavior')
    stage_start=normal.index('function var_0_3.setAwakeTwiceStage');stage_end=normal.index('function var_0_3.canEnvolve',stage_start);stage_fn=normal[stage_start:stage_end]
    req('totalEquipList_' not in stage_fn,'stage update unexpectedly invalidates equip cache')
    req(confirm.index('var_18_1:equipItems') < confirm.index('var_18_1.totalEquipList_ = nil'),'EquipConfirm cache invalidation ordering')
    req('arg_37_0.task:getTaskReward(arg_37_0.tableID, xyd.TaskType.AWAKE)' in cell and 'arg_40_0.task:getTaskReward(arg_40_0.tableID, xyd.TaskType.AWAKE' in cell,'stage claim MID161 source')
    req('twice_awake_stage_' in backend and 'onUpdateTwiceAwakeStage(arg_36_1.twice_awake_stage_)' in backend,'Blood stage projection source')

    src=json.load(open(a.data_root/'awakening_source_catalog.json'));meta=json.load(open(a.data_root/'hero_equipment_meta.json'));items=meta['items'];partners=meta['partners']
    def flagged_special(i):
        r=items.get(str(i),{});return int(r.get('is_awaken_item',0) or 0)>0 or int(r.get('is_bloodline_item',0) or 0)>0
    ordinary_bad=[];ordinary_slots=set()
    for mid,r in src['ordinary_stage1_routes'].items():
        gear=int(r['exclusive_gear_item']);eq=partners[str(r['origin_table_id'])]['equip_lists'];found=set()
        for lst in eq.values():
            for idx,item in enumerate(lst,1):
                if int(item)==gear:found.add(idx)
        if found!={1}:ordinary_bad.append((mid,sorted(found)))
        ordinary_slots|=found
    req(not ordinary_bad and len(src['ordinary_stage1_routes'])==164,'ordinary special slot census')
    blood_bad=[];blood_slots=set()
    for mid,r in src['blood_stage1_routes'].items():
        eq=partners[str(r['origin_table_id'])]['equip_lists'];found=set()
        for lst in eq.values():
            for idx,item in enumerate(lst,1):
                if flagged_special(int(item)):found.add(idx)
        if found!={1}:blood_bad.append((mid,sorted(found)))
        blood_slots|=found
    req(not blood_bad and len(src['blood_stage1_routes'])==81,'Blood lineage slot census')
    anomalies=[]
    for mid,r in src['blood_stage1_routes'].items():
        gear=int(r['exclusive_gear_item']);row=items[str(gear)]
        if int(row.get('is_bloodline_item',0) or 0)<=0:anomalies.append((int(mid),gear))
    req(anomalies==[(2166001,21001080)],f'Blood flag anomaly drift {anomalies}')
    print(json.dumps({'pass':'207.0','stage':'P2-C','status':'PASS','src64_file_count':4370,'verified_source_files':len(EXPECTED),'ordinary_stage1_slot1_routes':164,'blood_stage1_lineage_slot1_routes':81,'reo_unflagged_blood_gear':[2166001,21001080],'blood_mid54_client_cache_anomaly_source_confirmed':True,'promotion_selective_preserve_source_confirmed':True},indent=2,sort_keys=True));return 0
if __name__=='__main__':raise SystemExit(main())
