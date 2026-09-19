#!/usr/bin/env python3
from __future__ import annotations
import fnmatch,hashlib,json,sys,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')
lock=json.loads((ROOT/'oracles.lock.json').read_text())
fixture=json.loads((ROOT/'testdata/sourcefacts/pass446_i5_player_core.json').read_text())
def fsha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''):h.update(b)
 return h.hexdigest()
def locate(oid):
 o=next(x for x in lock['oracles'] if x['id']==oid)
 for p in sorted(OROOT.iterdir()):
  if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in o['filename_patterns']) and fsha(p)==o['sha256']: return p
 raise SystemExit(f'{oid}: verified oracle not found')
def shab(b):return hashlib.sha256(b).hexdigest()
cur=locate('current_src64');v1=locate('v1_pass353');old=locate('old_client')
paths={
 'SelfPlayer.lua':'app-assets/output/assets/src_64/app/model/SelfPlayer.lua',
 'Mailbox.lua':'app-assets/output/assets/src_64/app/model/Mailbox.lua',
 'MailboxWindow.lua':'app-assets/output/assets/src_64/app/windows/MailboxWindow.lua',
 'Task.lua':'app-assets/output/assets/src_64/app/model/Task.lua',
 'Backpack.lua':'app-assets/output/assets/src_64/app/model/Backpack.lua',
 'ItemTable.lua':'app-assets/output/assets/src_64/app/common/tables/ItemTable.lua',
 'ExchangeCodeWindow.lua':'app-assets/output/assets/src_64/app/windows/ExchangeCodeWindow.lua',
 'Backend.lua':'app-assets/output/assets/src_64/app/common/network/Backend.lua',
 'mid.lua':'app-assets/output/assets/src_64/app/common/network/mid.lua',
 'StoryData.lua':'app-assets/output/assets/src_64/app/common/StoryData.lua',
}
errs=[];txt={}
with zipfile.ZipFile(cur) as z:
 for k,p in paths.items():
  b=z.read(p); got=shab(b); exp=fixture['current_src64'][k]
  if got!=exp:errs.append(f'current source hash drift {k}: {got}')
  txt[k]=b.decode('utf-8-sig',errors='replace')
 enums=z.read('app-assets/output/assets/src_64/app/common/enums.lua').decode('utf-8-sig',errors='replace')
checks=[
 ('player core stock fields', all(x in txt['SelfPlayer.lua'] for x in ['params.exp','params.lev','params.func_ids','params.player_name','params.avatar_id','params.player_type','params.guide_function_ids','params.guide_return_id'])),
 ('story SAVE_STORY exact fields', all(x in txt['StoryData.lua'] for x in ['xyd.mid.SAVE_STORY','story_id =','story_state =','guide_id ='])),
 ('GUIDE_END source marker', 'xyd.GuideStoryType.GUIDE_END = 100197' in enums),
 ('mail MID identities', all(x in txt['mid.lua'] for x in ['xyd.mid.LOAD_MAIL_LIST = 368','xyd.mid.SET_MAIL_READ = 369','xyd.mid.MAIL_ONEKEY = 370'])),
 ('mail compound identity', 'id = arg_14_1.id' in txt['Mailbox.lua'] and 'is_region = arg_14_1.is_region' in txt['Mailbox.lua'] and 'iter_8_1.id == var_8_1.id and iter_8_1.is_region == var_8_1.is_region' in txt['Mailbox.lua']),
 ('mail namespace batch split', all(x in txt['MailboxWindow.lua'] for x in ['onekeyIds.region_ids','onekeyIds.normal_ids','if iter_7_1.is_region then'])),
 ('one-key current client bound is 20 before warning path', 'local var_0_4 = 20' in txt['MailboxWindow.lua']),
 ('mail claim response reward channels', 'var_8_0.rewards' in txt['Mailbox.lua'] and 'var_12_0.awards' in txt['Mailbox.lua'] and 'var_12_0.mail_list.mail_list' in txt['Mailbox.lua']),
 ('item stack cap and mail-overflow hint', 'xyd.tables.item:stack(arg_12_1.itemID)' in txt['Backpack.lua'] and 'xyd.tables.item:stackMail(arg_12_1.itemID) == 1' in txt['Backpack.lua'] and 'stack_exceed_mail' in txt['ItemTable.lua']),
 ('reward and task are sibling channels', 'handleRewards(arg_36_1.extra_drops_)' in txt['Backend.lua'] and ':onTaskBackendEvent(arg_36_1)' in txt['Backend.lua']),
 ('task families source-shaped', all(x in txt['Task.lua'] for x in ['daily_mission_','mainline_mission_','partner_mission_','awake_mission_'])),
 ('redeem wire stable current', 'code = arg_5_0:nodeByName("name_txt"):getString()' in txt['ExchangeCodeWindow.lua'] and 'platform = cc.Application:getInstance():getTargetPlatform()' in txt['ExchangeCodeWindow.lua'] and 'request(xyd.mid.REDEEM_CODE' in txt['ExchangeCodeWindow.lua'] and 'arg_5_0:handleRewards(arg_7_1.awards)' in txt['ExchangeCodeWindow.lua']),
 ('MID230 numeric stable current', 'xyd.mid.REDEEM_CODE = 230' in txt['mid.lua']),
]
for label,ok in checks:
 if not ok:errs.append('current source fact missing '+label)
# Cross-version Redeem stability is source evidence, not V1 backend policy.
with zipfile.ZipFile(old) as z:
 candidates=[n for n in z.namelist() if n.endswith('/app/windows/ExchangeCodeWindow.lua') or n=='src/app/windows/ExchangeCodeWindow.lua']
 if not candidates: errs.append('old-client ExchangeCodeWindow.lua missing')
 else:
  ob=z.read(candidates[0])
  if shab(ob)!=fixture['current_src64']['ExchangeCodeWindow.lua']: errs.append('old-client/current redeem window no longer byte-identical')
# Pass353 is used only to corroborate mechanism classes that must not be copied wholesale.
with zipfile.ZipFile(v1) as z:
 names=set(z.namelist())
 for n in ['gxb_backend/mail/service.py','gxb_backend/mail/repository.py','gxb_backend/state/reward_transaction_service.py']:
  if n not in names:errs.append('Pass353 corroborative mechanism missing '+n)
 if 'gxb_backend/mail/service.py' in names:
  t=z.read('gxb_backend/mail/service.py').decode(errors='replace')
  if 'MailClaimService' not in t or 'load_locked' not in t or 'settlement.settle' not in t:errs.append('Pass353 mail atomic-claim corroboration missing')
if errs:
 print('I5 ORACLE PLAYER-CORE CHECK: FAIL');[print(' -',e) for e in errs];raise SystemExit(1)
print('I5 ORACLE PLAYER-CORE CHECK: PASS')
print('verified current src_64 player/story/mail/stack/task/redeem facts; old-client MID230 stability; Pass353 mechanisms corroborative only')
