#!/usr/bin/env python3
"""Exact source identity, branch and threshold oracle for the bounded4A core."""
from pathlib import Path
import hashlib,json,sys,zipfile
from generate_builtin_content import SourceArchive,parse_generated_lua_table
B=Path(__file__).resolve().parents[1]
a=Path(sys.argv[1]);blobs=SourceArchive(a).read_verified()
manifest=json.loads((B/'docs/i7c4a/SOURCE_MANIFEST.json').read_text())
with zipfile.ZipFile(a)as z:
 for r in manifest:
  b=z.read('app-assets/output/assets/src_64/'+r['path']);assert hashlib.sha256(b).hexdigest()==r['sha256'],r['path']
 text=z.read('app-assets/output/assets/src_64/app/windows/NewChangeAvatarWindow.lua').decode()
 for token in ['iter_7_1.color_ >= xyd.EquipQuality.PURPLE','iter_7_1:isSuper() and iter_7_1:getStar() >= 2','iter_7_1:beforeAwakenID()','var_35_4 == 6 and var_35_5 <= arg_35_0.selfPlayer.vip','iter_35_3.startTime + xyd.tables.avatar:getAvatarTime(iter_35_3.itemID) * 24 * 3600 > xyd.ServerTime.get():getServerTime()','xyd.tables.avatar.is_show_[iter_7_3] == 1']:
  assert token in text,token
src=parse_generated_lua_table(blobs['data/tables/vip.lua'].data)
actual=json.loads((B/'internal/content/builtin/generated/privilege_catalog.json').read_text())['rows']
expected=[dict(level=int(r['id']),charge=int(r['charge_req']),skill_cap=int(r['skill_max']))for r in src];expected.sort(key=lambda x:x['level']);assert actual==expected
assert [r['level']for r in actual]==list(range(16))
print(json.dumps(dict(status='PASS_EXACT_SRC64_IDENTITY_BRANCHES_VIP16',sources_verified=len(blobs),targeted_members=len(manifest),vip_rows=len(actual),classification='SOURCE_FACT_NOT_ORIGINAL_SERVER_OR_STOCK_RUNTIME_PROOF')))
