#!/usr/bin/env python3
from pathlib import Path
import re, sys
ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def read(rel): return (ROOT/rel).read_text()

service=read('internal/application/characterpet/appearance_style_service.go')
svcroot=read('internal/application/characterpet/service.go')
dispatch=read('internal/adapters/stockruntime/pet_dispatcher.go')
main=read('cmd/gxb-api/main_postgres.go')
store=read('internal/adapters/postgres/characterstore/appearance.go')
replay=read('internal/foundation/replaycatalog/catalog.go')
arch=read('internal/archguard/ca7_2_contract_test.go')
check=read('tools/check.sh')
service_tests=read('internal/application/characterpet/appearance_style_service_test.go')
recovery_tests=read('internal/application/characterpet/appearance_style_recovery_test.go')
dispatcher_tests=read('internal/adapters/stockruntime/pet_dispatcher_test.go')
store_tests=read('internal/adapters/postgres/characterstore/appearance_ca7_5_test.go')
practice_tests=read('internal/application/characterpractice/service_semantics_test.go')

for tok in [
    'func (s Service) AcquirePetStyle(', 'func (s Service) SelectPetStyle(', 'func (s Service) CancelPetStyle(',
    'PetAppearanceMutationStore', 'tx.Serializable', 'FenceActorTx',
    'AppearanceRevisionTx', 'LockPetByIDTx', 'BuildEffectivePetAppearanceTx', 'SavePetAppearanceMutationTx', 'SavePetActiveStyleTx',
    'petStyleAcquireSchema', 'petStyleSelectSchema', 'petStyleCancelSchema',
]: req(tok in service, f'CA7-5 service marker missing {tok!r}')
req('AppearanceMutationStore PetAppearanceMutationStore' in svcroot,'CA7-5 Pet mutation seam not present in Service')
req('AppearanceMutationStore: heroDB' in main,'CA7-5 production Pet mutation store composition missing')
req('Appearance: contentDB' in main,'CA7-5 production appearance content composition missing')

# CA7-7 native contention reconciliation: the Pet style family must use the
# shared transaction foundation's opt-in definite-abort de-phasing policy.
# This guard deliberately checks the helper and all three call sites rather
# than requiring an inline RetryPolicy literal.
for tok in [
    'func petStyleRetryPolicy() tx.RetryPolicy',
    'MaxAttempts:              8',
    'RetryDefiniteAbort:       true',
    'DefiniteAbortBackoffBase: 25 * time.Millisecond',
    'DefiniteAbortBackoffMax:  400 * time.Millisecond',
    'TestCA75PetStyleRetryPolicyUsesBoundedContentionBackoff',
]: req(tok in service + service_tests, f'CA7-5 contention retry policy marker missing {tok!r}')
req(service.count('petStyleRetryPolicy()') == 4, 'CA7-5 Pet style retry policy must be defined once and used by all three mutations')

for tok in ['case 1893:', 'case 1894:', 'case 1895:', 'invalid_pet_style_acquire', 'invalid_pet_style_select', 'invalid_pet_style_cancel']:
    req(tok in dispatch,f'CA7-5 stock dispatcher marker missing {tok!r}')
req('requiredPetInt64(req.Envelope.Params, "item_id")' in dispatch,'MID1893 strict integral parser missing')
req('requiredPetInt64(req.Envelope.Params, "pet_id")' in dispatch and 'requiredPetInt64(req.Envelope.Params, "style_id")' in dispatch,'MID1894 strict integral parsers missing')

pet_reg=re.search(r'for _, mid := range \[]uint16\{([^}]*)\} \{\n\t\tmustRegister\(mid, petD\)',main)
req(bool(pet_reg),'production Pet registration set unresolved')
if pet_reg:
    for mid in ['1893','1894','1895']:
        req(re.search(rf'\b{mid}\b',pet_reg.group(1)) is not None,f'production Pet MID{mid} registration missing')
hero_reg=re.search(r'for _, mid := range \[]uint16\{([^}]*)\} \{\n\t\tmustRegister\(mid, heroD\)',main)
if hero_reg:
    for mid in ['1893','1894','1895']:
        req(re.search(rf'\b{mid}\b',hero_reg.group(1)) is None,f'Pet MID{mid} leaked into Hero production registration')

for tok in ['InsertPetStyleEntitlement', 'SavePetActiveStyle']:
    req(tok in store,f'CA7-5 Pet-owned persistence marker missing {tok!r}')
