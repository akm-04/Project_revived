#!/usr/bin/env python3
from pathlib import Path
import hashlib,os,sys,zipfile
R=Path(__file__).resolve().parents[1]; errs=[]
def req(x,msg):
    if not x: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
archive=Path(os.environ.get('GXB_R4A_SOURCE_ARCHIVE',''))
req(archive.is_file(),'exact source archive missing; set GXB_R4A_SOURCE_ARCHIVE')
expected={
 'app-assets/output/assets/src_64/app/model/Pet.lua':'214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660',
 'app-assets/output/assets/src_64/app/windows/PetMainWindow.lua':'fcebe7e4fa742d8a176c8da10502c410e5031720023369bebed01c7da3a99832',
 'app-assets/output/assets/src_64/app/common/network/Backend.lua':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840',
 'app-assets/output/assets/src_64/data/tables/pet.lua':'bc974045ec92fd7c0ebb2655d635d1b057eee7f74a871cfa2316b511ad55986e',
 'app-assets/output/assets/src_64/data/tables/item.lua':'59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc',
 'app-assets/output/assets/src_64/data/tables/partner_exp.lua':'55f3808decc768a40343aaed2d0c85a5beda34926fbb559970296d140871b39b',
 'app-assets/output/assets/src_64/data/tables/pet_exp.lua':'7ebc02c3ce25cd9048c516d958caa4277d04bfa289a71b14cfb6f2d9bfe9eb4f',
}
texts={}
if archive.is_file():
    with zipfile.ZipFile(archive) as z:
        names=set(z.namelist())
        for n,w in expected.items():
            req(n in names,f'missing src_64 member {n}')
            if n in names:
                b=z.read(n); req(sha(b)==w,f'source hash drift {n}: {sha(b)}'); texts[n]=b.decode('utf-8','replace')
pet=texts.get('app-assets/output/assets/src_64/app/model/Pet.lua','')
main=texts.get('app-assets/output/assets/src_64/app/windows/PetMainWindow.lua','')
for token in ['pet_id = arg_86_0:getPetID()', 'equip_index = arg_86_1', 'PET_EQUIP', 'tonumber(arg_87_1.error_code or 0) == 30001', 'itemNum = 1', 'PET_ONE_KEY_EQUIP']:
    req(token in pet,f'Pet.lua evidence missing {token!r}')
for token in ['for iter_120_0 = 1, 3 do','xyd.tables.item:isAwakenItem(var_120_5:getTableID()) == 0','xyd.tables.partnerExp:totalExp','50001087','50001088','50001089','arg_131_0.selfPlayer.mana = arg_131_0.selfPlayer.mana - arg_131_0.needGold2Equip']:
    req(token in main,f'PetMainWindow.lua evidence missing {token!r}')
# Product must retain the source-compatible wire/compatibility decisions.
wire=(R/'internal/adapters/stockruntime/pet_dispatcher.go').read_text()
req('case 783:' in wire and 'case 792:' in wire,'implemented stock routes absent')
mid792=wire.split('case 792:',1)[1].split('case 791:',1)[0]
req('"economy_":' not in mid792,'MID792 contradicts stock local Mana subtraction')
planner=(R/'internal/application/characterpet/equipment_planner.go').read_text()
req('50001087, 50001088, 50001089' in planner,'Pet potion compatibility set/order missing')
req('MaxEXPShortfall' in planner,'max-not-sum EXP rule missing')
if errs:
 print('CA4-4A SOURCE ORACLE CHECK: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-4A SOURCE ORACLE CHECK: PASS')
print('exact current src_64 MID783/MID792 wire, 30001, one-key planner, partnerExp/potion and local-Mana evidence matches implementation contracts')
