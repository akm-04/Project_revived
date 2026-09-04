from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_production_start_ensures_ota_before_http_listener():
    text = (ROOT / "gxb-dev.sh").read_text()
    ensure = text.index('prepare_stock_updates "$py"')
    gunicorn = text.index('start_bg http "$VENV/bin/gunicorn"', ensure)
    assert ensure < gunicorn
    assert 'update_controller.py ensure' in text


def test_proxy_does_not_bypass_catalog_aware_resource_gateway():
    text = (ROOT / "gxb-dev.sh").read_text()
    assert 'location /res/ { alias' not in text
    assert 'location / {' in text
    routes = (ROOT / "gxb_backend/transport/routes_engine.py").read_text()
    assert '@app.route("/res/<path:asset>"' in routes
    assert 'resource_gateway.capture(request, asset)' in routes


def test_workspace_v7_persists_ota_outside_disposable_backend():
    text = (ROOT / "gxb_backend_workspace_portable_v7.sh").read_text()
    assert 'WRAPPER_VERSION="7"' in text
    assert 'OTA_DIR="${GXB_OTA_HOME:-$RUNTIME_DIR/ota}"' in text
    assert 'ln -s -- "$OTA_DIR/updates" "$root/local_assets/updates"' in text
    for name in ('release_registry.json', 'update_manifest.json', 'update_controller_state.json'):
        assert name in text
    assert 'persistent OTA publication state' in text
