#!/usr/bin/env python3
from pathlib import Path
import zipfile,hashlib,sys,re
root=Path(__file__).resolve().parents[1]; base=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')
arc=next(iter(sorted(base.glob('all-assest-rechecked-1*.zip'))),None); errs=[]
if not arc: print('I3 ORACLE BOOTSTRAP CHECK: FAIL\n - current src_64 archive missing');sys.exit(1)
want={
'app-assets/output/assets/src_64/app/scenes/LoadingScene.lua':'01c0e71ceee0f08f747552af66bd0f907ebfff1257be58ec480d3606a88f4a17',
'app-assets/output/assets/src_64/app/windows/LoginWindow.lua':'8b91542e1f0648a2a859e9618a8a9c64dd46f9961fb8a049d0b06ce2cabec7e0',
'app-assets/output/assets/src_64/app/windows/RegionWindow.lua':'37ce8b7ee2751e628549529cc96160cf3e2e208142a0fe8ebcb54c6d945f870d',
'app-assets/output/assets/src_64/app/windows/SwitchItem.lua':'f2267637840195814d7e526d80f4159ade02ebd6edca1048aa976434ae6c5a30',
'app-assets/output/assets/src_64/app/common/utils.lua':'6e56c7342e889d7ae8d41fe47cb06f66832227efe702f3863f693ee7ba84ffad',
'app-assets/output/assets/src_64/app/common/network/Backend.lua':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840'}
with zipfile.ZipFile(arc) as z:
 txt={}
 for n,h in want.items():
  b=z.read(n); got=hashlib.sha256(b).hexdigest();
  if got!=h:errs.append(f'hash drift {n}: {got}')
  txt[n]=b.decode(errors='replace')
load=txt[next(n for n in txt if n.endswith('/LoadingScene.lua'))]; login=txt[next(n for n in txt if n.endswith('/LoginWindow.lua'))]; region=txt[next(n for n in txt if n.endswith('/RegionWindow.lua'))]; switch=txt[next(n for n in txt if n.endswith('/SwitchItem.lua'))]; utils=txt[next(n for n in txt if n.endswith('/utils.lua'))]; back=txt[next(n for n in txt if n.endswith('/Backend.lua'))]
checks=[('MID1 sid','sid = arg_29_1.sid' in load),('MID1 login_token','login_token = arg_29_0.token' in load),('MID1 region','region = arg_29_1.region.region_id' in load),('MID1 is_new','isNew = tonumber(arg_30_1.is_new)' in load),('MID18','LOAD_USER_REGIONS' in login),('current fresh index 4','var_2_1 = var_2_0[4]' in login),('region full predicate','max_player_id <= var_8_13.cur_id' in region),('existing owner exemption','not arg_8_0:haveCharactorsInRegion(arg_9_0.region_id)' in region),('player region formula','math.floor(tonumber(arg_169_0) / var_169_0)' in utils and 'var_169_0 = 100000' in utils),('switch reset','removeAllEventListeners' in switch and 'ServerTime.get():reset()' in switch),('backend stores MID1 token','arg_23_0.token_ = arg_27_0.token' in back and 'arg_23_0.region_ = arg_27_0.region' in back)]
for label,ok in checks:
 if not ok:errs.append('source fact missing '+label)
if errs:
 print('I3 ORACLE BOOTSTRAP CHECK: FAIL');[print(' -',x) for x in errs];sys.exit(1)
print('I3 ORACLE BOOTSTRAP CHECK: PASS');print('verified current MID18/MID1 selection, full/existing-owner gate, player-region formula, stock switch teardown and token replacement')
