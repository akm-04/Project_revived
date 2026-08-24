# Pass141 — Phase 4 Client Test Plan

Status: **QA PREPARATION COMPLETE / RUNTIME ACCEPTANCE PENDING**

This plan tests the already-implemented Phase1–3 RNG/Gift Opening backbone. It does not activate `gift.equip`, generated Hero/Horcrux outputs, or Pet lifecycle systems.

## Test-account preparation

Sandbox UID `13371337` receives a one-shot, non-replenishing Pass141 QA seed:

- all **100** Phase3 ordinary-random MID241 source package items, target quantity 20 each, source-stack bounded;
- `50001172` Orange Gear Pack ×20;
- `50001173` Purple Gear Pack ×20;
- `50005206` Optional Gift Box ×20.

These 100 random source packages cover **96 unique dropbox pool IDs / 134 ordered draw occurrences**. Dropbox IDs themselves are server/source pool identifiers, not Backpack item IDs; the QA seed therefore grants the owning package items.

## A. Magic Vending Machine — MID70

Frontend identification from effective `src_64`:

**Summon/Vending Machine screen → fourth machine → Magic Vending Machine** (`SummonWindow.machine4`, MAGIC state).

Visible buttons: **Switch / Buy 1 / Buy 10**. The rule copy calls the purchase **Magic Juice**. Activity1175 exposes the same UI.

1. Enter the Magic Vending Machine.
2. Use **Switch** and select a girl you already own.
3. Record current Crystal and the selected girl's scroll/fragment quantity if visible.
4. Press **Buy 1** once.
   - Expected Crystal delta: `-500`.
   - Expected source-shaped result: 5 selected-girl scrolls plus the unchanged random byproduct policy.
   - Buy 1 must not use the 10-pull crit mechanic.
5. Record the result screen and inventory/economy changes.
6. Press **Buy 10** once.
   - Expected Crystal delta: `-5000`.
   - Expected: unchanged Magic policy, including the existing Buy-10 crit draw plus per-purchase byproduct draws.
   - Backend topology is 11 `summon.magic` draws for one Buy-10 request; the client need not display this count directly. Server log evidence is authoritative for topology if instrumented/visible.
7. Confirm no MID71 switch operation itself produces random rewards or consumes purchase cost.

## B. Deterministic/elective MID241

### Orange Gear Pack — `50001172`
Open one pack, deliberately choose a non-first orange gear. Confirm exactly that selected gear is awarded and source pack decrements once.

### Purple Gear Pack — `50001173`
Open one pack, deliberately choose a non-first purple gear. Confirm exactly that selected gear is awarded and source pack decrements once.

### Optional Gift Box — `50005206`
Open one pack and choose one of its three options. Confirm the selected gift is awarded. These routes are deterministic/elective and must consume no gameplay entropy.

## C. Ordinary random MID241

The account contains all 100 supported random source packages. Full mapping: `docs/PASS141_MID241_RANDOM_QA_MAP.json`.

Priority probes:

1. **Random Application** `50001407` — gift `90061001`, pool `600001`, positive total 1200. Proves denominator is not assumed to be 10000.
2. **Random Scrolls** `50001566` — gift `90001818`, pool `720001`, positive total 310. Second non-10000 pool.
3. **Daily Magazine** `50001418` — gift `90060006`, pool `600003` repeated 5 times. Open one; expect five draw-settlements. Then batch multiple copies if the UI exposes quantity.
4. **Special Magazine** `50001419` — gift `90060007`, pool `600004` repeated 5 times. Same repeated-pool test with zero-weight candidates present in source.
5. **Freshmen Pet Pack** `50001097` — gift `90001256`, ordered pools `430001 + 430002×5`. Tests mixed/repeated pool ordering.

### Pet scope warning
Pet-named packs are being tested only as MID241 package-open operations: source package debit + random ordinary stack awards. A successful Gift Opening test does **not** mean Pet summon, Pet ownership, Pet equipment, or Pet progression is complete.

## D. Broad random-box sweep

After priority probes, sample as many of the remaining seeded random packages as practical. The goal is not statistical proof of distribution; it is to detect client crashes, malformed award projection, missing source debit, unsupported output types, or transactional defects.

For any failure, record:

- source package name + item ID;
- quantity opened;
- visible award(s);
- whether the package decremented;
- client error/crash text;
- corresponding `server.txt` lines.

## E. Explicitly do not test as success criteria

- the 199 `gift.equip` hero-specific gear packs — still fail-closed and deferred to Girls/Equipment Economy Closure;
- generated Hero/entity random gift outputs;
- generated HUNQI/Horcrux unique-instance outputs;
- missing-source cases;
- three temporal `spirit_energy` source gaps;
- Pet lifecycle functionality beyond ordinary MID241 stack settlement.

## Evidence bundle to return

Please return a `debug.zip` containing at minimum complete `server.txt`, any client error/crash logs, and a short note of which item IDs/actions were attempted. Screenshots are useful but not mandatory.

## Runtime acceptance gate

Phase4 closes only after logs show Magic + deterministic/elective MID241 + ordinary random MID241 are client-usable, or after any demonstrated defects are reconciled and retested.
