# Backend machine memory — Pass154.0

Canonical implementation: `gxb-backend-v0.16.8-pass154.0`.

- Skins + Recharge Phase A-D remains functionally runtime accepted from Pass153.
- Pass154 changes presentation metadata only. OTA **1.631.10** is cumulative over 1.631.9 and preserves all 138 entries.
- Synthetic skin Recharge names are `<Girl> <stable per-Girl ordinal>`; canonical skin names/model/skill IDs remain unchanged in source catalogs.
- Synthetic elemental Recharge names are concise capability labels.
- Synthetic activation/authorization remains >=1.631.9; OTA 1.631.10 is only a display update.
- Product IDs, gift IDs, reward semantics, prices, Crystal/charge/VIP deltas, receipts, UoW, ROS, and ownership semantics are unchanged.
- 3 direct-Hero Packs, 15 missing-gift Packs, temporary-skin lifecycle, and MID1407 remain deferred/fail-closed as previously recorded.
- NEXT: Horcrux RNG research/cartography against effective src_64 for multiple passes as needed; only after sufficient evidence -> architecture/design -> bounded implementation -> tests/client reconciliation.
- Permanent rule: cross-check effective `src_64` before every backend behavioral modification and preserve epistemic classes.
