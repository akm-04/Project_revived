#!/usr/bin/env python3
from pathlib import Path
import sys
r=Path(__file__).resolve().parents[1]
server=(r/'internal/adapters/stockruntime/realtime_server.go').read_text()
policy=(r/'internal/adapters/stockruntime/realtime_policy.go').read_text()
writer=(r/'internal/adapters/stockruntime/realtime_writer.go').read_text()
main=(r/'cmd/gxb-realtime/main_postgres.go').read_text()
test=(r/'internal/adapters/stockruntime/realtime_r3b_test.go').read_text()
errors=[]
for needle,text,msg in [
 ('handshakeDeadline := time.Now().Add(policy.HandshakeTimeout)',server,'absolute handshake deadline missing'),
 ('context.WithTimeout(ctx, policy.AuthQueryTimeout)',server,'auth query deadline missing'),
 ('context.WithTimeout(ctx, timeout)',server,'liveness query deadline missing'),
 ('ErrRealtimeClientIdle',server,'client idle retirement missing'),
 ('ClientFrameDispatcher interface',server,'post-auth dispatcher seam missing'),
 ('newConnWriter',server,'single-writer runtime not wired'),
 ('MaxConnections',policy,'connection admission policy missing'),
 ('ClientIdleTimeout <= hb',policy,'stock-heartbeat-compatible idle validation missing'),
 ('GXB_REALTIME_MAX_CONNECTIONS',policy,'runtime env configurability missing'),
 ('type connWriter struct',writer,'bounded single-writer missing'),
 ('wireRT.ErrQueueFull',writer,'writer backpressure missing'),
 ('listenerSlots := make(chan struct{}, runtimePolicy.MaxConnections)',main,'listener goroutine admission bound missing'),
 ('RealtimePolicyFromEnv(os.Getenv)',main,'runtime policy not wired in postgres main'),
 ('TestR3BAbsoluteHandshakeDeadlineSlowloris',test,'slowloris test missing'),
 ('TestR3BAdmissionSaturationAndRelease',test,'admission saturation test missing'),
 ('TestR3BAuthAndLivenessQueryTimeouts',test,'query timeout test missing'),
 ('TestR3BHeartbeatKeepsAliveAndSilentConnectionExpires',test,'heartbeat/idle test missing'),
 ('TestR3BBoundedSingleWriterBackpressure',test,'writer backpressure test missing'),
]:
    if needle not in text: errors.append(msg)
if errors:
    [print('R3B VALIDATION ERROR:',e) for e in errors]; sys.exit(1)
print('R3B VALIDATION: PASS')
