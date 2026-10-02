#!/usr/bin/env python3
from __future__ import annotations
import fnmatch,hashlib,json,re,sys,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')
lock=json.loads((ROOT/'oracles.lock.json').read_text())
def fsha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''):h.update(b)
 return h.hexdigest()
def locate(oid):
 o=next(x for x in lock['oracles'] if x['id']==oid)
 for p in sorted(OROOT.iterdir()):
  if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in o['filename_patterns']) and fsha(p)==o['sha256']:
   return p
 raise SystemExit(f'{oid}: verified oracle not found')
def member(z,n):
 with zipfile.ZipFile(z) as q:return q.read(n)
def sha(b):return hashlib.sha256(b).hexdigest()
errs=[]
cur=locate('current_src64'); v1=locate('v1_pass353')
paths={
 'backend':'app-assets/output/assets/src_64/app/common/network/Backend.lua',
 'mid':'app-assets/output/assets/src_64/app/common/network/mid.lua',
 'selfplayer':'app-assets/output/assets/src_64/app/model/SelfPlayer.lua',
 'selfguild':'app-assets/output/assets/src_64/app/model/SelfGuild.lua',
 'loading':'app-assets/output/assets/src_64/app/scenes/LoadingScene.lua',
 'update':'app-assets/output/assets/src_64/UpdateScene.lua',
 'login':'app-assets/output/assets/src_64/app/windows/LoginWindow.lua',
 'whitealbum':'app-assets/output/assets/src_64/app/windows/WhiteAlbumWindow.lua',
 'collect_special':'app-assets/output/assets/src_64/data/tables/collect_special.lua',
}
expected={
 'backend':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840',
 'mid':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
 'selfplayer':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
 'selfguild':'c744e6f256a796a98613911372c1821b3e02f21d38480184df9c095373bd64f9',
 'loading':'01c0e71ceee0f08f747552af66bd0f907ebfff1257be58ec480d3606a88f4a17',
 'update':'52c78a98002a27532343334360bd264af02700cbbda631d3b0cbf367e55516ac',
 'login':'8b91542e1f0648a2a859e9618a8a9c64dd46f9961fb8a049d0b06ce2cabec7e0',
 'whitealbum':'851a53f588b59d95cfe460f3399ab1a6904fff7714131c358f3c3a73910b6bb9',
 'collect_special':'5c159c89f7ffcbfb698d9599539a897896ce0e9ab93e7d04875d012d59df509a',
}
with zipfile.ZipFile(cur) as z:
 txt={}
 for k,n in paths.items():
  b=z.read(n)
  if sha(b)!=expected[k]:errs.append(f'current source hash drift: {k} {sha(b)}')
  txt[k]=b.decode('utf-8-sig',errors='replace')
