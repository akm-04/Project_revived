-- owner: character/practice
-- name: InsertPracticeRoot :execrows
INSERT INTO player_practice_roots(
  player_id,bless_remaining,bless_capacity_at_epoch,base_mana,base_crystal,state_version,created_at,updated_at
) VALUES ($1,0,0,0,0,1,$2,$2)
ON CONFLICT (player_id) DO NOTHING;

-- name: ReadPracticeRoot :one
SELECT player_id,free_last_consumed_at,daily_epoch_start_at,daily_epoch_policy_version,
       bless_remaining,bless_capacity_at_epoch,bless_vip_level_at_epoch,
       bless_privilege_provider_revision,bless_content_revision,base_mana,base_crystal,
       state_version,created_at,updated_at
FROM player_practice_roots WHERE player_id=$1;

-- name: LockPracticeRoot :one
SELECT player_id,free_last_consumed_at,daily_epoch_start_at,daily_epoch_policy_version,
       bless_remaining,bless_capacity_at_epoch,bless_vip_level_at_epoch,
       bless_privilege_provider_revision,bless_content_revision,base_mana,base_crystal,
       state_version,created_at,updated_at
FROM player_practice_roots WHERE player_id=$1 FOR UPDATE;

-- name: SavePracticeRootGeneration :execrows
UPDATE player_practice_roots
SET daily_epoch_start_at=$2,daily_epoch_policy_version=$3,
    bless_remaining=$4,bless_capacity_at_epoch=$5,bless_vip_level_at_epoch=$6,
    bless_privilege_provider_revision=$7,bless_content_revision=$8,
    base_mana=$9,base_crystal=$10,state_version=state_version+1,updated_at=$11
WHERE player_id=$1 AND state_version=$12;

-- name: SavePracticeRootAccounting :execrows
UPDATE player_practice_roots
SET free_last_consumed_at=$2,daily_epoch_start_at=$3,daily_epoch_policy_version=$4,
    bless_remaining=$5,bless_capacity_at_epoch=$6,bless_vip_level_at_epoch=$7,
    bless_privilege_provider_revision=$8,bless_content_revision=$9,
    base_mana=$10,base_crystal=$11,state_version=state_version+1,updated_at=$12
WHERE player_id=$1 AND state_version=$13;

-- name: UpsertHeroPracticeCandidate :execrows
INSERT INTO player_hero_practice_candidates(
  player_id,session_id,partner_id,actor_state_version,proposed_str,proposed_int,proposed_agi,
  generation_operation_id,generation_context_id,generation_kind,generation_content_revision,
  generation_policy_refs,created_at,updated_at
) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12::jsonb,$13,$14)
ON CONFLICT (player_id,session_id,partner_id) DO UPDATE
SET actor_state_version=EXCLUDED.actor_state_version,
    proposed_str=EXCLUDED.proposed_str,proposed_int=EXCLUDED.proposed_int,proposed_agi=EXCLUDED.proposed_agi,
    generation_operation_id=EXCLUDED.generation_operation_id,
    generation_context_id=EXCLUDED.generation_context_id,
    generation_kind=EXCLUDED.generation_kind,
    generation_content_revision=EXCLUDED.generation_content_revision,
    generation_policy_refs=EXCLUDED.generation_policy_refs,
    created_at=EXCLUDED.created_at,
    updated_at=EXCLUDED.updated_at;

-- name: UpsertPetPracticeCandidate :execrows
INSERT INTO player_pet_practice_candidates(
  player_id,session_id,pet_id,actor_state_version,proposed_str,proposed_int,proposed_agi,
  generation_operation_id,generation_context_id,generation_kind,generation_content_revision,
  generation_policy_refs,created_at,updated_at
) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12::jsonb,$13,$14)
ON CONFLICT (player_id,session_id,pet_id) DO UPDATE
SET actor_state_version=EXCLUDED.actor_state_version,
    proposed_str=EXCLUDED.proposed_str,proposed_int=EXCLUDED.proposed_int,proposed_agi=EXCLUDED.proposed_agi,
    generation_operation_id=EXCLUDED.generation_operation_id,
    generation_context_id=EXCLUDED.generation_context_id,
    generation_kind=EXCLUDED.generation_kind,
    generation_content_revision=EXCLUDED.generation_content_revision,
    generation_policy_refs=EXCLUDED.generation_policy_refs,
    created_at=EXCLUDED.created_at,
    updated_at=EXCLUDED.updated_at;

-- name: ReadHeroPracticeCandidate :one
SELECT player_id,session_id::text,partner_id,actor_state_version,proposed_str,proposed_int,proposed_agi,
       generation_operation_id::text,generation_context_id::text,generation_kind,generation_content_revision,
       generation_policy_refs::text,created_at,updated_at
FROM player_hero_practice_candidates
WHERE player_id=$1 AND session_id=$2 AND partner_id=$3;

-- name: LockHeroPracticeCandidate :one
SELECT player_id,session_id::text,partner_id,actor_state_version,proposed_str,proposed_int,proposed_agi,
       generation_operation_id::text,generation_context_id::text,generation_kind,generation_content_revision,
       generation_policy_refs::text,created_at,updated_at
FROM player_hero_practice_candidates
WHERE player_id=$1 AND session_id=$2 AND partner_id=$3 FOR UPDATE;

-- name: DeleteHeroPracticeCandidate :execrows
DELETE FROM player_hero_practice_candidates
WHERE player_id=$1 AND session_id=$2 AND partner_id=$3;

-- name: ReadPetPracticeCandidate :one
SELECT player_id,session_id::text,pet_id,actor_state_version,proposed_str,proposed_int,proposed_agi,
       generation_operation_id::text,generation_context_id::text,generation_kind,generation_content_revision,
       generation_policy_refs::text,created_at,updated_at
FROM player_pet_practice_candidates
WHERE player_id=$1 AND session_id=$2 AND pet_id=$3;

-- name: LockPetPracticeCandidate :one
SELECT player_id,session_id::text,pet_id,actor_state_version,proposed_str,proposed_int,proposed_agi,
       generation_operation_id::text,generation_context_id::text,generation_kind,generation_content_revision,
       generation_policy_refs::text,created_at,updated_at
FROM player_pet_practice_candidates
WHERE player_id=$1 AND session_id=$2 AND pet_id=$3 FOR UPDATE;

-- name: DeletePetPracticeCandidate :execrows
DELETE FROM player_pet_practice_candidates
WHERE player_id=$1 AND session_id=$2 AND pet_id=$3;
