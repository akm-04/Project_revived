"""MID113 -> MID114 Campaign battle operation identity and replay contracts.

Pass117 uses one source-native client UUID across Campaign battle staging and
settlement. This module owns identity/fingerprint/replay mechanics only; Campaign
probability, progression, costs, and reward policy remain domain-owned.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass
import hashlib
import json
import re
from typing import Any, Mapping


STAGE_RECEIPT_DOMAIN = "mid113_campaign_battle_stage"
RESULT_RECEIPT_DOMAIN = "mid114_campaign_battle_result"
RECEIPT_MODE = "CLIENT_UUID_V4"
RETENTION_POLICY = "CLIENT_UUID_PERMANENT"
STAGE_PROTOCOL_MID = 113
RESULT_PROTOCOL_MID = 114
REPLAY_SCHEMA_VERSION = 1

_UUID_RE = re.compile(
    r"^mid113-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
)


class CampaignBattleOperationIdentityError(ValueError):
    pass


def _strict_int(value: Any, *, field: str, default: int | None = None) -> int:
    if value is None and default is not None:
        return int(default)
    if isinstance(value, bool):
        raise CampaignBattleOperationIdentityError(f"{field} must be an integer")
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise CampaignBattleOperationIdentityError(f"{field} must be an integer") from exc


def _positive_int(value: Any, *, field: str) -> int:
    result = _strict_int(value, field=field)
    if result <= 0:
        raise CampaignBattleOperationIdentityError(f"{field} must be positive")
    return result


def _nonnegative_int(value: Any, *, field: str, default: int = 0) -> int:
    result = _strict_int(value, field=field, default=default)
    if result < 0:
        raise CampaignBattleOperationIdentityError(f"{field} must be nonnegative")
    return result


def _text(value: Any) -> str:
    return str(value or "")


def _canonical_fingerprint(preimage: Mapping[str, Any]) -> str:
    blob = json.dumps(
        dict(preimage), sort_keys=True, separators=(",", ":"), ensure_ascii=False
    ).encode("utf-8")
    return "sha256:" + hashlib.sha256(blob).hexdigest()


def _operation_id(request: Mapping[str, Any]) -> str | None:
    raw = request.get("campaign_battle_op_id")
    if raw is None or str(raw).strip() == "":
        return None
    operation_id = str(raw).strip().lower()
    if not _UUID_RE.fullmatch(operation_id):
        raise CampaignBattleOperationIdentityError(
            "campaign_battle_op_id is not a mid113-prefixed UUIDv4"
        )
    return operation_id


def mid113_stage_fingerprint(request: Mapping[str, Any]) -> str:
    preimage = {
        "schema_version": 1,
        "protocol_mid": STAGE_PROTOCOL_MID,
        "campaign_id": _positive_int(request.get("campaign_id"), field="campaign_id"),
        "campaign_type": _positive_int(request.get("campaign_type"), field="campaign_type"),
        "formation": _text(request.get("formation")),
        "pet_id": _nonnegative_int(request.get("pet_id"), field="pet_id"),
        "rent_player_id": _text(request.get("rent_player_id")),
        "rent_formation": _text(request.get("rent_formation")),
        "rent_pet_player_id": _text(request.get("rent_pet_player_id")),
        "rent_pet_id": _text(request.get("rent_pet_id")),
    }
    return _canonical_fingerprint(preimage)


def mid114_result_fingerprint(request: Mapping[str, Any]) -> str:
    preimage = {
        "schema_version": 1,
        "protocol_mid": RESULT_PROTOCOL_MID,
        "campaign_id": _positive_int(request.get("campaign_id"), field="campaign_id"),
        "campaign_type": _positive_int(request.get("campaign_type"), field="campaign_type"),
        "formation": _text(request.get("formation")),
        "star": max(0, min(3, _nonnegative_int(request.get("star"), field="star"))),
        "pet_id": _nonnegative_int(request.get("pet_id"), field="pet_id"),
        "awake_mission": _nonnegative_int(request.get("awake_mission"), field="awake_mission"),
        "pet_awaken_mission": _nonnegative_int(
            request.get("pet_awaken_mission"), field="pet_awaken_mission"
        ),
        "assist_partner": _nonnegative_int(request.get("assist_partner"), field="assist_partner"),
    }
    return _canonical_fingerprint(preimage)


@dataclass(frozen=True)
class CampaignBattleStageIdentity:
    operation_id: str
    campaign_id: int
    campaign_type: int
    formation: str
    fingerprint: str

    @classmethod
    def from_request(cls, request: Mapping[str, Any]) -> "CampaignBattleStageIdentity | None":
        if not isinstance(request, Mapping):
            raise CampaignBattleOperationIdentityError("MID113 request must be a mapping")
        operation_id = _operation_id(request)
        if operation_id is None:
            return None
        campaign_id = _positive_int(request.get("campaign_id"), field="campaign_id")
        campaign_type = _positive_int(request.get("campaign_type"), field="campaign_type")
        if campaign_type not in (1, 2):
            raise CampaignBattleOperationIdentityError(
                "campaign_battle_op_id is valid only for Normal/Super MID113"
            )
        return cls(
            operation_id=operation_id,
            campaign_id=campaign_id,
            campaign_type=campaign_type,
            formation=_text(request.get("formation")),
            fingerprint=mid113_stage_fingerprint(request),
        )


@dataclass(frozen=True)
class CampaignBattleResultIdentity:
    operation_id: str
    campaign_id: int
    campaign_type: int
    formation: str
    star: int
    fingerprint: str

    @classmethod
    def from_request(cls, request: Mapping[str, Any]) -> "CampaignBattleResultIdentity | None":
        if not isinstance(request, Mapping):
            raise CampaignBattleOperationIdentityError("MID114 request must be a mapping")
        operation_id = _operation_id(request)
        if operation_id is None:
            return None
        campaign_id = _positive_int(request.get("campaign_id"), field="campaign_id")
        campaign_type = _positive_int(request.get("campaign_type"), field="campaign_type")
        if campaign_type not in (1, 2):
            raise CampaignBattleOperationIdentityError(
                "campaign_battle_op_id is valid only for Normal/Super MID114"
            )
        star = max(0, min(3, _nonnegative_int(request.get("star"), field="star")))
        return cls(
            operation_id=operation_id,
            campaign_id=campaign_id,
            campaign_type=campaign_type,
            formation=_text(request.get("formation")),
            star=star,
            fingerprint=mid114_result_fingerprint(request),
        )


def build_mid113_stage_replay_payload(
    *,
    identity: CampaignBattleStageIdentity,
    response: Mapping[str, Any],
    active_session: Mapping[str, Any],
    source_catalog_sha256: str,
) -> dict[str, Any]:
    if not isinstance(response, Mapping):
        raise ValueError("MID113 response must be a mapping")
    if not isinstance(active_session, Mapping):
        raise ValueError("MID113 active session must be a mapping")
    items = response.get("items")
    if not isinstance(items, list):
        raise ValueError("MID113 response items must be a list")
    drop_plan = active_session.get("drop_plan")
    if not isinstance(drop_plan, Mapping):
        raise ValueError("MID113 active session drop_plan is missing")
    catalog_hash = str(source_catalog_sha256).strip().lower()
    if not re.fullmatch(r"[0-9a-f]{64}", catalog_hash):
        raise ValueError("source_catalog_sha256 must be 64 lowercase hex characters")
    static_response = {
        key: copy.deepcopy(response.get(key))
        for key in ("battle_id", "report", "seed", "enemy_info", "items")
    }
    return {
        "schema_version": REPLAY_SCHEMA_VERSION,
        "protocol_mid": STAGE_PROTOCOL_MID,
        "request": {
            "campaign_id": identity.campaign_id,
            "campaign_type": identity.campaign_type,
            "formation": identity.formation,
        },
        "static_response": static_response,
        "staged": {
            "drop_plan": copy.deepcopy(dict(drop_plan)),
            "reward_plan": {
                key: int(active_session.get(key, 0) or 0)
                for key in ("mana_gain", "star_gift", "partner_exp", "player_exp_gain")
            },
        },
        "audit": {
            "source_catalog_sha256": catalog_hash,
            "source_pool_id": int(drop_plan.get("source_pool_id", 0) or 0),
            "policy_id": str(drop_plan.get("policy_id") or ""),
            "policy_version": int(drop_plan.get("policy_version", 0) or 0),
        },
    }


def validate_mid113_stage_replay_payload(
    payload: Any, *, identity: CampaignBattleStageIdentity
) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise ValueError("MID113 stage receipt replay payload is missing")
    if int(payload.get("schema_version", 0) or 0) != REPLAY_SCHEMA_VERSION:
        raise ValueError("MID113 stage receipt schema mismatch")
    if int(payload.get("protocol_mid", 0) or 0) != STAGE_PROTOCOL_MID:
        raise ValueError("MID113 stage receipt protocol mismatch")
    request = payload.get("request")
    if not isinstance(request, dict):
        raise ValueError("MID113 stage receipt request tuple is missing")
    if int(request.get("campaign_id", 0) or 0) != identity.campaign_id:
        raise ValueError("MID113 stage receipt campaign_id mismatch")
    if int(request.get("campaign_type", 0) or 0) != identity.campaign_type:
        raise ValueError("MID113 stage receipt campaign_type mismatch")
    if str(request.get("formation") or "") != identity.formation:
        raise ValueError("MID113 stage receipt formation mismatch")
    static = payload.get("static_response")
    staged = payload.get("staged")
    audit = payload.get("audit")
    if not isinstance(static, dict) or not isinstance(static.get("items"), list):
        raise ValueError("MID113 stage receipt static response is invalid")
    if not isinstance(staged, dict) or not isinstance(staged.get("drop_plan"), dict):
        raise ValueError("MID113 stage receipt staged DropPlan is invalid")
    if not isinstance(staged.get("reward_plan"), dict):
        raise ValueError("MID113 stage receipt reward plan is invalid")
    if not isinstance(audit, dict) or not re.fullmatch(
        r"[0-9a-f]{64}", str(audit.get("source_catalog_sha256") or "")
    ):
        raise ValueError("MID113 stage receipt audit is invalid")
    return copy.deepcopy(payload)


def build_mid114_result_replay_payload(
    *, identity: CampaignBattleResultIdentity, response: Mapping[str, Any]
) -> dict[str, Any]:
    if not isinstance(response, Mapping):
        raise ValueError("MID114 response must be a mapping")
    static_response = {
        str(key): copy.deepcopy(value)
        for key, value in response.items()
        if str(key) not in {"economy_", "chapter_info", "campaigns"}
    }
    economy = response.get("economy_")
    economy_keys = sorted(str(key) for key in economy) if isinstance(economy, Mapping) else []
    campaigns = response.get("campaigns")
    touched_ids: list[int] = []
    if isinstance(campaigns, list):
        for row in campaigns:
            if not isinstance(row, Mapping):
                continue
            try:
                cid = int(row.get("campaign_id", 0) or 0)
            except (TypeError, ValueError):
                cid = 0
            if cid > 0 and cid not in touched_ids:
                touched_ids.append(cid)
    return {
        "schema_version": REPLAY_SCHEMA_VERSION,
        "protocol_mid": RESULT_PROTOCOL_MID,
        "request": {
            "campaign_id": identity.campaign_id,
            "campaign_type": identity.campaign_type,
            "formation": identity.formation,
            "star": identity.star,
        },
        "static_response": static_response,
        "projection": {
            "economy_keys": economy_keys,
            "chapter_info": isinstance(response.get("chapter_info"), Mapping),
            "campaign_ids": touched_ids,
        },
    }


def validate_mid114_result_replay_payload(
    payload: Any, *, identity: CampaignBattleResultIdentity
) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise ValueError("MID114 result receipt replay payload is missing")
    if int(payload.get("schema_version", 0) or 0) != REPLAY_SCHEMA_VERSION:
        raise ValueError("MID114 result receipt schema mismatch")
    if int(payload.get("protocol_mid", 0) or 0) != RESULT_PROTOCOL_MID:
        raise ValueError("MID114 result receipt protocol mismatch")
    request = payload.get("request")
    if not isinstance(request, dict):
        raise ValueError("MID114 result receipt request tuple is missing")
    expected = {
        "campaign_id": identity.campaign_id,
        "campaign_type": identity.campaign_type,
        "formation": identity.formation,
        "star": identity.star,
    }
    for key, value in expected.items():
        actual = request.get(key)
        if key == "formation":
            if str(actual or "") != str(value):
                raise ValueError(f"MID114 result receipt {key} mismatch")
        elif int(actual or 0) != int(value):
            raise ValueError(f"MID114 result receipt {key} mismatch")
    if not isinstance(payload.get("static_response"), dict):
        raise ValueError("MID114 result receipt static_response is missing")
    projection = payload.get("projection")
    if not isinstance(projection, dict):
        raise ValueError("MID114 result receipt projection is missing")
    keys = projection.get("economy_keys")
    ids = projection.get("campaign_ids")
    if not isinstance(keys, list) or any(not isinstance(key, str) or not key for key in keys):
        raise ValueError("MID114 result receipt economy keys are invalid")
    if not isinstance(projection.get("chapter_info"), bool):
        raise ValueError("MID114 result receipt chapter_info flag is invalid")
    if not isinstance(ids, list) or any(not isinstance(value, int) or value <= 0 for value in ids):
        raise ValueError("MID114 result receipt campaign ids are invalid")
    return copy.deepcopy(payload)
