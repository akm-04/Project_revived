#!/usr/bin/env python3
"""Verify narrow client-source facts bounding I6C Guild core.

Hash/lexical corroboration only. This does not make UI reachability server
authority and does not infer unrecovered historical reset/succession policies.
"""
from __future__ import annotations
import fnmatch, hashlib, json, sys, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1] if len(sys.argv)>1 else "/mnt/data")
lock=json.loads((ROOT/"oracles.lock.json").read_text())
fixture=json.loads((ROOT/"testdata/sourcefacts/pass501_i6c_guild_core.json").read_text())

def fsha(p:Path)->str:
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20),b''): h.update(b)
    return h.hexdigest()
def locate(oid:str)->Path:
    o=next(x for x in lock['oracles'] if x['id']==oid)
    for p in sorted(OROOT.iterdir()):
        if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in o['filename_patterns']) and fsha(p)==o['sha256']:
            return p
    raise SystemExit(f"{oid}: verified oracle not found")
def shab(b:bytes)->str:return hashlib.sha256(b).hexdigest()
current=locate('current_src64'); old=locate('old_client')
cp={
 'SelfGuild.lua':'app-assets/output/assets/src_64/app/model/SelfGuild.lua',
 'mid.lua':'app-assets/output/assets/src_64/app/common/network/mid.lua',
 'Backend.lua':'app-assets/output/assets/src_64/app/common/network/Backend.lua',
 'TeamFindWindow.lua':'app-assets/output/assets/src_64/app/windows/TeamFindWindow.lua',
 'TeamMemberManageMenu.lua':'app-assets/output/assets/src_64/app/windows/TeamMemberManageMenu.lua',
 'TeamApplyMemberWindow.lua':'app-assets/output/assets/src_64/app/windows/TeamApplyMemberWindow.lua',
 'TeamManageMenuWindow.lua':'app-assets/output/assets/src_64/app/windows/TeamManageMenuWindow.lua',
 'TeamCreateWindow.lua':'app-assets/output/assets/src_64/app/windows/TeamCreateWindow.lua',
 'TeamSettingWindow.lua':'app-assets/output/assets/src_64/app/windows/TeamSettingWindow.lua',
 'TeamSettingDataWindow.lua':'app-assets/output/assets/src_64/app/windows/TeamSettingDataWindow.lua',
 'GuildDetailWindow.lua':'app-assets/output/assets/src_64/app/windows/GuildDetailWindow.lua',
 'misc.lua':'app-assets/output/assets/src_64/data/tables/misc.lua',
 'message.lua':'app-assets/output/assets/src_64/data/tables/message.lua',
}
op={'SelfGuild.lua':'src/app/model/SelfGuild.lua','mid.lua':'src/app/common/network/mid.lua','Backend.lua':'src/app/common/network/Backend.lua','misc.lua':'src/data/tables/misc.lua','message.lua':'src/data/tables/message.lua'}
errs=[]; cur={}; hist={}
with zipfile.ZipFile(current) as z:
    for n,p in cp.items():
        b=z.read(p); cur[n]=b.decode('utf-8-sig',errors='replace')
        if shab(b)!=fixture['current_src64'][n]: errs.append(f"current hash drift {n}: {shab(b)}")
with zipfile.ZipFile(old) as z:
    for n,p in op.items():
        b=z.read(p); hist[n]=b.decode('utf-8-sig',errors='replace')
        if shab(b)!=fixture['old_client'][n]: errs.append(f"old hash drift {n}: {shab(b)}")
