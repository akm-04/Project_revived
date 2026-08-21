"""Runtime entry point for the modular backend."""

from __future__ import annotations

import threading
import time

from gxb_backend.app_factory import create_app
from gxb_backend.chat.stub import ChatStubServer
from gxb_backend.config import SETTINGS
from gxb_backend.updates.local_update import load_manifest


def _run_flask(app, port: int) -> None:
    app.run(
        host=SETTINGS.bind_host,
        port=port,
        debug=False,
        threaded=True,
        use_reloader=False,
    )


def main() -> None:
    app = create_app(SETTINGS)
    print("==================================================")
    print(" GXB modular v0.9.0 Pass68.1 Economy Backbone Part1 + Medium free runtime hotfix")
    print(f" SDK bind    : http://{SETTINGS.bind_host}:{SETTINGS.sdk_port}")
    print(f" ENGINE bind : http://{SETTINGS.bind_host}:{SETTINGS.engine_port}")
    print(f" ADVERTISE_HOST = {SETTINGS.advertise_host}")
    print(f" SELF_URL = {SETTINGS.self_url}")
    print(f" CHAT advertised = {SETTINGS.chat_host}:{SETTINGS.chat_port}")
    print(f" BOOT_DETAIL_MODE = {SETTINGS.bootstrap_detail_mode}")
    print(f" FUNC_MODE = {SETTINGS.func_mode}")
    print(f" PROFILE = {SETTINGS.profile}")
    print(f" LEGACY_SANDBOX_DB = {SETTINGS.player_db_path}")
    print(f" MULTIUSER_ROOT = {SETTINGS.multiuser_root}")
    print(f" CLIENT_LOG_URL = {SETTINGS.client_log_url}")
    print(f" RESOURCE_GATEWAY = {SETTINGS.resource_gateway_enabled}")
    print(f" RES_DOWNLOAD_URL = {SETTINGS.res_download_url if SETTINGS.resource_gateway_enabled else '(disabled)'}")
    print(f" RESOURCE_CATALOG = {SETTINGS.resource_catalog_path}")
    print(f" ASSET_ROOT_MODE = {SETTINGS.asset_root_mode}")
    print(f" ASSET_SEARCH_ROOTS = {', '.join(str(p) for p in SETTINGS.asset_roots)}")
    print(f" ASSET_DISCOVERY_DEPTH = {SETTINGS.asset_discovery_depth}")
    print(f" RESOURCE_MD5_VERIFY = {SETTINGS.resource_verify_md5}")
    update_manifest = load_manifest(SETTINGS)
    print(f" LOCAL_UPDATE_MANIFEST = {SETTINGS.local_update_manifest_path}")
    print(f" PROTOCOL_REGISTRY = {SETTINGS.protocol_registry_path}")
    if update_manifest is None:
        print(" LOCAL_UPDATE = disabled/not-built")
    else:
        print(
            f" LOCAL_UPDATE = enabled target={update_manifest['version']} "
            f"volumes={update_manifest['volume']} silent={update_manifest['silent']}"
        )
    print("==================================================")

    if SETTINGS.enable_chat_stub:
        ChatStubServer(SETTINGS.chat_host, SETTINGS.chat_port).start()

    t_sdk = threading.Thread(target=_run_flask, args=(app, SETTINGS.sdk_port), daemon=True, name="gxb-sdk-http")
    t_engine = threading.Thread(target=_run_flask, args=(app, SETTINGS.engine_port), daemon=True, name="gxb-engine-http")
    t_sdk.start()
    t_engine.start()

    try:
        while True:
            time.sleep(3600)
    except KeyboardInterrupt:
        print("\nStopping GXB backend.")


if __name__ == "__main__":
    main()
