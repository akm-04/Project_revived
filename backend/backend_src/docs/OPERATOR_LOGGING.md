# Operator logging

`python3 server.py` now automatically writes its filtered console transcript to
`runtime_logs/server.txt`. The file is reset on each launch so it can be zipped
directly after a smoke test.

The persistent default is the `DEBUG_VERBOSE` integer near the top of
`server.py`; `--debug-verbose 1..4` overrides it for one launch.

- `1`: basic/gameplay output, errors, missing assets, and HTTP 404s.
- `2`: level 1 plus packaged client window/resource-probe events.
- `3`: level 2 plus successful `/res` and update download traffic.
- `4`: all output, including raw Flask/Werkzeug access lines.

This is only a human-facing console filter. Structured evidence such as
`all_requests.jsonl`, `resource_requests.jsonl`, `resource_client_probe.jsonl`,
and `client_error_logs.jsonl` is always written independently and is never
suppressed by `DEBUG_VERBOSE`.

Future modules should use
`gxb_backend.observability.console_runtime.console_emit(category, message)` with
one of the named categories (`basic`, `error`, `missing`, `window`,
`http_download`, `full`) instead of inventing new print-string filters.
