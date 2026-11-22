# RULING I9-12: "Have Fun!" (mission 116) credits the lender on placement

Date 2026-11-21. Lead ruling under the amend-on-evidence policy. Logged for user review.

Amends I9_GUILD_RENTAL_V1 C16 (and C3's "records Fact 116") and I9_PHASE_DECISIONS D413 ("Fact 116 on each paid borrow").

## Rule

- Placing a hero offer on the guild rental board (MID 594/619, `guildrental.Service.Place`) records one `HERO_LENT` fact (delta 1) for the lender. It is recorded in the same transaction as the offer insert, with business key = the offer key (lender:kind:unit:rent_time).
- Pets do not count ("Lend 1 battle girl").
- A paid borrow (battle START, `LendTx`) records no fact 116.
- The I9-9 `HERO_LENT` binding is live in the mission materializer.

## Evidence

- mission.lua 10018 "Have Fun!", desc "Lend 1 battle girl.", task_req 116, task_num 1 (1.631.0 :742-753; 1.164 :688-699).
- translation.lua:3016 LEND_HERO_ALERT "You will lend {} out, confirm?" is shown before RENT_HERO (ChooseHerosAlertWindow.lua:30-52, both clients).
- The user's real-client report (BUGS #131): placing a girl did not advance the task.
- The original server's exact counting action is UNKNOWN; the client text and the user report select lender-on-place.

Implementation: i9-12havefun 6c3a906e, merged into i9-12. Report: tmp/i912_research/HAVEFUN.md.
