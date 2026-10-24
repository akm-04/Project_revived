# Pass531 CA3 Work-fix independent post-implementation reality check

Verdict: **GREEN at the normal-chat/local repair ceiling; exact Work requalification required.**

This check reread the controlling Pass528 CA3-3 contract/acceptance expectations, the sealed I2 transport boundary, the active `src_64` HTTP sender, Luna's exact native failure evidence, and the produced Pass531 code. It does not treat test success as proof of design correctness by itself.

## Evidence classification

- **SOURCE_FACT:** active `Backend.lua` adds `mid`, `token`, `region`, `v_`, `app_v`, and `platform` to ordinary command payloads before JSON encoding.
- **RUNTIME_OBSERVED:** exact Pass530 Pet HTTP requests failed at strict dispatcher validation before command services; real PostgreSQL concurrency emitted SQLSTATE 40001 and Pass530 surfaced Pet-not-found to one caller.
- **STRONG_INFERENCE:** the transport failure is shared by every strict StockRuntime dispatcher that interprets the unnormalized top-level map as pure gameplay parameters; Hero had the same predicate shape even though Luna's first Pet-focused harness did not test it.
- **IMPLEMENTATION_DECISION:** normalize the recovered six-field stock metadata set at strict top-level StockRuntime validation, not inside nested gameplay rows and not globally in the HTTP edge.
- **IMPLEMENTATION_DECISION:** encode Pet row presence explicitly at the Store port. Only a normalized no-row is semantic absence; all other failures remain errors.
- **DISPROVEN:** treating `mid/token/region` as the complete stock-added ordinary HTTP metadata set.
- **DISPROVEN:** treating every non-definite-abort Pet row-lock error as Pet-not-found.

## Contract review

The repair preserves command-specific strict gameplay validation: arbitrary top-level gameplay fields remain rejected, nested item/row maps remain strict, and the command decoders still own wire-type/shape validation. The lock change does not alter mutation ordering, ownership, receipt fencing, I5 composition, or content semantics; it only prevents infrastructure failures from being fabricated as semantic absence.

No source contradiction was found that reopens Pass528 research/design. No new gameplay formula, identifier, endpoint, content rule, or client behavior was invented.

## Remaining proof limits

Normal-chat Go execution is compatibility-copy only because the canonical candidate retains Go 1.27.1 while the local sandbox runs Go 1.23.2. Pass531 therefore requires exact pinned Work proof. The first Luna Work run did not have an installed stock client or authoritative Pass525 old serving node and did not execute controlled UNKNOWN-COMMIT/timing/revision fault scenarios; those gates remain open.
