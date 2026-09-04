"""MID117 durable operation-identity and replay serialization contract.

Pass113 froze these helpers inertly; Pass114 activates them in WorldRepository
for source-native UUID exactly-once Campaign sweep settlement. The helpers own no
Campaign drop probability, pool, cost, or progression policy.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass
import hashlib
import json
import re
from typing import Any, Mapping


RECEIPT_DOMAIN = "mid117_campaign_sweep"
RECEIPT_MODE = "CLIENT_UUID_V4"
RETENTION_POLICY = "CLIENT_UUID_PERMANENT"
PROTOCOL_MID = 117
REPLAY_SCHEMA_VERSION = 1

_UUID_RE = re.compile(
    r"^mid117-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
)


class Mid117OperationIdentityError(ValueError):
    pass


@dataclass(frozen=True)
class Mid117OperationIdentity:
    operation_id: str
    campaign_id: int
    campaign_type: int
    sweep_num: int
    sweep_type: int
    awake_mission: int
    fingerprint: str

    @classmethod
    def from_request(cls, request: Mapping[str, Any]) -> "Mid117OperationIdentity | None":
        if not isinstance(request, Mapping):
            raise Mid117OperationIdentityError("MID117 request must be a mapping")
        raw = request.get("campaign_sweep_op_id")
        if raw is None or str(raw).strip() == "":
            return None
        operation_id = str(raw).strip().lower()
        if not _UUID_RE.fullmatch(operation_id):
            raise Mid117OperationIdentityError(
                "MID117 campaign_sweep_op_id is not a mid117-prefixed UUIDv4"
            )
        campaign_id = _positive_int(request.get("campaign_id"), field="campaign_id")
        campaign_type = _positive_int(request.get("campaign_type"), field="campaign_type")
        sweep_num = _positive_int(request.get("sweep_num"), field="sweep_num")
        sweep_type = _positive_int(request.get("sweep_type"), field="sweep_type")
        if sweep_type not in (1, 2):
            raise Mid117OperationIdentityError("sweep_type must be ITEM_SWEEP(1) or CRYSTAL_SWEEP(2)")
        awake_mission = _nonnegative_int(request.get("awake_mission", 0), field="awake_mission")
        return cls(
            operation_id=operation_id,
            campaign_id=campaign_id,
            campaign_type=campaign_type,
            sweep_num=sweep_num,
            sweep_type=sweep_type,
            awake_mission=awake_mission,
            fingerprint=mid117_request_fingerprint(
                campaign_id=campaign_id,
                campaign_type=campaign_type,
                sweep_num=sweep_num,
                sweep_type=sweep_type,
                awake_mission=awake_mission,
            ),
        )


def _positive_int(value: Any, *, field: str) -> int:
    result = _strict_int(value, field=field)
    if result <= 0:
        raise Mid117OperationIdentityError(f"{field} must be positive")
    return result


def _nonnegative_int(value: Any, *, field: str) -> int:
    result = _strict_int(value, field=field)
    if result < 0:
        raise Mid117OperationIdentityError(f"{field} must be nonnegative")
    return result


def _strict_int(value: Any, *, field: str) -> int:
    if isinstance(value, bool):
        raise Mid117OperationIdentityError(f"{field} must be an integer")
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise Mid117OperationIdentityError(f"{field} must be an integer") from exc


def mid117_request_fingerprint(
    *,
    campaign_id: Any,
    campaign_type: Any,
    sweep_num: Any,
    sweep_type: Any,
    awake_mission: Any = 0,
) -> str:
    stype = _positive_int(sweep_type, field="sweep_type")
    if stype not in (1, 2):
        raise Mid117OperationIdentityError("sweep_type must be ITEM_SWEEP(1) or CRYSTAL_SWEEP(2)")
    preimage = {
        "schema_version": 1,
        "protocol_mid": PROTOCOL_MID,
        "campaign_id": _positive_int(campaign_id, field="campaign_id"),
        "campaign_type": _positive_int(campaign_type, field="campaign_type"),
        "sweep_num": _positive_int(sweep_num, field="sweep_num"),
        "sweep_type": stype,
        "awake_mission": _nonnegative_int(awake_mission, field="awake_mission"),
    }
    blob = json.dumps(
        preimage,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return "sha256:" + hashlib.sha256(blob).hexdigest()


def build_mid117_replay_payload(
    *,
    identity: Mid117OperationIdentity,
    response: Mapping[str, Any],
    source_pool_id: int,
    source_catalog_sha256: str,
    repeat_policy_id: str,
    repeat_policy_version: int,
    awakening_overlay_audit: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    if not isinstance(response, Mapping):
        raise ValueError("MID117 committed response must be a mapping")
    items = response.get("items")
    economys = response.get("economys")
    additional = response.get("additional")
    if not isinstance(items, list) or any(not isinstance(row, list) for row in items):
        raise ValueError("MID117 committed response items must be a list of per-sweep lists")
    if len(items) != identity.sweep_num:
        raise ValueError("MID117 committed response items length does not match sweep_num")
    if not isinstance(economys, list) or len(economys) != identity.sweep_num:
        raise ValueError("MID117 committed response economys length does not match sweep_num")
    if not isinstance(additional, list):
        raise ValueError("MID117 committed response additional must be a list")

    static_response: dict[str, Any] = {
        "items": copy.deepcopy(items),
        "economys": copy.deepcopy(economys),
        "additional": copy.deepcopy(additional),
    }
    if "chapter_event" in response:
        static_response["chapter_event"] = copy.deepcopy(response.get("chapter_event"))

    economy = response.get("economy_")
    economy_keys = (
        sorted(str(key) for key in economy.keys())
        if isinstance(economy, Mapping)
        else []
    )
    catalog_hash = str(source_catalog_sha256).strip().lower()
    if not re.fullmatch(r"[0-9a-f]{64}", catalog_hash):
        raise ValueError("source_catalog_sha256 must be 64 lowercase hex characters")
    pool_id = _nonnegative_int(source_pool_id, field="source_pool_id")
    policy_version = _positive_int(repeat_policy_version, field="repeat_policy_version")
    policy_id = str(repeat_policy_id).strip()
    if not policy_id:
        raise ValueError("repeat_policy_id must be nonempty")

    audit: dict[str, Any] = {
        "repeat_policy_id": policy_id,
        "repeat_policy_version": policy_version,
        "source_catalog_sha256": catalog_hash,
        "source_pool_id": pool_id,
    }
    if awakening_overlay_audit is not None:
        if not isinstance(awakening_overlay_audit, Mapping):
            raise ValueError("awakening_overlay_audit must be a mapping")
        audit["awakening_campaign_overlay"] = copy.deepcopy(dict(awakening_overlay_audit))

    return {
        "schema_version": REPLAY_SCHEMA_VERSION,
        "protocol_mid": PROTOCOL_MID,
        "request": {
            "campaign_id": identity.campaign_id,
            "campaign_type": identity.campaign_type,
            "sweep_num": identity.sweep_num,
            "sweep_type": identity.sweep_type,
            "awake_mission": identity.awake_mission,
        },
        "static_response": static_response,
        "projection": {
            "economy_keys": economy_keys,
            "campaign": isinstance(response.get("campaign"), Mapping),
            "trial": isinstance(response.get("trial"), Mapping),
            "challenge": isinstance(response.get("challenge"), Mapping),
        },
        "audit": audit,
    }


def validate_mid117_replay_payload(
    payload: Any,
    *,
    identity: Mid117OperationIdentity,
) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise ValueError("MID117 receipt replay payload is missing")
    if int(payload.get("schema_version", 0) or 0) != REPLAY_SCHEMA_VERSION:
        raise ValueError("MID117 receipt replay schema is unsupported")
    if int(payload.get("protocol_mid", 0) or 0) != PROTOCOL_MID:
        raise ValueError("MID117 receipt protocol mismatch")

    request = payload.get("request")
    if not isinstance(request, dict):
        raise ValueError("MID117 receipt request tuple is missing")
    expected = {
        "campaign_id": identity.campaign_id,
        "campaign_type": identity.campaign_type,
        "sweep_num": identity.sweep_num,
        "sweep_type": identity.sweep_type,
        "awake_mission": identity.awake_mission,
    }
    for key, value in expected.items():
        if int(request.get(key, -1) or 0) != value:
            raise ValueError(f"MID117 receipt {key} mismatch")

    static = payload.get("static_response")
    if not isinstance(static, dict):
        raise ValueError("MID117 receipt static_response is missing")
    items = static.get("items")
    economys = static.get("economys")
    additional = static.get("additional")
    if not isinstance(items, list) or len(items) != identity.sweep_num or any(not isinstance(row, list) for row in items):
        raise ValueError("MID117 receipt items are invalid")
    if not isinstance(economys, list) or len(economys) != identity.sweep_num:
        raise ValueError("MID117 receipt economys are invalid")
    if not isinstance(additional, list):
        raise ValueError("MID117 receipt additional is invalid")

    projection = payload.get("projection")
    if not isinstance(projection, dict):
        raise ValueError("MID117 receipt projection descriptor is missing")
    keys = projection.get("economy_keys")
    if not isinstance(keys, list) or any(not isinstance(key, str) or not key for key in keys):
        raise ValueError("MID117 receipt economy_keys are invalid")
    for key in ("campaign", "trial", "challenge"):
        if not isinstance(projection.get(key), bool):
            raise ValueError(f"MID117 receipt {key} projection flag is invalid")

    audit = payload.get("audit")
    if not isinstance(audit, dict):
        raise ValueError("MID117 receipt audit metadata is missing")
    if not str(audit.get("repeat_policy_id") or "").strip():
        raise ValueError("MID117 receipt repeat_policy_id is missing")
    if int(audit.get("repeat_policy_version", 0) or 0) <= 0:
        raise ValueError("MID117 receipt repeat_policy_version is invalid")
    if int(audit.get("source_pool_id", -1)) < 0:
        raise ValueError("MID117 receipt source_pool_id is invalid")
    if not re.fullmatch(r"[0-9a-f]{64}", str(audit.get("source_catalog_sha256") or "")):
        raise ValueError("MID117 receipt source_catalog_sha256 is invalid")
    overlay = audit.get("awakening_campaign_overlay")
    if overlay is not None:
        if not isinstance(overlay, dict):
            raise ValueError("MID117 receipt Awakening overlay audit is invalid")
        if int(overlay.get("schema_version", 0) or 0) != 1:
            raise ValueError("MID117 receipt Awakening overlay schema is invalid")
        if not str(overlay.get("policy_id") or "").strip():
            raise ValueError("MID117 receipt Awakening overlay policy is missing")
        if int(overlay.get("policy_version", 0) or 0) <= 0:
            raise ValueError("MID117 receipt Awakening overlay policy version is invalid")
        if int(overlay.get("rate_base", 0) or 0) <= 0:
            raise ValueError("MID117 receipt Awakening overlay rate base is invalid")
        resolved = overlay.get("resolved")
        sweeps = overlay.get("sweeps")
        if not isinstance(resolved, list) or any(not isinstance(row, dict) for row in resolved):
            raise ValueError("MID117 receipt Awakening overlay resolution is invalid")
        if not isinstance(sweeps, list) or len(sweeps) != identity.sweep_num:
            raise ValueError("MID117 receipt Awakening overlay sweeps are invalid")
        if any(not isinstance(row, dict) for row in sweeps):
            raise ValueError("MID117 receipt Awakening overlay sweep audit is invalid")
    return copy.deepcopy(payload)
