"""Compatibility-safe PlayerState <-> I4 JSONB transformation."""
from __future__ import annotations

import copy
import hashlib
import json
from dataclasses import dataclass
from typing import Any, Mapping

from gxb_backend.foundation.contracts import PlayerAggregateRecord
from gxb_backend.state.persistence_state import ensure_persistence_state
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState

_TYPED_IDENTITY_KEYS=("account_uid","player_id","region","token")


def canonical_json_digest(value: Any) -> str:
    """Return the Pass334 canonical semantic SHA-256 for migration accounting."""
    blob=json.dumps(value,sort_keys=True,separators=(",",":"),ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(blob).hexdigest()

@dataclass(frozen=True)
class LegacyReceiptExtraction:
    domain: str
    key: str
    record: Mapping[str, Any]

    def migration_key(self, player_id: int | str) -> str:
        # Pass334 freezes this identity form so re-running an importer cannot
        # create a second semantic receipt for the same embedded source row.
        return f"player:{int(player_id)}:{self.domain}:{self.key}"

    @property
    def canonical_digest(self) -> str:
        return canonical_json_digest(dict(self.record))

@dataclass(frozen=True)
class LegacyMailExtraction:
    ordinal: int
    legacy_mail_id: str | None
    payload: Mapping[str, Any]

    @property
    def canonical_digest(self) -> str:
        return canonical_json_digest(dict(self.payload))

    def delivery_key(self, player_id: int | str) -> str:
        # Pass334 requires player + source ordinal/id + canonical row digest.
        # Hash the identity envelope to keep the target unique key bounded even
        # when a legacy protocol mail id is unexpectedly long.
        identity={
            "player_id":int(player_id),
            "source_ordinal":int(self.ordinal),
            "legacy_mail_id":self.legacy_mail_id,
            "canonical_row_digest":self.canonical_digest,
        }
        return "legacy-mail:"+canonical_json_digest(identity)

@dataclass(frozen=True)
class ExtractionAccounting:
    receipt_count: int
    receipt_identity_digest: str
    receipt_semantic_digest: str
    mail_count: int
    mail_identity_digest: str
    mail_semantic_digest: str

@dataclass(frozen=True)
class PlayerTransformResult:
    record: PlayerAggregateRecord
    receipts: tuple[LegacyReceiptExtraction,...]
    mails: tuple[LegacyMailExtraction,...]
    account_global_payload: Mapping[str,Any]

    def extraction_accounting(self) -> ExtractionAccounting:
        player_id=int(self.record.player_id)
        receipt_ids=[x.migration_key(player_id) for x in self.receipts]
        receipt_rows=[
            {"migration_key":x.migration_key(player_id),"record":dict(x.record)}
            for x in self.receipts
        ]
        mail_ids=[x.delivery_key(player_id) for x in self.mails]
        mail_rows=[
            {
                "delivery_key":x.delivery_key(player_id),
                "ordinal":int(x.ordinal),
                "legacy_mail_id":x.legacy_mail_id,
                "payload":dict(x.payload),
            }
            for x in self.mails
        ]
        return ExtractionAccounting(
            receipt_count=len(receipt_rows),
            receipt_identity_digest=canonical_json_digest(receipt_ids),
            receipt_semantic_digest=canonical_json_digest(receipt_rows),
            mail_count=len(mail_rows),
            mail_identity_digest=canonical_json_digest(mail_ids),
            mail_semantic_digest=canonical_json_digest(mail_rows),
        )

class PlayerPayloadCodec:
    """Preserve mature/unknown gameplay JSON while relationalizing typed owners.

    The codec is pure: it does not persist, allocate IDs, normalize gameplay or
    contact PostgreSQL.  This is important for I7 migration rehearsal and for
    proving round-trip semantics in I4 without a live server.
    """
    schema_version=JsonPlayerDatabase.SCHEMA_VERSION

    @classmethod
    def transform(cls, player:PlayerState)->PlayerTransformResult:
        # ``serialize_player`` deliberately refreshes its source-extension snapshot.
        # Run it on a deep copy so this transformation remains side-effect free.
        body=copy.deepcopy(JsonPlayerDatabase.serialize_player(copy.deepcopy(player)))
        identity=body.get("identity") if isinstance(body.get("identity"),dict) else {}
        for key in _TYPED_IDENTITY_KEYS:
            identity.pop(key,None)
        body["identity"]=identity

        domains=body.get("domains") if isinstance(body.get("domains"),dict) else {}
        persistence=domains.get("persistence_state") if isinstance(domains.get("persistence_state"),dict) else {}
        state_version=max(0,int(persistence.pop("state_version",0) or 0))
        receipt_root=persistence.pop("receipts",{})
        domains["persistence_state"]=persistence
        body["domains"]=domains

        receipts=[]
        if isinstance(receipt_root,dict):
            for domain,bucket in sorted(receipt_root.items(),key=lambda x:str(x[0])):
                if not isinstance(bucket,dict): continue
                for key,record in sorted(bucket.items(),key=lambda x:str(x[0])):
                    if isinstance(record,dict): receipts.append(LegacyReceiptExtraction(str(domain),str(key),copy.deepcopy(record)))

        lobby=body.get("lobby") if isinstance(body.get("lobby"),dict) else {}
        mail_rows=lobby.pop("mails",[])
        body["lobby"]=lobby
        mails=[]
        if isinstance(mail_rows,list):
            for i,row in enumerate(mail_rows):
                if not isinstance(row,dict): continue
                raw=row.get("mail_id",row.get("id"))
                mails.append(LegacyMailExtraction(i,None if raw is None else str(raw),copy.deepcopy(row)))

        record=PlayerAggregateRecord(
            player_id=int(player.player_id), account_uid=str(player.account_uid), region_id=int(player.region),
            schema_version=cls.schema_version, state_version=state_version, payload=body,
        )
        # Pass334 explicitly forbids inferring account-global authority by merging
        # region-player VIP/progress. I4 therefore exposes an empty extraction.
        return PlayerTransformResult(record,tuple(receipts),tuple(mails),{})

    @classmethod
    def hydrate(cls, record:PlayerAggregateRecord, base_player:PlayerState, *, receipts:tuple[LegacyReceiptExtraction,...]=(), mails:tuple[LegacyMailExtraction,...]=())->PlayerState:
        body=copy.deepcopy(dict(record.payload))
        identity=body.setdefault("identity",{})
        if not isinstance(identity,dict): identity={}; body["identity"]=identity
        identity.update({"account_uid":str(record.account_uid),"player_id":str(record.player_id),"region":int(record.region_id)})
        # raw gameplay/session token is deliberately never reconstructed from DB
        identity["token"]=""
        domains=body.setdefault("domains",{})
        if not isinstance(domains,dict): domains={}; body["domains"]=domains
        persistence=domains.setdefault("persistence_state",{})
        if not isinstance(persistence,dict): persistence={}; domains["persistence_state"]=persistence
        persistence["state_version"]=int(record.state_version)
        if receipts:
            root={}
            for item in receipts: root.setdefault(item.domain,{})[item.key]=copy.deepcopy(dict(item.record))
            persistence["receipts"]=root
        lobby=body.setdefault("lobby",{})
        if not isinstance(lobby,dict): lobby={}; body["lobby"]=lobby
        if mails: lobby["mails"]=[copy.deepcopy(dict(x.payload)) for x in sorted(mails,key=lambda x:x.ordinal)]
        player=JsonPlayerDatabase.deserialize_player(body,base_player)
        ensure_persistence_state(player)["state_version"]=int(record.state_version)
        player.account_uid=str(record.account_uid); player.player_id=str(record.player_id); player.region=int(record.region_id); player.token=""
        return player
