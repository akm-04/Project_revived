from gxb_backend.transport.decoder import decode_payload, is_legacy_nil_payload


def test_stock_payload_nil_is_recognized_as_exact_compatibility_sentinel():
    assert is_legacy_nil_payload(b"nil")
    assert is_legacy_nil_payload("nil")
    for value in (None, b"", b"null", b"{}", b"nil ", b"NIL"):
        assert not is_legacy_nil_payload(value)


def test_stock_payload_nil_remains_undecodable_and_requires_route_noop_policy():
    value, method = decode_payload(b"nil")
    assert value is None
    assert method == "undecoded"


def test_route_source_scopes_nil_noop_to_exact_sentinel_and_keeps_generic_failure():
    from pathlib import Path
    source=(Path(__file__).resolve().parents[1]/"gxb_backend"/"transport"/"routes_engine.py").read_text(encoding="utf-8")
    assert "if is_legacy_nil_payload(raw):" in source
    assert 'return json_response({"error_code": 0})' in source
    assert '"error_kind": "MALFORMED_ENGINE_REQUEST"' in source
    assert "status_code=400" in source
