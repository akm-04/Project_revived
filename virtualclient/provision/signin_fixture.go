package provision

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// SignInBonusFixture is explicit historical fixture state for stock VIP-bonus UI proof, never login-history provenance.
func SignInBonusFixture(ctx context.Context, dsn, account string) error {
	p, err := postgres.Open(ctx, dsn, postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute, ApplicationName: "vc-signin-fixture"})
	if err != nil {
		return err
	}
	defer p.Close()
	var pid identity.PlayerID
	if err = p.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, account).Scan(&pid); err != nil {
		return err
	}
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		return err
	}
	defer tr.Rollback(ctx)
	content := contentstore.Store{}
	revision, err := content.ActiveRevision(ctx, tr)
	if err != nil {
		return err
	}
	at, err := (postgres.AuthoritativeTime{Queryer: tr}).Now(ctx)
	if err != nil {
		return err
	}
	initial, err := (objective.SignRoot{StateVersion: 1}).Refresh(at, revision)
	if err != nil {
		return err
	}
	store := i5store.Store{}
	root, err := store.LockSignInTx(ctx, tr, pid, initial)
	if err != nil {
		return err
	}
	catalog, err := content.SignInCatalogTx(ctx, tr, root.ContentRevision)
	if err != nil {
		return err
	}
	month, err := catalog.Month(root.Month % 100)
	if err != nil {
		return err
	}
	next, err := signInBonusFixture(root, month)
	if err != nil {
		return err
	}
	if err = store.SaveSignInTx(ctx, tr, pid, next, root.StateVersion); err != nil {
		return err
	}
	return tr.Commit(ctx)
}
func signInBonusFixture(root objective.SignRoot, month objective.SignMonth) (objective.SignRoot, error) {
	if root.Validate() != nil || root.Count > 2 || len(month.Awards) < 3 || month.Month != root.Month%100 || month.Awards[2].DoubleVIP < 0 {
		return root, fmt.Errorf("sign-in bonus fixture requires fresh month and day3 VIP reward")
	}
	root.Count = 2
	root.Signed = 0
	root.StateVersion++
	return root, nil
}
