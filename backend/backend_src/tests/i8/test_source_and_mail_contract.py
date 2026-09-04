import json
from hashlib import sha256
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

EXPECTED={
 "Backend.lua":"79ebbb6452bc62e764142d4dc04e5d024ead78f54562c0144921143ca6ad5df4",
 "LoadingScene.lua":"06da664086d167fa6be0401defb59d27411716543a648fabe76f81d4d0de9e84",
 "LoginWindow.lua":"f6fb06e51dca4e16ecd8755c7ae67c8000da1cc6b728d3e44f1bb3ed230eeb2e",
 "SwitchItem.lua":"5f423c19ea8d58119709ed60e812dc526093d754a300c16cc9c9e815457b6fa3",
 "mid.lua":"11d4036ef68cdce66810bc02d5dfc7226a9c4286388bfd5a6cb2bc1a21f96a18",
}

def test_src64_identity_context_anchors_remain_exact():
    files=list((ROOT/"local_assets/src_64").rglob("*.lua"))
    by_name={p.name:p for p in files if p.name in EXPECTED}
    assert set(by_name)==set(EXPECTED)
    p349=json.loads((ROOT/'docs/json/PASS349_I10_PRELOGIN_MID2864_RECONCILIATION.json').read_text())
    for name,digest in EXPECTED.items():
        allowed={digest}
        if name == 'Backend.lua':
            allowed.add(p349['candidate_hashes']['local_assets/src_64/app/common/network/Backend.lua'])
        if name == 'LoginWindow.lua':
            p352=json.loads((ROOT/'docs/json/PASS352_I10_STOCK_RUNTIME_RECONCILIATION.json').read_text())
            allowed.add(p352['candidate_hashes']['local_assets/src_64/app/windows/LoginWindow.lua'])
        assert sha256(by_name[name].read_bytes()).hexdigest() in allowed

def test_mail_handlers_delegate_to_relational_authority():
    text=(ROOT/"gxb_backend/handlers/mail.py").read_text()
    for seam in ("relational_mail_list","relational_mail_read","relational_mail_onekey"):
        assert seam in text
    source=(ROOT/"gxb_backend/runtime/state_repository.py").read_text()
    assert "parse_onekey_addresses" in source and "MailAddress" in source
