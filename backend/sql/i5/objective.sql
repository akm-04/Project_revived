-- owner: objective-core
-- source: Pass415/Pass422 Wave-E objective facts

-- name: LockMissionInstance :one
SELECT player_id,program_id,objective_id,generation_id,definition_revision,progress,completed_at,claim_state,claimed_at,state_version
FROM player_mission_instances
WHERE player_id=$1 AND program_id=$2 AND objective_id=$3 AND generation_id=$4 FOR UPDATE;

-- name: InsertMissionInstance :exec
INSERT INTO player_mission_instances(player_id,program_id,objective_id,generation_id,definition_revision,progress,completed_at,claim_state,claimed_at,state_version)
VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,1);

-- name: UpdateMissionInstance :execrows
UPDATE player_mission_instances
SET progress=$5,completed_at=$6,claim_state=$7,claimed_at=$8,state_version=state_version+1
WHERE player_id=$1 AND program_id=$2 AND objective_id=$3 AND generation_id=$4 AND state_version=$9;
