# Pass129 client smoke — architecture-hygiene runtime gate

This candidate is intended to be gameplay-byte-equivalent to accepted Pass128.2. The smoke exists to prove the new composition root starts cleanly in the real server/client path before the roadmap resumes.

1. Start the Pass129 backend normally and login with a usable account; confirm there is no Campaign composition/identity construction exception.
2. Open Campaign and confirm MID112 renders Normal map normally and preserves complete numeric Super cursor fields.
3. Exercise one stock-shaped Normal MID113 -> MID114 battle if practical; confirm result/progression behavior is unchanged.
4. On an account with Function31/Super available, open Super Campaign and confirm visibility plus related-Normal gating remains unchanged. One MID117 sweep is useful but not mandatory if the account is not seeded for it.
5. Capture server log/debug bundle. Treat tutorial/vending skip as the already-known separate client-local-state follow-up unless a new backend error precedes it.

Acceptance: no new exception, no changed Campaign wire shape, no changed authorization/settlement semantics, and no repeated ghost persistence attributable to construction.
