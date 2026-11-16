package rankingstore

import (
	"os"
	"strings"
	"testing"
)

func TestR7RankingBoardScoresMigrationEnvelopeAndShape(t *testing.T) {
	raw, err := os.ReadFile("../../../../migrations/00159_r7_ranking_board_scores.sql")
	if err != nil {
		t.Fatal(err)
	}
	s := string(raw)
	if !strings.HasPrefix(s, "-- +goose Up\n") || strings.Contains(s, "-- +goose Down") {
		t.Fatal("migration violates the forward-only Goose envelope")
	}
	for _, need := range []string{
		"CREATE TABLE ranking_board_scores",
		"PRIMARY KEY(policy, player_id)",
		"REFERENCES players(player_id)",
		"CHECK(score >= 0)",
		"CHECK(policy <> '')",
		"CHECK(revision <> '')",
		"metric jsonb NOT NULL",
		"CREATE INDEX ranking_board_scores_order_idx ON ranking_board_scores(policy, logical_server_id, score DESC, score_since, player_id)",
	} {
		if !strings.Contains(s, need) {
			t.Fatalf("00159 missing %q", need)
		}
	}
}
