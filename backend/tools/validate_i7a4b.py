#!/usr/bin/env python3
"""Additional selected4B static boundary checks; native semantics are a separate gate."""
from pathlib import Path
import hashlib,json,subprocess,sys
R=Path(__file__).resolve().parents[1]
failures=[]
def check(v,m):
 if not v:failures.append(m)
pins={'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d','.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718','migrations/00033_i7a4a_social_foundation.sql':'59f919552065ef0c8bbd9629e1f7aa471095abebd02de7f2db256a171a4d25ed'}
for p,h in pins.items():check(hashlib.sha256((R/p).read_bytes()).hexdigest()==h,'pin/migration drift '+p)
for script in ['validate_i7a4a.py','check_schema_query_ownership.py']:
 check(subprocess.run([sys.executable,str(R/'tools'/script)],cwd=R).returncode==0,'retained guard failed '+script)
for rel in ['internal/application/socialrelation','internal/application/socialinbox']:
 for p in (R/rel).glob('*.go'):
  if p.name.endswith('_test.go'):continue
  s=p.read_text()
  for forbidden in ['internal/adapters','internal/protocol','database/sql','github.com/jackc/pgx','time.Now(','INSERT INTO ','UPDATE ','DELETE FROM ','SELECT ']:check(forbidden not in s,str(p.relative_to(R))+' forbidden '+forbidden)
for rel in ['internal/adapters/socialpresentation/transaction_reader.go','internal/application/playerpresentation/transaction.go']:
 s=(R/rel).read_text()
 for forbidden in ['pgxpool','time.Now(','Begin(', 'Commit(', 'INSERT INTO ', 'UPDATE ', 'DELETE FROM ']:check(forbidden not in s,rel+' forbidden '+forbidden)
check(not list((R/'migrations').glob('00034*')),'unexpected migration00034')
check('//go:build postgres && socialintegration' in (R/'internal/integration/socialrelation/commands_test.go').read_text(),'native fixtures must require explicit socialintegration tag')
info=json.loads((R/'BUILD_INFO.json').read_text());check(info.get('i7a4b',{}).get('stock_activation') is False,'candidate metadata must keepstock invisible')
check(info.get('i7a4b',{}).get('acceptance')=='NOT_ACCEPTED_CANDIDATE_ONLY','candidate must not accept itself')
if failures:
 print('I7A4B STATIC VALIDATION: FAIL');print('\n'.join(failures));raise SystemExit(1)
print('I7A4B STATIC VALIDATION: PASS; native20-case gate/source consumer/reality evidence separately required')