req('SavePetAppearanceMutationTx' in store,'CA7-5 one-CAS composite persistence seam missing')

for tok in ['ca7.pet-style-acquire','CurrentStateConvergence','gxb.ca7-5.pet-style-acquire.v1','ca7.pet-style-select','ParameterStateSet','gxb.ca7-5.pet-style-select.v1','ca7.pet-style-cancel','gxb.ca7-5.pet-style-cancel.v1']:
    req(tok in replay,f'CA7-5 replay catalog marker missing {tok!r}')

# Frozen R2 acceptance-matrix proof must remain visible and candidate-bound.
for tok in [
    'TestCA75AcquireGrantOnlyConsumesOncePreservesActiveAndSortsStyles',
    'TestCA75AcquireFreshOwnedConvergesWithoutDebitOrVersionBump',
    'TestCA75AcquireNormalizesStaleRawSelectorBeforeGrant',
    'TestCA75AcquireInsufficientItemOccursAfterPetLockAndWritesNothing',
    'TestCA75SelectConflictCancelAndNoopVersionSemantics',
    'TestCA75CancelClearsStaleRawPositiveSelectorEvenWhenEffectiveAlreadyZero',
    'TestCA75SelectAndCancelReceiptFingerprintsBindExactSemanticParams',
    'TestCA75ReloadProjectionTracksMutationAndNoopStateVersion',
]: req(tok in service_tests,f'CA7-5 behavior proof missing {tok}')
for tok in [
    'TestCA75UnknownCommitAcquireReconcilesReceiptWithoutSecondDebit',
    'TestCA75UnknownCommitSelectReconcilesReceiptWithoutSecondMutation',
    'TestCA75UnknownCommitCancelReconcilesReceiptWithoutSecondMutation',
    'TestCA75ConcurrentFreshSameItemAcquireConsumesAndMutatesOnce',
    'TestCA75ConcurrentSameStyleSelectBumpsOnce',
    'TestCA75ConcurrentDifferentStyleSelectOneWinnerOneConflict',
    'TestCA75ConcurrentSelectCancelSerializableOrdering',
    'TestCA75ConcurrentAcquireSelectInitiallyUnownedSerializesDeterministically',
    'TestCA75CrossPetAcquireHoldsSeparatePetLocksBeforeI5',
]: req(tok in recovery_tests,f'CA7-5 recovery/concurrency proof missing {tok}')
for tok in ['TestCA75PetStyleMIDsStrictWireAndStockProjection','TestCA75PetStyleMIDsRejectMalformedAndInventedParams','TestCA75PetStyleErrorTransportMapping']:
    req(tok in dispatcher_tests,f'CA7-5 stock-wire proof missing {tok}')
for tok in ['TestCA75SavePetAppearanceMutationTxEntitlementAndSelectorShareOneOwnerCAS','TestCA75SavePetActiveStyleTxUsesOwnerCASOnly']:
    req(tok in store_tests,f'CA7-5 owner-CAS proof missing {tok}')
req('TestCA75PetStateVersionMutationStalesPracticeProposalWhileSemanticNoopPreservesIt' in practice_tests,'CA7-5 CA6 Practice fence proof missing')

req('TestCA75AppearanceActivationPreservesOwnerAndSuccessorFences' in arch,'CA7-5 architecture activation guard missing')
req('check_ca7_5_source_oracle.py' in check and 'validate_ca7_5.py' in check,'CA7-5 retained guards are not wired into cumulative check')
for later in ['case 1896:', 'case 1897:', 'case 1898:']:
    req(later not in dispatch,f'CA7-6+ route unexpectedly activated {later}')

# CA7-5 is schema-neutral by frozen contract.
req(not list((ROOT/'migrations').glob('*ca7_5*')),'CA7-5 unexpectedly introduced a schema migration')
# Owner SQL must remain inside the Character adapter; no separate Cosmetics owner is authorized.
req(not (ROOT/'internal/application/cosmetics').exists(),'unauthorized Cosmetics application aggregate introduced')
req(not (ROOT/'internal/domain/cosmetics').exists(),'unauthorized Cosmetics domain aggregate introduced')

if errs:
    print('CA7-5 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA7-5 VALIDATION: PASS')
print('Pet-owned home-style acquisition/select/cancel, one-CAS persistence, D11 replay, strict stock routing, schema ownership and successor fences preserved')
