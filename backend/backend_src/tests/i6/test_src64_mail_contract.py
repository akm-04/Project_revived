from __future__ import annotations
import hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
E=ROOT/'source_evidence/pass345_src64_mail'

def test_current_src64_mail_sources_match_research_hashes():
    expected={
        'Mailbox.lua':'3232f5c4b7c8dc60bf2c76249813d684959e4970040890ea2d0a3f544516ba14',
        'MailboxWindow.lua':'f53ec450208d799ba8954ba50ce4f6a92793664ea2f85190c281132bea2b7a7d',
        'MailItem.lua':'c51de51edab94af4b02f45d84ffa64cbcbf4e611cbd3c28fba973cdd35a78b94',
    }
    for name,sha in expected.items(): assert hashlib.sha256((E/name).read_bytes()).hexdigest()==sha

def test_current_src64_mail_identity_and_onekey_namespaces_are_preserved():
    mailbox=(E/'Mailbox.lua').read_text(); window=(E/'MailboxWindow.lua').read_text()
    assert 'id = arg_14_1.id' in mailbox and 'is_region = arg_14_1.is_region' in mailbox
    assert 'iter_8_1.id == var_8_1.id and iter_8_1.is_region == var_8_1.is_region' in mailbox
    assert 'onekeyIds.region_ids' in window and 'onekeyIds.normal_ids' in window
    assert '"|" .. iter_7_1.id' in window

def test_current_src64_mail_responses_require_snapshot_and_award_shapes():
    mailbox=(E/'Mailbox.lua').read_text()
    assert 'var_12_0.awards' in mailbox
    assert 'var_12_0.mail_list.mail_list' in mailbox
    assert 'var_12_0.mail_list.total' in mailbox
    assert 'var_12_0.mail_list.new_mail_total' in mailbox
    assert 'var_8_0.rewards' in mailbox

def test_client_expiry_is_display_only_not_authoritative_deletion():
    item=(E/'MailItem.lua').read_text()
    assert 'expired_time' in item
    # MailItem is a presentation window; canonical deletion remains server-side.
    assert 'SET_MAIL_READ' not in item and 'MAIL_ONEKEY' not in item
