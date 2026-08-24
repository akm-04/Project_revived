"""Pass111 durable MID50 operation-identity and replay contract.

This module owns no Summon probability or pool policy.  It validates the
source-native client UUID bridge, fingerprints the stable MID50 request tuple,
and serializes the split replay payload frozen in Pass109: immutable static
outcomes plus instructions for rendering current cumulative projections.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass
import hashlib
import json
import re
from typing import Any, Mapping


RECEIPT_DOMAIN = "mid50_summon"
RECEIPT_MODE = "CLIENT_UUID_V4"
RETENTION_POLICY = "CLIENT_UUID_PERMANENT"

_UUID_RE = re.compile(
    r"^mid50-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
)


class Mid50OperationIdentityError(ValueError):
    pass


@dataclass(frozen=True)
class Mid50OperationIdentity:
    operation_id: str
    summon_type: int
    summon_index: int
    fingerprint: str

    @classmethod
    def from_request(
        cls,
        request: Mapping[str, Any],
        *,
        summon_type: int,
        summon_index: int,
    ) -> "Mid50OperationIdentity | None":
        raw = request.get("summon_op_id")
        if raw is None or str(raw).strip() == "":
            return None
        operation_id = str(raw).strip().lower()
        if not _UUID_RE.fullmatch(operation_id):
            raise Mid50OperationIdentityError("MID50 summon_op_id is not a mid50-prefixed UUIDv4")
        stype = _strict_int(summon_type, field="summon_type")
        sindex = _strict_int(summon_index, field="summon_index")
        return cls(
            operation_id=operation_id,
            summon_type=stype,
            summon_index=sindex,
            fingerprint=mid50_request_fingerprint(stype, sindex),
        )


def _strict_int(value: Any, *, field: str) -> int:
    if isinstance(value, bool):
        raise Mid50OperationIdentityError(f"{field} must be an integer")
    try:
        result = int(value)
    except (TypeError, ValueError) as exc:
        raise Mid50OperationIdentityError(f"{field} must be an integer") from exc
    if result <= 0:
        raise Mid50OperationIdentityError(f"{field} must be positive")
    return result


def mid50_request_fingerprint(summon_type: int, summon_index: int) -> str:
    preimage = {
        "schema_version": 1,
        "protocol_mid": 50,
        "summon_type": _strict_int(summon_type, field="summon_type"),
        "summon_index": _strict_int(summon_index, field="summon_index"),
    }
    blob = json.dumps(
        preimage,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return "sha256:" + hashlib.sha256(blob).hexdigest()


def build_mid50_replay_payload(
    *,
    semantic: str,
    identity: Mid50OperationIdentity,
    response: Mapping[str, Any],
) -> dict[str, Any]:
    if not isinstance(response, Mapping):
        raise ValueError("MID50 committed response must be a mapping")
    static_response = {
        str(key): copy.deepcopy(value)
        for key, value in response.items()
        if str(key) not in {"economy_", "summon_info"}
    }
    economy = response.get("economy_")
    economy_keys = (
        sorted(str(key) for key in economy.keys())
        if isinstance(economy, Mapping)
        else []
    )
    return {
        "schema_version": 1,
        "protocol_mid": 50,
        "semantic": str(semantic),
        "request": {
            "summon_type": int(identity.summon_type),
            "summon_index": int(identity.summon_index),
        },
        "static_response": static_response,
        "projection": {
            "economy_keys": economy_keys,
            "summon_info": isinstance(response.get("summon_info"), Mapping),
        },
    }


def validate_mid50_replay_payload(
    payload: Any,
    *,
    identity: Mid50OperationIdentity,
) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise ValueError("MID50 receipt replay payload is missing")
    if int(payload.get("schema_version", 0) or 0) != 1:
        raise ValueError("MID50 receipt replay schema is unsupported")
    if int(payload.get("protocol_mid", 0) or 0) != 50:
        raise ValueError("MID50 receipt protocol mismatch")
    request = payload.get("request")
    if not isinstance(request, dict):
        raise ValueError("MID50 receipt request tuple is missing")
    if int(request.get("summon_type", 0) or 0) != identity.summon_type:
        raise ValueError("MID50 receipt summon_type mismatch")
    if int(request.get("summon_index", 0) or 0) != identity.summon_index:
        raise ValueError("MID50 receipt summon_index mismatch")
    if not isinstance(payload.get("static_response"), dict):
        raise ValueError("MID50 receipt static_response is missing")
    projection = payload.get("projection")
    if not isinstance(projection, dict):
        raise ValueError("MID50 receipt projection descriptor is missing")
    keys = projection.get("economy_keys")
    if not isinstance(keys, list) or any(not isinstance(key, str) or not key for key in keys):
        raise ValueError("MID50 receipt economy_keys are invalid")
    if not isinstance(projection.get("summon_info"), bool):
        raise ValueError("MID50 receipt summon_info projection flag is invalid")
    return copy.deepcopy(payload)
