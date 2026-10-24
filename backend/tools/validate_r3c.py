#!/usr/bin/env python3
from pathlib import Path
import sys
r=Path(__file__).resolve().parents[1]
manifest=(r/'internal/projection/lobby/manifest.go').read_text()
evidence=(r/'internal/projection/lobby/evidence.go').read_text()
api=(r/'cmd/gxb-api/main_postgres.go').read_text()
rtmain=(r/'cmd/gxb-realtime/main_postgres.go').read_text()
report=(r/'cmd/gxb-wave-s-report/main.go').read_text()
http=(r/'internal/adapters/stockruntime/http_dispatchers.go').read_text()
rt=(r/'internal/adapters/stockruntime/realtime_server.go').read_text()
tests='\n'.join([
 (r/'internal/projection/lobby/manifest_test.go').read_text(),
 (r/'internal/projection/lobby/evidence_test.go').read_text(),
 (r/'internal/adapters/stockruntime/realtime_r3b_test.go').read_text(),
])
errors=[]
checks=[
 ('func NewBootTracker() *BootTracker',manifest,'aggregate-only production tracker constructor missing'),
 ('if !t.captureEnabled {',manifest,'capture-disabled no-detail path missing'),
 ('DefaultEvidenceMaxEvents',evidence,'finite evidence event cap missing'),
 ('DefaultEvidenceRingEvents',evidence,'finite evidence ring cap missing'),
 ('GXB_WAVE_S_MAX_EVENTS',evidence,'evidence event cap env configuration missing'),
 ('GXB_WAVE_S_RING_EVENTS',evidence,'evidence ring cap env configuration missing'),
 ('RunID',manifest,'run correlation missing'),
 ('ProcessID',manifest,'process correlation missing'),
 ('SessionTag',manifest,'session correlation tag missing'),
 ('ContextTag',manifest,'context correlation tag missing'),
 ('ConnectionTag',manifest,'connection correlation tag missing'),
 ('PhaseServerIntent',manifest,'server-intent evidence phase missing'),
 ('PhaseClientConsumed',manifest,'client-consumed evidence phase missing'),
 ('BootLuaException',manifest,'client Lua exception evidence missing'),
 ('func (t *BootTracker) S0Manifest()',manifest,'server manifest evaluator missing'),
 ('multiple gameplay contexts',manifest,'mixed-context manifest rejection marker missing'),
 ('func (t *BootTracker) Quiescence(',manifest,'quiescence evaluator missing'),
 ('clientLiveThrough',manifest,'connected-client quiescence requirement missing'),
 ('func (t *BootTracker) ClientProof(',manifest,'client proof evaluator missing'),
 ('NON_GREEN_CLIENT_PROOF_REQUIRED',manifest,'server evidence cannot silently become client acceptance'),
 ('EvidenceConfigFromEnv(lobby.ProcessAPI',api,'API evidence runtime wiring missing'),
 ('RunHealthPulses',api,'API capture health pulses missing'),
 ('EvidenceConfigFromEnv(lobby.ProcessRealtime',rtmain,'realtime evidence runtime wiring missing'),
 ('RunHealthPulses',rtmain,'realtime capture health pulses missing'),
 ('if !out.AcceptanceGreen',report,'report command does not fail non-green acceptance'),
 ('os.Exit(1)',report,'non-green report exit missing'),
 ('Phase: lobby.PhaseServerIntent',http,'MID1 embedded server-intent classification missing'),
 ('CorrelationTags(',rt,'realtime opaque correlation missing'),
 ('Phase: lobby.PhaseClientState',rt,'realtime lifecycle state evidence missing'),
 ('TestR3CRealtimeEvidenceUsesOpaqueCorrelatedLifecycle',tests,'actual realtime opaque-correlation test missing'),
 ('TestCaptureDisabledRetainsNoDetailedEvents',tests,'capture-disabled bounded-memory test missing'),
 ('TestCapturedRingBoundAndOverflowHealth',tests,'finite capture/overflow test missing'),
 ('TestLoadRejectsMixedRunIDs',tests,'run separation test missing'),
 ('TestServerEvidenceCannotBecomeClientProof',tests,'server/client proof separation test missing'),
 ('TestDisconnectIsNotHealthyQuiescence',tests,'disconnect-not-quiescent test missing'),
 ('TestStaleCaptureHealthIsNotQuiescence',tests,'capture-health quiescence test missing'),
 ('TestClientLuaExceptionMakesAcceptanceNonGreen',tests,'Lua-exception acceptance test missing'),
 ('TestTimerHeavySixtySecondsStaysMemoryBounded',tests,'timer-heavy boundedness test missing'),
]
for needle,text,msg in checks:
    if needle not in text: errors.append(msg)
if errors:
    for e in errors: print('R3C VALIDATION ERROR:',e)
    sys.exit(1)
print('R3C VALIDATION: PASS')
