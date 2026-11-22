#!/usr/bin/env python3
"""Host tests for the Backend.lua HTTP polling overlay generator."""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import apply_backend_http_poll as generator  # noqa: E402

STOCK = "local class = {}\nfunction class.get()\n\treturn class\nend\n\nreturn var_0_1\n"
OVERLAY = "local enabled = __GXB_HTTP_POLL__\n-- GXB_HTTP_POLL marker\n"


def expect_error(function, message):
    try:
        function()
    except ValueError as error:
        assert message in str(error), (message, error)
        return
    raise AssertionError(f"expected {message}")


def main():
    patched_http_poll = generator.build(STOCK, OVERLAY, True)
    assert "local enabled = true" in patched_http_poll
    assert patched_http_poll.endswith("\nreturn var_0_1\n"), repr(
        patched_http_poll[-30:]
    )
    assert patched_http_poll.index("local enabled") < patched_http_poll.rindex(
        "return var_0_1"
    )

    patched_tcp = generator.build(STOCK, OVERLAY, False)
    assert "local enabled = false" in patched_tcp
    assert patched_tcp != patched_http_poll

    expect_error(lambda: generator.build(patched_http_poll, OVERLAY, True), "already contains")
    expect_error(
        lambda: generator.build("return var_0_1\nreturn var_0_1\n", OVERLAY, True),
        "does not end",
    )
    expect_error(lambda: generator.build("local x\n", OVERLAY, True), "does not end")
    expect_error(lambda: generator.build(STOCK, "no placeholder\n", True), "mode placeholder")

    print("PASS apply_backend_http_poll: 6 assertions")


if __name__ == "__main__":
    main()
