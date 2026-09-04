# Pass280 — Wave G request-registry reconciliation

## Why this patch is now evidence-backed
The stock-client debug capture (`debug.zip`, SHA256 `1da6405b...da711`) reproduces the 20–40 second modal loading problem after fresh login/restarts. Three login windows each show repeated successful background status traffic: MID124 occurs 10/9/10 times and MID1056 occurs 9/9/9 times in the first 60 seconds. The backend is returning complete source-shaped bodies, so the delay is not explained by a missing MID124/MID1056 server serializer.

Current authoritative `Backend.lua` contains:

`arg_53_0.requests_ = arg_53_0.request_ or {}`

and there is no assignment to `Backend.request_` anywhere in that class. Therefore every new HTTP/log request necessarily replaces the entire plural request-handle table. This is no longer a suspicious typo only: the capture proves overlapping live requests, so Pass269 Tier-C's handle-loss/replacement gate is met.

The same stock code increments `LoadingProxy` before starting a normal request, gives ordinary HTTP requests a 20-second timeout, and removes loading only on the completion/failure callback path. The reported 20–40 second stalls are therefore highly consistent with request lifecycle corruption, but causality remains runtime-gated until the patched client is smoke-tested.

## Minimal reconciliation
Pass280 changes exactly one current-source line in both client architectures:

`self.requests_ = self.request_ or {}`

→

`self.requests_ = self.requests_ or {}`

No LoadingProxy behavior changes. No EventCentre/Practice coalescing is added in this pass. Foreground `showLoading` defaults/semantics are unchanged.

## Why HydrationCoordinator is deferred one retest
The capture does show repeated equivalent MID124/MID1056 traffic, which is within the R2 coordinator's intended scope. However, the proven request-table clobber can itself prevent/perturb the callbacks that populate `SelfPlayer.practiceInfo` and `EventCentre.deskInfo`. Applying both patches at once would destroy causal isolation. Pass280 therefore repairs request ownership first. If the next smoke still shows equivalent fan-out/modal churn, the R2 HydrationCoordinator/Policy remains the next bounded compatibility step.

## Other capture findings, not part of this patch
The debug also contains independent domain/client errors in Fumo, Arena defense-formation shape, SchoolStory, Illusion asset error logging, Treasure empty-team UI, and March team info. They are preserved as follow-up evidence but are not allowed to widen this loading reconciliation patch.

## OTA and rollback
Cumulative compatibility OTA advances 1.631.22 → **1.631.23**. The new OTA contains patched Backend.lua for src_32/src_64 plus all prior cumulative overrides. The patch is one-line isolated and can be rolled back by returning to Pass279/v0.43.0 + OTA1.631.22.

## Next runtime gate
Clear client data (or otherwise ensure resource version <1.631.23), install OTA1.631.23, then repeat the first-login/restart idle test. Primary acceptance evidence:

- lobby modal loading no longer stalls ~20s;
- MID124/MID1056 first-minute counts collapse materially;
- foreground menu requests still show normal brief loading;
- no request retry/error regressions;
- capture a new debug.zip for before/after comparison.

Do not add HydrationCoordinator or LoadingProxy changes until that run is analyzed.
