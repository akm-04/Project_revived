#!/usr/bin/env python3
from pathlib import Path
import re,sys
R=Path(__file__).resolve().parents[1]; errs=[]
def req(x,msg):
    if not x: errs.append(msg)
def need(rel,*tokens):
    p=R/rel
    if not p.exists(): errs.append(f'missing {rel}'); return ''
    s=p.read_text(errors='replace')
    for t in tokens:
        if t not in s: errs.append(f'{rel}: missing {t!r}')
    return s
plan=need('internal/application/characterpet/equipment_planner.go','petEquipmentPotionOrder = [...]int64{50001087, 50001088, 50001089}','planPetOneKeyEquipment','reservePetEquipmentTarget','qty != used','MaxEXPShortfall','PotionEXPGranted','PetEquipmentOrdinary')
req('for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++' in plan,'MID792 slot traversal order drift')
req('if shortfall > out.MaxEXPShortfall' in plan,'MID792 no longer takes maximum EXP shortfall')
svc=need('internal/application/characterpet/equipment_service.go','func (s Service) OneKeyEquip','PrepareEquipmentResourcesTx','ApplyEquipmentResourceDebitTx','EquipmentCompatibilityExpPolicyTx','PetExpPolicyTx','ResultKind: "NO_WORK"','gxb.ca4-4a.mid792.v1')
req('SavePetStateTx' in svc,'MID792 missing cohesive Pet CAS')
dis=need('internal/adapters/stockruntime/pet_dispatcher.go','case 792:','invalid_pet_one_key_equip')
block=dis.split('case 792:',1)[1].split('case 791:',1)[0]
req('onlyStockGameplayParams(req.Envelope.Params, "pet_id")' in block,'MID792 request shape drift')
req('Body: map[string]any{}' in block,'MID792 success body not empty')
req('"economy_":' not in block,'MID792 leaks economy projection')
need('internal/application/characterpet/equipment_planner_oracle_test.go','TestPetOneKeyRickSharedReservationAndExactManaOracles','177000','441000','440999','TestPetOneKeyPartnerExpCompatibilityQuirkAppliesRealPetProgression','209000','210000')
need('internal/application/characterpet/equipment_service_test.go','TestPetOneKeyEquipServiceAppliesI5AndPetStateOnce','TestPetOneKeyEquipCanonicalNoWorkIsReceiptedSuccess')
need('internal/adapters/stockruntime/pet_dispatcher_test.go','TestPetDispatcherMID792StrictWireAndNeverProjectsManaOrPlan')
main=need('cmd/gxb-api/main_postgres.go'); req(re.search(r'\b792\b',main) is not None,'MID792 not registered in production route list')
if errs:
 print('CA4-4A-I4 VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-4A-I4 VALIDATION: PASS')
print('MID792 canonical planner, neutral I5 debit, partnerExp compatibility/real Pet EXP split, no-work receipt and empty stock response are present')
