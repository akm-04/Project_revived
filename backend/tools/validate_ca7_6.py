#!/usr/bin/env python3
from pathlib import Path
import re, sys
ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def read(rel): return (ROOT/rel).read_text()
asset=read('internal/application/characterasset/appearance_contribution.go')
hero=read('internal/application/characterhero/appearance_contribution.go')
pet=read('internal/application/characterpet/appearance_contribution.go')
hero_tests=read('internal/application/characterhero/appearance_contribution_test.go')
pet_tests=read('internal/application/characterpet/appearance_contribution_test.go')
projection_tests=read('internal/application/characterasset/appearance_projection_test.go')
integration=read('internal/application/characterpractice/ca7_6_integration_test.go')
queries=read('internal/adapters/postgres/characterqueries/querytext_gen.go')
materializer=read('internal/application/characterhero/appearance_materializer.go')
replay=read('internal/foundation/replaycatalog/catalog.go')
check=read('tools/check.sh')
arch=read('internal/archguard/ca7_6_contract_test.go') if (ROOT/'internal/archguard/ca7_6_contract_test.go').exists() else ''

for tok in ['type HeroAppearanceContribution struct','type PetAppearanceContribution struct','OwnerID','TableID','OriginTableID','ContentRevision','Appearance','HeroAppearanceContributionProvider','PetAppearanceContributionProvider','ValidateExactRevisionID']:
    req(tok in asset,f'CA7-6 contribution marker missing {tok!r}')
for tok in ['HeroAppearanceContributionTx(','tx.Queryer','AppearanceRevisionTx','ReadHeroByPartnerIDTx','ListHeroSkinEntitlementsTx','ListHeroLIVEEntitlementsTx','BuildEffectiveHeroAppearanceTx','h.CreationContentRevision','HeroKindTx','h.PlayerID != pid','h.PartnerID != partnerID']:
    req(tok in hero,f'CA7-6 Hero contribution marker missing {tok!r}')
for tok in ['PetAppearanceContributionTx(','tx.Queryer','AppearanceRevisionTx','ReadPetByIDTx','ListPetStyleEntitlementsTx','BuildEffectivePetAppearanceTx','p.PlayerID != pid','p.PetID != petID']:
    req(tok in pet,f'CA7-6 Pet contribution marker missing {tok!r}')
# Caller-owned read seam: fail on ownership/policy creep in the new production files.
combined='\n'.join([asset,hero,pet])
for pattern,label in [
    (r'\btx\.Runner\b','tx.Runner'),
    (r'\bActiveRevision\s*\(','ActiveRevision call'),
    (r'\btime\.Now\s*\(','time.Now call'),
    (r'"[^"\n]*/foundation/receipt(?:/[^"\n]*)?"','foundation/receipt import'),
    (r'"[^"\n]*/application/i5(?:/[^"\n]*)?"','application/i5 import'),
    (r'\bTimedRunner\b','TimedRunner'),
    (r'\.(?:Begin|Commit|Rollback)\s*\(','transaction ownership call'),
    (r'FOR\s+UPDATE','FOR UPDATE SQL'),
    (r'\b(?:BattleModelID|EffectiveModelID|SkillModelID|SkinSkillID)\b','battle-derived identifier'),
    (r'\b(?:board_partner|board_card|board_model_id)\b','Library board-state identifier'),
]:
    req(re.search(pattern, combined, re.I) is None, f'CA7-6 read seam contains forbidden ownership/policy marker {label!r}')
for writeish in ['SaveHero','SavePet','InsertHero','InsertPet','UpsertHero','Debit','Credit','PutTx(']:
    req(writeish not in hero+pet,f'CA7-6 read seam contains write/economy marker {writeish!r}')
# Exact current revision must be validated before owner read and Hero kind must use creation revision.
req(hero.find('r.Content.AppearanceRevisionTx(') < hero.find('r.Store.ReadHeroByPartnerIDTx('), 'Hero contribution does not fail closed on exact revision before owner read')
req(pet.find('r.Content.AppearanceRevisionTx(') < pet.find('r.Store.ReadPetByIDTx('), 'Pet contribution does not fail closed on exact revision before owner read')
req('HeroKindTx(ctx, q, h.CreationContentRevision, h.TableID)' in hero,'Hero kind provenance no longer uses CreationContentRevision')
req('BuildEffectiveHeroAppearanceTx(ctx, q, revision' in hero,'Hero current appearance qualification no longer uses caller revision')

for tok in ['TestHeroAppearanceContributionReaderUsesPinnedRevisionAndCreationKindProvenance','TestHeroAppearanceContributionReaderFailsClosedBeforeOwnerRead','TestHeroAppearanceContributionReaderRejectsOwnerMismatch','TestHeroAppearanceContributionReloadIsDeterministicAndIndependent','TestHeroAppearanceContributionFreezesObservationAcrossLaterDurableMutation']:
    req(tok in hero_tests,f'CA7-6 Hero contribution proof missing {tok}')
for tok in ['TestPetAppearanceContributionReaderUsesPinnedRevisionAndStableObservation','TestPetAppearanceContributionReaderFailsClosedBeforeOwnerRead','TestPetAppearanceContributionReaderRejectsOwnerMismatch','TestPetAppearanceContributionReloadIsDeterministicAndIndependent','TestPetAppearanceContributionFreezesObservationAcrossLaterDurableMutation']:
    req(tok in pet_tests,f'CA7-6 Pet contribution proof missing {tok}')
