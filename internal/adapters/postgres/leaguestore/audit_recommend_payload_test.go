package leaguestore

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/tx"
)

type auditRecommendQuery struct{ rows []string }
type auditRecommendRow string

func (q *auditRecommendQuery) QueryRow(context.Context, string, ...any) tx.Row {
	row := q.rows[0]
	q.rows = q.rows[1:]
	return auditRecommendRow(row)
}
func (r auditRecommendRow) Scan(destinations ...any) error {
	if len(destinations) != 1 {
		return fmt.Errorf("unexpected columns %d", len(destinations))
	}
	*destinations[0].(*string) = string(r)
	return nil
}

func TestAuditA066RecommendationDecodesSQLPayloadEnvelope(t *testing.T) {
	for _, version := range []int16{0, 1} {
		for _, table := range []string{"league_players", "league_matches"} {
			t.Run(fmt.Sprintf("%s/version%d", table, version), func(t *testing.T) {
				raw, err := os.ReadFile("testdata/payloads/" + table + ".payload/v0.json")
				if err != nil {
					t.Fatal(err)
				}
				rows, err := json.Marshal([]map[string]any{{"player_id": int64(190001), "attacker": int64(190001), "payload": json.RawMessage(raw), "version": version}})
				if err != nil {
					t.Fatal(err)
				}
				query := &auditRecommendQuery{rows: []string{"[]", "[]"}}
				if table == "league_players" {
					query.rows[0] = string(rows)
				} else {
					query.rows[1] = string(rows)
				}
				result, err := (Store{}).HeroRecommendSourceTx(context.Background(), query, 1, time.Now().UTC(), 10)
				if err != nil {
					t.Fatal("SQL-built payload/version envelope rejected:", err)
				}
				if table == "league_players" && (len(result.Formations) != 1 || len(result.Formations[0].PartnerIDs) == 0) {
					t.Fatalf("missing defense formation: %+v", result)
				}
				if table == "league_matches" && len(result.Popularity) == 0 {
					t.Fatalf("missing match popularity: %+v", result)
				}
			})
		}
	}
}
