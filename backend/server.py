#!/usr/bin/env python3
"""Compatibility launcher for the modular GXB EOL backend.

No-argument behavior starts the backend.  Human-facing console output is
filtered by DEBUG_VERBOSE and automatically teed to the next unused runtime_logs/server*.txt transcript.
Structured JSONL evidence under runtime_logs is never filtered.
"""
from __future__ import annotations

import argparse
from pathlib import Path

# Operator default.  Edit this one value for persistent local preference.
# 1 = basic/gameplay + errors + missing assets/404
# 2 = level 1 + client window/resource-probe events
# 3 = level 2 + successful asset/update HTTP download traffic
# 4 = all console/debug/access output
DEBUG_VERBOSE = 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="server.py",
        description=(
            "Start the local Girls X Battle EOL backend. Console output is automatically "
            "written to the next unused runtime_logs/server*.txt; structured runtime logs remain separate."
        ),
        epilog=(
            "Debug verbosity:\n"
            "  1 basic/gameplay + errors + missing assets/404\n"
            "  2 + client window/resource-probe events\n"
            "  3 + successful /res and update download traffic\n"
            "  4 all output including raw Flask/Werkzeug access lines\n\n"
            "Writable update quick start:\n"
            "  python3 tools/set_local_update_enabled.py on|off\n"
            "  python3 tools/build_local_lua_update.py --version N.N.N --silent\n\n"
            "local_assets/res/ may be populated by the operator as an asset search root; "
            "the Pass212-style OTA builder packages only sparse src_32/src_64 overrides.\n"
            "This launcher exposes no gameplay/admin mutation switches."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--debug-verbose", type=int, choices=(1, 2, 3, 4), default=None,
        help="override server.py DEBUG_VERBOSE for this launch only",
    )
    return parser


def main() -> None:
    args = build_parser().parse_args()
    verbosity = args.debug_verbose if args.debug_verbose is not None else DEBUG_VERBOSE

    from gxb_backend.observability.console_runtime import configure_console
    configure_console(runtime_log_dir=Path(__file__).resolve().parent / "runtime_logs", verbosity=verbosity)

    from gxb_backend.run import main as run_backend
    run_backend()


if __name__ == "__main__":
    main()
