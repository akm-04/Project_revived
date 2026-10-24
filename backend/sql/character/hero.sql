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
  current_skin_id,illusion_skin_id,creation_content_revision,state_version,created_at,updated_at,is_like,raw_skill_1,raw_skill_2,raw_skill_3,raw_skill_4,raw_skill_5,raw_skill_6,raw_skill_id_1,raw_skill_id_2,raw_skill_id_3,raw_skill_id_4,raw_skill_id_5,raw_skill_id_6,skill_seed_policy_id
) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$40);

-- name: ListPlayerHeroes :one
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'player_id',player_id,'partner_id',partner_id,'table_id',table_id,'origin_table_id',origin_table_id,
  'star',star,'level',level,'exp',exp,'color',color,
  'equip_1',equip_1,'equip_2',equip_2,'equip_3',equip_3,'equip_4',equip_4,'equip_5',equip_5,'equip_6',equip_6,
  'fumo_1',fumo_1,'fumo_2',fumo_2,'fumo_3',fumo_3,'fumo_4',fumo_4,'fumo_5',fumo_5,'fumo_6',fumo_6,
  'practice_str',practice_str,'practice_int',practice_int,'practice_agi',practice_agi,
  'is_like',is_like,'current_skin_id',current_skin_id,'illusion_skin_id',illusion_skin_id,
  'creation_content_revision',creation_content_revision,'state_version',state_version,
  'created_at',created_at,'updated_at',updated_at,'raw_skill_1',raw_skill_1,'raw_skill_2',raw_skill_2,'raw_skill_3',raw_skill_3,'raw_skill_4',raw_skill_4,'raw_skill_5',raw_skill_5,'raw_skill_6',raw_skill_6,'raw_skill_id_1',raw_skill_id_1,'raw_skill_id_2',raw_skill_id_2,'raw_skill_id_3',raw_skill_id_3,'raw_skill_id_4',raw_skill_id_4,'raw_skill_id_5',raw_skill_id_5,'raw_skill_id_6',raw_skill_id_6,'skill_seed_policy_id',skill_seed_policy_id
) ORDER BY partner_id),'[]'::jsonb)::text
FROM player_heroes WHERE player_id=$1;

-- name: ReadHeroByOrigin :one
SELECT player_id,partner_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,equip_4,equip_5,equip_6,fumo_1,fumo_2,fumo_3,fumo_4,fumo_5,fumo_6,practice_str,practice_int,practice_agi,current_skin_id,illusion_skin_id,is_like,creation_content_revision,state_version,created_at,updated_at,raw_skill_1,raw_skill_2,raw_skill_3,raw_skill_4,raw_skill_5,raw_skill_6,raw_skill_id_1,raw_skill_id_2,raw_skill_id_3,raw_skill_id_4,raw_skill_id_5,raw_skill_id_6,skill_seed_policy_id
FROM player_heroes WHERE player_id=$1 AND origin_table_id=$2;

-- name: ReadHeroByPartnerID :one
SELECT player_id,partner_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,equip_4,equip_5,equip_6,fumo_1,fumo_2,fumo_3,fumo_4,fumo_5,fumo_6,practice_str,practice_int,practice_agi,current_skin_id,illusion_skin_id,is_like,creation_content_revision,state_version,created_at,updated_at,raw_skill_1,raw_skill_2,raw_skill_3,raw_skill_4,raw_skill_5,raw_skill_6,raw_skill_id_1,raw_skill_id_2,raw_skill_id_3,raw_skill_id_4,raw_skill_id_5,raw_skill_id_6,skill_seed_policy_id
FROM player_heroes WHERE player_id=$1 AND partner_id=$2;

-- name: LockHeroByPartnerID :one
SELECT player_id,partner_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,equip_4,equip_5,equip_6,fumo_1,fumo_2,fumo_3,fumo_4,fumo_5,fumo_6,practice_str,practice_int,practice_agi,current_skin_id,illusion_skin_id,is_like,creation_content_revision,state_version,created_at,updated_at,raw_skill_1,raw_skill_2,raw_skill_3,raw_skill_4,raw_skill_5,raw_skill_6,raw_skill_id_1,raw_skill_id_2,raw_skill_id_3,raw_skill_id_4,raw_skill_id_5,raw_skill_id_6,skill_seed_policy_id
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

-- CA7-2 appearance foundation. These queries are persistence primitives only;
-- CA7-2 does not route stock appearance mutation MIDs. Child writes must be
-- composed with the owner-version CAS in the same caller-owned transaction.

-- name: SaveHeroAppearanceSelectors :execrows
UPDATE player_heroes
SET current_skin_id=$3,illusion_skin_id=$4,state_version=state_version+1,updated_at=$5
WHERE player_id=$1 AND partner_id=$2 AND state_version=$6;

-- name: TouchHeroAppearanceVersion :execrows
UPDATE player_heroes
SET state_version=state_version+1,updated_at=$3
WHERE player_id=$1 AND partner_id=$2 AND state_version=$4;

-- name: ListHeroSkinEntitlements :one
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'model_id',model_id,'expires_at',expires_at
) ORDER BY model_id),'[]'::jsonb)::text
FROM player_hero_skin_entitlements
WHERE player_id=$1 AND partner_id=$2;

-- name: UpsertHeroSkinEntitlement :execrows
INSERT INTO player_hero_skin_entitlements(player_id,partner_id,model_id,expires_at)
VALUES ($1,$2,$3,$4)
ON CONFLICT (player_id,partner_id,model_id)
DO UPDATE SET expires_at=EXCLUDED.expires_at;

-- name: ListHeroLIVEEntitlements :one
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'model_id',model_id,'is_show',is_show
) ORDER BY model_id),'[]'::jsonb)::text
FROM player_hero_live_entitlements
WHERE player_id=$1 AND partner_id=$2;

-- name: UpsertHeroLIVEEntitlement :execrows
INSERT INTO player_hero_live_entitlements(player_id,partner_id,model_id,is_show)
VALUES ($1,$2,$3,$4)
ON CONFLICT (player_id,partner_id,model_id)
DO UPDATE SET is_show=EXCLUDED.is_show;

-- name: SaveHeroBookmark :execrows
UPDATE player_heroes SET is_like=$3,state_version=state_version+1,updated_at=$4
WHERE player_id=$1 AND partner_id=$2 AND state_version=$5;

-- name: SaveHeroSkillChoice :execrows
UPDATE player_heroes SET raw_skill_id_1=$3,raw_skill_id_2=$4,raw_skill_id_3=$5,raw_skill_id_4=$6,raw_skill_id_5=$7,raw_skill_id_6=$8,state_version=state_version+1,updated_at=$9
WHERE player_id=$1 AND partner_id=$2 AND state_version=$10;
