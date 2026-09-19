# I3 Identity / Session / Logical Server / Character Bootstrap Contract

- Provider principal, account, session, SID/login token, gameplay context, gameplay bearer, server and player IDs are distinct typed concepts.
- Production account authentication requires the SID+login_token pair; generic gameplay token/region injection is ignored for MID18/MID1 account authority.
- Multiple account sessions are allowed by preservation default; one live gameplay context per session.
- Same-target MID1 coalesces to the same live context and rederived bearer; target change is planned only after target admission/bootstrap can succeed.
- Logical servers are semantic rows independent of process topology. Initial honest catalog is Server 1 and Server 2 only.
- Player IDs preserve `floor(player_id/100000)==region`, allocating serials 1..99999 from the locked server cursor; no PostgreSQL sequence is canonical.
- New-character MID1 requires same-session MID18 observation; existing owners may direct-MID1 from cached selection without a fresh MID18.
- Server-full/closed-to-new is stock 20018 business admission and never session-takeover policy.
- `first_entry_pending` makes lost-response/repeated MID1 replay `is_new=1` until source-grounded onboarding progression later clears it.
- Required bootstrap contributors execute atomically with player root/context under the I1 transaction kernel; no outbound network side effect is allowed.
- This normal-chat milestone proves pure models/schema/static invariants only. Real PostgreSQL locking/constraint/concurrency behavior remains W1 after I4.
