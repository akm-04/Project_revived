Contract-Id: I9_11_GIRLS_LOG_V1

# Girls Log design (A-124, A-125)

Lead design 2026-11-18 for REALITY_CHECK_I9-11.md R3. Contract owner: I9_LIBRARY_V1 (librarylocal). Sol T30 findings
A-124 and A-125 (work/audit/proposals/). Both LOW; both close inside I9-11 unless a logged ruling moves G2's build.

## G1. Live partner-log projection (A-125), build now

Client evidence: SelfPlayer.lua:3216-3217 handles PLAYER_NOTICE notice_type 24 (`xyd.NoticeType.LIBRARY_PARTNER_LOG`,
enums.lua:2080) with params `{partner_id, log_info}` and calls Library:freshPartnerLog (Library.lua:705-710), which
replaces the cached `partner_logs` of an already-loaded partner and refreshes an open detail window. A partner the client
has not loaded is ignored by the client, so a push is always safe.

1. One writer. Every Girls Log row goes through one librarylocal application method (the shared journal path; today
   librarystore RecordHeroLogTx/InsertHeroLogTx are called from characterhero and librarylocal). That method inserts the
   row (unchanged ON CONFLICT semantics) and, only when a row was actually inserted, emits a realtime wakeup in the same
   transaction: route `library.partner_log.v1`, ref `<player>:<partner_id>`, through `pg.EmitRealtimeWakeup` as
   adventure and guild campaign do. No callers write log rows directly afterwards; archguard or a source test pins that.
2. Delivery. A registered wakeup handler reads the partner's full log map with the same projection MID 836 uses
   (one function, not a copy) and pushes notice 24 `{partner_id, log_info}` to that player's sessions only.
3. Optional display (D1): a wakeup or push failure never fails the producing transaction and never retries the producer.
   A fresh 836 or login stays the recovery path. A duplicate wakeup re-sends the same full map, which the client
   replaces idempotently, so no delivery table is needed.
4. Replay: a receipt replay inserts nothing, so it emits nothing.
5. Proofs: natives through the production dispatcher with 836 loaded: promotion (20001), star, awakening, favor, dialog,
   marriage and acquisition each push exactly one notice 24 for the right partner with the full map; a receipt replay
   pushes none; another player's session receives none. A unit test of the projection shared with 836.

## G2. Battle milestones 60001-60004 (A-124), research then build

Client evidence: library_hero_log.lua rows 36-39 (log_type 6): 60001/60002/60003/60004 at 1/50/100/1000, text
"完成N次战斗" ("complete N battles"): completion, not victory.

Design:
1. Durable per-hero count: new table `library_hero_battle_counts(player_id FK, partner_id, count, payload_version)`
   in the next free migration number (lead assigns at dispatch; 00178 is the I9-11 spare). Rank: the Library rank
   already used by the journal (stop-and-report if none exists).
2. Producer: one typed librarylocal port `ObserveBattleTx(c, t, player, partnerIDs, at)` called by each eligible mode's
   settlement transaction, only on the first settlement (never on a receipt replay, never from a read), with the
   player's own owned heroes that fought. It increments each count and writes the crossed log ids through the G1
   writer, so the notice follows for free.
3. Old saves: counts start at 0 at deploy; no invented history (Sol's note).

Policy (for user review, P-GL1, recommended): a hero's count rises by one for each battle that reaches a server-settled
result, win or loss, in which that owned hero fought on the player's side, in every combat mode the server settles.
Excluded: robots, borrowed or enemy heroes, attempts abandoned without a result, battle replays and report views.

Research task first (read-only): list every mode with a server-settled battle result, its settlement function file:line,
where the player's own fighting heroes are known there, and whether it settles once per attempt. The build waits for
that list and the P-GL1 answer.

## G2 approved rulings (user 2026-11-19, RQ1-RQ4; supersede the "for user review" wording above)

- P-GL1 APPROVED: a hero's count rises by one for each battle that reaches a first server-settled result, win or
  loss, in which that owned hero fought on the player's side. Excluded: robots, rentals/borrowed, assist and enemy
  heroes, attempts abandoned without a result, receipt replays, report views and reads.
- RQ1: practice settlements (pet campaign PracticeNoValue) do not count.
- RQ2: modes with no own-hero roster at settlement (dodgeball, mentor exam, character practice) do not count; never
  invent a roster.
- RQ3: awakening battle settles wins only, so it counts only wins; this is the mode, not a counting rule.
- RQ4: G2 is built inside I9-11. The eligible modes and hook points are those of
  tmp/reality_11r/g2-research-REPORT.md (28 rows less the RQ1/RQ2 exclusions).
- Shared settlements (top floor, 1 on 1, arena, champions league, tournament, adventure co-op, illusion team, occult
  team) attribute each settled player only their own heroes (origin OwnedSelf/OwnedMember and player equal to the
  settled player); team modes use the roster frozen at START.
- Storage: table library_hero_battle_counts (player_id, partner_id, count, payload_version per R8) in migration 00179 (renumbered at the G2a merge, bb574d92; 00180 is the A-134 drop);
  counts start at 0 at deploy (no invented history). The counter row lock is taken last in the settlement
  transaction. Crossing 1/50/100/1000 writes log ids 60001-60004 through the G1 single writer, so notice 24 follows.
