package identitystore

import (
	"context"
	"errors"
	"time"

	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// InsertSessionHoldTx records one logout hold in the bus transaction.
func (Store) InsertSessionHoldTx(ctx context.Context, transaction tx.Tx, hold appidentity.SessionHold) error {
	if transaction == nil || hold.HeldUntil.IsZero() || hold.CommandKey == "" {
		return errors.New("invalid session hold")
	}
	_, err := transaction.Exec(ctx, `INSERT INTO operator_session_holds(scope_kind,scope_key,held_until,reason,command_key,created_at) VALUES($1,$2,$3,$4,$5,$6)`,
		hold.ScopeKind, hold.ScopeKey, hold.HeldUntil.UTC(), hold.Reason, hold.CommandKey, time.Now().UTC())
	return err
}

// ActiveSessionHoldTx asks whether a global, server or player hold is live at
// the request time. A player hold matches only a resolved player id.
func (Store) ActiveSessionHoldTx(ctx context.Context, query tx.Queryer, server identity.LogicalServerID, player identity.PlayerID, at time.Time) (bool, error) {
	if query == nil || at.IsZero() {
		return false, errors.New("invalid session hold read")
	}
	var active bool
	err := query.QueryRow(ctx, `SELECT EXISTS(
  SELECT 1 FROM operator_session_holds
  WHERE held_until > $3
    AND (scope_kind='global'
      OR (scope_kind='server' AND scope_key=$1)
      OR (scope_kind='player' AND scope_key=$2)))`, int32(server), int64(player), at.UTC()).Scan(&active)
	return active, err
}

// PlayerIDsForSessionIDsTx resolves named sessions to the players their live
// contexts name; a session without a live player is absent.
func (Store) PlayerIDsForSessionIDsTx(ctx context.Context, query tx.Queryer, sessions []identity.SessionID) ([]identity.PlayerID, error) {
	if query == nil {
		return nil, errors.New("invalid session player read")
	}
	if len(sessions) == 0 {
		return []identity.PlayerID{}, nil
	}
	ids := make([]string, 0, len(sessions))
	for _, session := range sessions {
		ids = append(ids, session.UUID().String())
	}
	var out []int64
	err := query.QueryRow(ctx, `SELECT COALESCE(array_agg(DISTINCT player_id ORDER BY player_id),'{}'::bigint[]) FROM gameplay_contexts WHERE ended_at IS NULL AND session_id = ANY($1::uuid[])`, ids).Scan(&out)
	if err != nil {
		return nil, err
	}
	players := make([]identity.PlayerID, 0, len(out))
	for _, id := range out {
		players = append(players, identity.PlayerID(id))
	}
	return players, nil
}
