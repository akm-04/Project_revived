# Pass459 R3B Realtime Resource Hardening

R3B repairs RF-009 locally without changing stock heartbeat wire behavior. It adds explicit configurable process admission limits, a single absolute pre-auth handshake deadline, independent authority-query timeouts, client-idle retirement independent of DB liveness, a minimal post-auth dispatcher seam, and one bounded single-writer loop per connection. Process-local newest-admission semantics remain; EX-05 multi-process ownership is still open.

Normal-chat proof uses net.Pipe/unit/race testing. Exact tagged PostgreSQL runtime build and real socket/fd/load/query-timeout behavior remain R7 live gates.
