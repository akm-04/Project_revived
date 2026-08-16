#!/usr/bin/env python3
"""Compatibility launcher for the modular GXB v0.6.3 album/story recovery + local hot-update backend.

Existing workflows that run `python server.py` can keep doing so.
"""

from gxb_backend.run import main


if __name__ == "__main__":
    main()
