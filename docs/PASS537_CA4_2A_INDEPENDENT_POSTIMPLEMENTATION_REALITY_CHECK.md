# Pass537 CA4-2A Independent Postimplementation Reality Check

## Verdict

**GREEN LOCAL CA4-2A STAGE ACCEPTANCE; EXACT/NATIVE AGGREGATE PROOF REMAINS DEFERRED.** The produced CA4-2A implementation matches the sealed Pass536 research contract and the explicitly authorized CA4-2A design slice. This verdict is limited to the content/persistence/raw-state foundation. It does not authorize or claim CA4-2B/C/D gameplay implementation, MID54/MID62 production activation, exact Go 1.27.1 execution, PostgreSQL/River proof, or W2 stock-client proof.

## Independence

A separate postimplementation checker was built outside the backend tree and bound to the exact Pass535 parent, sealed Pass536 contract/design inputs, authoritative source archive, and final CA4-2A tree. The final independent run is **62/62 GREEN**. No external reviewer participated; this is an independent reread/check by the same assistant rather than a claim of third-party review.

## Identity and immutable-source reality

- Parent backend SHA-256: `8259dd97a0424cd15f82502845d9a3d6e1ee41081e5747baa7c20d86c0a575cd`.
- Parent implementation revision: `3aa3d533ebe9aa84ca61c8d8f958841a6f9c76d465dba30611490a75beb9827c`.
- Sealed Pass536 authority SHA-256: `a9d32e203c9ac78f96831b2884b4f1c65379c8932c90045d93b1959da35b274d`.
- Exact current source archive SHA-256: `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.
- Generated CA4-2A content revision: `bd11a7482062dbaa851f3b495e3dc6efab88085011b3fe75d82105e127bba106`.
- Canonical `.go-version`, `go.mod`, and `go.sum` remain byte-identical to the Pass535 parent.

The independent source oracle directly reparses current `partner.lua`/`item.lua` rather than trusting the content compiler. It reproduces **555 rows × 16 colors × 6 slots = 53,280 positions**: 50,504 ordinary nonzero mappings, 1,646 special mappings, and 1,130 deliberate zero mappings, with 214 unique ordinary and 164 unique special item IDs. Generated `hero_equipment_catalog.json` exactly matches that direct parse. Every nonzero mapped item remains inside the existing CA4-1 equipment primitive root set.

## Ownership and persistence reality

`gxb_content_hero_equipment` is Content Registry-owned immutable content. Mutable equipment state remains Character/Hero-owned as six durable nonnegative integer values. No universal Equipment aggregate, equipment-instance table, synthetic durable item identity, or historical per-color equipment ledger was introduced.

The database deliberately does **not** constrain slot values to `<=1`: CA4-2A Normal-Hero behavior validates 0/1 at the family seam, while the shared persistence shape remains capable of later Super enhancement values greater than one. Migration `00020_ca4_2_hero_equipment.sql` initializes existing Hero slots to zero.

The Hero store now supports one cohesive CAS covering level, EXP and all six equipment values. The older narrower progression CAS remains available for existing owners. Stock reload projection emits the durable equipment values rather than hard-coded zeros.

## Raw state / content-revision reality

The new Normal-Hero `RawEquipmentState` reader is observation-only. It requires the caller-pinned content revision and `HERO_EQUIPMENT_CA4_2` capability, resolves exact `(hero_table_id, color, slot)` content, emits exactly six slots, represents uncollected slots as `TemplateID=0`, and rejects contradictory Normal state such as collected zero/special mappings or slot values greater than one. It does not mutate Hero/I5 state and does not implement Fumo, Super, Spirit, or Horcrux lifecycle.

## Stage-boundary reality

The final tree contains no production dispatcher `case 54:` or `case 62:` activation, no MID54/MID62 gameplay planner, no CA4-2B prepared I5 debit seam, and no Super equipment mapping artifact. Shared MID54/MID62 production registration therefore remains deferred through the later family qualification required by the sealed CA4 plan.

## Test/evidence reality

Canonical static/source/query/architecture checks are GREEN: content regeneration, CA4-1 and CA4-2A source oracles, generated content/character/kernel query text, SBOM/dependency policy, schema/query ownership, sqlc-generation policy, CA4-1 validator, CA4-2A validator, CA3-3 cumulative validator, and R5 cumulative validator.

Unmodified canonical Go execution was attempted first. The canonical candidate requests exact Go 1.27.1; the local launcher attempted to fetch that toolchain, but network/DNS access to `proxy.golang.org` is unavailable. This result is classified **ENVIRONMENT_BLOCKED**, not PASS and not a product failure. Canonical pins were not altered.

A fresh disposable compatibility copy changed only the Go environment declarations (`go 1.26.0 -> 1.23.0`, removed `toolchain go1.27.1`, `.go-version -> 1.23.2`). On that diagnostic copy: focused touched-package tests GREEN; focused race GREEN; `go vet ./...` GREEN; architecture guard GREEN; bounded package-by-package regression **92/92 GREEN**. These are **COMPATIBILITY_COPY_ONLY** results and do not satisfy the exact/native aggregate gate.

## Remaining lifecycle gates

Exact Go 1.27.1, pinned sqlc where applicable, real PostgreSQL migration/upgrade/restore/locking/replay/concurrency, and River only where accumulated CA4 behavior depends on it remain OPEN under the sealed aggregate pre-CA4-E native Work gate. W2 unmodified-stock-client proof remains separately routed. No part of this local acceptance waives or marks those gates passed.

## Conclusion

No source, content-authority, durable-owner, future-Super representation, CAS, reload-projection, raw-state, migration-scope, or phase-boundary contradiction remains in CA4-2A. CA4-2A may be locally accepted under the existing aggregate-native deferral. **This user authorization ends at CA4-2A**: the next permitted activity is CA4-2B design/contract reconciliation or an explicit authorization decision, not automatic CA4-2B coding.
