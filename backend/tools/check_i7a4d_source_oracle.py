#!/usr/bin/env python3
"""Candidate-bound effective Social client consumer check. No original-server or W2 claim."""
from pathlib import Path
import hashlib,json,sys,zipfile
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1])
expected={'app/model/SocialSystem.lua': 'ec5bea26bbdcbb67ca2ea80ab5ad7e9fb53ee613a3ffcbb13ae5dfef9ddf0502', 'app/windows/SocialSystemWindow.lua': '5d0c3e1e20d69b7009ff52bf94ad438c6a133c8b099301d951bd1e413b90f112', 'app/windows/AddFriendWindow.lua': 'efe0b3f662ac57f51dbb94940eec9346e146e73c33ae4248f5e152d103417ed1', 'app/windows/AddBlackListWindow.lua': 'de8d2be7917b930ae3d67540d833a9735f9db5d6b1c17534972f92421134d90c', 'app/windows/AddFriendLayer.lua': '468b149ae6f9ee636365567a18481c47b5740ee168add68d4f20f44e4f62a6f8', 'app/common/enums.lua': '15340bd89fe7c6f150ccfd4a5cd2a2f0e8e73c89dfae9ac3388376a4799901f3', 'app/common/utils.lua': '6e56c7342e889d7ae8d41fe47cb06f66832227efe702f3863f693ee7ba84ffad', 'data/tables/misc.lua': '058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a'}
archive=OROOT/'all-assest-rechecked-1.zip'
h=hashlib.sha256()
with archive.open('rb')as f:
 for b in iter(lambda:f.read(1048576),b''):h.update(b)
assert h.hexdigest()=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf','current oracle identity mismatch'
with zipfile.ZipFile(archive)as z:
 source={}
 for p,w in expected.items():
  b=z.read('app-assets/output/assets/src_64/'+p);assert hashlib.sha256(b).hexdigest()==w,p;source[p]=b.decode('utf-8-sig')
s=source['app/model/SocialSystem.lua'];w=source['app/windows/SocialSystemWindow.lua']
assert all(k in s for k in ['params.friend_list == 1','params.friend_req == 1','params.friend_notice == 1','params.player_id > 0'])
assert 'notice_type == xyd.FriendNoticeType.ACCEPT' in w and 'notice_type == xyd.FriendNoticeType.DENY' in w and 'notice_type == xyd.FriendNoticeType.DELETE' in w
view=(ROOT/'internal/projection/socialview/view.go').read_text();assert '`json:"notice_type"`' in view
reload=(ROOT/'internal/adapters/stockruntime/social_reload.go').read_text();assert 'Value: int64(0)' in reload and 'len(m) != 2' in reload and 'domainrt.World' in reload
contract=json.loads((ROOT/'docs/i7a4d/PASS637_I7A4D_IMPLEMENTATION_CONTRACT.json').read_text());assert contract['new_migration'] is None
assert not (ROOT/'migrations/00034_i7a4d.sql').exists()
print(json.dumps({'status':'PASS','class':'CURRENT_SRC64_STATIC_CONSUMER_PLUS_CANDIDATE_SOURCE_CROSSCHECK','source_sha256':h.hexdigest(),'files':expected,'limits':['No physicalclientW2','HistoricalV1 corroboration only','Referencehintcodec/time/quota/selection policies remain reconstruction contracts']},sort_keys=True))
