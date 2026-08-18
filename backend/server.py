#!/usr/bin/env python3
"""Compatibility launcher for the modular GXB v0.8.14 Pass 35.3 backend.

No-argument behavior remains the historical launcher: ``python3 server.py``
starts the backend.  ``-h`` / ``--help`` is operator documentation only.
"""
from __future__ import annotations

import argparse


def build_parser() -> argparse.ArgumentParser:
    return argparse.ArgumentParser(
        prog="server.py",
        description=(
            "Start the local Girls X Battle EOL backend. With no options this launches "
            "the SDK HTTP plane, engine HTTP plane, optional chat stub, resource gateway, "
            "and the currently configured (disabled-by-default) MID2 update advertisement."
        ),
        epilog=(
            "Writable update quick start:\n"
            "  1. Read UPDATE_README.md.\n"
            "  2. Prepared/Pass35.1-runtime-validated package: local_assets/updates/gxb-local-1.631.2.zip.001\n"
            "     (manifest is shipped enabled=false).\n"
            "  3. Enable:  python3 tools/set_local_update_enabled.py on\n"
            "  4. Disable: python3 tools/set_local_update_enabled.py off\n"
            "  5. Rebuild: python3 tools/build_local_lua_update.py --version N.N.N --disable\n\n"
            "Update layout:\n"
            "  local_assets/res/       lazy exact-MD5 /res resources\n"
            "  local_assets/src_32/    sparse writable 32-bit Lua/data overrides\n"
            "  local_assets/src_64/    sparse writable 64-bit Lua/data overrides\n"
            "  local_assets/updates/   generated MID2 ZIP volumes\n"
            "  local_assets/update_manifest.json  MID2 advertisement control\n\n"
            "Resource versions MUST be exactly numeric N.N.N (for example 1.631.2).\n"
            "Update events are logged to runtime_logs/local_update_events.jsonl.\n"
            "This launcher intentionally exposes no gameplay/admin mutation switches."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )


def main() -> None:
    # argparse handles -h/--help and rejects unknown launcher options before the
    # heavier backend runtime modules are imported.
    build_parser().parse_args()
    from gxb_backend.run import main as run_backend

    run_backend()


if __name__ == "__main__":
    main()
