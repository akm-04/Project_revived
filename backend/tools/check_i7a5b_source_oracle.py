#!/usr/bin/env python3
from pathlib import Path
import sys,json,hashlib
b=Path(__file__).resolve().parents[1];src=Path(sys.argv[1]);j=json.load(open(b/'docs/i7a5b/SOURCE_IDENTITY.json'))
for row in j['members']:
 p=src/row['cache'].removeprefix('source_cache/current/');assert hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],p
print(json.dumps({'status':'PASS_I7A5B_EXACT_SRC64','current_members':len(j['members']),'original_server_truth':False,'physical_client_execution':False}))
