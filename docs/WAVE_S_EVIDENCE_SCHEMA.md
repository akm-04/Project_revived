# Wave-S evidence schema (R3C)

Detailed evidence is opt-in with `GXB_WAVE_S_EVIDENCE_DIR` and a path-safe `GXB_WAVE_S_RUN_ID`. API and realtime processes generate independent opaque process IDs and write `<run>-api.jsonl` / `<run>-realtime.jsonl`; an eventual client harness may write `<run>-client.jsonl` using the same schema.

Every detailed record identifies `run_id`, `process_role`, `process_id`, event `kind`, evidence `phase` and UTC time. Post-login records may carry opaque `session_tag`, `context_tag` and `connection_tag`. Session/context tags are per-run SHA-256-derived correlation values; they are not canonical IDs or credentials.

Evidence phases are deliberately non-interchangeable:

- `SERVER_INTENT`: response composition intent, e.g. an embedded MID1 record.
- `TRANSPORT_WRITE_RECORDED`: bytes were handed to the server transport write path, e.g. room-entry acknowledgement. This is not client delivery or consumption evidence.
- `SERVER_WRITE`: legacy pre-R6 evidence label accepted only for historical decode/manifest compatibility; new captures do not emit it.
- `CLIENT_REQUEST_OBSERVED`: server observed a client request.
- `CLIENT_OBSERVED` / `CLIENT_CONSUMED`: reserved for the independent client observer/harness.
- `CAPTURE_HEALTH`: capture lifecycle/health.
- `CLIENT_STATE`: connection/client lifecycle.

Server manifest health and client acceptance are separate verdicts. A server-only capture can be server-green while acceptance remains non-green. Quiescence is valid only with healthy capture and correlated live WORLD/SERVICE client state throughout the interval.

Default capture limits: 100,000 total events and a 2,048-event in-memory ring. Both may be reduced/configured within hard bounds. Capture overflow/failure poisons evidence health instead of silently dropping proof.
