-- owner: character/saved-preset
-- name: InsertSavedPresetRoot :execrows
INSERT INTO player_saved_preset_roots(player_id,state_version,created_at,updated_at)
VALUES ($1,1,$2,$2)
ON CONFLICT (player_id) DO NOTHING;

-- name: ReadSavedPresetAggregate :one
SELECT r.player_id,r.state_version,r.created_at,r.updated_at,
       COALESCE((
         SELECT jsonb_agg(jsonb_build_object(
           'lane_ordinal',l.lane_ordinal,
           'name',l.name,
           'pet_id',l.pet_id,
           'heroes',COALESCE((
             SELECT jsonb_agg(jsonb_build_object(
               'hero_ordinal',h.hero_ordinal,'partner_id',h.partner_id
             ) ORDER BY h.hero_ordinal)
             FROM player_saved_preset_heroes h
             WHERE h.player_id=l.player_id AND h.lane_ordinal=l.lane_ordinal
           ),'[]'::jsonb)
         ) ORDER BY l.lane_ordinal)
         FROM player_saved_preset_lanes l WHERE l.player_id=r.player_id
       ),'[]'::jsonb)::text
FROM player_saved_preset_roots r WHERE r.player_id=$1;

-- name: LockSavedPresetRoot :one
SELECT player_id,state_version,created_at,updated_at
FROM player_saved_preset_roots WHERE player_id=$1 FOR UPDATE;

-- name: DeleteSavedPresetLanes :execrows
DELETE FROM player_saved_preset_lanes WHERE player_id=$1;

-- name: InsertSavedPresetLane :execrows
INSERT INTO player_saved_preset_lanes(player_id,lane_ordinal,name,pet_id)
VALUES ($1,$2,$3,$4);

-- name: InsertSavedPresetHero :execrows
INSERT INTO player_saved_preset_heroes(player_id,lane_ordinal,hero_ordinal,partner_id)
VALUES ($1,$2,$3,$4);

-- name: SaveSavedPresetRootVersion :execrows
UPDATE player_saved_preset_roots
SET state_version=state_version+1,updated_at=$2
WHERE player_id=$1 AND state_version=$3;

-- name: SavedPresetReferencesHero :one
SELECT EXISTS (
  SELECT 1
  FROM player_saved_preset_heroes
  WHERE player_id=$1 AND partner_id=$2
);

-- name: SavedPresetReferencesPet :one
SELECT EXISTS (
  SELECT 1
  FROM player_saved_preset_lanes
  WHERE player_id=$1 AND pet_id=$2
);
