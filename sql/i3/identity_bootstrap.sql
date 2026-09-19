-- owner: identity/logicalserver/bootstrap
-- name: SelectAccountSessionAuth :one
SELECT a.account_id,a.account_uid,a.status,a.disabled_at,a.liveness_version,
       s.session_id,s.auth_profile,s.issued_at,s.absolute_expires_at,s.idle_timeout_seconds,s.last_activity_at,s.revoked_at,s.revocation_reason,s.liveness_version
FROM account_sessions s JOIN accounts a ON a.account_id=s.account_id WHERE s.session_id=$1;

-- name: SelectSessionCredentialByDigest :one
SELECT credential_id,session_id,kind,digest,issued_at,expires_at,revoked_at FROM account_session_credentials WHERE digest=$1;

-- name: ListVisibleLogicalServers :many
SELECT logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at,retired_at
FROM logical_servers WHERE directory_visible=true ORDER BY logical_server_id;

-- name: UpsertSessionServerObservation :exec
INSERT INTO account_session_server_observations(session_id,logical_server_id,observed_at) VALUES($1,$2,$3)
ON CONFLICT(session_id,logical_server_id) DO UPDATE SET observed_at=EXCLUDED.observed_at;

-- name: SelectPlayerByAccountServer :one
SELECT player_id,account_id,logical_server_id,created_at,bootstrap_profile_version,first_entry_pending,state_version FROM players WHERE account_id=$1 AND logical_server_id=$2;

-- name: LockLogicalServerForCharacterCreate :one
SELECT logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at,retired_at
FROM logical_servers WHERE logical_server_id=$1 FOR UPDATE;

-- name: HasSessionServerObservation :one
SELECT EXISTS(SELECT 1 FROM account_session_server_observations WHERE session_id=$1 AND logical_server_id=$2);

-- name: InsertPlayerRoot :exec
INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version,first_entry_pending,state_version) VALUES($1,$2,$3,$4,$5,$6,1);

-- name: AdvanceLogicalServerCursor :execrows
UPDATE logical_servers SET next_player_id=$2,state_version=state_version+1 WHERE logical_server_id=$1 AND next_player_id=$3;

-- name: SelectLiveGameplayContextBySession :one
SELECT context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,ended_at,end_reason,liveness_version FROM gameplay_contexts WHERE session_id=$1 AND ended_at IS NULL;

-- name: EndGameplayContext :execrows
UPDATE gameplay_contexts SET ended_at=$2,end_reason=$3,liveness_version=liveness_version+1 WHERE context_id=$1 AND ended_at IS NULL;

-- name: InsertGameplayContext :exec
INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at,liveness_version) VALUES($1,$2,$3,$4,$5,$6,$7,1);

-- name: InsertGameplayCredential :exec
INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at) VALUES($1,$2,$3,$4,$5,$6,$7);

-- name: InsertBootstrapPlayerDirectoryProfile :exec
-- I4 bootstrap creator for the future Player-Core-owned directory projection.
INSERT INTO player_directory_profiles(
  player_id,name,lev,vip,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id,state_version,created_at,updated_at
) VALUES($1,'',1,0,$2,0,0,1,1,$3,$3);

-- name: ListOwnedPlayerDirectoryProfiles :many
SELECT p.player_id,p.logical_server_id,d.name,d.lev,d.vip,d.avatar_id,d.avatar_frame_id,d.conquer_lev,d.conquer_loop_id
FROM players p JOIN player_directory_profiles d ON d.player_id=p.player_id
WHERE p.account_id=$1 ORDER BY p.logical_server_id;
