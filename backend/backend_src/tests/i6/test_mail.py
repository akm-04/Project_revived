from __future__ import annotations
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from gxb_backend.foundation.resource_keys import ResourceClass
from gxb_backend.mail.models import MailAddress, MailDeliveryIntent, MailRecord
from gxb_backend.mail.service import MailAlreadyClaimed, MailClaimService, MailDeliveryService, MailExpired
from gxb_backend.transactions.errors import ReceiptReplayConflict

NOW=datetime(2026,1,1,tzinfo=timezone.utc)

def record(address=MailAddress(False,1), *, claimed=False, expires=None):
    return MailRecord(10,100001,address,'delivery:1',{'id':999,'is_region':9,'title':'x'},({'item_id':1,'item_num':2},),NOW,expires,NOW if claimed else None,NOW if claimed else None,'test','1',{'ext':'kept'})

def test_wire_identity_columns_override_opaque_payload_and_preserve_extensions():
    row=record(MailAddress(True,7)).to_wire()
    assert row['id']==7 and row['is_region']==1 and row['title']=='x'
    assert row['attachments']==[{'item_id':1,'item_num':2}]

def test_mail_addresses_keep_two_protocol_namespaces_distinct_and_deterministic():
    assert MailAddress(False,5)!=MailAddress(True,5)
    assert sorted([MailAddress(True,3),MailAddress(False,9),MailAddress(False,3)])==[MailAddress(False,3),MailAddress(False,9),MailAddress(True,3)]

def test_delivery_service_stages_notification_only_after_first_durable_insert():
    calls=[]
    class Repo:
        def deliver(self,conn,intent): calls.append('deliver'); return record(), bool(intent.source_id=='dup')
    class Tx:
        connection=object()
        def stage_outbox(self,x): calls.append(('notify',x))
    svc=MailDeliveryService(Repo()); intent=lambda sid: MailDeliveryIntent(100001,'dk:'+sid,'test',sid,{},())
    svc.deliver(Tx(),intent('new'),notification='N'); assert calls==['deliver',('notify','N')]
    calls.clear(); svc.deliver(Tx(),intent('dup'),notification='N'); assert calls==['deliver']

class FakeCoordinator:
    def __init__(self): self.request=None; self.tx=SimpleNamespace(connection=object())
    def run(self,request,op): self.request=request; self.tx.request=request; return op(self.tx)

class FakeReceipts:
    def __init__(self): self.rows={}
    def get(self,conn,key): return self.rows.get(key.scope)
    def record_or_replay(self,conn,*,key,request_fingerprint,result,**kw):
        existing=self.rows.get(key.scope)
        if existing is not None:
            if existing.request_fingerprint!=request_fingerprint.hex(): raise ReceiptReplayConflict(key.scope)
            return existing,True
        rec=SimpleNamespace(request_fingerprint=request_fingerprint.hex(),result=dict(result))
        self.rows[key.scope]=rec
        return rec,False

class FakeRepo:
    def __init__(self,rows): self.rows=dict(rows); self.marked=[]
    def load_locked(self,conn,pid,address): return self.rows.get(address),(NOW)
    def mark_claimed(self,conn,row_id): self.marked.append(row_id); return True
class Settlement:
    def __init__(self): self.seen=[]
    def settle(self,tx,mail): self.seen.append(mail.address); return [{'mail':mail.address.protocol_mail_id}]

def test_mail_onekey_claim_declares_player_before_child_resources_and_settles_in_address_order():
    a=MailAddress(True,2); b=MailAddress(False,7); c=MailAddress(False,3)
    repo=FakeRepo({x:record(x) for x in (a,b,c)}); coord=FakeCoordinator(); settlement=Settlement()
    result=MailClaimService(coord,repo,settlement,FakeReceipts()).claim_many(player_id=100001,addresses=[a,b,c],request_id='r')
    assert result.claimed==(c,b,a)
    assert settlement.seen==[c,b,a]
    classes=[x.resource_class for x in coord.request.resources]
    assert classes[0] is ResourceClass.PLAYER and classes[1:]==[ResourceClass.CHILD]*3
    assert coord.request.retry_safe is True

