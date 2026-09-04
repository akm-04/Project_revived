"""StateRepository strangler stores and ResourceTransaction-bound player sub-UoW."""
from __future__ import annotations

from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass, field
from typing import Any, Iterator, Protocol

from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.persistence_state import ensure_persistence_state
from gxb_backend.state.unit_of_work import OperationContext, PlayerUnitOfWork
from .locking import player_state_resource
from .codec import PlayerPayloadCodec
from .repositories import PostgresPlayerAggregateRepository

class PlayerStateStore(Protocol):
    process_cache_safe: bool
    def load(self, player_id:Any)->PlayerState|None: ...
    def save(self, player:PlayerState)->None: ...
    def fingerprint(self, player_id:Any)->object|None: ...

class LegacyJsonPlayerStateStore:
    process_cache_safe=True
    def __init__(self,multiuser_database:Any): self.db=multiuser_database
    def load(self,player_id:Any)->PlayerState|None:return self.db.load_player(str(player_id))
    def save(self,player:PlayerState)->None:self.db.save_player(player)
    def fingerprint(self,player_id:Any)->object|None:
        try: st=self.db.player_path(str(player_id)).stat()
        except FileNotFoundError:return None
        return (int(st.st_mtime_ns),int(st.st_size))

@dataclass
class _Binding:
    transaction:Any
    expected_state_versions:dict[int,int]=field(default_factory=dict)

class TransactionBoundPostgresPlayerStateStore:
    process_cache_safe=False
    """Candidate I4 store; unusable unless explicitly bound to ResourceTransaction."""
    def __init__(self, repository:PostgresPlayerAggregateRepository, base_player_factory):
        self.repository=repository; self.base_player_factory=base_player_factory; self._binding:ContextVar[_Binding|None]=ContextVar('gxb_i4_player_tx',default=None)
    @contextmanager
    def bind(self,transaction:Any)->Iterator[None]:
        token=self._binding.set(_Binding(transaction));
        try: yield
        finally:self._binding.reset(token)
    def _current(self)->_Binding:
        b=self._binding.get()
        if b is None: raise RuntimeError('PostgreSQL PlayerState store requires an active ResourceTransaction binding')
        return b
    def load(self,player_id:Any)->PlayerState|None:
        b=self._current(); pid=int(player_id); rec=self.repository.load_for_update(b.transaction,pid)
        if rec is None:return None
        b.expected_state_versions[pid]=int(rec.state_version)
        return PlayerPayloadCodec.hydrate(rec,self.base_player_factory())
    def save(self,player:PlayerState)->None:
        b=self._current(); pid=int(player.player_id)
        expected=b.expected_state_versions.get(pid)
        if expected is None: raise RuntimeError('save requires this PlayerState to be loaded in the current ResourceTransaction')
        transformed=PlayerPayloadCodec.transform(player)
        # Mature handlers may call StateRepository.save() directly rather than
        # entering a PlayerUnitOfWork.  Preserve their semantics while keeping
        # one optimistic version increment per relational save.
        if int(transformed.record.state_version) == int(expected):
            persistence = ensure_persistence_state(player)
            persistence["state_version"] = int(expected) + 1
            transformed=PlayerPayloadCodec.transform(player)
        self.repository.save(b.transaction,transformed.record,expected_state_version=expected)
        b.expected_state_versions[pid]=int(transformed.record.state_version)
    def fingerprint(self,player_id:Any)->object|None:
        # DB row locks/state_version replace filesystem mtime fingerprinting.
        return None

@contextmanager
def relational_player_sub_uow(store:TransactionBoundPostgresPlayerStateStore, transaction:Any, player_id:int, operation:OperationContext)->Iterator[PlayerUnitOfWork]:
    """Run existing PlayerUnitOfWork beneath a declared outer ResourceTransaction.

    The player row must already be part of the outer request's canonical resource
    plan.  This prevents a caller from taking a late PLAYER lock after SHARED or
    another player resource and silently violating the universal order.
    """
    request=getattr(transaction,"request",None)
    resources=tuple(getattr(request,"resources",()) or ())
    required=player_state_resource(player_id)
    if required not in resources:
        raise RuntimeError(f"outer ResourceTransaction did not declare {required.resource_class.name}:{required.kind}:{required.identity}")
    with store.bind(transaction):
        player=store.load(player_id)
        if player is None: raise LookupError(str(player_id))
        uow=PlayerUnitOfWork(player,lambda:store.save(player))
        with uow.transaction(operation): yield uow
