Goose expand/contract migrations begin in I1. PostgreSQL is the only V2 gameplay database.

Production migrations are forward-only; rollback is restore/redeploy, not destructive DOWN SQL.
Every canonical SQL migration must begin with the literal `-- +goose Up` directive so the pinned Goose runner parses the file; `-- +goose Down` sections are forbidden.

- 00001: I1 kernel semantic receipts.
- 00002: I3 identity/session/logical-server/player-root/gameplay-context foundation.
- 00003: Pass438 source-reality repair adding stock-visible account_uid. It fails closed if legacy V2 account rows exist because UUID->stock UID invention is forbidden.
- 00004: Pass438 I4 bootstrap-owned seed for the future Player-Core directory projection required by stock MID18. It fails closed if preexisting player roots lack evidence-backed profile state; I5 owns later profile mutation.
- 00005: I5 Player Core / TypedEconomy / Mail / Objective / Redeem canonical tables.
- 00006: I5 transactional policy/definition registries.
- 00007: R2A identity lifecycle relational-consistency constraints and composite parent keys; no new product/session policy.
- 00008: R2C per-player TypedEconomy owner/root creation fence. Contains no starter economy value or temporal policy state; RF-015 remains open.
- 00009: R4B immutable content revision/activation storage, receipt operation-policy evidence, and nullable legacy content-revision references. Expand-compatible with Pass468; R4C/D own runtime behavior.

- 00010: R4 manifest identity NOT NULL hardening.
- 00011: R5 foundation repairs.
- 00012: I6C canonical Guild/GuildMembership authority and Guild workflow ledgers.
- 00013: F2/I6C data-cleanup-only replay repair removing obsolete Guild applications for players who already have canonical membership.
- 00064: I7C-5A Combat foundation: locator roots (lock rank 609), append-only snapshots/resolutions/report blobs and the Pass418 attempt envelope. Empty on upgrade.
- 00065: I7C-5B Top Floor: content catalog, per-server ladder root (lock rank 601), ranks, player state, fights, last-10 records, partner usage, daily settlements and the Achievement 100001 streak table. Empty on upgrade.
