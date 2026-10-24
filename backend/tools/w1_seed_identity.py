#!/usr/bin/env python3
"""Generate a deterministic W1-only identity/session seed SQL file.

This does not mutate PostgreSQL. It turns operator-supplied stock SID/login_token
values into the exact V2 at-rest HMAC digests so Work mode can seed an already-
logged-in unmodified client without adding a private authentication bypass.
"""
from __future__ import annotations
import argparse,hashlib,hmac,sys,uuid

def digest(secret:bytes,label:str,raw:str)->bytes:
 return hmac.new(secret,b'gxb-v2/credential/v1\x00'+label.encode()+b'\x00'+raw.encode(),hashlib.sha256).digest()

def q(s:str)->str:return "'"+s.replace("'","''")+"'"
p=argparse.ArgumentParser()
p.add_argument('--sid',required=True);p.add_argument('--login-token',required=True)
p.add_argument('--digest-secret',required=True)
p.add_argument('--output',required=True)
p.add_argument('--account-id',default='11111111-1111-4111-8111-111111111111')
p.add_argument('--account-uid',required=True,help='stock-visible stable account UID; do not substitute player_id')
p.add_argument('--session-id',default='22222222-2222-4222-8222-222222222222')
a=p.parse_args()
sec=a.digest_secret.encode()
if len(sec)<16:sys.exit('digest secret must be >=16 bytes')
for x in [a.account_id,a.session_id]: uuid.UUID(x)
sid=digest(sec,'sid',a.sid).hex(); login=digest(sec,'login_token',a.login_token).hex()
sidcid=str(uuid.uuid5(uuid.UUID(a.session_id),'w1-sid')); logcid=str(uuid.uuid5(uuid.UUID(a.session_id),'w1-login-token'))
sql=f'''-- W1 TEST FIXTURE ONLY. Never package raw SID/login_token in PassMap/backend.\nBEGIN;\nINSERT INTO accounts(account_id,account_uid,status,created_at,liveness_version) VALUES ({q(a.account_id)},{q(a.account_uid)},'ACTIVE',CURRENT_TIMESTAMP,1) ON CONFLICT(account_id) DO UPDATE SET account_uid=EXCLUDED.account_uid,status='ACTIVE',disabled_at=NULL,liveness_version=accounts.liveness_version+1;\nINSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at,liveness_version) VALUES ({q(a.session_id)},{q(a.account_id)},'SID_LOGIN_TOKEN_PAIR',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,1) ON CONFLICT(session_id) DO UPDATE SET revoked_at=NULL,revocation_reason=NULL,last_activity_at=CURRENT_TIMESTAMP,liveness_version=account_sessions.liveness_version+1;\nDELETE FROM account_session_credentials WHERE session_id={q(a.session_id)};\nINSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at) VALUES\n ({q(sidcid)},{q(a.session_id)},'SID',decode('{sid}','hex'),CURRENT_TIMESTAMP),\n ({q(logcid)},{q(a.session_id)},'LOGIN_TOKEN',decode('{login}','hex'),CURRENT_TIMESTAMP);\nCOMMIT;\n'''
open(a.output,'w',encoding='utf-8').write(sql)
print(a.output)
