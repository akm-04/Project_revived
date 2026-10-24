#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,re,sys
R=Path(__file__).resolve().parents[1]; errs=[]
def need(rel,*tokens):
 p=R/rel
 if not p.exists(): errs.append(f'missing {rel}'); return ''
 s=p.read_text(errors='replace')
 for t in tokens:
  if t not in s: errs.append(f'{rel}: missing {t!r}')
 return s
def req(x,msg):
 if not x: errs.append(msg)

manifest=json.loads(need('internal/content/builtin/generated/manifest.json') or '{}')
later='HERO_PROMOTION_RESTORATION_CA4_3B' in manifest.get('enabled_capabilities',[])
ca45='SUPER_EQUIPMENT_CA4_5' in manifest.get('enabled_capabilities',[])

svc=need('internal/application/characterhero/fumo_service.go','func (s Service) FeedFumo(','aggregateFumoMaterials','PrepareHeroEquipmentResourcesTx','ApplyHeroEquipmentResourceDebitTx','putHeroFumoReceipt','deriveFumoLevelsTx','ErrHeroFumoUnavailable')
for tok in ['credited = remaining','checkedMul64(credited, target.ManaPerFumo)','Count: counts[itemID]','SaveHeroStateTx','PolicyVersion = "pass542-ca4-3a"']:
 req(tok in svc,f'MID58 service missing {tok!r}')
req('time.Now' not in svc and 'time.Since' not in svc,'MID58 invented wall-clock dedupe/time heuristic')

hd=need('internal/adapters/stockruntime/hero_dispatcher.go','case 58:','FeedFumo(ctx, actor','"fumo": got.Fumo','"fumo_lev": levels','"economy_": map[string]any{"mana": mana}')
main=need('cmd/gxb-api/main_postgres.go','Fumo: contentDB','heroD := stockruntime.HeroDispatcher')
route=re.search(r'for _, mid := range \[]uint16\{([^}]*)\} \{\s*mustRegister\(mid, heroD\)',main,re.S)
req(bool(route) and re.search(r'(^|\D)58(\D|$)',route.group(1)) is not None,'MID58 not production registered in Hero route set')
if ca45:
 req(bool(route) and all(re.search(rf'(^|\D){mid}(\D|$)', route.group(1)) is not None for mid in (54,62)), 'CA4-5 MID54/62 production registration missing')
else:
 req(not route or re.search(r'(^|\D)(54|62)(\D|$)',route.group(1)) is None,'MID54/62 production registration leaked before CA4-5')

# Historical B-stage leak guards permit qualified CA4-3B promotion while Quick
# Fumo and the shared CA4-2 production deferrals remain enforced.
req('case 29:' not in hd,'out-of-scope dispatcher leaked case 29:')
if not later:
 for token in ['case 51:', 'case 57:']:
  req(token not in hd,f'out-of-scope dispatcher leaked {token}')
else:
 for token in ['case 51:', 'case 57:']:
  req(token in hd,f'qualified CA4-3B dispatcher missing {token}')
for p in (R/'internal/application/characterhero').glob('*.go'):
 if p.name.endswith('_test.go'): continue
 s=p.read_text(errors='replace')
 for token in ['QuickFumo','PromotionReset','ResetFumo','RestoreFumo']:
  if token in s: errs.append(f'out-of-scope CA4-3B/quick mechanic in {p.relative_to(R)}: {token}')

# Sealed vector fixture identity is immutable.
vec=R/'internal/application/characterhero/testdata/ca4_3a_mid58_adversarial_vectors.json'
req(vec.exists(),'missing sealed MID58 vector fixture')
if vec.exists():
 req(hashlib.sha256(vec.read_bytes()).hexdigest()=='063c8b17d72f423b62533d00b4e18453d0b159d1fa1927fc4ef40313ce34b3e7','MID58 vector fixture drift')

expected={
 '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
 'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4',
 'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,want in expected.items():
 got=hashlib.sha256((R/rel).read_bytes()).hexdigest(); req(got==want,f'canonical pin changed {rel}: {got}')

if errs:
 print('CA4-3A-B VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-3A-B VALIDATION: PASS')
print('MID58 service/receipt/I5 debit/dispatcher/Mana projection/production registration present; CA4-5 shared MID54/62 activation is qualified' if ca45 else ('MID58 service/receipt/I5 debit/dispatcher/Mana projection/production registration present; qualified CA4-3B promotion is permitted while Quick Fumo and MID54/62 activation remain absent' if later else 'MID58 service/receipt/I5 debit/dispatcher/Mana projection/production registration present; later-stage writers and MID54/62 activation remain absent'))
