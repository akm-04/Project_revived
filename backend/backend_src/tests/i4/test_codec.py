from __future__ import annotations

import copy

from gxb_backend.persistence.codec import LegacyMailExtraction, LegacyReceiptExtraction, PlayerPayloadCodec
from gxb_backend.state.persistence_state import ensure_persistence_state
from gxb_backend.state.profiles import make_fresh_player


def _player():
    p = make_fresh_player(account_uid="20000001", player_id="12500001", region=125, region_name="Deep Valley")
    p.player_name = "I4 Roundtrip"
    p.token = "raw-gameplay-secret"
    root = ensure_persistence_state(p)
    root["state_version"] = 7
    root["receipts"] = {
        "summon": {"op-1": {"status": "COMMITTED", "opaque_receipt_extension": 9}}
    }
    p.mails = [{"mail_id": "m-1", "title": "legacy", "opaque_mail_extension": {"x": 1}}]
    p._json_source_player = {
        "identity": {"account_uid": "stale", "player_id": "stale", "region": 9, "token": "stale", "opaque_identity": {"a": 1}},
        "domains": {"opaque_future_domain": {"nested": [1, 2, 3]}},
        "future_top_level": {"future_nested": {"k": "v"}},
    }
    return p


def test_transform_extracts_typed_identity_state_version_receipts_mail_and_secret() -> None:
    p = _player()
    before = copy.deepcopy(vars(p))
    out = PlayerPayloadCodec.transform(p)
    assert out.record.player_id == 12_500_001
    assert out.record.account_uid == "20000001"
    assert out.record.region_id == 125
    assert out.record.state_version == 7
    identity = out.record.payload["identity"]
    for forbidden in ("account_uid", "player_id", "region", "token"):
        assert forbidden not in identity
    assert identity["opaque_identity"] == {"a": 1}
    assert "state_version" not in out.record.payload["domains"]["persistence_state"]
    assert "receipts" not in out.record.payload["domains"]["persistence_state"]
    assert "mails" not in out.record.payload["lobby"]
    assert out.receipts == (LegacyReceiptExtraction("summon", "op-1", {"status": "COMMITTED", "opaque_receipt_extension": 9}),)
    assert out.mails[0].legacy_mail_id == "m-1"
    assert out.account_global_payload == {}
    # Pure migration transform must not refresh/mutate the source PlayerState.
    assert vars(p) == before


def test_roundtrip_preserves_unknown_extensions_and_rehydrates_compatibility_views() -> None:
    p = _player()
    out = PlayerPayloadCodec.transform(p)
    base = make_fresh_player(account_uid="x", player_id="1", region=1, region_name="Local-1")
    restored = PlayerPayloadCodec.hydrate(out.record, base, receipts=out.receipts, mails=out.mails)
    assert restored.account_uid == "20000001"
    assert restored.player_id == "12500001"
    assert restored.region == 125
    assert restored.token == ""
    assert ensure_persistence_state(restored)["state_version"] == 7
    assert ensure_persistence_state(restored)["receipts"]["summon"]["op-1"]["opaque_receipt_extension"] == 9
    assert restored.mails[0]["opaque_mail_extension"] == {"x": 1}
    source = restored._json_source_player
    assert source["future_top_level"] == {"future_nested": {"k": "v"}}
    assert source["domains"]["opaque_future_domain"] == {"nested": [1, 2, 3]}
    assert source["identity"]["opaque_identity"] == {"a": 1}


def test_roundtrip_then_transform_does_not_reintroduce_typed_json_fields() -> None:
    p = _player()
    first = PlayerPayloadCodec.transform(p)
    restored = PlayerPayloadCodec.hydrate(first.record, make_fresh_player(account_uid="x", player_id="1", region=1, region_name="Local-1"), receipts=first.receipts, mails=first.mails)
    second = PlayerPayloadCodec.transform(restored)
    assert second.record.player_id == first.record.player_id
    assert second.record.account_uid == first.record.account_uid
    assert second.record.region_id == first.record.region_id
    assert second.record.state_version == first.record.state_version
    assert second.record.payload["future_top_level"] == first.record.payload["future_top_level"]
    for forbidden in ("account_uid", "player_id", "region", "token"):
        assert forbidden not in second.record.payload["identity"]


def test_pass334_receipt_migration_identity_and_mail_delivery_identity_are_deterministic() -> None:
    out = PlayerPayloadCodec.transform(_player())
    receipt = out.receipts[0]
    assert receipt.migration_key(out.record.player_id) == "player:12500001:summon:op-1"
    assert receipt.migration_key(out.record.player_id) == receipt.migration_key("12500001")
    mail = out.mails[0]
    first = mail.delivery_key(out.record.player_id)
    second = LegacyMailExtraction(mail.ordinal, mail.legacy_mail_id, copy.deepcopy(dict(mail.payload))).delivery_key(out.record.player_id)
    assert first == second
    assert first.startswith("legacy-mail:")
    assert len(first) == len("legacy-mail:") + 64


def test_pass334_extraction_accounting_is_exact_and_semantic() -> None:
    out = PlayerPayloadCodec.transform(_player())
    accounting = out.extraction_accounting()
    assert accounting.receipt_count == 1
    assert accounting.mail_count == 1
    assert len(accounting.receipt_identity_digest) == 64
    assert len(accounting.receipt_semantic_digest) == 64
    assert len(accounting.mail_identity_digest) == 64
    assert len(accounting.mail_semantic_digest) == 64

    # Deterministic for the same immutable source.
    assert accounting == PlayerPayloadCodec.transform(_player()).extraction_accounting()

    # Exact semantic accounting: an extension change must alter the semantic
    # digest and mail delivery identity, rather than silently disappearing.
    changed = _player()
    changed.mails[0]["opaque_mail_extension"] = {"x": 2}
    changed_accounting = PlayerPayloadCodec.transform(changed).extraction_accounting()
    assert changed_accounting.mail_semantic_digest != accounting.mail_semantic_digest
    assert changed_accounting.mail_identity_digest != accounting.mail_identity_digest

    changed_receipt = _player()
    ensure_persistence_state(changed_receipt)["receipts"]["summon"]["op-1"]["opaque_receipt_extension"] = 10
    changed_receipt_accounting = PlayerPayloadCodec.transform(changed_receipt).extraction_accounting()
    assert changed_receipt_accounting.receipt_semantic_digest != accounting.receipt_semantic_digest
    # Receipt identity is based on player/domain/key, so semantic content may
    # change its audit digest without changing the deterministic import key.
    assert changed_receipt_accounting.receipt_identity_digest == accounting.receipt_identity_digest