mid=cur['mid.lua']; sg=cur['SelfGuild.lua']; backend=cur['Backend.lua']; misc=cur['misc.lua']; messages=cur['message.lua']; old_messages=hist['message.lua']
checks=[
 ('core MID identities', all(x in mid for x in ['xyd.mid.LOAD_ALL_TEAMS = 576','xyd.mid.CREATE_TEAM = 577','xyd.mid.DISSOLUTION_TEAM = 578','xyd.mid.LOAD_TEAM_BY_ID = 579','xyd.mid.APPLY_TEAM = 580','xyd.mid.LOAD_APPLY_LIST_TEAM = 581','xyd.mid.ACCEPT_APPLY_TEAM = 582','xyd.mid.REFUSE_APPLY_TEAM = 583','xyd.mid.LEAVE_TEAM = 584','xyd.mid.UPDATE_DES_TEAM = 585','xyd.mid.APPOINT_JOB_TEAM = 586','xyd.mid.KICK_TEAM = 587','xyd.mid.SETTING_TEAM = 589','xyd.mid.PLAYER_LOAD_APPLY_LIST_TEAM = 598','xyd.mid.CANCEL_APPLY_TEAM = 599','xyd.mid.GET_SELF_GUILD = 612','xyd.mid.INVITE_TO_GUILD = 2563','xyd.mid.ACCEPT_INVITE_TO_GUILD = 2564','xyd.mid.GET_GUILD_INFO = 2565'])),
 ('bootstrap/direct Guild reload and request fields', 'request(xyd.mid.GET_SELF_GUILD, {}' in sg and 'request(xyd.mid.LOAD_TEAM_BY_ID, {}' in sg and 'apply_player_id' in cur['TeamApplyMemberWindow.lua'] and 'member_id' in cur['TeamMemberManageMenu.lua'] and 'guild_id' in sg),
 ('CantJoinGuild payload consumption', 'arg_10_1.error_code == xyd.CantJoinGuild' in cur['TeamFindWindow.lua'] and 'time_ = arg_10_1.time' in cur['TeamFindWindow.lua']),
 ('leader/deputy role UI corroboration', 'job = 1' in cur['TeamMemberManageMenu.lua'] and 'job = 2' in cur['TeamMemberManageMenu.lua'] and 'memberJob == 0' in cur['TeamMemberManageMenu.lua']),
 ('create/settings fields', 'icon_frame = 0' in cur['TeamCreateWindow.lua'] and 'min_allow_level' in cur['TeamSettingWindow.lua'] and 'apply_type' in cur['TeamSettingWindow.lua'] and 'des =' in cur['TeamSettingDataWindow.lua']),
 ('detail presentation fields exist', 'three_huoyue' in cur['GuildDetailWindow.lua'] and 'guild_rank' in cur['GuildDetailWindow.lua']),
 ('web injects gameplay token and region', 'arg_23_2.token = arg_23_0.token_' in backend and 'arg_23_2.region = arg_23_0.region_' in backend),
 ('Guild policy rows include 3-day offline threshold', all(x in misc for x in ['guild_create_lev','guild_create_diamond','guild_joinnew_interval','guild_joinold_interwal','guild_join_limit','guild_people_limit','guild_offline_chief'])),
 ('Guild messages 30010-30020 include recovered policy denials', all(x in messages for x in [
    '"30010"','You can\'t join the guild in 1 hour','"30011"','Can\'t join the same guild in 48 hours',
    '"30012"','You can join the guild for 3 times in 7 days at most','"30013"','You can only apply for 3 guilds at the same time',
    '"30014"','The guild you apply refuses any player to join ','"30015"','Can\'t find the guild',
    '"30016"','The guild you apply is full','"30017"','You can only dismiss your guild when there is only leader left',
    '"30018"','You can choose 5 vice leaders at most in one guild','"30019"','Other players have used this name, please change it ',
    '"30020"',"Guild members is full,can't join "
 ])),
 ('historical Guild-message corroboration', all(x in old_messages for x in ['"30018"','You can choose 5 vice leaders at most in one guild','"30019"','Other players have used this name, please change it '])),
 ('historical core corroboration', 'xyd.mid.GET_SELF_GUILD = 612' in hist['mid.lua'] and 'request(xyd.mid.GET_SELF_GUILD' in hist['SelfGuild.lua'] and 'guild_offline_chief' in hist['misc.lua']),
]
for label,ok in checks:
    if not ok: errs.append('source fact missing: '+label)
if errs:
    print('I6C SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    raise SystemExit(1)
print('I6C SOURCE ORACLE CHECK: PASS')
print('verified Guild MID/request/presentation/policy/message source shape in current + historical corpora; no unrecovered server calendar/succession semantics inferred')
