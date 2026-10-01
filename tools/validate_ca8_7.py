#!/usr/bin/env python3
from pathlib import Path
import hashlib, os, re, sys

ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def read(rel): return (ROOT/rel).read_text()
def file_sha(rel): return hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()

product_path=ROOT/'internal/application/characterasset/battle_contribution.go'
test_path=ROOT/'internal/application/characterasset/battle_contribution_test.go'
arch_path=ROOT/'internal/archguard/ca8_7_contract_test.go'
source_path=ROOT/'tools/check_ca8_7_source_oracle.py'
for p in [product_path,test_path,arch_path,source_path]:
    req(p.is_file(),f'CA8-7 required file missing {p.relative_to(ROOT)}')
product=product_path.read_text() if product_path.is_file() else ''
tests=test_path.read_text() if test_path.is_file() else ''
arch=arch_path.read_text() if arch_path.is_file() else ''
check=read('tools/check.sh')

for tok in [
    'const BattleCharacterContributionSchemaVersion = "ca8-7/v1"',
    'type BattleCharacterScopeWitness struct', 'OperationID     ids.UUID', 'ContentRevision string', 'ObservedAt      time.Time',
    'type OwnedHeroBattleContribution struct', 'type OwnedPetBattleContribution struct',
    'type BorrowedHeroBattleContribution struct', 'type BorrowedPetBattleContribution struct',
    'type SyntheticHeroBattleContribution struct', 'type SyntheticPetBattleContribution struct',
    'type BattleCharacterContributionReader struct', 'Owned    *OwnedCompositeBuilder', 'Borrowed *BorrowedCompositeBuilder',
    'func (r BattleCharacterContributionReader) OwnedHeroTx', 'func (r BattleCharacterContributionReader) OwnedPetTx',
    'func (r BattleCharacterContributionReader) BorrowedHeroTx', 'func (r BattleCharacterContributionReader) BorrowedPetTx',
    'func (r BattleCharacterContributionReader) SyntheticHero', 'func (r BattleCharacterContributionReader) SyntheticPet',
    'r.Owned.OwnedHeroTx(ctx, scope, ref)', 'r.Owned.OwnedPetTx(ctx, scope, ref)',
    'r.Borrowed.BorrowedHeroTx(ctx, scope, ref)', 'r.Borrowed.BorrowedPetTx(ctx, scope, ref)',
    'MaterializeSyntheticHero(scope, spec)', 'MaterializeSyntheticPet(scope, spec)',
    'HeroSkillsDisposition: ProviderUnavailableUnqualified',
]: req(tok in product,f'CA8-7 product marker missing {tok!r}')

# Scope witness must remain narrow. No retry attempt, queryer, entropy or policy
# set belongs in Character contribution provenance.
m=re.search(r'type BattleCharacterScopeWitness struct \{(.*?)\n\}',product,re.S)
if m:
    fields=[ln.strip().split()[0] for ln in m.group(1).splitlines() if ln.strip() and not ln.strip().startswith('//')]
    req(fields==['SchemaVersion','OperationID','ContentRevision','ObservedAt'],f'CA8-7 witness fields drift: {fields}')
else:
    req(False,'unable to parse BattleCharacterScopeWitness')

for bad,label in [
    ('ProviderRequiredButUnavailable','consumer requiredness'), ('database/sql','database/sql'), ('foundation/tx','foundation/tx'),
    ('time.Now(','fresh clock'), ('ActiveRevision(','content discovery'), ('CombatSnapshot{','CombatSnapshot construction'),
    ('snapshot_hash','snapshot hash'), ('entropy_policy_version','entropy policy'), ('rules_corpus_version','rules policy'),
    ('trust_profile_version','trust policy'), ('content_policy_version','content policy'), ('FIGHT_RESULT','stock battle wire'),
]: req(bad not in product,f'CA8-7 product contains forbidden {label} marker')

# Do not duplicate accepted materializer/clone logic.
for bad in ['cloneRawEquipment(', 'clonePractice(', 'cloneHeroAppearance(', 'clonePetAppearance(', 'cloneSyntheticFeaturePayload(']:
    req(bad not in product,f'CA8-7 duplicated accepted helper {bad}')

for tok in [
    'TestBattleCharacterScopeWitnessUsesOnlyStableCharacterScope',
    'TestBattleContributionOwnedHeroAndPetReuseAcceptedComposite',
    'TestBattleContributionBorrowedPreservesExactLenderAndCapability',
    'TestBattleContributionSyntheticHeroAndPetPreserveQualifiedProfile',
    'TestBattleContributionRejectsInvalidDependenciesAndInputsBeforeMaterialization',
    'TestBattleContributionValidationFailsClosedOnRequirednessAndScopeDrift',
    'TestBattleContributionOwnedCompositeRemainsImmutableByCopy',
]: req(tok in tests,f'CA8-7 focused proof missing {tok}')
for tok in ['TestCA87BattleContributionCharacterOwnershipFence','TestCA87IntroducesNoPersistenceWireOrBattleOwnerArtifact']:
    req(tok in arch,f'CA8-7 archguard proof missing {tok}')

req('run python3 tools/check_ca8_7_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"' in check,'CA8-7 source-oracle not wired into tools/check.sh')
req('run python3 tools/validate_ca8_7.py' in check,'CA8-7 static validator not wired into tools/check.sh')

if os.environ.get('GXB_COMPAT_SCRATCH') != '1':
    req(file_sha('go.mod')=='313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','canonical go.mod pin drift')
    req(file_sha('go.sum')=='efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d','canonical go.sum pin drift')
    req(file_sha('.go-version')=='a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718','canonical .go-version pin drift')

for d in [ROOT/'migrations', ROOT/'internal/adapters/stockruntime', ROOT/'internal/protocol']:
    if d.exists():
        for p in d.rglob('*'):
            if p.is_file():
                n=p.name.lower()
                req('ca8_7' not in n and 'battle_contribution' not in n,f'CA8-7 unexpected persistence/wire artifact {p.relative_to(ROOT)}')

if errs:
    print('CA8-7 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA8-7 VALIDATION: PASS')
print('typed Character battle handoff, narrow scope witness, accepted CA8-3/4/5 reuse, Hero-skill unavailability, downstream I8 boundary and canonical pins preserved')
