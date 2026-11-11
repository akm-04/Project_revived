package provision

import (
	"context"
	"fmt"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ProfileCommentFixture declares one peer-written comment on the driven
// player's profile, so the stock card space tab renders a comment row.
// shortcut: the row is fixture data written through the ProfileFeedback
// store, not proof of the peer's stock request path.
func ProfileCommentFixture(ctx context.Context, databaseURL, accountID, peerAccountID string) error {
	pool, err := postgres.Open(ctx, databaseURL, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "gxb-vc-profile-comment-fixture"})
	if err != nil {
		return err
	}
	defer pool.Close()
	var owner, peer identity.PlayerID
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, accountID).Scan(&owner); err != nil {
		return fmt.Errorf("profile comment fixture owner: %w", err)
	}
	if err = pool.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, peerAccountID).Scan(&peer); err != nil {
		return fmt.Errorf("profile comment fixture peer: %w", err)
	}
	now := time.Now().UTC()
	store := profilefeedbackstore.Store{}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer transaction.Rollback(ctx)
	root, present, err := store.ReadRootTx(ctx, transaction, owner)
	if err != nil {
		return fmt.Errorf("profile comment fixture root: %w", err)
	}
	if !present {
		root = d.Root{PlayerID: owner, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
		if err = store.InsertRootTx(ctx, transaction, root); err != nil {
			return fmt.Errorf("profile comment fixture root insert: %w", err)
		}
	}
	comment, err := store.InsertCommentTx(ctx, transaction, d.Comment{Target: owner, Author: peer, Content: "vc-r1-profile-comment", CreatedAt: now, CreatedVersion: root.StateVersion})
	if err != nil {
		return fmt.Errorf("profile comment fixture comment: %w", err)
	}
	if comment.ID == 0 {
		return fmt.Errorf("profile comment fixture comment id absent")
	}
	return transaction.Commit(ctx)
}
