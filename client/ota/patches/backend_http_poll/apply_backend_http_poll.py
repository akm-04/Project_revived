#!/usr/bin/env python3
"""Insert the HTTP polling socket factory into stock Backend.lua."""

import argparse
import pathlib
import re
import sys

OVERLAY_PATH = pathlib.Path(__file__).resolve().parent / "backend_http_poll_overlay.lua"
MODE_PLACEHOLDER = "__GXB_HTTP_POLL__"
ANCHOR = re.compile(r"(?P<leading>\r?\n)return var_0_1(?P<trailing>\s*)\Z")


def build(stock: str, overlay: str, http_poll: bool) -> str:
    if MODE_PLACEHOLDER not in overlay:
        raise ValueError("overlay is missing the mode placeholder")
    if "GXB_HTTP_POLL" in stock:
        raise ValueError("stock input already contains the overlay")
    if len(re.findall(r"^return var_0_1\s*$", stock, re.MULTILINE)) != 1:
        raise ValueError("stock input does not end with a single `return var_0_1`")
    anchor = ANCHOR.search(stock)
    if anchor is None:
        raise ValueError("stock input does not end with a single `return var_0_1`")
    patched = overlay.replace(MODE_PLACEHOLDER, "true" if http_poll else "false")
    return (
        stock[: anchor.start()]
        + anchor.group("leading")
        + patched.rstrip("\n")
        + "\n\nreturn var_0_1"
        + anchor.group("trailing")
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stock", required=True, type=pathlib.Path)
    parser.add_argument("--output", required=True, type=pathlib.Path)
    parser.add_argument("--overlay", type=pathlib.Path, default=OVERLAY_PATH)
    parser.add_argument("--mode", choices=("http-poll", "tcp"), default="tcp")
    arguments = parser.parse_args()

    stock = arguments.stock.read_text(encoding="utf-8")
    overlay = arguments.overlay.read_text(encoding="utf-8")
    try:
        patched = build(stock, overlay, arguments.mode == "http-poll")
    except ValueError as error:
        print(f"apply_backend_http_poll: {error}", file=sys.stderr)
        return 1
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(patched, encoding="utf-8")
    print(f"apply_backend_http_poll: wrote {arguments.output} mode={arguments.mode}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
