#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,re,subprocess,sys
B=Path('/mnt/data/ca4_3a_b_work/backend'); errs=[]; n=0
def ck(c,m):
 global n;n+=1
 if not c: errs.append(m)
def txt(r): return (B/r).read_text(errors='replace')
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
# Exact phase parent and authority.
ck(sha('/mnt/data/gxb-backend-v2-v0.69.3-pass540-ca4-2-accepted-pass541.zip')=='46ba902fe7adc2a9f97b8f1050b056ed0efcc5e35e541b914958f6b74ea4331e','CA4-2 accepted parent drift')
ck(sha('/mnt/data/pass542_package/gxb-backend-pass-542.0-passmap.zip')=='db7e15c6dcc8935f61f7e0bbabb21aabd158cc5fa4825cc0140aac06bfbc903b','Pass542 authority drift')
# Pins/dependencies.
for rel,w in {'.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718','go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}.items(): ck(sha(B/rel)==w,f'pin drift {rel}')
# A content capability/durability.
manifest=json.load(open(B/'internal/content/builtin/manifest.json')) if (B/'internal/content/builtin/manifest.json').exists() else None
# source oracle checker is authoritative static proof.
for cmd in [['python3','tools/check_ca4_3a_source_oracle.py'],['python3','tools/validate_ca4_3a_b.py'],['python3','tools/check_schema_query_ownership.py'],['python3','tools/check_sqlc_generation_policy.py'],['python3','tools/check_dependency_policy.py'],['python3','tools/validate_current_candidate.py']]:
 r=subprocess.run(cmd,cwd=B,capture_output=True,text=True); ck(r.returncode==0,f'failed {cmd}: {r.stdout}{r.stderr}')
# Migration/raw persistence.
mig=txt('migrations/00021_ca4_3a_hero_fumo.sql')
for t in ['hero_fumo_targets','hero_fumo_materials','fumo_1','fumo_2','fumo_3','fumo_4','fumo_5','fumo_6']: ck(t in mig,f'migration missing {t}')
hero=txt('internal/domain/character/hero.go'); equip=txt('internal/domain/character/equipment.go')
ck(re.search(r'\bFumo\s+HeroFumoSlots\b',hero) is not None,'Hero raw Fumo owner missing')
ck('func (s HeroFumoSlots) Validate() error' in equip,'raw Fumo validator missing')
ck('fumo_level' not in mig.lower(),'durable fumo_level leaked')
store='\n'.join([txt('internal/adapters/postgres/characterstore/store.go'),txt('internal/adapters/postgres/characterqueries/querytext_gen.go')])
for t in ['fumo_1','fumo_6','SaveHeroStateTx']: ck(t in store,f'Hero store/CAS missing {t}')
proj=txt('internal/projection/hero/stock.go')
ck('"fumos"' in proj,'stock raw fumos missing')
# Raw equipment seam.
raw='\n'.join(p.read_text(errors='replace') for p in (B/'internal/application/characterasset').glob('*.go'))
ck('RawFumo' in raw,'RawEquipmentState RawFumo missing')
# B service semantics.
svc=txt('internal/application/characterhero/fumo_service.go')
for t in ['FeedFumo','validateNormalHeroForEquipment','aggregateFumoMaterials','HeroFumoMaterialTx','PrepareHeroEquipmentResourcesTx','StackQuantity','ApplyHeroEquipmentResourceDebitTx','checkedMul64(credited, target.ManaPerFumo)','SaveHeroStateTx','deriveFumoLevelsTx','putHeroFumoReceipt']: ck(t in svc,f'MID58 service missing {t}')
ck('credited = remaining' in svc,'overfeed cap missing')
ck('Count: counts[itemID]' in svc,'full requested-copy debit missing')
ck('time.Now' not in svc and 'time.Since' not in svc,'invented time dedupe')
# Receipt semantics.
ck('"CA4_3A_HERO_FUMO"' in svc and '"gxb.ca4-3a.mid58.v1"' in svc,'semantic receipt identity missing')
ck('FingerprintRequest(map[string]any{"partner_id": partnerID, "equip_index": equipIndex, "materials": materials})' in svc,'receipt fingerprint drift')
# Wire/activation.
dis=txt('internal/adapters/stockruntime/hero_dispatcher.go'); main=txt('cmd/gxb-api/main_postgres.go')
for t in ['case 58:','"partner_id", "equip_index", "materials"','FeedFumo(ctx, actor','"fumo": got.Fumo','"fumo_lev": levels','"economy_": map[string]any{"mana": mana}']: ck(t in dis,f'MID58 wire missing {t}')
ck('[]uint16{49, 52, 55, 58, 63, 67, 89}' in main,'MID58 route not active')
for bad in ['mustRegister(54','mustRegister(62','case 29:','case 51:','case 57:']: ck(bad not in main+'\n'+dis,f'out-of-scope route {bad}')
# Vector/oracle identities.
vp=B/'internal/application/characterhero/testdata/ca4_3a_mid58_adversarial_vectors.json'; vd=json.load(open(vp))
ck(sha(vp)=='063c8b17d72f423b62533d00b4e18453d0b159d1fa1927fc4ef40313ce34b3e7','vectors drift')
ck(len(vd['vectors'])==17,'vector count')
ck('TestCA43AMID58ExecutableAdversarialVectors' in txt('internal/application/characterhero/fumo_service_test.go'),'behavioral vector runner missing')
ck('TestFeedFumoOverfeedConsumesAllCreditsRemainingAndReplays' in txt('internal/application/characterhero/fumo_service_test.go'),'receipt replay test missing')
# Evidence.
for p,needle in [('/mnt/data/ca4_3a_b_exact_attempt_current.log','proxy.golang.org'),('/mnt/data/ca4_3a_b_compat7_gate.log','=== vet all ==='),('/mnt/data/ca4_3a_b_compat7_package_regression.log','SUMMARY packages_run=92 fail=0'),('/mnt/data/ca4_3a_b_independent_check.log','PASS 47/47')]: ck(Path(p).exists() and needle in Path(p).read_text(errors='replace'),f'evidence missing {p}')
# Metadata identity coherence after B promotion.
build=json.load(open(B/'BUILD_INFO.json')); snap=json.load(open(B/'SNAPSHOT_INFO.json')); sbom=json.load(open(B/'SBOM.spdx.json'))
ck(build['version']=='v0.70.1' and snap['version']=='v0.70.1','version drift')
ck(build['pass']=='544.0' and snap['pass']=='544.0','pass drift')
ck(build['content_revision']=='aa89ed03a9315a9faf8392b9beb4141594ad911033483659ea0c31674a79dc83','content revision drift')
ck(build['implementation_revision_sha256']==snap['implementation_revision_sha256'],'implementation revision metadata drift')
ck(next(p for p in sbom['packages'] if p['SPDXID']=='SPDXRef-GXB')['versionInfo']=='v0.70.1','SBOM version drift')
if errs:
 print(f'CA4-3A AGGREGATE INDEPENDENT CHECK: FAIL {n-len(errs)}/{n}')
 for e in errs: print(' -',e)
 sys.exit(1)
print(f'CA4-3A AGGREGATE INDEPENDENT CHECK: PASS {n}/{n}')
print('A+B content/durability/MID58/I5/receipt/projection/activation compose without ownership drift; later CA4-3B+ mechanics absent.')
