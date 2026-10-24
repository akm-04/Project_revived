#!/usr/bin/env python3
"""Build/check the immutable I6C Guild-core policy from verified client sources.

Source-proven numeric/string rows come from hash-bound misc.lua and message.lua.
Calendar windows, allocator policy, icon-frame compatibility, moderation boundary,
and offline succession activation remain explicit reconstruction-policy constants
from the Pass498 implementation contract; they are not inferred from the client.
"""
from __future__ import annotations
import argparse, fnmatch, hashlib, json, re, sys, zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
LOCK=json.loads((ROOT/'oracles.lock.json').read_text())
OUT=ROOT/'internal/content/guildpolicy/generated/guild_core_policy.json'
CUR_MISC='app-assets/output/assets/src_64/data/tables/misc.lua'
OLD_MISC='src/data/tables/misc.lua'
CUR_MESSAGE='app-assets/output/assets/src_64/data/tables/message.lua'
OLD_MESSAGE='src/data/tables/message.lua'
CUR_MISC_SHA='058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a'
OLD_MISC_SHA='9c6b222db3a7b1eb14cd719de61339ed17b7010403a89bbdb46a47055c11d3c8'
CUR_MESSAGE_SHA='538875e1f791c1faf2c0ad113eb73b1d3a53d1c07d9738f4c70315fa59e00e1d'
OLD_MESSAGE_SHA='c4b988d1b228caeb15dbf193a486ad81f2a10608575e6aa404f4d768cb757481'

PROVEN_KEYS={
 'create_level':'guild_create_lev','create_crystal_cost':'guild_create_diamond',
 'rename_crystal_cost':'guild_modifyname_diamond','guild_applicant_cap':'guild_apply_limit',
 'name_max_chars':'guild_create_name_limit','join_other_after_leave_seconds':'guild_joinnew_interval',
 'reapply_previous_guild_seconds':'guild_joinold_interwal','join_level_min':'guild_level_min',
 'join_level_max':'guild_level_max','joins_limit':'guild_join_limit',
 'outgoing_application_cap':'guild_request_limit','bulletin_max_chars':'guild_bulletin_limit',
 'member_cap':'guild_people_limit','name_min_chars':'guild_create_name_lower_bound',
 'bulletin_min_chars':'guild_bulletin_lower_bound','leader_offline_seconds':'guild_offline_chief',
 'initial_vitality':'guild_vitality','invite_send_limit':'invite_guild_num_daily',
 'invite_lifetime_seconds':'invite_guild_time',
}
CORROBORATED=tuple(PROVEN_KEYS.values())

def sha(b:bytes)->str:return hashlib.sha256(b).hexdigest()
def file_sha(p:Path)->str:
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''):h.update(b)
 return h.hexdigest()
def oracle(oid:str, root:Path)->Path:
 o=next(x for x in LOCK['oracles'] if x['id']==oid)
 for p in sorted(root.iterdir()):
  if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in o['filename_patterns']) and file_sha(p)==o['sha256']:
   return p
 raise SystemExit(f'{oid}: verified oracle not found under {root}')
def rows(text:str)->dict[str,str]:
 # misc.lua records are { "key", "value", "type", "comment" }. Restrict
 # extraction to the first two quoted fields; duplicate keys fail closed.
 pat=re.compile(r'\{\s*"([^"]+)"\s*,\s*"([^"]*)"\s*,',re.S)
 out={}
 for k,v in pat.findall(text):
  if k in out: raise SystemExit(f'duplicate misc key: {k}')
  out[k]=v
 return out

def message_rows(text:str)->dict[int,str]:
 # message.lua records are { "code", "zh", "en", "kind" }. Bind the exact
 # hash first, then extract only the code and English text needed by Guild.
 pat=re.compile(r'\{\s*"(\d+)"\s*,\s*"[^"]*"\s*,\s*"([^"]*)"\s*,\s*"[^"]*"\s*\}',re.S)
 out={}
 for code,en in pat.findall(text):
  i=int(code)
  if i in out: raise SystemExit(f'duplicate message code: {i}')
  out[i]=en
 return out

