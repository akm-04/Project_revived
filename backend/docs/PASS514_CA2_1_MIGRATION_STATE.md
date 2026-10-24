# Pass514 CA2-1 migration checkpoint — UNSEALED implementation state

Authority: sealed Pass513 HOT/CURRENT remains semantic authority. This backend is an unfinished CA2-1 implementation candidate and is not CA2-1 accepted, CA2 accepted, or release-accepted.

Current scope: CA2-1 Hero Foundation, Content & Projection only. CA2-2 progression and CA2-3 acquisition remain unstarted.

Implemented in the current candidate:
- migration 00014 CA2 Hero foundation;
- new Character sqlc owner/querytext/store boundary;
- deterministic Hero core catalog compiler from exact current src_64;
- HERO_CORE_CA2 capability in existing schema-v1 immutable content revision;
- relational Hero content persistence/verification;
- player_hero_roots + player_heroes canonical persistence;
- Character domain Hero aggregate/root types;
- canonical Hero stock projection;
- application service for MID49 roster and MID89 sort_type;
- stock Hero dispatcher and postgres wiring/bootstrap projection;
- source/static CA2-1 guards.

Known qualified source output: 568 Hero templates, 100 Hero EXP rows, 5 Normal-star rows, 10 physical Super-star rows, 70 Vows prerequisite rows, 291 acquisition mappings. Super effective ceiling remains 8 stars; capacity/MID64 remains UNKNOWN and production acquisition stays gated.

Observed checks before migration packaging:
- CA2-1 static validator PASS;
- schema/query ownership PASS;
- sqlc generation policy PASS;
- character querytext check PASS;
- deterministic builtin content --check against exact src_64 PASS, revision e8061a82658033813ee1c182f0f3b062cb0af5b43e21acea7b905e713ad0e964;
- CA2-1 source-oracle check PASS;
- focused Go tests for domain/character, projection/hero, application/characterhero, adapters/postgres/contentstore PASS on fresh Go-1.23 compatibility copy only.

Not yet complete / not claimed:
- no broad package-by-package regression after the current full CA2-1 integration;
- no current full race/vet gate after the current full integration;
- no exact Go 1.27.1 proof in normal-chat sandbox;
- no real PostgreSQL 18.6 / sqlc native gate for this CA2-1 candidate;
- no independent post-implementation CA2-1 reality check yet;
- no CA2-1 acceptance; no CA2 phase acceptance; no CA2-2 authorization by checkpoint state.

Important history: an earlier unsealed CA2-1 scratch tree appeared partially lost during the long chat, but the current rebuild was reconstructed from the exact accepted backend + sealed Pass513 contract. The present rebuilt tree is the authoritative newer implementation candidate for migration purposes; do not merge any older scratch tree over it.
