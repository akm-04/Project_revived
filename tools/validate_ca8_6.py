#!/usr/bin/env python3
from pathlib import Path
import hashlib, os, re, sys

ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def read(rel): return (ROOT/rel).read_text()
def file_sha(rel): return hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()

product_path=ROOT/'internal/application/characterasset/public_showcase.go'
test_path=ROOT/'internal/application/characterasset/public_showcase_test.go'
arch_path=ROOT/'internal/archguard/ca8_6_contract_test.go'
source_path=ROOT/'tools/check_ca8_6_source_oracle.py'
for p in [product_path,test_path,arch_path,source_path]:
    req(p.is_file(),f'CA8-6 required file missing {p.relative_to(ROOT)}')

product=product_path.read_text() if product_path.is_file() else ''
tests=test_path.read_text() if test_path.is_file() else ''
arch=arch_path.read_text() if arch_path.is_file() else ''
check=read('tools/check.sh')

for tok in [
    'type PublicHeroCharacterFacet struct', 'Origin                ActorOrigin', 'Base                  HeroBaseObservation',
    'Equipment             ProviderObservation[RawEquipmentState]', 'Practice              ProviderObservation[PracticeContribution]',
    'Appearance            ProviderObservation[HeroAppearanceContribution]', 'HeroSkillsDisposition ProviderDisposition',
    'type PublicPetCharacterFacet struct', 'Base       PetBaseObservation', 'Appearance ProviderObservation[PetAppearanceContribution]',
    'type PublicShowcaseCharacterReader struct', 'OwnerComposite *OwnedCompositeBuilder',
    'func (r PublicShowcaseCharacterReader) HeroTx(ctx context.Context, scope CoherentReadScope, ref character.HeroRef)',
    'func (r PublicShowcaseCharacterReader) PetTx(ctx context.Context, scope CoherentReadScope, ref character.PetRef)',
    'r.OwnerComposite.OwnedHeroTx(ctx, scope, ref)', 'r.OwnerComposite.OwnedPetTx(ctx, scope, ref)',
    'owned.Origin != ActorOriginOwned', 'owned.Base.Ref != ref', 'HeroSkillsDisposition: ProviderUnavailableUnqualified',
]: req(tok in product,f'CA8-6 product marker missing {tok!r}')

# Hero skill state is status-only; do not grow values into the facet.
m=re.search(r'type PublicHeroCharacterFacet struct \{(.*?)\n\}',product,re.S)
if m:
    block=m.group(1)
    skill_lines=[ln.strip() for ln in block.splitlines() if 'Skill' in ln or 'skill' in ln]
    req(skill_lines==['HeroSkillsDisposition ProviderDisposition'],f'Hero facet gained skill values/fields: {skill_lines}')
else:
    req(False,'unable to parse PublicHeroCharacterFacet')

# The implementation is a projection facade, not another owner/provider engine.
for bad,label in [
    ('database/sql','database/sql'), ('foundation/tx','foundation/tx'), ('time.Now(','fresh clock'), ('ActiveRevision(','content discovery'),
    ('ActorOriginBorrowed','borrowed origin'), ('ActorOriginTrial','trial origin'), ('ActorOriginNPCTemplate','NPC origin'),
    ('GET_PLAYER_CARD_INFO','MID1829 wire'), ('MODIFY_SHOW_CASE','MID1832 wire'), ('GET_SHOWCASE_DETAIL','MID1838 wire'),
    ('show_case','stock public DTO'), ('is_like','Bookmark'), ('CombatSnapshot','final CombatSnapshot'),
    ('RawIDs','raw ids'), ('ShowcaseIndex','raw showcase index'), ('ProfilePlayerID','public profile identity'),
]: req(bad not in product,f'CA8-6 product contains forbidden {label} marker')
req('cloneRawEquipment(' not in product and 'clonePractice(' not in product and 'cloneHeroAppearance(' not in product and 'clonePetAppearance(' not in product,
    'CA8-6 duplicated accepted OwnedCompositeBuilder clone helpers')

for tok in [
    'TestPublicShowcaseHeroAndPetSuccess', 'TestPublicShowcaseFailsClosedInvalidRequests',
    'TestPublicShowcasePropagatesBaseAndCoherenceFailures', 'TestPublicShowcasePreservesOptionalProviderDispositionAndErrors',
    'TestPublicShowcasePersistentIdentityDoesNotCollapseToTableID', 'TestPublicShowcaseReturnedNestedStateIsDefensivelyCopied',
]: req(tok in tests,f'CA8-6 focused proof missing {tok}')
for tok in ['TestCA86PublicShowcaseCharacterOwnershipFence','TestCA86IntroducesNoPersistenceWireOrForeignOwnerArtifact']:
    req(tok in arch,f'CA8-6 archguard proof missing {tok}')

req('run python3 tools/check_ca8_6_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"' in check,'CA8-6 source-oracle not wired into tools/check.sh')
req('run python3 tools/validate_ca8_6.py' in check,'CA8-6 static validator not wired into tools/check.sh')

# Canonical dependency/toolchain pins must remain pristine through Normal Chat.
# tools/check.sh explicitly marks disposable toolchain accommodations with
# GXB_COMPAT_SCRATCH=1; do not misclassify that diagnostic copy as canonical.
if os.environ.get('GXB_COMPAT_SCRATCH') != '1':
    req(file_sha('go.mod')=='313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','canonical go.mod pin drift')
    req(file_sha('go.sum')=='efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d','canonical go.sum pin drift')

for d in [ROOT/'migrations', ROOT/'internal/adapters/stockruntime', ROOT/'internal/protocol']:
    if d.exists():
        for p in d.rglob('*'):
            if p.is_file():
                n=p.name.lower()
                req('ca8_6' not in n and 'public_showcase' not in n,f'CA8-6 unexpected persistence/wire artifact {p.relative_to(ROOT)}')

if errs:
    print('CA8-6 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA8-6 VALIDATION: PASS')
print('thin OWNED-only facade, provider-disposition boundary, Hero-skill residual, tests/archguard/source-oracle wiring and pristine canonical Go pins preserved')
