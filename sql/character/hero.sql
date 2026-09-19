-- owner: character/hero-core
-- name: InsertHeroRoot :execrows
INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)
VALUES ($1,1,0,1,$2,$2)
ON CONFLICT (player_id) DO NOTHING;

-- name: ReadHeroRoot :one
SELECT player_id,next_partner_id,sort_type,state_version,created_at,updated_at
FROM player_hero_roots WHERE player_id=$1;

-- name: LockHeroRoot :one
SELECT player_id,next_partner_id,sort_type,state_version,created_at,updated_at
FROM player_hero_roots WHERE player_id=$1 FOR UPDATE;

-- name: SaveHeroSortType :execrows
UPDATE player_hero_roots SET sort_type=$2,state_version=state_version+1,updated_at=$3
WHERE player_id=$1 AND state_version=$4;

-- name: SaveHeroRootAllocator :execrows
UPDATE player_hero_roots
SET next_partner_id=$2,state_version=state_version+1,updated_at=$3
WHERE player_id=$1 AND state_version=$4;

-- name: InsertPlayerHero :execrows
INSERT INTO player_heroes(
  player_id,partner_id,table_id,origin_table_id,star,level,exp,color,
  equip_1,equip_2,equip_3,equip_4,equip_5,equip_6,
  fumo_1,fumo_2,fumo_3,fumo_4,fumo_5,fumo_6,
  creation_content_revision,state_version,created_at,updated_at
) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24);

-- name: ListPlayerHeroes :one
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'player_id',player_id,'partner_id',partner_id,'table_id',table_id,'origin_table_id',origin_table_id,
  'star',star,'level',level,'exp',exp,'color',color,
  'equip_1',equip_1,'equip_2',equip_2,'equip_3',equip_3,'equip_4',equip_4,'equip_5',equip_5,'equip_6',equip_6,
  'fumo_1',fumo_1,'fumo_2',fumo_2,'fumo_3',fumo_3,'fumo_4',fumo_4,'fumo_5',fumo_5,'fumo_6',fumo_6,
  'practice_str',practice_str,'practice_int',practice_int,'practice_agi',practice_agi,
  'creation_content_revision',creation_content_revision,'state_version',state_version,
  'created_at',created_at,'updated_at',updated_at
) ORDER BY partner_id),'[]'::jsonb)::text
FROM player_heroes WHERE player_id=$1;

-- name: ReadHeroByOrigin :one
SELECT player_id,partner_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,equip_4,equip_5,equip_6,fumo_1,fumo_2,fumo_3,fumo_4,fumo_5,fumo_6,practice_str,practice_int,practice_agi,creation_content_revision,state_version,created_at,updated_at
FROM player_heroes WHERE player_id=$1 AND origin_table_id=$2;

-- name: ReadHeroByPartnerID :one
SELECT player_id,partner_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,equip_4,equip_5,equip_6,fumo_1,fumo_2,fumo_3,fumo_4,fumo_5,fumo_6,practice_str,practice_int,practice_agi,creation_content_revision,state_version,created_at,updated_at
FROM player_heroes WHERE player_id=$1 AND partner_id=$2;

-- name: LockHeroByPartnerID :one
SELECT player_id,partner_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,equip_4,equip_5,equip_6,fumo_1,fumo_2,fumo_3,fumo_4,fumo_5,fumo_6,practice_str,practice_int,practice_agi,creation_content_revision,state_version,created_at,updated_at
FROM player_heroes WHERE player_id=$1 AND partner_id=$2 FOR UPDATE;

-- name: SaveHeroProgression :execrows
UPDATE player_heroes
SET star=$3,level=$4,exp=$5,state_version=state_version+1,updated_at=$6
WHERE player_id=$1 AND partner_id=$2 AND state_version=$7;

-- name: SaveHeroState :execrows
UPDATE player_heroes
SET star=$3,level=$4,exp=$5,color=$6,
    equip_1=$7,equip_2=$8,equip_3=$9,equip_4=$10,equip_5=$11,equip_6=$12,
    fumo_1=$13,fumo_2=$14,fumo_3=$15,fumo_4=$16,fumo_5=$17,fumo_6=$18,
    state_version=state_version+1,updated_at=$19
WHERE player_id=$1 AND partner_id=$2 AND state_version=$20;

-- name: SaveHeroPractice :execrows
UPDATE player_heroes
SET practice_str=$3,practice_int=$4,practice_agi=$5,state_version=state_version+1,updated_at=$6
WHERE player_id=$1 AND partner_id=$2 AND state_version=$7;
