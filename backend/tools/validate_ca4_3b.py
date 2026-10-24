#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, re, sys
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

m=J('internal/content/builtin/generated/manifest.json')
req((m.get('compiler_version'),m.get('parser_version')) in {('ca4-3b','lua-generated-v9-hero-promotion-restoration'),('ca4-4a-i1','lua-generated-v10-pet-equipment'), ('ca6-2-practice-foundation','lua-generated-v13-practice')},'CA4-3B cumulative compiler/parser drift')
req(m.get('revision_id')=='6a9727da99a03a596625aafb9579c91ac1edec13ec8d02b7701a44c7a5d9a9fe','CA4-3B content revision drift')
req('HERO_PROMOTION_RESTORATION_CA4_3B' in m.get('enabled_capabilities',[]),'CA4-3B capability absent')
req(m.get('diagnostics',{}).get('hero_promotion_restoration_eligible_equipment')==195,'restoration eligible count diagnostic drift')
req(len(m.get('sources',[]))==36,'source manifest count drift')
req(len(m.get('artifact_sha256s',{}))==12,'artifact hash count drift')

cat=J('internal/content/builtin/generated/hero_promotion_restoration_catalog.json')
elig=cat.get('eligible_equipment',[]); fr=cat.get('quality_fractions',[]); den=cat.get('denominations',[])
req(len(elig)==195,'eligible equipment count drift')
qd={q:0 for q in range(2,7)}
last=0
for row in elig:
    iid=row.get('equipment_item_id',0); q=row.get('source_quality',0)
    req(iid>last,'eligible equipment not strictly sorted/unique'); last=iid
    req(q in qd,f'invalid source quality {q}');
    if q in qd: qd[q]+=1
req(qd=={2:35,3:35,4:65,5:42,6:18},f'quality distribution drift {qd}')
req(fr==[
 {'denominator':1,'numerator':1,'quality':2},
 {'denominator':8,'numerator':3,'quality':3},
 {'denominator':50,'numerator':9,'quality':4},
 {'denominator':100,'numerator':9,'quality':5},
 {'denominator':200,'numerator':9,'quality':6}], 'quality fractions drift')
req(den==[
 {'item_id':50001007,'ordinal':0,'value':200},
 {'item_id':50001006,'ordinal':1,'value':60},
 {'item_id':50001003,'ordinal':2,'value':10}], 'restoration denomination drift')

migp=R/'migrations/00022_ca4_3b_hero_promotion_restoration.sql'; mig=read(migp.relative_to(R).as_posix())
for token in ['gxb_content_hero_promotion_restoration_equipment','gxb_content_hero_promotion_restoration_fractions','gxb_content_hero_promotion_restoration_denominations','ON DELETE RESTRICT']:
    req(token in mig,f'00022 missing {token}')
req('-- +goose Down' not in mig,'00022 violates forward-only migration law')
lock=J('docs/architecture/CUMULATIVE_MIGRATION_LOCK.json')
want=hashlib.sha256(migp.read_bytes()).hexdigest() if migp.exists() else ''
req(lock.get('highest_migration')==migp.name,'migration high-water is not 00022')
req(lock.get('migrations',{}).get(migp.name)==want,'00022 migration hash not sealed')
own=J('docs/architecture/CANONICAL_TABLE_OWNERSHIP.json').get('tables',{})
for table in ['gxb_content_hero_promotion_restoration_equipment','gxb_content_hero_promotion_restoration_fractions','gxb_content_hero_promotion_restoration_denominations']:
    row=own.get(table,{})
    req(row.get('owner')=='content-registry' and row.get('migration')=='migrations/00022_ca4_3b_hero_promotion_restoration.sql',f'{table} ownership drift')

provider=read('internal/application/i5/max_hero_color_policy.go')
req('PreservationMaxHeroColor int64 = 5' in provider,'max_color preservation value drift')
req('GXB1_PRESERVATION_MAX_HERO_COLOR_V1' in provider,'max_color policy revision absent')
bootstrap=read('internal/adapters/postgres/i5store/bootstrap_projection.go')
req('"17.max_color"' in bootstrap,'MID17 max_color ownership claim absent')
req('mid17["max_color"] = b.MaxHeroColor.MaxHeroColor()' in bootstrap,'MID17 max_color projection absent')

sql=read('sql/content/content.sql')
for token in ['InsertContentHeroPromotionRestoration','VerifyContentRevision','ReadHeroPromotionRestorationEquipment','ReadHeroPromotionRestorationFractions','ReadHeroPromotionRestorationDenominations']:
    req(token in sql,f'content query missing {token}')
store=read('internal/adapters/postgres/contentstore/hero_promotion_restoration.go')
for token in ['HERO_PROMOTION_RESTORATION_CA4_3B','HeroPromotionRestorationEligibilityTx','HeroPromotionRestorationPolicyTx']:
    req(token in store,f'runtime restoration content seam missing {token}')

# Existing immutable toolchain pins must remain untouched during environment accommodation.
expected={
 '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
 'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4',
 'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,w in expected.items():
    p=R/rel
    req(p.exists() and hashlib.sha256(p.read_bytes()).hexdigest()==w,f'canonical toolchain pin changed {rel}')

if errs:
    print('CA4-3B STAGE A VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA4-3B STAGE A VALIDATION: PASS')
print('immutable restoration source facts, forward-only schema ownership, exact-revision runtime seams, and revisioned nonlocking max_color preservation policy are present')
