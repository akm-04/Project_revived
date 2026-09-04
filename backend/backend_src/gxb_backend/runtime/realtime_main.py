from __future__ import annotations
import signal
import threading
from .composition import create_realtime_gateway

def main() -> int:
    gateway, provider = create_realtime_gateway()
    stop = threading.Event()
    def halt(*_): stop.set()
    signal.signal(signal.SIGTERM, halt); signal.signal(signal.SIGINT, halt)
    gateway.start()
    try:
        while not stop.wait(1.0): pass
    finally:
        gateway.stop(); provider.dispose()
    return 0

if __name__ == "__main__": raise SystemExit(main())
