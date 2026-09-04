# v0.8.0 — Multi-user identity foundation

## Evidence basis

Implementation is derived from cumulative Pass 22:

- Pass 20 Lua account→region→MID1 lifecycle;
- Pass 21 Android/Smali Xinyd registration/login/session protocol;
- Pass 22 canonical player/storage/PvP ownership synthesis;
- live registration trace confirming MID65282 followed by MID65281 and demonstrating that v0.7.0 collapsed all credentials onto UID 13371337 / Moppleton.

## Implemented boundary

This release implements only the identity/storage spine needed by every later multi-player domain:

```text
SDK credential account
  → persistent UID
  → persistent session SID/TOKEN
  → account-scoped MID18 character directory
  → atomic MID1 account+region character resolution/creation
  → request-scoped canonical player repositories
```

It does not implement Arena matchmaking/scoring/rank mutation yet.

## Source-confirmed vs local policy

### Source/live-confirmed

- MID65282 registration request fields and required `uid` + `login_email` success fields.
- Registration transitions into MID65281 credential login.
- MID65281 requires `uid` and login-session cookies.
- Java ultimately gives Lua SID and TOKEN.
- MID18 consumes account session and returns `regions`, `players`, `recall_regions`.
- No Lua CREATE_PLAYER occurs between MID18 and MID1.
- MID1 is the strongest character resolve/create boundary.
- `is_new=1` enters opening story.
- empty player name is valid before MID23 tutorial naming.
- `player_id` is the cross-domain durable game identity and conventionally encodes region in high digits.

### Local compatibility policy

- PBKDF2-SHA256 password verifier format/iteration count.
- UID counter starting range.
- exact nonzero SDK error code for duplicate/wrong-password cases.
- no session expiry/revocation policy yet.
- fresh credential player's exact starting currencies (kept conservative at zero where source has not proved values).
- local region capacity sentinel.

These must not be presented as recovered official-server values.

## Migration rule

`data/player_db.json` is imported only when the v0.8 multi-user store has no sandbox player mapping. After that, `data/server_state` is canonical.

This avoids rewriting the proven anonymous sandbox while allowing credential users to have independent progress.

## Request isolation rule

Authenticated engine requests resolve self from session/token plus region before a gameplay handler runs. Existing domain repositories therefore mutate the selected canonical player without accepting arbitrary `player_id` ownership from the request.

Cross-player public projection remains a separate later slice. It must never return another player's private economy/tutorial/session state.

## PvP readiness consequence

Arena/Top/Region Arena can later build on:

- stable player IDs;
- per-player Hero/formation state;
- account-independent public player projections;
- ranking indexes that reference player IDs;
- immutable historical report snapshots.

No further identity rewrite should be necessary for those systems.
