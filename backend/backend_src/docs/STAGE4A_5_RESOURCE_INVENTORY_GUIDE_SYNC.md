# Stage 4A.5 — Resource / Inventory / Guide Sync

See root `README.md` and root `memory.md` for the operational handoff.

This stage adds:

- recursive directory-only discovery of multiple nested `res` roots;
- MID113-side Campaign asset dependency auditing for stalls that occur before
  FileDownloader issues HTTP;
- canonical `InventoryRepository` / MID81 Backpack state;
- conservative guaranteed first-clear `init_dropbox` Campaign item commits;
- schema-4 string-keyed `guide_function_ids` persistence and legacy migration.

It does not add arbitrary dummy-resource substitution, regular/lower-rate
Campaign RNG, Campaign energy/economy accounting, Sweep rewards, or workplace
semantics.
