# Roadmap from v0.7 stable baseline

## Stable baseline to preserve

- Girls/Hero detail including Skin/Affinity.
- Campaign local battle loop and durable progression.
- Campaign 200002 story partner claim.
- Backpack + Sweep/EXP consumables.
- Timed skill-point parity.
- Runtime `/res/` lazy asset CDN reconstruction.
- MID2 update package transport, with v0.7 numeric-version safety.
- Asset-gated menus now loading on demand; deeper domain logic remains separate work.

## Ordered implementation plan

1. **Formation state** — source-shape MID208/MID209 and shared team state.
2. **Campaign completeness** — pending fight validation, energy/economy, source RNG/rewards.
3. **Hero progression** — power-up/evolve/equipment/pieces/collection; awakening only with valid prerequisites.
4. **Vending/Summon/Shop** — reuse canonical Hero/Inventory/Economy state.
5. **Institute-family domains as exercised** — Institute, Emblem, Vows, Alchemy, Workshop calls should be traced individually now that their UI/assets load.
6. **Activities** — individual activity contracts, not a generic mega-response.
7. **Voyage/subdomains** — separate Hunqi/Memories/Sandbag/Illusion etc.
8. **Competitive/Arena last** — compressed result transports, opponent snapshots, reports/replays and source gaps make it the highest-risk domain.

Payment remains out of scope.
