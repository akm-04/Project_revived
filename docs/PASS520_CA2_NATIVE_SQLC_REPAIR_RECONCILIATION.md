# Pass520 CA2 native sqlc repair reconciliation

## Outcome

`RUNTIME_OBSERVED`: The exact immutable Pass519 candidate (`a6bf87421767c5451f69fcf359995d28d91a6c6f861f55422bcdd642583e0141`) failed the mandatory pinned `sqlc v1.31.1` generation gate in `VerifyContentRevision` at `sql/content/content.sql:228` with `column "table_id" does not exist`.

`RUNTIME_OBSERVED`: Luna isolated the failure to the Hero JSON expected-CTE projections and returned a separate proposed repair. The pristine Pass519 extraction remained byte-identical.

`INDEPENDENT_REALITY_CHECK`: Normal chat reviewed the product diff and did not adopt the Work tree wholesale. The repair was reproduced independently from pristine Pass519 by changing only `sql/content/content.sql`, replacing the affected `jsonb_to_recordset` projections with explicit typed field extraction via `jsonb_array_elements` over the same revision-bound Hero JSON arrays. `internal/adapters/postgres/contentqueries/querytext_gen.go` was then regenerated with the repository generator and independently matched Luna's generated result byte-for-byte.

`IMPLEMENTATION_DECISION`: This is a build/query-generation compatibility repair only. It does not change content revision, Hero mechanics, schema, migrations, production routes, provider activation, capacity policy, ownership, lock ordering, or retry/receipt semantics.

## Semantic equivalence boundary

The repaired expected CTEs read exactly the same Hero manifest arrays and cast the same fields to the same SQL types. Missing arrays produce an expected/stored mismatch; missing fields produce NULL-bearing rows that mismatch the stored non-null relational rows; malformed typed values fail casts. Verification therefore remains fail-closed.

## Work evidence reviewed

- Work evidence ZIP SHA256: `36fad089f0390e50f3c6650b9dcec11bd30ca996a4cab460cb5de153395179bf`
- Luna proposed repaired archive SHA256: `b1ad9ceb47704ab673b327531b6fefc9ce244e69d838dbbf144ebe5b3ba03caa`
- Luna proposed implementation revision: `7b2951eae0fcbbd4e33691e275ac7a86b0f932d88d225f2ffef6d41467ffdb5b`

The Luna archive itself is not promoted as canonical. Pass520 is reconstructed from pristine Pass519 with the reviewed source fix applied separately.

## Remaining aggregate CA2 gate

The first Work run left mandatory real-PostgreSQL Hero mutation/concurrency coverage blocked: duplicate-origin service/DB behavior, HeroRoot allocator contention, same-Hero EXP/evolution serialization, diagnostic capacity-allow MID59/MID305/PartnerEntity materialization, Grant-v3/MID59 contention, cross-stage MID305-vs-MID52 locking, and forced ambiguous PostgreSQL COMMIT. Stock-client proof was also environment-blocked. Pass520 remains an aggregate CA2 gate candidate, not CA2 acceptance.
