#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, sys
R=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def read(rel):
    p=R/rel
    if not p.exists(): errs.append(f'missing {rel}'); return ''
    return p.read_text(errors='replace')
def J(rel):
    try: return json.loads(read(rel) or '{}')
    except Exception as e: errs.append(f'{rel}: {e}'); return {}

# Stage A: immutable source facts and PlayerProgression policy remain qualified.
m=J('internal/content/builtin/generated/manifest.json')
req(m.get('revision_id')=='6a9727da99a03a596625aafb9579c91ac1edec13ec8d02b7701a44c7a5d9a9fe','CA4-3B content revision drift')
req('HERO_PROMOTION_RESTORATION_CA4_3B' in m.get('enabled_capabilities',[]),'CA4-3B capability absent')
cat=J('internal/content/builtin/generated/hero_promotion_restoration_catalog.json')
elig=cat.get('eligible_equipment',[])
qd={q:0 for q in range(2,7)}
for row in elig:
    q=row.get('source_quality')
    if q in qd: qd[q]+=1
req(len(elig)==195 and qd=={2:35,3:35,4:65,5:42,6:18},f'restoration eligibility drift count={len(elig)} dist={qd}')
provider=read('internal/application/i5/max_hero_color_policy.go')
req('PreservationMaxHeroColor int64 = 5' in provider,'max_color compatibility value drift')
req('GXB1_PRESERVATION_MAX_HERO_COLOR_V1' in provider,'max_color policy revision absent')

# Stage B: additive I5 strict restoration and promotion union seams.
b=read('internal/application/i5/hero_promotion_resources.go')
for token in [
    'type StrictRestorationRequest struct',
    'type PreparedStrictRestoration struct',
    'type TxStrictRestorationSettler interface',
    'type HeroPromotionResourceRequest struct',
    'type PreparedHeroPromotionResources struct',
    'type TxHeroPromotionResourceSettler interface',
    'ErrStrictRestorationAlreadySettled',
    'PrepareStrictRestorationTx', 'ApplyStrictRestorationTx',
    'PrepareHeroPromotionResourcesTx', 'ApplyHeroPromotionResourcesTx',
]: req(token in b,f'Stage B seam missing {token}')
req(b.count('ErrStrictRestorationAlreadySettled') >= 3,'strict restoration durable receipt rechecks appear incomplete')
req('applied           bool' in b or 'applied bool' in b,'prepared promotion one-shot guard absent')

# Stage C: source-qualified Character transition + restoration + outer receipt.
p=read('internal/application/characterhero/promotion_restoration.go')
req('P0_FUMO_RESTORE_V1_AGGREGATE_FLOOR_GREEDY_SOURCE_ORDER' in p,'restoration compatibility policy id absent')
req('math/big' in p,'exact rational restoration arithmetic absent')
s=read('internal/application/characterhero/promotion_service.go')
for token in [
    'HeroPromotionMID51Promote', 'HeroPromotionMID57Promote', 'HeroPromotionMID57Collect',
    'heroPromotionReceiptSchema     = "gxb.ca4-3b.hero-promotion.v1"',
    'func (s Service) PowerUpHero(', 'func (s Service) OneClickJinjie(',
    'player.max-color', 'MaxHeroColorPolicyRevision()',
    'MID51 receipt branch mismatch', 'MID57 receipt branch mismatch',
    'SaveHeroStateTx', 'PrepareStrictRestorationTx', 'PrepareHeroPromotionResourcesTx',
]: req(token in s,f'Stage C contract missing {token}')
req('decoded.Branch != HeroPromotionMID51Promote' in s,'MID51 replay branch fence absent')
req('decoded.Branch != HeroPromotionMID57Promote && decoded.Branch != HeroPromotionMID57Collect' in s,'MID57 replay branch fence absent')
req('len(missing) == 0' in s,'MID57 direct no-work rejection absent')
req('maxColor < 1 || maxColor > 16' in s,'max_color policy range guard absent')

svc=read('internal/application/characterhero/service.go')
for token in ['Promotion           HeroPromotionContent','PromotionResources  appi5.TxHeroPromotionResourceSettler','StrictRestoration   appi5.TxStrictRestorationSettler','MaxHeroColorPolicy  MaxHeroColorPolicyProvider','RestorationModifier RestorationModifier']:
    req(token in svc,f'Character service dependency missing {token}')

t=read('internal/application/characterhero/promotion_service_test.go')
for token in [
    'TestPowerUpHeroRestoresDestroyedOrdinaryFumoExactlyOnce',
    'TestOneClickJinjieBelowCapRequiresCompletePlanAndPromotesAtomically',
    'TestOneClickJinjieAtCapCollectsWithoutPromotionOrFumoReset',
    'TestOneClickJinjieIncompletePlanFailsBeforeAnyI5Write',
    'TestOneClickJinjiePotionEXPAndPromotionRemainOneHeroVersion',
    'TestPowerUpHeroUnknownCommitReceiptReconcilesWithoutReapply',
    'TestPowerUpHeroUnknownCommitWithoutOuterReceiptDoesNotBlindRetry',
    'TestPowerUpHeroRejectsMID57ReceiptBranchOnReplay',
    'TestOneClickJinjieRejectsMID51ReceiptBranchOnReplay',
]: req(token in t,f'Stage C adversarial test absent {token}')

# Canonical toolchain/dependency pins must remain untouched by diagnostics.
expected={
 '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
 'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4',
 'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,w in expected.items():
    p=R/rel
    req(p.exists() and hashlib.sha256(p.read_bytes()).hexdigest()==w,f'canonical toolchain pin changed {rel}')

if errs:
    print('CA4-3B STAGE C VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA4-3B STAGE C VALIDATION: PASS')
print('Stages A/B/C source facts, I5 transaction seams, Character transition/receipt/recovery invariants, and canonical pins are present')
