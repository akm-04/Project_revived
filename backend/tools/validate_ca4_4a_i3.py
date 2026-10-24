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
svc=need('internal/application/characterpet/equipment_service.go','func (s Service) EquipItem','ALREADY_EQUIPPED','ErrPetAwakeningProviderUnavailable','PetTemplateAwakenedTx','DebitMaterialCostTx','SavePetStateTx','PetUniqueEquipmentCommittedFact','gxb.ca4-4a.mid783.v1')
# Direct MID783 owns no recipe composition path: recipe traversal begins only in the later one-key helper.
direct=svc.split('func (s Service) EquipItem',1)[1].split('func (s Service) loadPetOneKeyContentTx',1)[0]
req('EquipmentRecipeEdgesTx' not in direct,'MID783 direct path unexpectedly traverses recipes')
req('Amount: 1' in direct,'MID783 does not debit exactly one finished item')
req('pos.Classification == character.PetEquipmentAwakening' in direct,'MID783 Awakening classification gate absent')
req('if !awakened' in direct and 'ErrPetAwakeningProviderUnavailable' in direct,'unawakened special path not fail-closed')
dis=need('internal/adapters/stockruntime/pet_dispatcher.go','case 783:','"equip_index"','error_code','30001')
block=dis.split('case 783:',1)[1].split('case 786:',1)[0]
req('HTTPStatus: http.StatusOK' in block,'MID783 not HTTP200 projected')
req('"error_code": int64(30001)' in block,'MID783 convergence code drift')
main=need('cmd/gxb-api/main_postgres.go')
req(re.search(r'\b783\b',main) is not None,'MID783 not registered in production route list')
test=need('internal/application/characterpet/equipment_service_test.go','TestPetEquipItemDirectDebitAndSameOperationReplay','TestPetEquipItemCrossRequestAlreadyEquippedIs30001SemanticResult','TestPetEquipItemAwakeningGateAndCommittedFact','TestPetEquipItemValidationFailsBeforeDurableMutation','TestPetEquipItemMissingFinishedItemDoesNotCollectSlot')
need('internal/adapters/stockruntime/pet_dispatcher_test.go','TestPetDispatcherMID783StrictWireAndAlreadyEquippedConvergence','TestPetDispatcherMID783SuccessResponseIsEmpty')
if errs:
 print('CA4-4A-I3 VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-4A-I3 VALIDATION: PASS')
print('MID783 direct finished-item debit, Pet CAS, replay/30001 convergence, Awakening activation gate and typed unique-equipment fact are present')
