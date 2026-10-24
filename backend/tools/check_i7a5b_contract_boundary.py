#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,re
b=Path(__file__).resolve().parents[1];sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
j=json.load(open(b/'docs/i7a5b/PASS642_I7A5B_CONTRACT_INDEX.json'))
for row in j['contracts']:
 p=b/'docs/i7a5b'/Path(row['path']).name
 assert p.is_file() and sha(p)==row['sha256'],p
app=(b/'internal/application/channelchat/structured.go').read_text()
assert all(x not in app for x in ['encoding/json','protocol/amf3','32782','32783','SELECT ','INSERT ','UPDATE ','Begin('])
assert 'ReadOnly: true' in app and 'MaxAttempts: 1' in app and 'tx.DefiniteCommit' in app
for p in list((b/'cmd').rglob('*.go'))+list((b/'internal').rglob('*.go')):
 if p.name.endswith('_test.go'):continue
 text=p.read_text();assert not re.search(r'structuredEnabled\s*[:=]\s*true',text),p
main=(b/'cmd/gxb-realtime/main_postgres.go').read_text();assert 'NewChannelChatDispatcher' in main and 'Owners:' not in main
wire=(b/'internal/protocol/realtime/channel_structured.go').read_text();assert 'MaxStructuredJSONBytes = 8192' in wire and 'depth > 4' in wire and 'values > 512' in wire and 'keys > 64' in wire and 'len(a) >= 64' in wire
assert 'validateRole = ValidateChannelChatForRole' in (b/'internal/protocol/realtime/channel_chat.go').read_text()
print(json.dumps({'status':'PASS_I7A5B_FINITE_INACTIVE_BOUNDARY','production_structured_activation':False,'unknown36863_activation':False,'actual_owner_proof':False}))
