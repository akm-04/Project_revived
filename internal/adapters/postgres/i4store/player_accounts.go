package i4store

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// PlayerAccounts is the identity owner's narrow companion-account read used by
// the same-account invitation refusal. It exposes no account state beyond the id.
type PlayerAccounts struct{}

func (PlayerAccounts) ReadAccountTx(ctx context.Context, q tx.Queryer, player identity.PlayerID) (identity.AccountID, error) {
	if q == nil || !player.Valid() {
		return identity.AccountID{}, errors.New("identity: invalid player account read")
	}
	var raw string
	if err := q.QueryRow(ctx, `SELECT account_id::text FROM players WHERE player_id=$1`, int64(player)).Scan(&raw); err != nil {
		return identity.AccountID{}, err
	}
	account, err := parseAccountID(raw)
	if err != nil {
		return identity.AccountID{}, err
	}
	return account, nil
}
