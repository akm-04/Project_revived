-- +goose Up
CREATE TABLE player_profile_comments (
 comment_id bigint GENERATED ALWAYS AS IDENTITY (MINVALUE 1 MAXVALUE 9007199254740991 NO CYCLE) PRIMARY KEY,
 target_player_id bigint NOT NULL REFERENCES player_profile_feedback_roots(player_id),
 author_player_id bigint NOT NULL CHECK(author_player_id>0 AND author_player_id<=9007199254740991 AND author_player_id<>target_player_id),
 content text NOT NULL CHECK(char_length(content) BETWEEN 1 AND 30),
 created_at timestamptz NOT NULL,
 created_root_version bigint NOT NULL CHECK(created_root_version>0),
 deleted_at timestamptz,
 deleted_root_version bigint,
 CHECK((deleted_at IS NULL AND deleted_root_version IS NULL) OR (deleted_at IS NOT NULL AND deleted_root_version IS NOT NULL AND deleted_root_version>created_root_version))
);
CREATE INDEX player_profile_comments_live_page ON player_profile_comments(target_player_id,created_at DESC,comment_id DESC) WHERE deleted_at IS NULL;
CREATE TABLE player_profile_comment_reactions (
 comment_id bigint NOT NULL REFERENCES player_profile_comments(comment_id),
 actor_player_id bigint NOT NULL CHECK(actor_player_id>0 AND actor_player_id<=9007199254740991),
 first_at timestamptz NOT NULL,
 root_version bigint NOT NULL CHECK(root_version>0),
 PRIMARY KEY(comment_id,actor_player_id)
);
-- Control identity precedes the gameplay transaction and survives its rollback.
-- Terminal state is retained forever; it never confers another occurrence ID.
CREATE TABLE player_profile_comment_operations (
 operation_id uuid PRIMARY KEY,
 actor_player_id bigint NOT NULL CHECK(actor_player_id>0 AND actor_player_id<=9007199254740991),
 target_player_id bigint NOT NULL CHECK(target_player_id>0 AND target_player_id<=9007199254740991),
 account_uid text NOT NULL,
 admission_payload jsonb NOT NULL CHECK(jsonb_typeof(admission_payload)='object'),
 state text NOT NULL CHECK(state IN ('PENDING','COMMITTED','ABORTED'))
);
CREATE UNIQUE INDEX player_profile_comment_pending_actor ON player_profile_comment_operations(actor_player_id) WHERE state='PENDING';
