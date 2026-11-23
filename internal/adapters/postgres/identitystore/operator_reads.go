package identitystore

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// OnlineCountsByServerTx counts the gameplay contexts per logical server whose
// session was active within the presence window. A revoked or quiet session is
// not online even while its context row is still open.
func (Store) OnlineCountsByServerTx(ctx context.Context, q tx.Queryer) (map[int64]int64, error) {
	if q == nil {
		return nil, errors.New("invalid online count read")
	}
	onlineSince := time.Now().UTC().Add(-identity.PresenceOnlineWindow)
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_object_agg(server_id::text,count),'{}'::jsonb)::text FROM (
SELECT c.logical_server_id AS server_id, count(*) AS count
FROM gameplay_contexts c JOIN account_sessions s ON s.session_id=c.session_id
WHERE c.ended_at IS NULL AND s.revoked_at IS NULL AND s.last_activity_at > $1
GROUP BY c.logical_server_id) rows`, onlineSince).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var counts map[string]int64
	if err := json.Unmarshal([]byte(raw), &counts); err != nil {
		return nil, err
	}
	out := make(map[int64]int64, len(counts))
	for server, count := range counts {
		id, err := strconv.ParseInt(server, 10, 64)
		if err != nil {
			return nil, err
		}
		out[id] = count
	}
	return out, nil
}

type onlineSessionWire struct {
	SessionID  string    `json:"session_id"`
	PlayerID   int64     `json:"player_id"`
	ServerID   int64     `json:"server_id"`
	StartedAt  time.Time `json:"started_at"`
	LastSeenAt time.Time `json:"last_seen_at"`
	Online     bool      `json:"online"`
}

// ListOnlineSessionsTx pages live sessions by session id. A nil ServerID
// selects every logical server. The caller asks for one row more than the page
// so it can report an exact next cursor.
func (Store) ListOnlineSessionsTx(ctx context.Context, q tx.Queryer, filter operator.OnlineSessionFilter) ([]operator.OnlineSession, error) {
	if q == nil || filter.Limit < 1 {
		return nil, errors.New("invalid online session read")
	}
	var server any
	if filter.ServerID != nil {
		server = int32(*filter.ServerID)
	}
	var after any
	if filter.After != "" {
		after = filter.After
	}
	var raw string
	onlineSince := time.Now().UTC().Add(-identity.PresenceOnlineWindow)
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'session_id',session_id::text,'player_id',player_id,'server_id',server_id,
  'started_at',started_at,'last_seen_at',last_seen_at,'online',online) ORDER BY session_id),'[]'::jsonb)::text
FROM (SELECT s.session_id, s.issued_at AS started_at, s.last_activity_at AS last_seen_at,
             (s.last_activity_at > $4) AS online, c.player_id, c.logical_server_id AS server_id
      FROM gameplay_contexts c JOIN account_sessions s ON s.session_id=c.session_id
      WHERE c.ended_at IS NULL AND s.revoked_at IS NULL
        AND ($1::int IS NULL OR c.logical_server_id=$1)
        AND ($2::uuid IS NULL OR s.session_id > $2::uuid)
      ORDER BY s.session_id LIMIT $3) rows`, server, after, filter.Limit, onlineSince).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []onlineSessionWire
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]operator.OnlineSession, 0, len(rows))
	for _, row := range rows {
		out = append(out, operator.OnlineSession{
			SessionID: row.SessionID, PlayerID: row.PlayerID, ServerID: row.ServerID,
			StartedAt: row.StartedAt.UTC(), LastSeenAt: row.LastSeenAt.UTC(), Online: row.Online,
		})
	}
	return out, nil
}
