from __future__ import annotations
from datetime import datetime,timezone
from gxb_backend.mail.models import MailAddress,MailRecord
from gxb_backend.mail.protocol import parse_single_address,parse_onekey_addresses,mailbox_snapshot,onekey_response,MailReadOutcome
NOW=datetime(2026,1,1,tzinfo=timezone.utc)
def rec(a,read=False): return MailRecord(1,100001,a,'d',{'category':2},(),NOW,None,NOW if read else None,None,'x','1',{})

def test_single_read_parses_exact_id_is_region_contract():
    assert parse_single_address({'id':'9','is_region':1})==MailAddress(True,9)

def test_onekey_pipe_namespaces_parse_to_compound_identities():
    got=parse_onekey_addresses({'normal_ids':'9|3|3','region_ids':'5|2'})
    assert got==(MailAddress(False,3),MailAddress(False,9),MailAddress(True,2),MailAddress(True,5))

def test_mailbox_snapshot_and_onekey_response_match_current_client_shape():
    snap=mailbox_snapshot([rec(MailAddress(False,1)),rec(MailAddress(True,2),read=True)],total=8)
    assert snap['total']==8 and snap['new_mail_total']==1 and [x['id'] for x in snap['mail_list']]==[1,2]
    out=onekey_response(awards=[{'table_id':1,'item_num':2}],snapshot=snap)
    assert out['mail_list'] == snap and out['awards'][0]['table_id']==1

def test_read_outcome_keeps_retention_policy_explicit_not_guessed():
    shown=MailReadOutcome(True,0,1,()).to_wire(); hidden=MailReadOutcome(True,0,0,()).to_wire()
    assert shown['is_shown']==1 and hidden['is_shown']==0

def test_mail_namespace_flag_parses_zero_one_without_python_truthiness_bug():
    assert parse_single_address({'id':1,'is_region':'0'})==MailAddress(False,1)
    assert parse_single_address({'id':1,'is_region':'1'})==MailAddress(True,1)
    try: parse_single_address({'id':1,'is_region':'region-ish'})
    except ValueError: pass
    else: raise AssertionError('unknown namespace flag must fail closed')
