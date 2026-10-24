# Imported W1 RED findings used by Pass439-Pass441

Source evidence archive SHA-256:
`405e7250f7f5535e152520d33825455cf46e33c90385cbbfe9e6925b27b1e781`

The first exact Pass438 W1 run reported four exact-candidate blockers (tagged dependency sums/closure, missing BootTracker constructor, Goose compound-statement parsing, River package mismatch), high gaps in sqlc cleanliness / dependency-SBOM closure / pre-W1 mechanical gating, and medium gaps in ambiguous-COMMIT reconciliation history and cross-process Wave-S instrumentation.

The Work diagnostic copy was evidence only and was never promoted as authority. Pass439-Pass441 implement the repairs in normal chat, cross-check them against current `src_64`/Pass353 where stock semantics are relevant, and require a fresh exact-candidate W1 rerun before I5.
