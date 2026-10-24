#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, subprocess, sys, re
CUR=Path('/mnt/data/ca4_3a_b_work/backend')
PAR=Path('/mnt/data/ca4_3a_b_parent543/backend')
errs=[]; checks=0

def ck(cond,msg):
 global checks
 checks+=1
 if not cond: errs.append(msg)
def text(rel): return (CUR/rel).read_text(errors='replace')
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()

ck(sha('/mnt/data/gxb-backend-v2-v0.70.0-pass543-ca4-3a-a-local-candidate.zip')=='49594fba218171fd936e7bb9b60f062bf7f5fb9e3477cebd9a6ddda9cbe6512f','parent archive identity drift')
for rel,want in {'.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718','go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}.items(): ck(sha(CUR/rel)==want,f'pin drift {rel}')
# B must not change schema/content/migrations/dependencies from A.
for rel in ['migrations/00021_ca4_3a_hero_fumo.sql','DEPENDENCIES.lock.json','go.sum']:
 ck((PAR/rel).read_bytes()==(CUR/rel).read_bytes(),f'unexpected B change {rel}')
# Diff allowlist.
out=subprocess.run(['diff','-qr',str(PAR),str(CUR)],capture_output=True,text=True).stdout.splitlines()
paths=[]
for line in out:
 m=re.search(r' and (/.+?) differ$',line)
 if m: paths.append(str(Path(m.group(1)).relative_to(CUR)))
 else:
  m=re.search(r'Only in (/.+?): (.+)$',line)
  if m and Path(m.group(1)).is_relative_to(CUR): paths.append(str(Path(m.group(1)).relative_to(CUR)/m.group(2)))
allow={
'cmd/gxb-api/main_postgres.go','internal/adapters/postgres/contentstore/hero_fumo.go','internal/adapters/stockruntime/hero_ca2_3_test.go','internal/adapters/stockruntime/hero_ca4_2_test.go','internal/adapters/stockruntime/hero_ca4_3a_test.go','internal/adapters/stockruntime/hero_dispatcher.go','internal/application/characterhero/fumo_service.go','internal/application/characterhero/fumo_service_test.go','internal/application/characterhero/service.go','internal/application/characterhero/testdata/ca4_3a_mid58_adversarial_vectors.json','internal/archguard/ca4_2_contract_test.go','internal/archguard/ca4_3a_contract_test.go','tools/validate_ca4_3a_b.py'}
ck(set(paths)==allow,f'diff allowlist mismatch extra={sorted(set(paths)-allow)} missing={sorted(allow-set(paths))}')
svc=text('internal/application/characterhero/fumo_service.go')
for tok in ['FeedFumo','PrepareHeroEquipmentResourcesTx','ApplyHeroEquipmentResourceDebitTx','SaveHeroStateTx','putHeroFumoReceipt','deriveFumoLevelsTx','checkedMul64(credited, target.ManaPerFumo)','Count: counts[itemID]']:
 ck(tok in svc,f'service missing {tok}')
ck('time.Now' not in svc and 'time.Since' not in svc,'invented time-based dedupe')
ck('FingerprintRequest(map[string]any{"partner_id": partnerID, "equip_index": equipIndex, "materials": materials})' in svc,'receipt fingerprint not exact request')
ck('validateNormalHeroForEquipment' in svc,'Normal-Hero family gate missing')
ck('current < 0 || current >= target.TotalCap' in svc,'cap rejection missing')
ck('if credited > remaining' in svc and 'credited = remaining' in svc,'overfeed clamp missing')
# Vector identity and shape.
vp=CUR/'internal/application/characterhero/testdata/ca4_3a_mid58_adversarial_vectors.json'; vd=json.load(open(vp))
ck(sha(vp)=='063c8b17d72f423b62533d00b4e18453d0b159d1fa1927fc4ef40313ce34b3e7','vector hash drift')
ck(len(vd.get('vectors',[]))==17,'vector count drift')
ck(sum(v['kind']=='SUCCESS' for v in vd['vectors'])==7,'success-vector count drift')
ck(sum(v['kind']=='REJECT' for v in vd['vectors'])==8,'reject-vector count drift')
ck(any(v['kind']=='RECEIPT_REPLAY' for v in vd['vectors']),'receipt vector missing')
ck(any(v['kind']=='PROTOCOL_LIMIT' for v in vd['vectors']),'protocol-limit vector missing')
# Route/projection boundary.
d=text('internal/adapters/stockruntime/hero_dispatcher.go'); main=text('cmd/gxb-api/main_postgres.go')
for tok in ['case 58:','FeedFumo(ctx, actor','"fumo": got.Fumo','"fumo_lev": levels','"economy_": map[string]any{"mana": mana}']: ck(tok in d,f'dispatch missing {tok}')
ck('[]uint16{49, 52, 55, 58, 63, 67, 89}' in main,'MID58 production registration missing')
for bad in ['mustRegister(54','mustRegister(62','case 29:','case 51:','case 57:']:
 ck(bad not in (main+'\n'+d),f'out-of-scope activation {bad}')
# A raw durability remains the only durable authority; B adds no schema owner.
hero=text('internal/domain/character/hero.go') if (CUR/'internal/domain/character/hero.go').exists() else ''
ck(re.search(r'\bFumo\s+HeroFumoSlots\b', hero) is not None,'raw Fumo durable field missing')
ck('fumo_level' not in '\n'.join(p.read_text(errors='replace') for p in (CUR/'migrations').glob('*.sql')).lower(),'durable fumo_level schema leaked')
# Tests/evidence current run.
for p,needle in [('/mnt/data/ca4_3a_b_compat7_gate.log','=== vet all ==='),('/mnt/data/ca4_3a_b_compat7_package_regression.log','SUMMARY packages_run=92 fail=0'),('/mnt/data/ca4_3a_b_exact_attempt_current.log','proxy.golang.org')]:
 ck(Path(p).exists() and needle in Path(p).read_text(errors='replace'),f'evidence missing {p} / {needle}')
# Static guard outputs current tree.
for cmd in [['python3','tools/validate_ca4_3a_b.py'],['python3','tools/check_ca4_3a_source_oracle.py'],['python3','tools/check_schema_query_ownership.py'],['python3','tools/check_sqlc_generation_policy.py']]:
 r=subprocess.run(cmd,cwd=CUR,capture_output=True,text=True); ck(r.returncode==0,f'command failed {cmd}: {r.stdout}{r.stderr}')

if errs:
 print(f'CA4-3A-B INDEPENDENT CHECK: FAIL {checks-len(errs)}/{checks}')
 for e in errs: print(' -',e)
 sys.exit(1)
print(f'CA4-3A-B INDEPENDENT CHECK: PASS {checks}/{checks}')
print('Pass543->B delta bounded; MID58/I5/receipt/projection/route semantics qualified; later stages absent; protocol-limit remains explicit.')
