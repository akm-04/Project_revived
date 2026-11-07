-- +goose Up
CREATE TABLE player_dorm_room_social (
 player_id bigint NOT NULL CHECK(player_id BETWEEN 100000 AND 9007199254740991),
 house_id bigint NOT NULL,
 house_name text NOT NULL CHECK(char_length(house_name)<=12),
 is_hidden boolean NOT NULL,
 state_version bigint NOT NULL CHECK(state_version>0),
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,house_id),
 FOREIGN KEY(player_id,house_id) REFERENCES player_dorm_rooms(player_id,house_id) ON DELETE CASCADE
);
CREATE TABLE player_dorm_praises (
 player_id bigint NOT NULL CHECK(player_id BETWEEN 100000 AND 9007199254740991),
 house_id bigint NOT NULL,
 actor_player_id bigint NOT NULL CHECK(actor_player_id BETWEEN 100000 AND 9007199254740991 AND actor_player_id<>player_id AND actor_player_id/100000=player_id/100000),
 first_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,house_id,actor_player_id),
 FOREIGN KEY(player_id,house_id) REFERENCES player_dorm_rooms(player_id,house_id) ON DELETE CASCADE
);
CREATE INDEX player_dorm_praises_page ON player_dorm_praises(player_id,house_id,first_at DESC,actor_player_id DESC);
CREATE SEQUENCE player_dorm_comment_id_seq AS bigint MAXVALUE 9007199254740991 NO CYCLE;
CREATE TABLE player_dorm_comments (
 comment_id bigint PRIMARY KEY DEFAULT nextval('player_dorm_comment_id_seq') CHECK(comment_id BETWEEN 1 AND 9007199254740991),
 player_id bigint NOT NULL CHECK(player_id BETWEEN 100000 AND 9007199254740991),
 house_id bigint NOT NULL,
 author_player_id bigint NOT NULL CHECK(author_player_id BETWEEN 100000 AND 9007199254740991 AND author_player_id<>player_id AND author_player_id/100000=player_id/100000),
 content text NOT NULL CHECK(char_length(content) BETWEEN 1 AND 60),
 created_at timestamptz NOT NULL,
 deleted_at timestamptz CHECK(deleted_at>=created_at),
 UNIQUE(player_id,house_id,comment_id),
 FOREIGN KEY(player_id,house_id) REFERENCES player_dorm_rooms(player_id,house_id) ON DELETE CASCADE
);
ALTER SEQUENCE player_dorm_comment_id_seq OWNED BY player_dorm_comments.comment_id;
CREATE INDEX player_dorm_comments_live_page ON player_dorm_comments(player_id,house_id,created_at DESC,comment_id DESC) WHERE deleted_at IS NULL;
CREATE TABLE player_dorm_comment_reactions (
 player_id bigint NOT NULL,
 house_id bigint NOT NULL,
 comment_id bigint NOT NULL,
 actor_player_id bigint NOT NULL CHECK(actor_player_id BETWEEN 100000 AND 9007199254740991 AND actor_player_id/100000=player_id/100000),
 first_at timestamptz NOT NULL,
 PRIMARY KEY(comment_id,actor_player_id),
 FOREIGN KEY(player_id,house_id,comment_id) REFERENCES player_dorm_comments(player_id,house_id,comment_id) ON DELETE CASCADE
);
CREATE INDEX player_dorm_comment_reactions_room ON player_dorm_comment_reactions(player_id,house_id,comment_id);
