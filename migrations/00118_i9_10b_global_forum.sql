-- +goose Up
-- owner: library-forum
-- +goose StatementBegin
DO $$
DECLARE reaction_constraint text;
BEGIN
 IF EXISTS (SELECT 1 FROM library_forum_comments WHERE logical_server_id <> author_player_id / 100000) THEN
  RAISE EXCEPTION 'global forum migration: comment author/server mismatch';
 END IF;
 SELECT conname INTO STRICT reaction_constraint FROM pg_constraint
 WHERE conrelid='library_forum_reactions'::regclass
 AND confrelid='library_forum_comments'::regclass AND contype='f';
 EXECUTE format('ALTER TABLE library_forum_reactions DROP CONSTRAINT %I',reaction_constraint);
END $$;
-- +goose StatementEnd

ALTER TABLE library_forum_reactions DROP CONSTRAINT library_forum_reactions_pkey;
ALTER TABLE library_forum_comments DROP CONSTRAINT library_forum_comments_pkey;
ALTER TABLE library_forum_reactions DROP COLUMN logical_server_id;
ALTER TABLE library_forum_comments DROP COLUMN logical_server_id;
ALTER TABLE library_forum_comments ADD COLUMN retired_at timestamptz;
ALTER TABLE library_forum_comments ADD CONSTRAINT library_forum_comments_retirement_check
 CHECK (retired_at IS NULL OR retired_at >= created_at);
ALTER TABLE library_forum_comments ADD PRIMARY KEY(forum_type,table_id,author_player_id);
ALTER TABLE library_forum_reactions ADD PRIMARY KEY(forum_type,table_id,author_player_id,viewer_player_id);
ALTER TABLE library_forum_reactions ADD CONSTRAINT library_forum_reactions_comment_fkey
 FOREIGN KEY(forum_type,table_id,author_player_id)
 REFERENCES library_forum_comments(forum_type,table_id,author_player_id) ON DELETE CASCADE;

CREATE TABLE library_forum_boards (
 forum_type smallint NOT NULL CHECK (forum_type IN (1,2)),
 table_id bigint NOT NULL CHECK (table_id > 0),
 PRIMARY KEY(forum_type,table_id)
);
INSERT INTO library_forum_boards(forum_type,table_id)
 SELECT DISTINCT forum_type,table_id FROM library_forum_comments;
CREATE INDEX library_forum_comments_live_order
 ON library_forum_comments(forum_type,table_id,created_at,author_player_id) WHERE retired_at IS NULL;

WITH ordered AS (
 SELECT forum_type,table_id,author_player_id,
 row_number() OVER(PARTITION BY forum_type,table_id ORDER BY created_at DESC,author_player_id DESC) AS position
 FROM library_forum_comments
)
UPDATE library_forum_comments AS comments
SET retired_at=GREATEST(statement_timestamp(),comments.created_at,comments.updated_at)
FROM ordered
WHERE ordered.position > 200 AND ordered.forum_type=comments.forum_type
 AND ordered.table_id=comments.table_id AND ordered.author_player_id=comments.author_player_id;
