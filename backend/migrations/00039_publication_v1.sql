-- +goose Up
-- PUBLICATION_V1 neutral expansion; no import or fabricated historical read state.
CREATE TABLE publication_sets (
 set_id uuid PRIMARY KEY,
 family text NOT NULL CHECK (family IN ('announcement','board','picture')),
 server_id integer NOT NULL CHECK (server_id>=0 AND (family<>'announcement' OR server_id=0)),
 starts_at timestamptz NOT NULL,
 ends_at timestamptz NULL CHECK (ends_at IS NULL OR ends_at>starts_at),
 install_sequence bigint GENERATED ALWAYS AS IDENTITY UNIQUE,
 input_digest text NOT NULL CHECK (length(input_digest)=64),
 UNIQUE (set_id,family)
);
CREATE INDEX publication_selection ON publication_sets(family,server_id,starts_at DESC,install_sequence DESC);
CREATE TABLE publication_items (
 set_id uuid NOT NULL REFERENCES publication_sets(set_id),
 position integer NOT NULL CHECK(position>=0),
 board_wire_id bigint NULL UNIQUE CHECK(board_wire_id>0 AND board_wire_id<=9007199254740991),
 payload jsonb NOT NULL,
 PRIMARY KEY(set_id,position)
);
CREATE TABLE publication_picture_reads (
 player_id bigint NOT NULL REFERENCES players(player_id),
 set_id uuid NOT NULL,
 family text NOT NULL DEFAULT 'picture' CHECK(family='picture'),
 read_at timestamptz NOT NULL,
 PRIMARY KEY(player_id,set_id),
 FOREIGN KEY(set_id,family) REFERENCES publication_sets(set_id,family)
);
-- Forward-only: revisions and referenced markers are retained together by consistent backup/restore.
