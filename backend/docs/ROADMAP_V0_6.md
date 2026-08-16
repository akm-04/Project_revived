# Revised reconstruction roadmap after stable core milestone

Date: 2026-08-17

## Stable baseline

User-runtime-confirmed working together:

- Girls list and individual Hero detail.
- Skin and Affinity tabs.
- Skill upgrades and diamond skill-point purchases.
- Normal Campaign team selection and client-simulated battles.
- MID113 → client battle → MID114 progression loop.
- Campaign unlock persistence.
- Backpack persistence.
- Conservative source-derived first-clear rewards.
- Sweep/Raid Mini Juice rewards.
- EXP consumables and persisted Hero leveling.
- Guide-function completion persistence.
- Runtime lazy resource downloads through the reconstructed `/res/<basename>.<md5>` gateway.

This is the stable gameplay milestone future work must preserve.

## v0.6 resource/update work

### Runtime lazy CDN — achieved

Live-confirmed:

```text
CENTER res_download_url
→ local lazy metadata
→ AssetDownload
→ xyd.FileDownloader
→ backend /res gateway
→ exact-MD5 bytes
→ native callback
```

Do not add speculative resource fields to MID113.

### MID2 force/Lua update plane — source-mapped, safe runtime probe next

UpdateScene source confirms MID2 can advertise ZIP-volume update descriptors and install them into the writable update path before restart. Writable `src_32/src_64` then precedes packaged Lua.

v0.6.4 adds a harmless two-file `--probe-only` package, update event logging, and a provenance catalog for the recovered APK/writable Lua layers. The package is disabled by default; one controlled device run should confirm MID2 download, ZIP verification, unzip, and restart before any loaded gameplay Lua is overridden.

### v0.6.3/v0.6.4 compatibility fixes

Runtime evidence exposed malformed MID2784 album state and missing Social recall arrays. Both are corrected. MID2064 is recovery-idempotent after a client callback crash and is now user-confirmed through MID114. v0.6.4 additionally mirrors timed skill-point recovery so Hero skill batches use the same effective balance as the client.

## Next gameplay domains

1. **Formation canonicalization** — finish MID208/209 around shared team state, including source-shaped `params.list` and `partner_ids` behavior.
2. **Campaign completeness** — energy, normal/dropbox RNG, economy awards, sweep accounting, chapter completion rewards and pending-session validation.
3. **Hero progression** — POWERUP_HERO 51, EVOLVE_HERO 52, equipment, pieces, collection and summon integration. Awakening stays later inside this domain because valid testing requires specific source-valid Hero prerequisites.
4. **Vending / Summon / Shop** — share HeroRepository + Inventory + Economy.
5. **Activities** — implement source-specific activity types one at a time; no giant generic `details` response.
6. **Voyage and subdomains** — reconstruct Hunqi, Memories, Sandbag, Illusion and other fan-out systems separately before treating Voyage as one feature.
7. **Competitive / Arena — last.** Classic Arena, Peak, reports/replays and compressed result transports wait until generic Hero/Formation/Battle primitives are mature. Never invent the unresolved PEAK_FIGHT_RESULT numeric MID.

Payment remains permanently out of scope.

---

## Superseded at v0.7.0

The v0.6 resource-research milestone is complete enough to promote the project baseline.
Use `docs/ROADMAP_V0_7.md` for current ordering. Runtime lazy CDN delivery and MID2
package transport are now both user-confirmed; v0.7.0 corrects the numeric resource-version
constraint exposed by the first MID2 probe. Competitive/Arena remains last.
