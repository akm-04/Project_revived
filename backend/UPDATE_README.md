# Update notes — v0.19.4 / Pass190.0

- Backend-only P1-I4B Cabinet implementation; OTA remains 1.631.12.
- Full deterministic Cabinet research MIDs 1059/1060/1061/1078/1079 now use nested source-shaped book state, existing UoW settlement, finite-job/acceleration utilities and typed Hero projections.
- Workshop P1-I4 is now static/regression accepted; next gate is P1-I5 cumulative regression + stock-client smoke/reconciliation.
- Original cancellation refund math remains an explicit compatibility policy; no invented scheduler/RNG/parallel Workshop state was added.

# Update notes — v0.19.2 / Pass188.0

- Backend-only P1-I3 Course/Electives implementation; OTA remains 1.631.12.
- Full deterministic MID2128–2142/2500 Course lifecycle now uses canonical Hero/study state and existing UoW settlement.
- Original study progress remains explicit +20 compatibility policy; Course recommendations are safe-empty and Gift Box awards fail closed.
- Next implementation wave: P1-I4 Workshop.

# Update notes — v0.16.8 / Pass154.0

- Cumulative OTA bumped from 1.631.9 to **1.631.10** so clients receive display-name polish.
- 262 synthetic permanent-skin Recharge names shortened to `<Girl> <ordinal>`.
- 10 synthetic elemental Recharge names shortened to compact capability-preserving labels.
- No settlement/economy/RNG/ownership behavior changed.
- No runtime smoke required for this presentation-only pass; Pass153 runtime acceptance remains authoritative.
- Next: Horcrux RNG source research/cartography.

## Pass224 clean-control reset
Pass224 intentionally returns the client OTA surface to the Pass212 cumulative baseline plus only `TaskAwakeCell.lua` and `NormalHero.lua` reconciliations. Previous sparse OTAs may have left writable window/resource overrides; omission does not delete them. Before Pass224 client smoke run:

```bash
adb shell pm clear com.carolgames.gxb
```

Then relaunch the prepared APK and let MID2 install resource version `1.631.19`. This resets client-local writable update state; backend player state is server-side.
