#!/usr/bin/env python3
import hashlib, json, re, sys, zipfile
from pathlib import Path

SRC_ZIP = Path('/mnt/data/i7a2_impl/assets/current_src64.zip')
BACKEND = Path('/mnt/data/i7a2_impl/backend_src/backend')
EXPECTED_SRC_SHA = 'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
BASE = 'app-assets/output/assets/src_64/'

def sha256(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024), b''):
            h.update(chunk)
    return h.hexdigest()

def require(cond, label):
    if not cond:
        raise AssertionError(label)
    checks.append(label)

def member(z, rel):
    return z.read(BASE+rel).decode('utf-8', errors='strict')

checks=[]
require(sha256(SRC_ZIP) == EXPECTED_SRC_SHA, 'current src_64 archive identity')
with zipfile.ZipFile(SRC_ZIP) as z:
    mid = member(z, 'app/common/network/mid.lua')
    expected_mids = {
        'CHAT_FROM_PLAYER':514, 'CHAT_FROM_FRIEND':516, 'SEND_CHAT_MESSAGE':32782,
        'CHAT_MESSAGE':32783, 'WORLD_NOTICE':32784, 'PLAYER_NOTICE':36854,
        'FORCE_RELOAD':36855, 'GUILD_BROADCAST':36863,
    }
    for name, value in expected_mids.items():
        require(re.search(rf'xyd\.mid\.{name}\s*=\s*{value}\b', mid) is not None, f'src_64 MID {name}={value}')

    backend = member(z, 'app/common/network/Backend.lua')
    # Exact physical socket branches recovered from the current client.
    world = backend[backend.index('if arg_47_1 == arg_47_0.socket_ then'):backend.index('elseif arg_47_1 == arg_47_0.leagueSocket_ then')]
    guild = backend[backend.index('elseif arg_47_1 == arg_47_0.leagueSocket_ then'):backend.index('elseif arg_47_1 == arg_47_0.serviceSocket_ then')]
    service_start = backend.index('elseif arg_47_1 == arg_47_0.serviceSocket_ then')
    service = backend[service_start:backend.index('function var_0_1.nextRequestHandle_', service_start)]
    for name in ['CHAT_MESSAGE','CHAT_FROM_PLAYER','CHAT_FROM_FRIEND','FORCE_RELOAD']:
        require(f'xyd.mid.{name}' in world, f'WORLD branch consumes {name}')
    for name in ['CHAT_MESSAGE','GUILD_BROADCAST']:
        require(f'xyd.mid.{name}' in guild, f'GUILD branch consumes {name}')
    require('xyd.mid.CHAT_MESSAGE' in service, 'SERVICE branch consumes CHAT_MESSAGE')
    require('xyd.mid.CHAT_FROM_PLAYER' not in guild+service, 'CHAT_FROM_PLAYER absent from GUILD/SERVICE special branches')
    require('xyd.mid.CHAT_FROM_FRIEND' not in guild+service, 'CHAT_FROM_FRIEND absent from GUILD/SERVICE special branches')
    require('xyd.mid.GUILD_BROADCAST' not in world+service, 'GUILD_BROADCAST absent from WORLD/SERVICE special branches')

    selfplayer = member(z, 'app/model/SelfPlayer.lua')
    require('titleInfo = arg_9_1.params.title_info or {}' in selfplayer, 'SelfPlayer truthy title_info assignment')
    require('bubbleInfo = arg_9_1.params.bubble_info or {' in selfplayer, 'SelfPlayer bubble_info fallback exists')
    require('bubble_id = xyd.tables.misc:getValue("default_bubble")' in selfplayer, 'SelfPlayer fallback reads default_bubble')

    messages = member(z, 'app/model/MessageManager.lua')
    require('var_49_1.titleInfo.title_id' in messages and 'var_49_1.titleInfo.unique_id' in messages and 'var_49_1.titleInfo.end_time' in messages,
            'MessageManager dereferences all title fields')

    bubbles = member(z, 'app/model/ChatBubble.lua')
    require('arg_8_0.selfPlayer.bubbleInfo.end_time' in bubbles and 'arg_8_0.selfPlayer.bubbleInfo.bubble_id' in bubbles,
            'ChatBubble dereferences end_time and bubble_id')

    misc = member(z, 'data/tables/misc.lua')
    require(re.search(r'"default_bubble",\s*\n\s*"10001"', misc) is not None, 'misc default_bubble=10001')

# Product-side assertions tie implementation to the source facts above.
mids = (BACKEND/'internal/protocol/mids/registry.go').read_text()
for name, value in expected_mids.items():
    require(re.search(rf'\b{value}\b', mids) is not None, f'product MID registry contains {value}')
require('case MIDChatFromPlayer, MIDChatFromFriend:' in mids and 'd.Transport = TCP' in mids and 'd.Direction = S2C' in mids,
        'product low-number 514/516 transport+direction override')

shapes = (BACKEND/'internal/projection/lobby/shapes.go').read_text()
for snippet in ['"title_id": int64(0)', '"unique_id": int64(0)', '"end_time": int64(0)', '"bubble_id": int64(10001)']:
    require(snippet in shapes, f'product MID17 compatibility contains {snippet}')

result = {'status':'GREEN','checks':len(checks),'source_zip_sha256':EXPECTED_SRC_SHA,'checks_detail':checks}
print(json.dumps(result, indent=2))
