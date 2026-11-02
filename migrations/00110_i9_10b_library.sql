-- +goose Up
-- owner: library-local-progression
-- I9_LIBRARY_V1 B1: board and background selection live on the existing Library root.
ALTER TABLE player_library_roots ADD COLUMN board_partner bigint NOT NULL DEFAULT 0 CHECK (board_partner >= 0);
ALTER TABLE player_library_roots ADD COLUMN board_card bigint NOT NULL DEFAULT 0 CHECK (board_card BETWEEN 0 AND 3);
ALTER TABLE player_library_roots ADD COLUMN board_model_id bigint NOT NULL DEFAULT 0 CHECK (board_model_id >= 0);
ALTER TABLE player_library_roots ADD COLUMN bg_main bigint NOT NULL DEFAULT 1 CHECK (bg_main > 0);
ALTER TABLE player_library_roots ADD COLUMN bg_room bigint NOT NULL DEFAULT 2 CHECK (bg_room > 0);
-- A cleared board has no card or model. A set board has CardStatus 1..3.
ALTER TABLE player_library_roots ADD CONSTRAINT player_library_roots_board_shape_check CHECK (
 (board_partner = 0 AND board_card = 0 AND board_model_id = 0) OR
 (board_partner > 0 AND board_card BETWEEN 1 AND 3)
);

-- owner: library-local-progression
-- One row per opened dialog. is_awarded/select_id are served even when zero.
CREATE TABLE player_library_dialogs (
 player_id bigint NOT NULL,
 partner_id bigint NOT NULL CHECK (partner_id > 0),
 dialog_id bigint NOT NULL CHECK (dialog_id > 0),
 is_read boolean NOT NULL,
 is_awarded boolean NOT NULL,
 select_id bigint NOT NULL DEFAULT 0 CHECK (select_id >= 0),
 updated_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, partner_id, dialog_id),
 FOREIGN KEY (player_id, partner_id) REFERENCES player_library_heroes(player_id, partner_id)
);
-- Materialized partner missions, states 1..4 (enums.lua LibraryMissionState).
CREATE TABLE player_library_partner_missions (
 player_id bigint NOT NULL,
 partner_id bigint NOT NULL CHECK (partner_id > 0),
 mission_id bigint NOT NULL CHECK (mission_id > 0),
 process bigint NOT NULL CHECK (process >= 0),
 mission_state bigint NOT NULL CHECK (mission_state BETWEEN 1 AND 4),
 updated_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, partner_id, mission_id),
 FOREIGN KEY (player_id, partner_id) REFERENCES player_library_heroes(player_id, partner_id)
);
-- Once per hero and act id 1..4.
CREATE TABLE player_library_act_awards (
 player_id bigint NOT NULL,
 partner_id bigint NOT NULL CHECK (partner_id > 0),
 act_id bigint NOT NULL CHECK (act_id BETWEEN 1 AND 4),
 awarded_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, partner_id, act_id),
 FOREIGN KEY (player_id, partner_id) REFERENCES player_library_heroes(player_id, partner_id)
);
-- School story claim, once per talk id.
CREATE TABLE player_library_talk_claims (
 player_id bigint NOT NULL,
 talk_id bigint NOT NULL CHECK (talk_id > 0),
 claimed_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, talk_id),
 FOREIGN KEY (player_id) REFERENCES player_library_roots(player_id)
);
-- Memory CG claim, once per cg id.
CREATE TABLE player_library_cg_claims (
 player_id bigint NOT NULL,
 cg_id bigint NOT NULL CHECK (cg_id > 0),
 claimed_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, cg_id),
 FOREIGN KEY (player_id) REFERENCES player_library_roots(player_id)
);
-- Paid background ownership; limit=0 rows are free and are not stored.
CREATE TABLE player_library_backgrounds (
 player_id bigint NOT NULL,
 bg_id bigint NOT NULL CHECK (bg_id > 0),
 unlocked_at timestamptz NOT NULL,
 PRIMARY KEY (player_id, bg_id),
 FOREIGN KEY (player_id) REFERENCES player_library_roots(player_id)
);

-- owner: library-forum
-- Cross-player rows for one logical server, shared-family lock rank 606.
-- One comment per author per (forum_type, table_id); text is at most 32 UTF-8 chars.
CREATE TABLE library_forum_comments (
 logical_server_id integer NOT NULL REFERENCES logical_servers(logical_server_id),
 forum_type smallint NOT NULL CHECK (forum_type IN (1, 2)),
 table_id bigint NOT NULL CHECK (table_id > 0),
 author_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 comment text NOT NULL CHECK (char_length(comment) BETWEEN 1 AND 32),
 created_at timestamptz NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY (logical_server_id, forum_type, table_id, author_player_id)
);
-- One like per viewer per comment; the reply count is derived from these rows.
CREATE TABLE library_forum_reactions (
 logical_server_id integer NOT NULL,
 forum_type smallint NOT NULL CHECK (forum_type IN (1, 2)),
 table_id bigint NOT NULL CHECK (table_id > 0),
 author_player_id bigint NOT NULL,
 viewer_player_id bigint NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
 created_at timestamptz NOT NULL,
 PRIMARY KEY (logical_server_id, forum_type, table_id, author_player_id, viewer_player_id),
 FOREIGN KEY (logical_server_id, forum_type, table_id, author_player_id)
  REFERENCES library_forum_comments(logical_server_id, forum_type, table_id, author_player_id) ON DELETE CASCADE
);

-- owner: library-local-progression
-- I9_LIBRARY_V1 C21: unique claim targets for the new command families.
ALTER TABLE player_library_admissions DROP CONSTRAINT player_library_admissions_family_check;
ALTER TABLE player_library_admissions ADD CONSTRAINT player_library_admissions_family_check CHECK (family IN (
 'LIBRARY_GIFT','LIBRARY_FEED','LIBRARY_SAVE','LIBRARY_NORMAL_CLAIM','LIBRARY_SPECIAL_CLAIM',
 'LIBRARY_BUY_GIFT','LIBRARY_BOARD','LIBRARY_TALK_AWARD','LIBRARY_ACT_AWARD','LIBRARY_SCHOOL_STORY',
 'LIBRARY_CG','LIBRARY_BG','LIBRARY_MISSION_AWARD'
));

-- owner: course
-- D485: 0 = never consumed. is_has_gift is gift_box_day != today (F7 05:00 GMT+8).
ALTER TABLE player_course_roots ADD COLUMN gift_box_day bigint NOT NULL DEFAULT 0 CHECK (gift_box_day >= 0);
