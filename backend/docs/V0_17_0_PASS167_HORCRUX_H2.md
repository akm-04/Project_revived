# v0.17.0 / Pass167 — Horcrux H2 deterministic lifecycle

Pass167 activates only deterministic Horcrux instance lifecycle operations: lock/unlock, direct equip/unequip, one-key unequip, and saved collocation CRUD/apply. Generated acquisition, strengthening, and Gods Trial settlement remain disabled for H3–H5.

The source feedback loop corrected `is_equip` to the stock-client contract: `0` means unequipped and a positive value is the owning `partner_id`. Hero `spirit_equip` remains the positional authority; `is_equip` is reconciled from it. Saved collocations remain authoritative for membership and `collo_count` is rebuilt from saved references.

Pass167 also separates immutable recovered source evidence from writable OTA overrides. `source_evidence/src_64` contains byte-identical source inputs used by catalog/source-contract tests; `local_assets/src_32` and `local_assets/src_64` now contain only cumulative hot-update overrides. The 138 inherited override bytes were rehydrated from the sealed Pass166 OTA archive before HOTA-002 was layered on top.

OTA 1.631.11 contains exactly 140 entries: the 138 Pass166 cumulative overrides plus `HunqiCombEditorWindow.lua` for both architectures. HOTA-002 fixes the client's edit path by decrementing old collocation membership before incrementing the replacement references.
