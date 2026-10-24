-- owner: player-core
-- source: Pass415 Wave-E Player Core

-- name: LockPlayerCoreProfile :one
SELECT player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at
FROM player_profiles WHERE player_id=$1 FOR UPDATE;

-- name: LockPlayerProgression :one
SELECT player_id,level,exp,state_version,updated_at
FROM player_progression WHERE player_id=$1 FOR UPDATE;

-- name: LockPlayerStoryCursor :one
SELECT player_id,story_id,story_state,guide_id,state_version,updated_at
FROM player_story_cursors WHERE player_id=$1 FOR UPDATE;

-- name: UpdatePlayerStoryCursor :execrows
UPDATE player_story_cursors
SET story_id=$2,story_state=$3,guide_id=$4,state_version=state_version+1,updated_at=$5
WHERE player_id=$1 AND state_version=$6;

-- name: ClearFirstEntryPending :execrows
UPDATE players SET first_entry_pending=false,state_version=state_version+1
WHERE player_id=$1 AND first_entry_pending=true;

-- name: ListPlayerFunctionUnlocks :many
SELECT player_id,function_id,opened_at,source_fact_key,state_version
FROM player_function_unlocks WHERE player_id=$1 ORDER BY function_id;

-- name: LockPlayerGuideReturnState :one
SELECT player_id,guide_return_id,guide_function_ids,state_version,updated_at
FROM player_guide_return_state WHERE player_id=$1 FOR UPDATE;
