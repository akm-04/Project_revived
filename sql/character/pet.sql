-- owner: character/pet-core
-- name: InsertPetRoot :execrows
INSERT INTO player_pet_roots(player_id,next_pet_id,state_version,created_at,updated_at)
VALUES ($1,1,1,$2,$2)
ON CONFLICT (player_id) DO NOTHING;

-- name: ReadPetRoot :one
SELECT player_id,next_pet_id,first_free_hatch_used,state_version,created_at,updated_at
FROM player_pet_roots WHERE player_id=$1;

-- name: LockPetRoot :one
SELECT player_id,next_pet_id,first_free_hatch_used,state_version,created_at,updated_at
FROM player_pet_roots WHERE player_id=$1 FOR UPDATE;

-- name: SavePetRootAllocator :execrows
UPDATE player_pet_roots
SET next_pet_id=$2,state_version=state_version+1,updated_at=$3
WHERE player_id=$1 AND state_version=$4;


-- name: SavePetRootFreeHatch :execrows
UPDATE player_pet_roots
SET first_free_hatch_used=$2,state_version=state_version+1,updated_at=$3
WHERE player_id=$1 AND state_version=$4;

-- name: SavePetShowState :execrows
UPDATE player_pets
SET is_show=$3,state_version=state_version+1,updated_at=$4
WHERE player_id=$1 AND pet_id=$2 AND state_version=$5;

-- name: InsertPlayerPet :execrows
INSERT INTO player_pets(
  player_id,pet_id,table_id,origin_table_id,star,level,exp,color,birthday,is_show,
  skill_1,skill_2,skill_3,skill_4,skill_5,equip_1,equip_2,equip_3,fumo_1,fumo_2,fumo_3,creation_content_revision,state_version,created_at,updated_at
) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25);

-- name: ListPlayerPets :one
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'player_id',player_id,'pet_id',pet_id,'table_id',table_id,'origin_table_id',origin_table_id,
  'star',star,'level',level,'exp',exp,'color',color,
  'skill_1',skill_1,'skill_2',skill_2,'skill_3',skill_3,'skill_4',skill_4,'skill_5',skill_5,
  'birthday',birthday,'is_show',is_show,'equip_1',equip_1,'equip_2',equip_2,'equip_3',equip_3,'fumo_1',fumo_1,'fumo_2',fumo_2,'fumo_3',fumo_3,
  'practice_str',practice_str,'practice_int',practice_int,'practice_agi',practice_agi,'creation_content_revision',creation_content_revision,'state_version',state_version,
  'created_at',created_at,'updated_at',updated_at
) ORDER BY pet_id),'[]'::jsonb)::text
FROM player_pets WHERE player_id=$1;

-- name: ReadPetByOrigin :one
SELECT player_id,pet_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,fumo_1,fumo_2,fumo_3,skill_1,skill_2,skill_3,skill_4,skill_5,birthday,is_show,
       practice_str,practice_int,practice_agi,creation_content_revision,state_version,created_at,updated_at
FROM player_pets WHERE player_id=$1 AND origin_table_id=$2;

-- name: ReadPetByID :one
SELECT player_id,pet_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,fumo_1,fumo_2,fumo_3,skill_1,skill_2,skill_3,skill_4,skill_5,birthday,is_show,
       practice_str,practice_int,practice_agi,creation_content_revision,state_version,created_at,updated_at
FROM player_pets WHERE player_id=$1 AND pet_id=$2;

-- name: LockPetByID :one
SELECT player_id,pet_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,fumo_1,fumo_2,fumo_3,skill_1,skill_2,skill_3,skill_4,skill_5,birthday,is_show,
       practice_str,practice_int,practice_agi,creation_content_revision,state_version,created_at,updated_at
FROM player_pets WHERE player_id=$1 AND pet_id=$2 FOR UPDATE;


-- name: SavePetState :execrows
UPDATE player_pets
SET star=$3,level=$4,exp=$5,color=$6,skill_1=$7,skill_2=$8,skill_3=$9,skill_4=$10,skill_5=$11,
    equip_1=$12,equip_2=$13,equip_3=$14,fumo_1=$15,fumo_2=$16,fumo_3=$17,state_version=state_version+1,updated_at=$18
WHERE player_id=$1 AND pet_id=$2 AND state_version=$19;

-- name: SavePetPractice :execrows
UPDATE player_pets
SET practice_str=$3,practice_int=$4,practice_agi=$5,state_version=state_version+1,updated_at=$6
WHERE player_id=$1 AND pet_id=$2 AND state_version=$7;
