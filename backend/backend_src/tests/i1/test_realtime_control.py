from __future__ import annotations

import pytest

from gxb_backend.realtime.control import (
    PRIVATE_SERVER_CONTROL_MID,
    PrivateControlKind,
    normalize_control_payload,
)


def test_private_control_mid_fits_existing_u16_frame() -> None:
    assert PRIVATE_SERVER_CONTROL_MID == 65_000
    assert 0 <= PRIVATE_SERVER_CONTROL_MID <= 65_535


def test_control_kinds_normalize_without_durable_side_effects() -> None:
    for kind in PrivateControlKind:
        assert normalize_control_payload({"kind": kind.value}) == {"kind": kind.value}
    assert normalize_control_payload({"kind": "ROOM_INVALIDATED", "room_id": "12"}) == {
        "kind": "ROOM_INVALIDATED",
        "room_id": 12,
    }


def test_private_control_rejects_unknown_kind_and_bad_room() -> None:
    with pytest.raises(ValueError):
        normalize_control_payload({"kind": "FORCE_RELOAD"})
    with pytest.raises(ValueError):
        normalize_control_payload({"kind": "ROOM_INVALIDATED", "room_id": 0})
