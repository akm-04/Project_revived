# Pass435 — Milestone I2: Protocol Edge / Exact Stock Wire Compatibility

## Implemented
- generated immutable numeric MID catalog from verified current `mid.lua`; numeric MID is key, aliases are metadata;
- ordinary HTTP form decoder with exactly one form/percent decode layer;
- bounded zlib multipart parser for all seven source MIDs and wrong-family rejection;
- MID1844 bounded file spool with source-shaped agreeing duplicate normalization and conflict rejection;
- explicit 404 unknown / 501 researched-unimplemented / 400 malformed / 413 cap / 503 pre-operation saturation behavior;
- semantic HTTP200 response path stays distinct from transport failures;
- bounded project-owned Xinyoudi AMF3 codec for the native/source profile;
- exact 10-byte big-endian realtime frame and 65,536-byte payload limit;
- incremental fragmentation/coalescing parser;
- physical WORLD/GUILD/SERVICE role type, pre-auth TCP_LOGIN gate and client wrong-direction rejection;
- bounded frame/byte writer queue and metadata-only observation sink;
- thin optional chi build-tag adapter; net/http project handler owns GXB edge behavior;
- source/V1 drift generators and oracle checks.

## Tests
- exact 66-byte TCP_LOGIN vector and Pass353 byte differential fixtures;
- every-byte frame fragmentation and coalescing;
- AMF marker acceptance/rejection, string refs, U29 signed boundaries, retry-safe deterministic encoding and decode budgets;
- ordinary HTTP one-layer corpus, all seven zlib MIDs, MID1844 duplicate conflict, body/inflate caps;
- unknown/unimplemented/semantic-success/saturation handlers;
- Go fuzz seed targets for AMF, realtime stream and ordinary HTTP;
- race tests for all protocol packages and architecture guards.

## Honest deferrals
The normal-chat environment still uses Go 1.23.2 and cannot fetch the target toolchain/modules. The optional `chi` adapter is therefore checked structurally/build-tagged but exact Go 1.27.1 tagged compilation remains a connected-environment proof. Real socket pressure/slow-consumer tuning and the unmodified stock client remain W1 after I4. No PostgreSQL/River behavior is claimed by I2.

## Verdict
Normal-chat I2 implementation is complete. Final preservation packaging is performed after this immutable implementation commit is stamped into snapshot metadata. No client modification or private V1 nonce/context mechanism was introduced.
