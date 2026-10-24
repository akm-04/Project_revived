#!/usr/bin/env python3
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
codec=(root/'internal/protocol/amf3/codec.go').read_text()
limits=(root/'internal/protocol/limits/limits.go').read_text()
frame=(root/'internal/protocol/realtime/frame.go').read_text()
tests=(root/'internal/protocol/amf3/codec_test.go').read_text() + (root/'internal/protocol/realtime/frame_test.go').read_text()
errors=[]
checks=[
 ('sealedN > d.cfg.AMFProperties',codec,'decoder sealed-count preallocation budget missing'),
 ('Reject unsupported trait shapes before any sealed-name allocation/read',codec,'unsupported trait preallocation fail-closed marker missing'),
 ('func EncodeWithConfig',codec,'bounded encoder API missing'),
 ('AMFOutputBytes',limits,'AMF output budget missing'),
 ('e.depth > e.cfg.AMFDepth',codec,'encoder depth budget missing'),
 ('e.nodes > e.cfg.AMFNodes',codec,'encoder node budget missing'),
 ('cyclic input',codec,'cycle rejection missing'),
 ('signed integer outside exact double range',codec,'signed exact-integer guard missing'),
 ('unsigned integer outside exact double range',codec,'unsigned exact-integer guard missing'),
 ('EncodeFrameWithConfig',frame,'bounded realtime frame encoder missing'),
 ('TestDecodeRejectsSealedTraitCountBeforeAllocation',tests,'sealed-count regression test missing'),
 ('TestEncodeWithConfigBoundsOutputAndContainers',tests,'encoder budget regression test missing'),
 ('TestEncodeRejectsCyclesAndDepth',tests,'cycle/depth regression test missing'),
 ('TestEncodeExactIntegerPolicyIsSymmetric',tests,'integer fidelity regression test missing'),
 ('FuzzDecodeBounded',tests,'decode fuzz target missing'),
 ('FuzzEncodeBounded',tests,'encode fuzz target missing'),
 ('FuzzStreamDecoder',tests,'stream fuzz target missing'),
]
for needle,text,msg in checks:
    if needle not in text: errors.append(msg)
if 'AMFOutputBytes > NativeFramePayloadMax' not in limits:
    errors.append('output budget is not capped by native frame maximum')
if errors:
    for e in errors: print('R3A VALIDATION ERROR:',e)
    sys.exit(1)
print('R3A VALIDATION: PASS')
