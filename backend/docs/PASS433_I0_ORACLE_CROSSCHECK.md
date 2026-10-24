# Pass433 I0 bounded oracle cross-check

The five externally supplied oracle archives were SHA-256 verified by `tools/verify_oracles.py` before I0 validation.

Current packaged `src_64/app/common/network/Backend.lua` was inspected directly from the verified all-assets archive. The stock client still retries failed web requests by preserving the original MID and params in `pendingRequests` and re-invoking `webRequest_`; ordinary payloads are JSON encoded then passed through `string.urlencode` before POST. No generic `client_op_id`, `summon_op_id`, or `contextEpoch` token appears in this current source file. I0 therefore introduces no private client nonce or client patch mechanism.

Frozen Pass353 was inspected only as an oracle. Its realtime implementation is Python/thread/socket based, confirming again that V2 is not a source-port or extension of the V1 application tree. No Pass353 application code was copied into this repository.

I0 conclusion: no current source/native/V1 fact contradicts the clean Go modular-monolith bootstrap or the Pass431 dependency ordering.
