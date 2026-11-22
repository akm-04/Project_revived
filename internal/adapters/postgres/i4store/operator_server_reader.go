package i4store

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const operatorServersJSON = `
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'server_id',logical_server_id,'name',name,
  'open',(existing_login_allowed AND retired_at IS NULL)) ORDER BY logical_server_id),'[]'::jsonb)::text
FROM logical_servers`

// ServerDirectoryReader is I4's operator logical-server read. The
// online_count is joined by the application from the session owner.
type ServerDirectoryReader struct{}

type operatorServerWire struct {
	ServerID int64  `json:"server_id"`
	Name     string `json:"name"`
	Open     bool   `json:"open"`
}

func (ServerDirectoryReader) OperatorServersTx(ctx context.Context, q tx.Queryer) ([]operator.OperatorServer, error) {
	if q == nil {
		return nil, errors.New("invalid operator server read")
	}
	var raw string
	if err := q.QueryRow(ctx, operatorServersJSON).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []operatorServerWire
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]operator.OperatorServer, 0, len(rows))
	for _, row := range rows {
		out = append(out, operator.OperatorServer{ServerID: row.ServerID, Name: row.Name, Open: row.Open})
	}
	return out, nil
}

// PlayerNamesTx reads the display names of a bounded player id set; a missing
// profile is absent from the map, never an error.
func (PlayerDirectoryReader) PlayerNamesTx(ctx context.Context, q tx.Queryer, playerIDs []int64) (map[int64]string, error) {
	out := make(map[int64]string, len(playerIDs))
	if q == nil {
		return nil, errors.New("invalid operator player name read")
	}
	if len(playerIDs) == 0 {
		return out, nil
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_object_agg(player_id::text,name),'{}'::jsonb)::text FROM player_directory_profiles WHERE player_id = ANY($1::bigint[])`, playerIDs).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var names map[string]string
	if err := json.Unmarshal([]byte(raw), &names); err != nil {
		return nil, err
	}
	for text, name := range names {
		id, err := parsePlayerID(text)
		if err != nil {
			return nil, err
		}
		out[id] = name
	}
	return out, nil
}

func parsePlayerID(text string) (int64, error) {
	return strconv.ParseInt(text, 10, 64)
}