for tok in ['TestTimedEntitlementEqualityAndStaleSelectorQualification','TestPaidLIVERemainsEffectiveAcrossOrdinaryTimedSkinExpiry']:
    req(tok in projection_tests,f'CA7-6 retained time/selector proof missing {tok}')
for tok in [
'TestCA76RealHeroTicketStalesAfterActualCA7MutationWithoutRefundOrDeletion',
'TestCA76RealPetTicketStalesAfterActualCA7MutationWithoutRefundOrDeletion',
'TestCA76SemanticNoopPreservesPendingProposalValidity',
'TestCA76AUTOAndCA7SerializeBySharedOwnerVersionInBothOrders',
'TestCA76AppearanceMutationsPreserveEarlierOwnedFields',
 ]: req(tok in integration,f'CA7-6 cross-service/preservation proof missing {tok}')

hero_preservation=read('internal/application/characterhero/ca7_6_preservation_test.go')
pet_preservation=read('internal/application/characterpet/ca7_6_preservation_test.go')
preset_preservation=read('internal/application/charactersavedpreset/ca7_6_preservation_test.go')
for tok in ['TestCA76HeroProgressionMutationPreservesAppearanceSelectors','TestCA76HeroEquipmentMutationPreservesAppearanceSelectors']:
    req(tok in hero_preservation,f'CA7-6 reverse Hero preservation proof missing {tok}')
for tok in ['TestCA76PetProgressionMutationPreservesAppearanceStyle','TestCA76PetEquipmentMutationPreservesAppearanceStyle']:
    req(tok in pet_preservation,f'CA7-6 reverse Pet preservation proof missing {tok}')
req('TestCA76SavedPresetMutationPreservesCA7AppearanceState' in preset_preservation,'CA7-6 CA5 real-service preservation proof missing')

# Query-level bidirectional preservation. Extract generated constants to avoid relying only on comments.
def const(name):
    m=re.search(rf'const {name} = `([^`]*)`',queries,re.S)
    req(bool(m),f'query constant missing {name}')
    return m.group(1) if m else ''
hero_state=const('SaveHeroState'); hero_practice=const('SaveHeroPractice'); hero_app=const('SaveHeroAppearanceSelectors')
pet_state=const('SavePetState'); pet_practice=const('SavePetPractice'); pet_app=const('SavePetActiveStyle')
for qname,q in [('SaveHeroState',hero_state),('SaveHeroPractice',hero_practice)]:
    for bad in ['current_skin_id','illusion_skin_id']:
        req(bad not in q,f'{qname} rewrites CA7 Hero selector {bad}')
for bad in ['star=','level=','exp=','color=','equip_','fumo_','practice_']:
    req(bad not in hero_app,f'SaveHeroAppearanceSelectors rewrites earlier Hero field marker {bad}')
for qname,q in [('SavePetState',pet_state),('SavePetPractice',pet_practice)]:
    req('active_style' not in q,f'{qname} rewrites CA7 Pet active_style')
for bad in ['star=','level=','exp=','color=','skill_','equip_','fumo_','practice_','is_show=','birthday=']:
    req(bad not in pet_app,f'SavePetActiveStyle rewrites earlier Pet field marker {bad}')
# CA5 is separate tables and cannot become an appearance writer.
for name in ['InsertSavedPresetRoot','InsertSavedPresetLane','InsertSavedPresetHero','SaveSavedPresetRootVersion']:
    q=const(name)
    req('player_heroes' not in q and 'player_pets' not in q and 'skin' not in q.lower() and 'style' not in q.lower(),f'{name} crossed into Character appearance owner SQL')

req('TxPermanentSkinMaterializer' in materializer and 'GrantPermanentSkinTx' in materializer,'accepted Commerce materializer boundary missing')
materializer_defs=[]
for path in (ROOT/'internal').rglob('*.go'):
    if 'type TxPermanentSkinMaterializer interface' in path.read_text(): materializer_defs.append(path.relative_to(ROOT).as_posix())
req(materializer_defs == ['internal/application/characterhero/appearance_materializer.go'], f'Character permanent-skin materializer duplicated/moved: {materializer_defs}')
req((ROOT/'internal/application/characterhero/appearance_materializer.go').is_file(),'accepted Character-side materializer file missing')
req(not (ROOT/'internal/application/cosmetics').exists() and not (ROOT/'internal/domain/cosmetics').exists(),'unauthorized Cosmetics owner introduced')
req(not list((ROOT/'migrations').glob('*ca7_6*')),'CA7-6 unexpectedly introduced schema migration')
req('ca7-6' not in replay.lower(),'CA7-6 unexpectedly introduced replay/receipt family')
# No new appearance gameplay routes are expected in CA7-6.
hero_dispatch=read('internal/adapters/stockruntime/hero_dispatcher.go'); pet_dispatch=read('internal/adapters/stockruntime/pet_dispatcher.go')
for later in ['case 1896:','case 1897:','case 1898:']:
    req(later not in hero_dispatch+pet_dispatch,f'CA7-6 unexpectedly activated successor gameplay route {later}')

req('TestCA76ContributionReadSeamAndPreservationFences' in arch,'CA7-6 architecture guard missing')
req('check_ca7_6_source_oracle.py' in check and 'validate_ca7_6.py' in check,'CA7-6 cumulative guards not wired into tools/check.sh')

if errs:
    print('CA7-6 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA7-6 VALIDATION: PASS')
print('typed caller-owned appearance contributions, provenance, Practice integration, bidirectional query preservation and no-new-authority fences preserved')
