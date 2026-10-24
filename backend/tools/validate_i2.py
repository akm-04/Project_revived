#!/usr/bin/env python3
from __future__ import annotations
import json,re,sys
from pathlib import Path
R=Path(__file__).resolve().parents[1]; errs=[]
def need(p):
    q=R/p
    if not q.exists():errs.append('missing '+p);return ''
    return q.read_text(errors='replace')

def j(p):
    try:return json.loads(need(p) or '{}')
    except Exception as e:errs.append(f'{p} invalid json: {e}');return {}
build=j('BUILD_INFO.json');stage=j('docs/PASS435_I2_STAGE_VALIDATION.json');facts=j('testdata/sourcefacts/pass435_current_mid_assignments.json');diff=j('testdata/wire/pass435_pass353_realtime_differential.json')
limits=need('internal/protocol/limits/limits.go');mids=need('internal/protocol/mids/registry.go');gen=need('internal/protocol/mids/registry_gen.go');httpd=need('internal/protocol/httpedge/decode.go');handler=need('internal/protocol/httpedge/handler.go');amf=need('internal/protocol/amf3/codec.go');frame=need('internal/protocol/realtime/frame.go');gate=need('internal/protocol/realtime/admission.go');queue=need('internal/protocol/realtime/queue.go');arch=need('internal/archguard/archguard_test.go');gomod=need('go.mod')
# Historical stage validators verify durable stage contracts. Current BUILD_INFO
# routing/version belongs to the newest stage validator.
if stage.get('pass')!='435.0' or stage.get('stage')!='I2':errs.append('stage identity mismatch')
if not str(stage.get('status','')).startswith('PASS'):errs.append('I2 stage was not sealed PASS')
if not build.get('implementation_started'):errs.append('current build unexpectedly says implementation not started')
if facts.get('source_sha256')!='026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af':errs.append('current mid.lua source hash mismatch')
if facts.get('assignment_count')!=1213 or facts.get('unique_numeric_mid_count')!=1211:errs.append('MID census mismatch')
if len(diff.get('fixtures',[]))<5:errs.append('Pass353 differential fixture set too small')
for pat,label in [(r'StockOrdinaryHTTPTimeout\s*=\s*20 \* time\.Second','StockOrdinaryHTTPTimeout'),(r'StockMultipartHTTPTimeout\s*=\s*30 \* time\.Second','StockMultipartHTTPTimeout'),(r'StockTCPLoginTimeout\s*=\s*10 \* time\.Second','StockTCPLoginTimeout'),(r'StockHeartbeatInterval\s*=\s*600 \* time\.Second','StockHeartbeatInterval'),(r'NativeFramePayloadMax\s*=\s*65536','NativeFramePayloadMax')]:
    if not re.search(pat,limits):errs.append('source/native limit missing '+label)
for token in ['IsRealtimeNumber','(mid & 0x9000) == 0x8000','IsGMNumber','(mid & 0x9000) == 0x9000','MIDUploadSpaceAvatar uint16 = 1844']:
    if token not in mids:errs.append('MID route contract missing '+token)
for n in [279,2484,535,774,1412,1570,2515]:
    if f'{n}:' not in mids.replace(' ', ''):errs.append(f'zlib MID {n} missing')
for token in ['url.ParseQuery','exactly one payload field required','zlib.NewReader','spoolUploadPart','conflicting source-shaped duplicate field','MID1844','form_name must match file part name']:
    if token not in httpd:errs.append('HTTP boundary missing '+token)
for token in ['StatusNotFound','StatusNotImplemented','StatusServiceUnavailable','CatalogRevision','recordObservation']:
    if token not in handler:errs.append('HTTP failure/dispatch contract missing '+token)
for token in ['case 0x00','case 0x06','case 0x09','case 0x0a','marker 0x%02x','only dynamic anonymous object','utf8.ValidString']:
    if token not in amf:errs.append('AMF profile missing '+token)
for token in ['HeaderBytes = 10','NativeFramePayloadMax','binary.BigEndian.PutUint16','binary.BigEndian.PutUint32','NewStreamDecoder']:
    if token not in frame:errs.append('TCP frame contract missing '+token)
for token in ['MIDTCPLogin','ErrPreauthMID','ErrWrongDirection','World','Guild','Service']:
    if token not in gate:errs.append('realtime admission missing '+token)
for token in ['maxFrames','maxBytes','ErrQueueFull']:
    if token not in queue:errs.append('writer queue missing '+token)
for token in ['allowedLayerImports','"protocol": {','TestLayerMatrixNegativeFixtures','TestNoGenericAMFRuntimeAuthority']:
    if token not in arch:errs.append('I2 architecture guard missing '+token)
if '{"protocol", module + "internal/domain/' not in arch:
    errs.append('I2 architecture negative fixture does not prove protocol->domain rejection')
if 'github.com/breign/goAMF3' in ''.join(need(str(p.relative_to(R))) for p in R.glob('internal/**/*.go') if p.is_file() and 'internal/archguard/' not in str(p.relative_to(R))):errs.append('goAMF3 imported into runtime source')
if 'github.com/go-chi/chi/v5 v5.3.1' not in gomod:errs.append('chi pinned runtime candidate missing from go.mod')
if 'client_operation_id' in ''.join([httpd,handler,amf,frame]) or 'summon_op_id' in ''.join([httpd,handler,amf,frame]):errs.append('private nonce leaked into I2')
if errs:
    print('I2 VALIDATION: FAIL');[print(' -',e) for e in errs];sys.exit(1)
print('I2 VALIDATION: PASS')
print('stock HTTP families, generated numeric MID catalog, bounded AMF3/TCP framing, fail-closed dispatch and differential fixtures verified')
