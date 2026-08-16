"""Runtime entry point for the modular backend."""

from __future__ import annotations

import threading
import time

from gxb_backend.app_factory import create_app
from gxb_backend.chat.stub import ChatStubServer
from gxb_backend.config import SETTINGS


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
    print(" GXB modular Stage 1 backend")
    print(f" SDK    : http://{SETTINGS.bind_host}:{SETTINGS.sdk_port}")
    print(f" ENGINE : http://{SETTINGS.bind_host}:{SETTINGS.engine_port}")
    print(f" SELF_URL = {SETTINGS.self_url}")
    print(f" CHAT advertised = {SETTINGS.chat_host}:{SETTINGS.chat_port}")
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
