-- +goose Up
-- owner: i5/player-core/function-state
-- I8.5-6 F1 (D59 private policy): production now announces every pure level
-- gate a player reached (and opens the level-1 gates at birth). Existing
-- players get the same rows from the active content revision: eligibility for
-- each reached pure level gate, an unlock for each announced (capability NONE)
-- one. Pet Function 38 keeps its own starter-egg path and is not backfilled.
WITH active AS (
  SELECT revision_id FROM gxb_content_activation WHERE slot = 'content'
), reached AS (
  SELECT p.player_id, g.function_id, a.revision_id, g.source_fact_key, g.announcement_capability
  FROM player_progression p
  JOIN gxb_content_function_gates g ON g.gate_kind = 'PURE_LEVEL' AND g.required_level <= p.level
  JOIN active a ON a.revision_id = g.revision_id
  JOIN player_function_state_owners o ON o.player_id = p.player_id
), eligible AS (
  INSERT INTO player_function_eligibility(player_id, function_id, content_revision, source_fact_key, eligible_at)
  SELECT player_id, function_id, revision_id, 'i8.5-6:function-backfill:v1:' || player_id || ':' || function_id, clock_timestamp()
  FROM reached
  ON CONFLICT (player_id, function_id) DO NOTHING
)
INSERT INTO player_function_unlocks(player_id, function_id, opened_at, source_fact_key, state_version)
SELECT player_id, function_id, clock_timestamp(), 'i8.5-6:function-backfill:v1:' || player_id || ':' || function_id, 1
FROM reached
WHERE announcement_capability = 'NONE'
ON CONFLICT (player_id, function_id) DO NOTHING;

UPDATE player_function_state_owners o
SET state_version = state_version + 1, updated_at = clock_timestamp()
WHERE EXISTS (SELECT 1 FROM player_function_unlocks u WHERE u.player_id = o.player_id AND u.source_fact_key LIKE 'i8.5-6:function-backfill:v1:%');
