package provision

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"slices"
	"time"
)

// FriendFixture declares a prior friendship with the single separately prepared peer; it proves no friend acquisition.
func FriendFixture(requestContext context.Context, databaseURL, accountID string) error {
	pool, err := postgres.Open(requestContext, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-friend-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var first, second int64
	if err := pool.QueryRow(requestContext, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&first); err != nil {
		return err
	}
	if err := pool.QueryRow(requestContext, `SELECT CASE WHEN count(*)=1 THEN min(player_id) ELSE 0 END FROM players WHERE account_id<>$1`, accountID).Scan(&second); err != nil {
		return err
	}
	if first < 1 || second < 1 {
		return fmt.Errorf("friend fixture needs exactly one prepared peer")
	}
	players := []identity.PlayerID{identity.PlayerID(first), identity.PlayerID(second)}
	slices.Sort(players)
	transaction, err := pool.Begin(requestContext, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(requestContext)
	for _, player := range players {
		server, err := socialrelation.CanonicalServer(player)
		if err != nil {
			return err
		}
		roots, err := (i4store.PlayerRootLocker{}).LockPlayerRootsTx(requestContext, transaction, server, []identity.PlayerID{player})
		if err != nil {
			return err
		}
		if len(roots) != 1 {
			return fmt.Errorf("friend fixture missing root")
		}
	}
	var at time.Time
	if err := transaction.QueryRow(requestContext, `SELECT clock_timestamp()`).Scan(&at); err != nil {
		return err
	}
	store := socialrelationstore.Store{}
	for _, player := range players {
		if _, err := store.EnsureRootTx(requestContext, transaction, player, at); err != nil {
			return err
		}
	}
	relation := socialrelation.Friendship{PlayerLowID: players[0], PlayerHighID: players[1], Generation: 1, Active: true, ActivatedAt: at, StateVersion: 1, UpdatedAt: at}
	if err := store.PutFriendshipTx(requestContext, transaction, nil, relation); err != nil {
		return err
	}
	return transaction.Commit(requestContext)
}
