#!/usr/bin/env python3
import pathlib,json,hashlib,sys
root=pathlib.Path(__file__).resolve().parents[1];source=pathlib.Path(sys.argv[1]);binding=json.loads((root/'docs/i7a5a/SOURCE_IDENTITY.json').read_text())
for row in binding['members']:
 rel=row['cache'].removeprefix('source_cache/current/');p=source/rel;assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],rel
mid=(source/'app/common/network/mid.lua').read_text(encoding='utf-8-sig');assert 'xyd.mid.SEND_CHAT_MESSAGE = 32782' in mid
model=(source/'app/model/MessageManager.lua').read_text(encoding='utf-8-sig');assert 'xyd.event.CHAT_ROOM_MESSAGE' in model and 'xyd.event.SERVICE_CHAT_ROOM_MESSAGE' in model
print(json.dumps({'status':'PASS_I7A5A_EXACT_SRC64','members':len(binding['members']),'ordinary_limit':140,'physical_channels':[0,2,4],'original_server_truth_claimed':False}))
