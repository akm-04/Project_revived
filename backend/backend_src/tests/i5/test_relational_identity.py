from __future__ import annotations

from types import SimpleNamespace
from uuid import uuid4

from gxb_backend.identity.errors import CredentialInvalid
from gxb_backend.realtime.identity import RelationalRealtimeIdentityResolver, RealtimePlayerMetadata


class FakeGameplay:
    def __init__(self, result=None, error=None): self.result=result; self.error=error; self.calls=[]
    def resolve(self, **kwargs):
        self.calls.append(kwargs)
        if self.error: raise self.error
        return self.result


class FakeMeta:
    def __init__(self, guild=0): self.guild=guild; self.calls=[]
    def resolve_realtime_metadata(self, player_id): self.calls.append(player_id); return RealtimePlayerMetadata(self.guild)


def test_relational_tcp_identity_consumes_gameplay_token_but_retains_only_nonsecret_ids():
    sid=uuid4(); cid=uuid4()
    gameplay=FakeGameplay(SimpleNamespace(account_uid="20000001",session_id=sid,context_id=cid,region_id=125,player_id=12500001))
    meta=FakeMeta(77)
    resolver=RelationalRealtimeIdentityResolver(gameplay,meta)
    identity=resolver.resolve_realtime_identity("super-secret-gameplay-token",125)
    assert identity is not None
    assert identity.uid=="20000001" and identity.player_id=="12500001" and identity.guild_id==77
    assert identity.sid==""
    assert identity.session_id==str(sid) and identity.context_id==str(cid)
    assert "super-secret" not in repr(identity)
    assert gameplay.calls[0]["gameplay_token"]=="super-secret-gameplay-token"


def test_relational_tcp_identity_fails_closed_on_identity_error_or_missing_metadata():
    resolver=RelationalRealtimeIdentityResolver(FakeGameplay(error=CredentialInvalid("bad")),FakeMeta())
    assert resolver.resolve_realtime_identity("bad",1) is None
    ctx=SimpleNamespace(account_uid="u",session_id=uuid4(),context_id=uuid4(),region_id=1,player_id=100001)
    class MissingMeta:
        def resolve_realtime_metadata(self, player_id): return None
    assert RelationalRealtimeIdentityResolver(FakeGameplay(ctx),MissingMeta()).resolve_realtime_identity("x",1) is None