def build(root:Path)->dict:
 curzip,oldzip=oracle('current_src64',root),oracle('old_client',root)
 with zipfile.ZipFile(curzip) as z:
  cb=z.read(CUR_MISC); cmb=z.read(CUR_MESSAGE)
 with zipfile.ZipFile(oldzip) as z:
  ob=z.read(OLD_MISC); omb=z.read(OLD_MESSAGE)
 if sha(cb)!=CUR_MISC_SHA: raise SystemExit(f'current misc hash drift: {sha(cb)}')
 if sha(ob)!=OLD_MISC_SHA: raise SystemExit(f'old misc hash drift: {sha(ob)}')
 if sha(cmb)!=CUR_MESSAGE_SHA: raise SystemExit(f'current message hash drift: {sha(cmb)}')
 if sha(omb)!=OLD_MESSAGE_SHA: raise SystemExit(f'old message hash drift: {sha(omb)}')
 c,o=rows(cb.decode('utf-8-sig')),rows(ob.decode('utf-8-sig'))
 cm,om=message_rows(cmb.decode('utf-8-sig')),message_rows(omb.decode('utf-8-sig'))
 for k in CORROBORATED:
  if k not in c or k not in o: raise SystemExit(f'missing corroborated key {k}')
  if c[k]!=o[k]: raise SystemExit(f'current/historical disagreement {k}: {c[k]} != {o[k]}')
 def iv(k:str)->int:
  try:return int(c[k])
  except Exception as e:raise SystemExit(f'invalid integer {k}={c.get(k)!r}: {e}')
 icons=[int(x) for x in c.get('guild_avatar','').split('|') if x]
 if not icons or len(set(icons))!=len(icons): raise SystemExit('invalid/duplicate guild_avatar source list')
 expected_deputy='You can choose 5 vice leaders at most in one guild'
 if cm.get(30018)!=expected_deputy or om.get(30018)!=expected_deputy:
  raise SystemExit(f'Guild deputy-limit message drift: current={cm.get(30018)!r} historical={om.get(30018)!r}')
 m=re.search(r'choose (\d+) vice leaders', cm[30018])
 if not m: raise SystemExit('unable to recover deputy limit from hash-bound message 30018')
 deputy_limit=int(m.group(1))
 d={name:iv(key) for name,key in PROVEN_KEYS.items()}
 d.update({
  'deputy_limit':deputy_limit,
  'guild_icons':icons,
  'guild_id_allocator':'LOGICAL_SERVER_BAND_MONOTONIC_NONREUSED_V1',
  'icon_frame_policy':'ZERO_ONLY_EFFECTIVE_CLIENT_V1_FUNCTION_NOT_OPEN',
  'invite_send_window':'ROLLING_24H_V1_POSTGRES_DECISION_TIME',
  'join_limit_window':'ROLLING_7D_V1_POSTGRES_DECISION_TIME',
  'offline_leader_succession':'PRESENCE_PROVIDER_GATED_AND_SUCCESSOR_SELECTION_POLICY_GATED',
  'profile':'guild-core-effective-client-v1',
  'source_current_misc_sha256':CUR_MISC_SHA,
  'source_historical_misc_sha256':OLD_MISC_SHA,
  'source_current_message_sha256':CUR_MESSAGE_SHA,
  'source_historical_message_sha256':OLD_MESSAGE_SHA,
  'text_policy':'BOUNDED_UTF8_AND_SOURCE_LENGTHS_ONLY_SERVER_PROFANITY_POLICY_UNQUALIFIED',
 })
 return d

def encoded(d:dict)->bytes:
 return (json.dumps(d,sort_keys=True,separators=(',',':'),ensure_ascii=False)+'\n').encode()

def main()->int:
 ap=argparse.ArgumentParser(); ap.add_argument('--oracle-root',default='/mnt/data'); ap.add_argument('--check',action='store_true'); ap.add_argument('--output',type=Path,default=OUT); a=ap.parse_args()
 b=encoded(build(Path(a.oracle_root)))
 if a.check:
  if not a.output.exists() or a.output.read_bytes()!=b:
   print('I6C GUILD POLICY BUILD: FAIL (generated artifact drift)'); return 1
  print('I6C GUILD POLICY BUILD: PASS')
  print(f'artifact_sha256={sha(b)} source_current_misc={CUR_MISC_SHA} source_historical_misc={OLD_MISC_SHA} source_current_message={CUR_MESSAGE_SHA} source_historical_message={OLD_MESSAGE_SHA}')
  return 0
 a.output.parent.mkdir(parents=True,exist_ok=True); a.output.write_bytes(b)
 print(f'wrote {a.output} sha256={sha(b)}'); return 0
if __name__=='__main__': raise SystemExit(main())
