-- +goose Up
-- CharacterHero owns canonical raw skill facts. Controlled upgrade before admission.
ALTER TABLE player_heroes ADD COLUMN raw_skill_1 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_2 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_3 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_4 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_5 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_6 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_id_1 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_id_2 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_id_3 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_id_4 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_id_5 bigint;
ALTER TABLE player_heroes ADD COLUMN raw_skill_id_6 bigint;
ALTER TABLE player_heroes ADD COLUMN skill_seed_policy_id text;
UPDATE player_heroes SET raw_skill_1=1,raw_skill_2=1,raw_skill_3=1,raw_skill_4=1,raw_skill_5=1,raw_skill_6=1,raw_skill_id_1=0,raw_skill_id_2=0,raw_skill_id_3=0,raw_skill_id_4=0,raw_skill_id_5=0,raw_skill_id_6=0,skill_seed_policy_id='I7C2A_V1_RAW_SKILL_SEED_V1',state_version=state_version+1,updated_at=transaction_timestamp() WHERE skill_seed_policy_id IS NULL;
ALTER TABLE player_heroes ALTER COLUMN raw_skill_1 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_1 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_2 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_2 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_3 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_3 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_4 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_4 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_5 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_5 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_6 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_6 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_id_1 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_id_1 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_id_2 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_id_2 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_id_3 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_id_3 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_id_4 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_id_4 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_id_5 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_id_5 >= 0);
ALTER TABLE player_heroes ALTER COLUMN raw_skill_id_6 SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (raw_skill_id_6 >= 0);
ALTER TABLE player_heroes ALTER COLUMN skill_seed_policy_id SET NOT NULL;
ALTER TABLE player_heroes ADD CHECK (skill_seed_policy_id <> '');
-- ContentRegistry owns the immutable per-revision skill ID/choice catalog.
-- Old revision rows remain NULL, never rewritten or qualified as new skill content.
ALTER TABLE gxb_content_hero_templates ADD COLUMN skill_slots jsonb;
ALTER TABLE gxb_content_hero_templates ADD CHECK (skill_slots IS NULL OR (jsonb_typeof(skill_slots)='array' AND jsonb_array_length(skill_slots)=6));
