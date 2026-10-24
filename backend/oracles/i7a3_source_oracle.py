#!/usr/bin/env python3
import argparse, hashlib, json, sys
from pathlib import Path

EXPECTED_HASHES = {
    "current_backend": "95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840",
    "current_guild_manage": "0a872003de5eb603e6229d357bbb19daf3fcea7c69eb68bcc8d6834ea298e5e5",
    "current_guild_list": "6a1bd075d6085714e803249b0a66f15b0e9cdcf3858ee37f5fe23b28a8fd0925",
    "current_social": "ec5bea26bbdcbb67ca2ea80ab5ad7e9fb53ee613a3ffcbb13ae5dfef9ddf0502",
    "current_mid": "026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af",
    "old_backend": "06f481e9358e357019c42fbf7d2cd8e650ba7044a774b182d833aebc85458315",
    "old_guild_manage": "7d62215226beb41aebc75e96fca84e122a48bbbf67d50c3a0039f1749e023ae8",
    "old_guild_list": "124b18e22dea6ac1e7942a7f18b0631931164ca19a143b5a9c29afd9b257d501",
    "old_mid": "c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942",
}

def sha256(p: Path) -> str:
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20), b''):
            h.update(b)
    return h.hexdigest()

def must(text: str, needle: str, label: str):
    if needle not in text:
        raise AssertionError(f"{label}: missing {needle!r}")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--current-root', required=True)
    ap.add_argument('--old-root', required=True)
    args=ap.parse_args()
    cur=Path(args.current_root)
    old=Path(args.old_root)
    paths={
        'current_backend': cur/'app/common/network/Backend.lua',
        'current_guild_manage': cur/'app/windows/TeamMemberManageWindow.lua',
        'current_guild_list': cur/'app/windows/TeamMemberListAlertWindow.lua',
        'current_social': cur/'app/model/SocialSystem.lua',
        'current_mid': cur/'app/common/network/mid.lua',
        'old_backend': old/'Backend.lua',
        'old_guild_manage': old/'TeamMemberManageWindow.lua',
        'old_guild_list': old/'TeamMemberListAlertWindow.lua',
        'old_mid': old/'mid.lua',
    }
    for key,p in paths.items():
        if not p.is_file():
            raise FileNotFoundError(f"{key}: {p}")
        got=sha256(p)
        if got != EXPECTED_HASHES[key]:
            raise AssertionError(f"{key}: sha256 {got} != {EXPECTED_HASHES[key]}")

    cb=paths['current_backend'].read_text(errors='replace')
    ob=paths['old_backend'].read_text(errors='replace')
    # Both clients: 600-second heartbeat source constant, and WORLD/GUILD/SERVICE heartbeat schedules.
    must(cb, 'local var_0_7 = 600', 'current heartbeat interval')
    must(ob, 'local var_0_6 = 600', 'old heartbeat interval')
    for label,text in [('current',cb),('old',ob)]:
        must(text, 'xyd.mid.CHAT_ROOM_ENTERED', f'{label} room-entered trigger')
        if text.count('sendMessage(xyd.mid.SOCKET_HEARTBEAT') < 3:
            raise AssertionError(f'{label}: expected per-role heartbeat sends for WORLD/GUILD/SERVICE')
        for socket_name in ('socket_', 'leagueSocket_', 'serviceSocket_'):
            must(text, socket_name, f'{label} {socket_name}')

    for label,key in [('current manage','current_guild_manage'),('current list','current_guild_list'),('old manage','old_guild_manage'),('old list','old_guild_list')]:
        text=paths[key].read_text(errors='replace')
        must(text, 'last_time', f'{label} last_time')
        must(text, 'xyd.ServerTime.get():getServerTime()', f'{label} authoritative display time')
        # Stock UI treats last_time as an epoch timestamp by passing it to os.date.
        must(text, 'os.date("%M"', f'{label} os.date epoch use')

    social=paths['current_social'].read_text(errors='replace')
    must(social, 'arg_7_2.is_online == 1', 'Friend online branch')
    must(social, 'getServerTime() - arg_7_2.last_time', 'Friend offline last_time branch')

    # CLOSE_GUILD_CHAT is a client-side symbol/event path, but no numeric MID exists in current or v1.164 mid.lua.
    if 'CLOSE_GUILD_CHAT' in paths['current_mid'].read_text(errors='replace'):
        raise AssertionError('current mid.lua unexpectedly defines numeric CLOSE_GUILD_CHAT')
    if 'CLOSE_GUILD_CHAT' in paths['old_mid'].read_text(errors='replace'):
        raise AssertionError('old mid.lua unexpectedly defines numeric CLOSE_GUILD_CHAT')
    must(cb, 'xyd.mid.CLOSE_GUILD_CHAT', 'current symbolic CLOSE_GUILD_CHAT use')

    result={
        'status':'GREEN',
        'checks':{
            'current_old_600s_per_role_heartbeat':True,
            'current_old_guild_last_time_epoch':True,
            'friend_is_online_distinct_from_last_time':True,
            'close_guild_chat_symbol_without_numeric_mid':True,
        },
        'hashes':EXPECTED_HASHES,
        'nonclaims':[
            'heartbeat interval and client consumers do not prove original server persistence mechanics',
            'CLOSE_GUILD_CHAT symbolic client branch does not authorize inventing a numeric server MID',
            'offline-leader successor selection remains outside this oracle and remains unqualified',
        ]
    }
    print(json.dumps(result, indent=2, sort_keys=True))

if __name__=='__main__':
    try:
        main()
    except Exception as e:
        print(f'I7A3_SOURCE_ORACLE_FAIL: {e}', file=sys.stderr)
        raise
