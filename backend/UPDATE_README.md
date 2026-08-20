# Update notes — v0.8.33 / Pass42.12

Adds the self-contained `gacha_control.py` operator utility, changes the shipped development featured mode to `startup_debug`, and adds an opt-in classic Small/Medium Item/Scroll/Girl + native-star balance overlay.

Existing classic math remains active when the overlay is disabled. Fixed Small/Medium x10 guarantees and the SX 25-purchase selected-hotspot guarantee remain unchanged. Recovered pool catalogs remain evidence and are not rewritten for balancing.

Run `python3 gacha_control.py --check` before/after operator edits. Any future critical gacha schema/topology change must update this tool in the same pass.
