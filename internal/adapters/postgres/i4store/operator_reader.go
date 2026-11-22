package i4store

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type operatorPlayerWire struct {
	PlayerID        int64      `json:"player_id"`
	AccountUID      string     `json:"account_uid"`
	Name            string     `json:"name"`
	Level           int64      `json:"lev"`
	LogicalServerID int64      `json:"logical_server_id"`
	CreatedAt       time.Time  `json:"created_at"`
	LastLoginAt     *time.Time `json:"last_login_at"`
}

const operatorPlayerProjection = `jsonb_build_object('player_id',p.player_id,'account_uid',a.account_uid,'name',d.name,'lev',d.lev,'logical_server_id',p.logical_server_id,'created_at',p.created_at,'last_login_at',o.last_login_at)`

// FindPlayersTx applies the bounded prefix/uid/server filters in one scoped
// statement; an empty filter is refused rather than enumerated.
func (PlayerDirectoryReader) FindPlayersTx(ctx context.Context, q tx.Queryer, filter playerdirectory.OperatorFind) ([]playerdirectory.OperatorPlayer, error) {
	if q == nil || (filter.UID == "" && filter.NamePrefix == "") || filter.Limit < 1 {
		return nil, errors.New("invalid operator player find")
	}
	var serverID int64
	if filter.ServerID != nil {
		serverID = *filter.ServerID
	}
	prefix := escapeLikePrefix(filter.NamePrefix)
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(row),'[]'::jsonb)::text FROM (
SELECT `+operatorPlayerProjection+` AS row
FROM players p
JOIN player_directory_profiles d ON d.player_id=p.player_id
JOIN accounts a ON a.account_id=p.account_id
LEFT JOIN player_login_observations o ON o.player_id=p.player_id
WHERE ($1='' OR a.account_uid=$1)
  AND ($2='' OR d.name ILIKE $2 ESCAPE '\')
  AND ($3=0 OR p.logical_server_id=$3)
ORDER BY p.player_id
LIMIT $4) scoped`, filter.UID, prefix, serverID, filter.Limit).Scan(&raw)
	if err != nil {
		return nil, err
	}
	return decodeOperatorPlayers(raw, filter.Limit)
}

// OperatorPlayerTx reads one player summary row; a missing player is absent,
// never an error.
func (PlayerDirectoryReader) OperatorPlayerTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID) (playerdirectory.OperatorPlayer, bool, error) {
	if q == nil || !pid.Valid() {
		return playerdirectory.OperatorPlayer{}, false, errors.New("invalid operator player read")
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT `+operatorPlayerProjection+`::text
FROM players p
JOIN player_directory_profiles d ON d.player_id=p.player_id
JOIN accounts a ON a.account_id=p.account_id
LEFT JOIN player_login_observations o ON o.player_id=p.player_id
WHERE p.player_id=$1`, int64(pid)).Scan(&raw)
	if err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return playerdirectory.OperatorPlayer{}, false, nil
		}
		return playerdirectory.OperatorPlayer{}, false, err
	}
	players, err := decodeOperatorPlayers("["+raw+"]", 1)
	if err != nil || len(players) != 1 {
		return playerdirectory.OperatorPlayer{}, false, err
	}
	return players[0], true, nil
}

// ServerPlayerIDsTx enumerates one logical server's players in the id range the
// bootstrap schema fixes for that server.
func (PlayerDirectoryReader) ServerPlayerIDsTx(ctx context.Context, q tx.Queryer, server identity.LogicalServerID, limit int) ([]identity.PlayerID, error) {
	if q == nil || !server.Valid() || limit < 1 {
		return nil, errors.New("invalid operator server recipient read")
	}
	first, last := int64(server)*100000, (int64(server)+1)*100000
	return scanPlayerIDs(ctx, q, `SELECT COALESCE(jsonb_agg(player_id),'[]'::jsonb)::text FROM (SELECT player_id FROM players WHERE player_id>$1 AND player_id<$2 ORDER BY player_id LIMIT $3) scoped`, first, last, limit)
}

// AllPlayerIDsTx enumerates every player up to the caller's bound.
func (PlayerDirectoryReader) AllPlayerIDsTx(ctx context.Context, q tx.Queryer, limit int) ([]identity.PlayerID, error) {
	if q == nil || limit < 1 {
		return nil, errors.New("invalid operator global recipient read")
	}
	return scanPlayerIDs(ctx, q, `SELECT COALESCE(jsonb_agg(player_id),'[]'::jsonb)::text FROM (SELECT player_id FROM players ORDER BY player_id LIMIT $1) scoped`, limit)
}

func scanPlayerIDs(ctx context.Context, q tx.Queryer, statement string, args ...any) ([]identity.PlayerID, error) {
	var raw string
	if err := q.QueryRow(ctx, statement, args...).Scan(&raw); err != nil {
		return nil, err
	}
	var ids []int64
	if err := json.Unmarshal([]byte(raw), &ids); err != nil {
		return nil, err
	}
	out := make([]identity.PlayerID, 0, len(ids))
	for _, id := range ids {
		out = append(out, identity.PlayerID(id))
	}
	return out, nil
}

func decodeOperatorPlayers(raw string, capacity int) ([]playerdirectory.OperatorPlayer, error) {
	var wire []operatorPlayerWire
	if err := json.Unmarshal([]byte(raw), &wire); err != nil {
		return nil, err
	}
	out := make([]playerdirectory.OperatorPlayer, 0, capacity)
	for _, row := range wire {
		player := playerdirectory.OperatorPlayer{
			PlayerID:        identity.PlayerID(row.PlayerID),
			AccountUID:      row.AccountUID,
			Name:            row.Name,
			Level:           row.Level,
			LogicalServerID: identity.LogicalServerID(row.LogicalServerID),
			CreatedAt:       row.CreatedAt.UTC(),
		}
		if row.LastLoginAt != nil {
			lastLogin := row.LastLoginAt.UTC()
			player.LastLoginAt = &lastLogin
		}
		out = append(out, player)
	}
	return out, nil
}

func escapeLikePrefix(prefix string) string {
	if prefix == "" {
		return ""
	}
	replacer := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)
	return replacer.Replace(prefix) + "%"
}
