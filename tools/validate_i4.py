#!/usr/bin/env python3
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
errs=[]
def need(path,*tokens):
 p=root/path
 if not p.exists(): errs.append(f'missing {path}'); return
 s=p.read_text(errors='replace')
 for t in tokens:
  if t not in s: errs.append(f'{path}: missing {t}')
need(Path('internal/domain/realtimeauth/authority.go'),'WORLD','SERVICE','GUILD','ServiceRoomID int64 = 99999','TEAM is a logical SERVICE projection')
need(Path('internal/adapters/stockruntime/realtime_server.go'),'handshakeDeadline','MIDSocketHeartbeat','validateLive','ConnectionRegistry')
need(Path('internal/adapters/stockruntime/realtime_registry.go'),'type ConnectionRegistry struct','func NewConnectionRegistry() *ConnectionRegistry')
need(Path('internal/adapters/stockruntime/realtime_policy.go'),'StockTCPLoginTimeout','StockHeartbeatInterval','ClientIdleTimeout','AuthQueryTimeout','LivenessQueryTimeout')
need(Path('internal/adapters/stockruntime/http_dispatchers.go'),'case 18:','case 1:','error_code": int64(20018)','room_id','log_url','server_time','story_type')
need(Path('internal/adapters/postgres/i4store/bootstrap_runtime.go'),'tx.Serializable','MID1Fingerprint(session.ID, req.Region)','generation:%d','FindTx','PutTx','revokeContextCredentials')
need(Path('internal/adapters/postgres/i4store/realtime_authority.go'),'ResolveGameplayBearer','ValidateActor','validateActorLiveness')
need(Path('internal/projection/lobby/shapes.go'),'EmbeddedMID1Records','1304','is_enroll')
need(Path('internal/projection/lobby/manifest.go'),'func NewBootTracker() *BootTracker','60 * time.Second','BootHeartbeat','BootLegitTimer')
need(Path('cmd/gxb-api/main_postgres.go'),'//go:build postgres','mustRegister(18','mustRegister(1','mustRegister(192','[]uint16{2, 7, 2864, 20480}','GXB_PUBLIC_ENGINE_URL')
need(Path('internal/adapters/stockruntime/prelogin.go'),'MIDCenterDiscovery','MIDVersionCheck','"contents": "{}"','JSON: "B"','JSON: "A"')
need(Path('internal/protocol/mids/registry.go'),'MIDVersionCheck','MIDCenterDiscovery','sourcePlaneAliases')
need(Path('cmd/gxb-realtime/main_postgres.go'),'//go:build postgres','NewConnectionRegistry','EvidenceConfigFromEnv','RunHealthPulses')
need(Path('tools/check_i4_oracle_wave_s.py'),'I4 ORACLE WAVE-S CHECK: PASS')
need(Path('internal/projection/lobby/evidence.go'),'NewBootTrackerWithJSONL','LoadBootTrackerJSONL')
need(Path('cmd/gxb-wave-s-report/main.go'),'EvaluateWaveS','AcceptanceGreen','os.Exit(1)')
need(Path('internal/adapters/river/doc.go'),'package riveradapter')
need(Path('tools/check_connected_candidate.py'),'go1.27.1','postgres river','sqlc','tree_digest','go.sum')
need(Path('tools/w1_seed_identity.py'),'W1 TEST FIXTURE ONLY','gxb-v2/credential/v1')
need(Path('migrations/00003_identity_account_uid_repair.sql'),'-- +goose StatementBegin','-- +goose StatementEnd','account_uid text NOT NULL','refusing to invent stock account identity')
need(Path('migrations/00004_player_directory_profile_bootstrap.sql'),'-- +goose Up','-- +goose StatementBegin','-- +goose StatementEnd','CREATE TABLE player_directory_profiles','avatar_id bigint NOT NULL DEFAULT 110001001','owner: player-core/directory-projection')
need(Path('internal/domain/logicalserver/directory.go'),'BootstrapDirectoryAvatarID int64 = 110001001')
need(Path('internal/adapters/postgres/i4store/bootstrap_runtime.go'),'player_directory_profiles','profile_present','missing required directory profile','insertPlayerDirectoryProfile')
need(Path('internal/domain/identity/types.go'),'type AccountUID string','UID             AccountUID')
need(Path('internal/projection/lobby/shapes.go'),'uid": string(v.Actor.AccountUID)','player_id": int64(v.Actor.PlayerID)')
need(Path('tools/w1_seed_identity.py'),"--account-uid",'do not substitute player_id')
# I4 must not fake extra logical-server seed rows.
mig=(root/'migrations/00002_identity_logicalserver_bootstrap.sql').read_text()
if "(3,'Server 3'" in mig or "(4,'Server 4'" in mig: errs.append('fake Server 3/4 seed detected')
# Keep I4 bounded: deep systems must remain untouched placeholders, not routed startup facades.
api=(root/'cmd/gxb-api/main_postgres.go').read_text()
for forbidden in ['CombatAttempt','commerce','gacha','GuildWar','SEND_CHAT_MESSAGE']:
 if forbidden in api: errs.append(f'I4 production router expanded into forbidden deep domain: {forbidden}')
if errs:
 print('I4 VALIDATION: FAIL'); [print(' -',x) for x in errs]; sys.exit(1)
print('I4 VALIDATION: PASS')
