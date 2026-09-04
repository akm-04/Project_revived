from __future__ import annotations
import signal
import threading
from .composition import create_scheduler_process

def main() -> int:
    process, provider = create_scheduler_process()
    stop = threading.Event()
    def halt(*_): stop.set()
    signal.signal(signal.SIGTERM, halt); signal.signal(signal.SIGINT, halt)
    try: process.run_forever(stop=stop.is_set)
    finally: provider.dispose()
    return 0

if __name__ == "__main__": raise SystemExit(main())
