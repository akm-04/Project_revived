-- +goose Up
-- owner: Ranking
-- R7: one durable current score per board and player. The metric remains the
-- owning provider's observation; this table only persists it for board reads
-- and weekly settlement.
CREATE TABLE ranking_board_scores(
 policy text NOT NULL CHECK(policy <> ''),
 logical_server_id bigint NOT NULL,
 player_id bigint NOT NULL REFERENCES players(player_id),
 score bigint NOT NULL CHECK(score >= 0),
 score_since timestamptz NOT NULL,
 revision text NOT NULL CHECK(revision <> ''),
 metric jsonb NOT NULL,
 updated_at timestamptz NOT NULL,
 PRIMARY KEY(policy, player_id)
);
CREATE INDEX ranking_board_scores_order_idx ON ranking_board_scores(policy, logical_server_id, score DESC, score_since, player_id);