b=txt['backend']; m=txt['mid']; sp=txt['selfplayer']; sg=txt['selfguild']; loading=txt['loading']; update=txt['update']; login=txt['login']; whitealbum=txt['whitealbum']; collect_special=txt['collect_special']
region_window=member(cur, 'app-assets/output/assets/src_64/app/windows/RegionWindow.lua').decode('utf-8-sig',errors='replace')
main_up=member(cur, 'app-assets/output/assets/src_64/app/windows/MainSceneUpWindow.lua').decode('utf-8-sig',errors='replace')
edit_name=member(cur, 'app-assets/output/assets/src_64/app/windows/EditPlayerNameWindow.lua').decode('utf-8-sig',errors='replace')
avatar_data=member(cur, 'app-assets/output/assets/src_64/data/tables/avatar.lua').decode('utf-8-sig',errors='replace')
checks=[
 ('UpdateScene MID20480 center discovery is pre-context', 'mid = 20480' in update and 'xyd.serverUrl = arg_12_0.url' in update and 'xyd.resDownloadUrl = arg_12_0.res_download_url' in update),
 ('UpdateScene MID2 version check is pre-context', 'mid = 2' in update and 'arg_18_0.is_appstore ~= 0' in update and 'arg_18_0.is_inapp ~= 0' in update),
 ('MID7 announce remains a current HTTP symbol/event surface', 'xyd.mid.LOAD_ANNOUNCE = 7' in m and 'xyd.mid.LOAD_ANNOUNCE' in b),
 ('SelfPlayer prelogin AB-test scalar exists', 'xyd.mid.GET_PLAYER_GROUP_BY_KEY' in sp and 'arg_285_0.abtestGroup[arg_285_1] = arg_286_1' in sp),
 ('MID192 numeric', 'xyd.mid.LOAD_CHAT_ROOM_INFO = 192' in m),
 ('TCP IDs', all(x in m for x in ['xyd.mid.TCP_LOGIN = 32771','xyd.mid.CHAT_ROOM_ENTERED = 32779','xyd.mid.SOCKET_HEARTBEAT = 32797'])),
 ('three stock sockets only', all(x in b for x in ['socket_','leagueSocket_','serviceSocket_'])),
 ('MID192 room claim', 'request(xyd.mid.LOAD_CHAT_ROOM_INFO' in b and 'room_id =' in b),
 ('discovery consumes host port room', all(x in b for x in ['arg_10_1.host','arg_10_1.port','arg_10_1.room_id'])),
 ('TCP_LOGIN token region room', all(x in b for x in ['token = arg_39_0.token_','region = arg_39_0.region_','var_39_0.room_id','sendMessage(xyd.mid.TCP_LOGIN'])),
 ('room entered arms heartbeat', 'arg_47_2 == xyd.mid.CHAT_ROOM_ENTERED' in b and 'sendMessage(xyd.mid.SOCKET_HEARTBEAT' in b),
 ('heartbeat payload empty object', 'local var_49_0 = {}' in b and 'local var_50_0 = {}' in b and 'local var_51_0 = {}' in b),
 ('reconnect path exists', 'performWithDelayGlobal(function()' in b and ':enterChatRoom()' in b and ':enterServiceChatRoom()' in b),
 ('MID1 log_url consumed', 'arg_23_0.logURL_ = arg_27_0.log_url' in b),
 ('empty log_url disables upload', 'arg_4_0.logURL_ == nil or #arg_4_0.logURL_ <= 0' in b),
 ('MID1 server_time sideband supported', 'arg_36_1.server_time ~= nil' in b and 'resetServerTime(arg_36_1.server_time)' in b),
 ('MID1 loading defaults', all(x in loading for x in ['story_type or xyd.storyABTest.Battle','tonumber(arg_30_1.is_debug) or 0','tonumber(arg_30_1.is_old_top) or 0'])),
 ('account uid/player identity are distinct stock fields', 'arg_215_0.uid = arg_215_1.params.uid' in sp and 'arg_9_0.uid = arg_9_1.params.uid' in sp and 'tostring(var_172_0.uid)' in member(cur, 'app-assets/output/assets/src_64/app/common/utils.lua').decode('utf-8-sig',errors='replace') and 'tostring(var_172_0.playerID)' in member(cur, 'app-assets/output/assets/src_64/app/common/utils.lua').decode('utf-8-sig',errors='replace')),
 ('MID1 20018 special case', 'error_code ~= 20018' in loading),
 ('MID1304 array semantics', 'xyd.mid.GET_OFFLINE_INFO' in sp and 'if #var_221_29 > 0 then' in sp),
 ('MID2784 current symbol identity', 'xyd.mid.ALBUM_SPECIAL_COLLECT_INFO = 2784' in m),
 ('MID2784 SelfPlayer consumes is_award as indexed collection', 'arg_269_0.albumSpecialCollect = arg_270_1.is_award' in sp and 'for iter_271_3 = 1, #arg_271_0.albumSpecialCollect do' in sp and 'arg_271_0.albumSpecialCollect[iter_271_3]' in sp),
 ('WhiteAlbumWindow consumes albumSpecialCollect as indexed collection', 'for iter_4_0 = 1, #arg_4_0.selfPlayer.albumSpecialCollect do' in whitealbum and 'arg_5_0.selfPlayer.albumSpecialCollect[arg_6_0]' in whitealbum),
 ('guild enroll truthiness', 'if var_103_0.is_enroll then' in sg),
 ('MID18 player summary fields are directly consumed', all(x in region_window for x in ['arg_3_0.lev > arg_3_1.lev','var_8_15.vip > 0','tonumber(var_8_15.lev)','var_8_15.avatar_id','var_8_15.avatar_frame_id','var_8_15.conquer_lev','var_8_15.conquer_loop_id'])),
 ('blank player name remains stock lifecycle signal', 'player.playerName == ""' in main_up and 'playerName == ""' in edit_name),
 ('110001001 exists as current initial-owned avatar row', '"110001001"' in avatar_data and '"初始擁有"' in avatar_data),
]
# Current White Album special-set compatibility is content-bound. Parse only
# the first field of each top-level row and require the exact current 1..23 ID set.
collect_special_ids=[int(x) for x in re.findall(r'\r?\n\t\t\{\r?\n\t\t\t"(\d+)",', collect_special)]
if collect_special_ids != list(range(1,24)):
 errs.append('current collect_special IDs/cardinality drift: '+repr(collect_special_ids))
