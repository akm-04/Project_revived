# GXB backend v0.8.0 — Multi-user Identity Foundation

Private/local EOL restoration backend for Girls X Battle 1.631.0.

This release is the first backend rewrite based on Pass 22's combined Lua + Android/Smali server map. It preserves the user-confirmed v0.7.0 gameplay/resource baseline while replacing the process-wide singleton identity with request-scoped SDK accounts, sessions, region characters, and per-player persistence.

Payment remains permanently out of scope.

## What v0.8.0 changes

### Real credential accounts

The source/live-confirmed Xinyd flow is now implemented:

```text
Register UI
  → SDK MID65282 register_platform
  → response requires uid + login_email
  → SDK automatically sends MID65281 platform_user_login
  → backend verifies password and issues SID/TOKEN + QQW* cookies
  → Java hands SID/TOKEN to Lua
```

Credential records are persistent and passwords are stored as salted PBKDF2-SHA256 verifiers, not plaintext.

Exact historical duplicate-account/wrong-password Xinyd error numbers were not recovered. v0.8.0 therefore uses a documented local compatibility nonzero error code with `error_msg` for those failures.

### Anonymous sandbox is preserved

MID65284 still resolves the existing fixed development identity:

```text
uid   = 13371337
sid   = 1993b58bfd1b93499ae19477b236d4a2
token = local_token
```

On the first v0.8.0 launch, the existing `data/player_db.json` is imported as that sandbox player's canonical state. This preserves the already-confirmed Moppleton/Girls/Campaign/Backpack/resource baseline and the intentionally large sandbox mana/crystal values.

### MID18 is account-scoped

`LOAD_USER_REGIONS` now returns:

- one shared region catalog;
- only the characters owned by the authenticated SDK account;
- empty `recall_regions` compatibility state.

A credential account with no character in any region receives `players=[]`, which matches the Lua new-account path.

### MID1 resolves or creates `(account, region) → player_id`

For credential accounts:

```text
MID1 RETRIEVE_TOKEN(region)
  → authenticate SID/TOKEN
  → find player_by_account_region[uid][region]
  → if present: load it, is_new=0
  → if absent: allocate player_id, create fresh state, is_new=1
```

Player IDs are allocated with the region encoded in the high digits (for example region 197 starts at `19700001`), matching the client-wide `player_id / 100000` region convention.

Creation is retry-safe: another MID1 for the same account+region resolves the already-created player instead of minting a duplicate.

### Fresh credential-player template

Pass 22 source proves:

- level-1/new-player lifecycle;
- empty/unset name is valid;
- `is_new=1` enters the opening story;
- StoryScene later opens EditNameScene;
- MID23 sets the chosen name.

It does **not** prove every original starting currency. Therefore v0.8.0 deliberately creates credential players with a conservative local fresh template:

- level 1;
- VIP 0;
- empty name;
- tutorial/guide state at the beginning;
- empty owned Hero/Inventory/Pet state;
- zero mana/crystal and nonessential currencies;
- normal base energy/timer containers.

Those numeric fresh-economy defaults are compatibility policy, not claimed official values. The anonymous sandbox is unchanged.

## Canonical storage layout

After first launch:

```text
data/server_state/
├── accounts/
│   └── <sdk_uid>.json
├── sessions/
│   └── <sid>.json
├── players/
│   └── <player_id>/
│       └── player.json
└── indexes/
    ├── account_by_login.json
    ├── player_by_account_region.json
    ├── session_by_token.json
    ├── region_player_serial.json
    └── counters.json
```

Ownership rules:

```text
SDK uid
  → session SID/TOKEN
  → account+region player mapping
  → stable game player_id
  → canonical gameplay state
```

Game progress is never keyed by `device_id`, SID, or TOKEN.

`data/player_db.json` remains in the package only as the **one-time v0.7 anonymous-sandbox migration source**. After `data/server_state/` has been created, edit/copy the canonical player files there instead.

## Existing gameplay compatibility

Existing Hero, Inventory, Campaign, Skill, Story, Activity, etc. handlers still call the same repository interface. The difference is that `get_player()` is now request-scoped to the authenticated account-region character.

Therefore a mutation such as:

```text
MID39 skill upgrade
MID55/63 EXP juice
MID113/114 Campaign
MID81 Backpack
```

persists into the active player's own `players/<player_id>/player.json` rather than one global `player_db.json`.

Cross-player PvP/public projections are intentionally **not** implemented in this release. Pass 22 already maps their architecture; this slice establishes the identity/storage spine they require.

## First migration/test procedure

Before the first v0.8.0 launch:

1. Copy your latest v0.7.0 `data/player_db.json` into this backend.
2. Preserve/copy your large `local_assets/res` tree as before.
3. If you use Lua hot updates, preserve `local_assets/src_32`, `src_64`, `updates`, and `update_manifest.json` as appropriate.
4. Start `python3 server.py`.

The first startup should print a line similar to:

```text
[MULTIUSER] importing singleton sandbox from .../data/player_db.json
```

It then creates `data/server_state/`.

### Credential account test

Use source-valid registration syntax:

```text
Account:  testuser01
Password: pass1234
```

Expected server sequence:

```text
MID65282
[SDK AUTH] register created ... uid=<new uid>
MID65281
[SDK AUTH] login success ... uid=<same uid> sid=<new sid> token=<new token>
MID18
[REGIONS] ... owned_players=0
MID1 region=197
[MULTIUSER] created player uid=<uid> region=197 player_id=19700001 name=''
[IDENTITY] ...
```

The client should enter its new-player opening flow because MID1 returns `is_new=1`.

### Two-user isolation test

Register a second account, e.g.:

```text
Account:  testuser02
Password: pass5678
```

Expected:

- different SDK UID;
- different SID/TOKEN;
- different region-197 `player_id`;
- MID18 for account B does not list account A's player;
- progress made by A remains in A's player JSON only.

Useful inspection command:

```bash
python3 tools/list_multiuser_state.py
```

It intentionally redacts tokens and never prints password verifiers.

## Offline self-test

The repository/state isolation logic can be tested without Flask/network/device runtime:

```bash
python3 tools/selftest_multiuser.py
```

It creates two temporary accounts and players, mutates only account A, checks retry-safe MID1 resolution and account-scoped MID18 ownership, and confirms the anonymous sandbox retains the established currency profile. It does not touch the real `data/server_state` tree.

## Resource/update baseline retained

v0.8.0 preserves the v0.7.0 live-confirmed content planes:

```text
runtime lazy assets:
  AssetDownload → FileDownloader → /res/<basename>.<md5>

Lua/data startup updates:
  MID2 → update ZIP volumes → MD5 → unzip → writable src_32/src_64 → restart
```

Client resource versions must remain numeric `N.N.N` values such as `1.631.1`.

## Validation policy

Assistant-side validation for this package is limited to Python syntax checks and offline repository/state tests. No Flask/HTTP/APK/ADB/emulator/gameplay runtime test is claimed.
