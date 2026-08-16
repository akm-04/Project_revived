"""Transport classification for GXB MIDs.

The Lua client routes Backend:request(mid, ...) through one of several
channels. Stage 1 implements the normal HTTP surface and a minimal TCP chat
stub; chat-bit-range and GM-bit-range MIDs should not be treated as ordinary
engine HTTP handlers unless they arrive there accidentally for diagnostics.
"""

from __future__ import annotations

from enum import Enum
from typing import Iterable

from .mids import MID


class RouteClass(str, Enum):
    ENGINE_HTTP = "engine-http-urlencoded-payload"
    ENGINE_ZLIB_FORM = "engine-http-zlib-form-payload"
    ENGINE_UPLOAD = "engine-http-upload-multipart"
    CHAT_TCP = "tcp/chat-routed"
    GM = "gm-routed"
    UNKNOWN = "unknown"


FORM_DATA_MIDS: set[int] = {
    getattr(MID, "ARENA_FIGHT_RESULT", -1),
    getattr(MID, "PEAK_START_FIGHT", -1),
    getattr(MID, "TREASURE_SAVE_BATTLE_RESULT", -1),
    getattr(MID, "REARENA_END_FIGHT", -1),
    getattr(MID, "REGION_FIGHT_RESULT", -1),
    getattr(MID, "CONQUER_SCHOOL_FIGHT_RESULT", -1),
    getattr(MID, "SAVE_FURNITURES", -1),
}
FORM_DATA_MIDS.discard(-1)

# Backend:isUpload() recognizes 1844 in the mapped client source.
UPLOAD_MIDS: set[int] = {1844}


CHAT_MASK = 36864
CHAT_VALUE = 32768
GM_VALUE = 36864


def is_chat_mid(mid: int) -> bool:
    return (int(mid) & CHAT_MASK) == CHAT_VALUE


def is_gm_mid(mid: int) -> bool:
    return (int(mid) & CHAT_MASK) == GM_VALUE


def classify_mid(mid: int) -> RouteClass:
    mid = int(mid)
    if is_gm_mid(mid):
        return RouteClass.GM
    if is_chat_mid(mid):
        return RouteClass.CHAT_TCP
    if mid in FORM_DATA_MIDS:
        return RouteClass.ENGINE_ZLIB_FORM
    if mid in UPLOAD_MIDS:
        return RouteClass.ENGINE_UPLOAD
    return RouteClass.ENGINE_HTTP


def contains_mid(values: Iterable[int], mid: int) -> bool:
    try:
        return int(mid) in {int(v) for v in values}
    except Exception:
        return False
