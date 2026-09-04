# v0.8.12 / Pass 35.1 — Update + Operator Hardening

Pass35.1 implements the maintenance scope approved by Pass35. It makes no intended gameplay-semantic changes.

## Operator/update changes

- Added root `UPDATE_README.md` with the complete MID20480/MID2 operator workflow and device revalidation checklist.
- Added `python3 server.py -h/--help` without changing ordinary no-argument startup.
- Corrected the obsolete non-numeric `1.631.0-local1` example. Resource versions remain strictly `N.N.N`.
- Staged the exact 62 recovered writable overrides from `downloaded-assets/output` into both `local_assets/src_32` and `src_64`.
- Built `1.631.2` as one MID2 ZIP volume with 124 entries, size 1,859,658 bytes, MD5 `b10010f6d63938327b7245abe04df851`.
- The distributed manifest is **enabled=false** and `silent=false`; the archive does not push an update until the operator explicitly enables it.

## Structural maintenance

### Read-only ProtocolRegistry

`data/protocol_registry.json` is generated from the canonical Pass34 MID atlas and contains 1,301 numeric records. It supplements `mid.lua` labels with raw/update-plane identities such as MID2 and MID20480 and GM-plane aliases. Engine/compatibility logs use the registry when available.

This metadata is observability-only. Numeric MID remains canonical and the registry is forbidden from deciding compatibility safety, response shape, mutation ownership, reward routing, or gameplay semantics.

### PlayerMaintenanceServices

Fresh/load-time normalization previously constructed Hero/Inventory/World/Summon repositories independently. Pass35.1 centralizes that non-request wiring in `PlayerMaintenanceServices`, sharing the same player/catalog/dependency conventions while deliberately providing no request UoW and no save callback. `MultiUserDatabase.normalize_player()` still owns whether/when the normalized player is persisted.

This specifically reduces constructor-drift risk without moving normalization business rules or changing defaults.

## Deliberately unchanged

- Pass33.1 Campaign100007 tutorial milestone and Function33 announcement.
- MID39 atomic Mana/Skill Point batch transaction.
- MID59 Lightin stone summon.
- Campaign/Mission reward semantics.
- Pass29 mutation-safe compatibility allow-list.
- MID90 Skill Point item response behavior remains unresolved and unchanged.
- No payment, PvP, or Guild implementation expansion.