def test_claim_replay_is_blocked_before_reward_settlement():
    a=MailAddress(False,1); repo=FakeRepo({a:record(a,claimed=True)}); settlement=Settlement()
    try: MailClaimService(FakeCoordinator(),repo,settlement,FakeReceipts()).claim_one(player_id=100001,address=a,request_id='r')
    except MailAlreadyClaimed: pass
    else: raise AssertionError('expected replay block')
    assert settlement.seen==[]

def test_expired_mail_is_blocked_before_reward_settlement():
    a=MailAddress(False,1); repo=FakeRepo({a:record(a,expires=NOW-timedelta(seconds=1))}); settlement=Settlement()
    try: MailClaimService(FakeCoordinator(),repo,settlement,FakeReceipts()).claim_one(player_id=100001,address=a,request_id='r')
    except MailExpired: pass
    else: raise AssertionError('expected expiry block')
    assert settlement.seen==[]


def test_claim_receipt_replays_one_shot_awards_before_touching_claimed_mail_again():
    a=MailAddress(False,11); repo=FakeRepo({a:record(a)}); settlement=Settlement(); receipts=FakeReceipts(); coord=FakeCoordinator()
    svc=MailClaimService(coord,repo,settlement,receipts)
    first=svc.claim_one(player_id=100001,address=a,request_id='http-1',client_operation_id='op-mail-11')
    assert first.awards==({'mail':11},) and settlement.seen==[a]
    # Simulate committed row state. The replay must return from the semantic
    # receipt before re-reading/re-settling the now-claimed mail.
    repo.rows[a]=record(a,claimed=True)
    second=svc.claim_one(player_id=100001,address=a,request_id='http-2',client_operation_id='op-mail-11')
    assert second==first and settlement.seen==[a]
    assert len(receipts.rows)==1

def test_claim_receipt_rejects_reuse_of_logical_operation_id_for_different_mail_set():
    a=MailAddress(False,11); b=MailAddress(True,11)
    repo=FakeRepo({a:record(a),b:record(b)}); receipts=FakeReceipts(); settlement=Settlement(); svc=MailClaimService(FakeCoordinator(),repo,settlement,receipts)
    svc.claim_one(player_id=100001,address=a,request_id='r1',client_operation_id='same-op')
    try: svc.claim_one(player_id=100001,address=b,request_id='r2',client_operation_id='same-op')
    except ReceiptReplayConflict: pass
    else: raise AssertionError('logical operation reuse with different fingerprint must fail')
    assert settlement.seen==[a]

def test_claim_without_client_operation_id_still_records_request_scoped_receipt():
    a=MailAddress(False,12); receipts=FakeReceipts(); settlement=Settlement(); repo=FakeRepo({a:record(a)})
    svc=MailClaimService(FakeCoordinator(),repo,settlement,receipts)
    first=svc.claim_one(player_id=100001,address=a,request_id='request-stable')
    repo.rows[a]=record(a,claimed=True)
    second=svc.claim_one(player_id=100001,address=a,request_id='request-stable')
    assert second==first and settlement.seen==[a]

def test_delivery_key_duplicate_returns_existing_only_when_semantics_match():
    from gxb_backend.mail.repository import MailRepository, MailDeliveryConflict
    class Maps:
        def __init__(self,row): self.row=row
        def first(self): return self.row
        def one(self): return self.row
    class Res:
        def __init__(self,row): self.row=row
        def mappings(self): return Maps(self.row)
    class Conn:
        def __init__(self,row): self.results=[Res(None),Res(row)]
        def execute(self,stmt): return self.results.pop(0)
    existing={
        'mail_row_id':1,'player_id':100001,'is_region':False,'protocol_mail_id':7,'delivery_key':'stable',
        'protocol_payload':{'title':'x'},'attachments':[],'created_at':NOW,'expires_at':None,'read_at':None,'claimed_at':None,
        'source_type':'finalizer','source_id':'g1:player','metadata':{},
    }
    intent=MailDeliveryIntent(100001,'stable','finalizer','g1:player',{'title':'x'},(),False,7)
    row,duplicate=MailRepository().deliver(Conn(existing),intent)
    assert duplicate is True and row.address==MailAddress(False,7)
    bad=MailDeliveryIntent(100001,'stable','finalizer','g1:player',{'title':'DIFFERENT'},(),False,7)
    try: MailRepository().deliver(Conn(existing),bad)
    except MailDeliveryConflict: pass
    else: raise AssertionError('same delivery key with different semantics must fail')
