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
- 00066: I7C-5C 1 on 1: content catalog, one global competition root (lock rank 602), player state with slots/points/teams/promotion, matches with per-round Combat attempts, last-20 records, partner usage, Wednesday/Sunday settlements with server/global ranks and titles; Achievement streaks keyed by (player, achievement) for 100002/100028. Empty on upgrade.
- 00067: I7C-5D Arena: content catalog, one global competition root (lock rank 603), season player state (stars/points/streaks/defense/missions/exchange awards), matches with one Combat attempt, last-20 records, per-season partner usage, season settlements with ranks/champion; Achievement profile 100003. Empty on upgrade.
- 00073: I8-4 Combat attempt kinds: the five registered trust profiles, NOT_REQUIRED resolution, pinned duplicate-terminal replay spec, supersede chain, append-only START packages and attestations. Existing attempts become server-report attempts with the stored-report replay.
- 00074: I8-5D Conquer attempt retirement: removes the mode-local `attempt` from conquer_school_players.state; Conquer attempts live in Combat. Open I7C-5E attempts close without refund.
- 00075: I8-6C multi-participant attempts: append-only member roster (convener at seat 0, at most 8 seats) and per-member settlements keyed by (attempt, member). Existing attempts have no roster (single-member). Empty on upgrade.
- 00076: I8.5-3 client observability: stock ErrorLog/crash uploads (per-upload rows with attribution and quarantine, parsed client rows), per-session log capabilities (digest only), and the HTTP request journal (outcome, error class, redacted cause, masked raw envelope for unknown/undecodable requests). Retention by expires_at (7 days routine, 30 days error/anomaly). No foreign keys. Empty on upgrade.
- 00077: I8.5-6 F3 player ids above the stock robot range (D63): logical-server cursors move to server*100000+25001 and a check keeps them there, because stock reads a wire table_id <= 25000 as a robot team. Players already allocated below it keep their ids.
- 00078: I8.5-6 F1 level function announcement (D59): existing players get the eligibility and unlock rows the new announcer writes for every pure level gate they reached in the active content revision (capability NONE; Pet Function 38 keeps its starter-egg path). Empty on a fresh database.
