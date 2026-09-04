#!/usr/bin/env python3
from __future__ import annotations
import argparse, hashlib, json, re
from pathlib import Path
EXPECTED={
'app/model/SelfPlayer.lua':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
'app/model/Task.lua':'d454ae7cb1e28d95d366aae30ba88d83432c974415f263991af6c4190d54bee5',
'app/windows/TaskAwakeCell.lua':'ff133e4afc528f2c5a31e2ec51a88f3ac9e1d3ab6b137f8ddbdff3dec7671ff6',
'app/windows/ItemComposeWindow.lua':'ec5c0d3eb769b512e3bfa98db2f3c41a88c9c40d8a2eb85f146da53acf6b092e',
'app/windows/FragmentMake.lua':'56dc888e894f7a14131cec70300ff10c7b2de8cf3aa0e7a3ab7fd01bb1f05d28',
'app/common/network/Backend.lua':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840',
'data/tables/misc.lua':'058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a',
'data/tables/item.lua':'59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc',
'data/tables/awaken_mission.lua':'fdbcaf96386a7aa775c23b071bfe9952ef6acfc57982d17300b8308417fdb123',
'data/tables/bloodline_mission.lua':'b773cd8ebb0936c76c7ad0727a5d9efa67e87b748f508c3cd66147f075b81299',
}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def req(c,m):
    if not c: raise AssertionError(m)
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--src-root',type=Path,required=True); ap.add_argument('--data-root',type=Path,default=Path(__file__).resolve().parents[1]/'data'); a=ap.parse_args(); root=a.src_root
    req(sum(1 for p in root.rglob('*') if p.is_file())==4370,'src64 census')
    for rel,h in EXPECTED.items(): req(sha(root/rel)==h,f'hash drift {rel}')
    task=(root/'app/model/Task.lua').read_text(errors='replace'); player=(root/'app/model/SelfPlayer.lua').read_text(errors='replace'); backend=(root/'app/common/network/Backend.lua').read_text(errors='replace'); misc=(root/'data/tables/misc.lua').read_text(errors='replace')
    req('TASK_AWAKE_OPEN' in task and 'TASK_AWAKE_GIVE_UP' in task and 'getAwakeItem' in task,'awake wire callbacks')
    req('getBackpack():addItem(var_42_0)' in player and 'removeItem(var_42_3)' in player,'MID83 local stack callback')
    req('extra_drops_' in backend and 'handleRewards(arg_36_1.extra_drops_)' in backend,'extra drops ordering consumer')
    m=re.search(r'"awake_item_wish_not",\s*"([0-9|]+)"',misc); req(m is not None,'wish blacklist source')
    wish={int(v) for v in m.group(1).split('|')}
    policy=json.load(open(a.data_root/'awakening_compatibility_policy.json'))
    req(wish==set(policy['wish_bottle']['blacklisted_intermediate_items']),'wish blacklist drift')
    req(len(policy['event_entitlements'])==18,'event entitlement census')
    src=json.load(open(a.data_root/'awakening_source_catalog.json')); meta=json.load(open(a.data_root/'hero_equipment_meta.json'))['items']
    for row in policy['event_entitlements']:
        routes=src['ordinary_stage1_routes' if row['awake_type']==1 else 'blood_stage1_routes']; route=routes[str(row['mission_id'])]
        req(route['route_class']=='EVENT_OUTLIER','event classification drift')
        gear=int(row['exclusive_gear_item']); req(gear==int(route['exclusive_gear_item']),'event gear drift')
        req(int(meta[str(gear)]['compose'][0])==int(row['intermediate_item']),'event intermediate recipe drift')
    print(json.dumps({'pass':'206.0','stage':'P2-B','status':'PASS','src64_file_count':4370,'verified_source_files':len(EXPECTED),'event_entitlements':18,'wish_blacklist':11,'extra_drops_table_id_shape_source_confirmed':True,'mid83_local_stack_callback_confirmed':True},indent=2,sort_keys=True)); return 0
if __name__=='__main__': raise SystemExit(main())