for label,ok in checks:
 if not ok:errs.append('current source fact missing '+label)
# Every direct SelfPlayer MID17 hydration field except optional buff_exp must be
# present in the I4 structural projection. This intentionally checks keys, not
# values; values remain bounded bootstrap policy until their owning domains land.
import re
src_fields=[]
fn_start=sp.find('function var_0_0.onPlayerInfo_')
fn_end=sp.find('\nfunction ', fn_start+10)
for fld in re.findall(r'arg_9_1\.params\.([A-Za-z0-9_]+)', sp[fn_start:fn_end]):
 if fld not in src_fields and fld != 'buff_exp': src_fields.append(fld)
shape_text=(ROOT/'internal/projection/lobby/shapes.go').read_text()
missing=[fld for fld in src_fields if f'"{fld}"' not in shape_text]
if missing: errs.append('I4 MID17 structural projection missing current SelfPlayer fields: '+','.join(missing))
# Preserve the current read-only registration boundary for the White Album repair.
# Parse hard-coded registration lists/direct registrations in the production router;
# MID2784 must remain present while mutation MIDs 72/2785 remain unregistered.
api_text=(ROOT/'cmd/gxb-api/main_postgres.go').read_text()
registered={int(x) for x in re.findall(r'mustRegister\(\s*(\d+)\s*,', api_text)}
for body in re.findall(r'for _, mid := range \[\]uint16\{([^}]*)\}\s*\{\s*mustRegister\(mid,', api_text, re.S):
 registered.update(int(x) for x in re.findall(r'\d+', body))
if 2784 not in registered: errs.append('I4 production router lost MID2784 registration')
for forbidden_mid in (72,2785):
 if forbidden_mid in registered: errs.append(f'I4 production router unexpectedly registers White Album mutation MID{forbidden_mid}')
# V1 is corroborative/differential only: verify its recovered realtime/MID192 facts,
# never import its private architecture or stubs into V2.
with zipfile.ZipFile(v1) as z:
 vserver=z.read('gxb_backend/realtime/server.py').decode(errors='replace')
 vchat=z.read('gxb_backend/handlers/chat.py').decode(errors='replace')
 vadm=z.read('gxb_backend/realtime/admission.py').decode(errors='replace')
 vboot=z.read('gxb_backend/handlers/bootstrap.py').decode(errors='replace')
 vpstate=z.read('gxb_backend/state/player_state.py').decode(errors='replace')
 vprotocol=z.read('docs/PLAYER_BOOT_PROTOCOL.md').decode(errors='replace')
 vcenter=z.read('gxb_backend/handlers/center.py').decode(errors='replace')
 vsystem=z.read('gxb_backend/handlers/system.py').decode(errors='replace')
 reality=json.loads(z.read('docs/json/PASS277_SOURCE_REALITY_CHECK.json'))
for label,ok in [
 ('V1 center/version public projections', '"url": self.ctx.settings.self_url' in vcenter and 'version_check_payload' in vcenter),
 ('V1 announce/AB scalar corroboration', 'return {"contents": json.dumps({})}' in vsystem and 'return "B" if key == "mtspy" else "A"' in vsystem),
 ('V1 TCP login validation', 'room_id' in vserver and 'token' in vserver and 'region' in vserver),
 ('V1 room entered projection', 'CHAT_ROOM_ENTERED' in vserver),
 ('V1 MID192 success projection', 'room_id' in vchat and 'room_id' in vadm and 'host' in vadm and 'port' in vadm),
 ('V1 source reality says MID192 authenticated', any('MID192 is authenticated HTTP discovery' in x for x in reality.get('current_src64',{}).get('facts',[]))),
 ('V1 MID1 log_url projection', '"log_url": self.ctx.settings.client_log_url' in vboot),
 ('V1 account uid/player id split', '"uid": account.uid' in vboot and '"uid": self.account_uid' in vpstate and 'uid`: account/session identity' in vprotocol and 'player_id`: game-player identity' in vprotocol),
]:
 if not ok:errs.append(label+' missing')
if errs:
 print('I4 ORACLE WAVE-S CHECK: FAIL'); [print(' -',e) for e in errs]; raise SystemExit(1)
print('I4 ORACLE WAVE-S CHECK: PASS')
print('verified current src_64 UpdateScene MID20480/MID2 + public MID7/MID2864 + MID1 log_url/server_time/default sidebands + room discovery/TCP_LOGIN/room-entered/heartbeat/reconnect + 20018/1304/Lua truthiness + MID2784 collection consumption + collect_special IDs 1..23; Pass353 corroborates bootstrap/realtime shapes only')
