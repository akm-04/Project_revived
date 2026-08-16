#!/usr/bin/env python3
"""Compatibility launcher for the modular Stage 4A.9 GXB backend.

Existing workflows that run `python server.py` can keep doing so.
"""

from gxb_backend.run import main


if __name__ == "__main__":
    main()
