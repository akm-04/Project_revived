//go:build postgres

// Package nativebirth births native-test players the way MID1 does: the fixture writes the identity roots (account, player,
// directory profile) and Persist runs the production persistence chain (characterbirth) under the installed builtin content,
// so a fixture player owns every row a real player owns (I8.5-6 D-DRIFT debt).
package nativebirth

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/commerceprivilege"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Root is an existing player root (account and players rows already inserted) awaiting its owner rows.
type Root struct {
	Account ids.UUID
	Player  identity.PlayerID
}

// Persist writes the owner rows of one existing player root in one transaction.
func Persist(ctx context.Context, p *postgres.Pool, account ids.UUID, server identity.LogicalServerID, player identity.PlayerID) error {
	if logicalserver.PlayerRegion(player) != server {
		return errors.New("fixture player outside its logical server band")
	}
	return PersistAll(ctx, p, []Root{{Account: account, Player: player}})
}

// NewRoots allocates account ids for players [first, last]; the fixture inserts those identity roots, then calls PersistAll.
func NewRoots(first, last identity.PlayerID) ([]Root, error) {
	roots := make([]Root, 0, last-first+1)
	for player := first; player <= last; player++ {
		account, err := ids.NewUUID()
		if err != nil {
			return nil, err
		}
		roots = append(roots, Root{Account: account, Player: player})
	}
	return roots, nil
}

// PersistAll births existing player roots in one transaction.
func PersistAll(ctx context.Context, p *postgres.Pool, roots []Root) error {
	revision, err := install(ctx, p)
	if err != nil {
		return err
	}
	pinned, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		return err
	}
	o, err := (operation.Factory{Clock: clock.System{}}).New(pinned)
	if err != nil {
		return err
	}
	// The birth precedes the fixture's own database-clock rows, as a real MID1 precedes later commands.
	o.StartedAt = time.Now().UTC().Add(-time.Minute)
	content := contentstore.Store{Queryer: p}
	privileges := commerceprivilege.Provider{Store: commerceprivilegestore.Store{}, Content: content}
	contributors := characterbirth.Contributors(content, privileges, revision)
	t, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		return err
	}
	defer t.Rollback(ctx)
	for _, root := range roots {
		b, err := bootstrapContext(root, o)
		if err != nil {
			return err
		}
		if err = appboot.ApplyPersistenceContributors(ctx, t, b, contributors); err != nil {
			return err
		}
	}
	return t.Commit(ctx)
}

func bootstrapContext(root Root, o operation.Context) (logicalserver.BootstrapContext, error) {
	accountID, err := identity.AccountIDFrom(root.Account)
	if err != nil {
		return logicalserver.BootstrapContext{}, err
	}
	session, err := ids.NewUUID()
	if err != nil {
		return logicalserver.BootstrapContext{}, err
	}
	sessionID, err := identity.SessionIDFrom(session)
	if err != nil {
		return logicalserver.BootstrapContext{}, err
	}
	server := logicalserver.PlayerRegion(root.Player)
	return logicalserver.BootstrapContext{AccountID: accountID, SessionID: sessionID, LogicalServerID: server, PlayerID: root.Player, Operation: o, BootstrapProfileVersion: "native-fixture"}, nil
}

// Reset empties every table keyed by player_id or account_id: owner rows a birth writes do not all cascade from the account root.
func Reset(ctx context.Context, p *postgres.Pool) error {
	_, err := p.Raw().Exec(ctx, `DO $$ BEGIN EXECUTE (
SELECT 'TRUNCATE ' || string_agg(DISTINCT format('%I', c.table_name), ', ') || ' CASCADE'
FROM information_schema.columns c JOIN information_schema.tables t USING (table_schema, table_name)
WHERE c.table_schema = 'public' AND c.column_name IN ('player_id', 'account_id') AND t.table_type = 'BASE TABLE'); END $$`)
	return err
}

// install makes the builtin content installed and active (idempotent) and answers its revision.
func install(ctx context.Context, p *postgres.Pool) (string, error) {
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		return "", err
	}
	empty, err := policy.NewSet()
	if err != nil {
		return "", err
	}
	o, err := (operation.Factory{Clock: clock.System{}}).New(empty)
	if err != nil {
		return "", err
	}
	service := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, err = service.EnsureBuiltinInstalled(ctx, o, bundle); err != nil {
		return "", err
	}
	if _, err = service.BootstrapActivationIfMissing(ctx, o, bundle); err != nil {
		return "", err
	}
	return bundle.RevisionID(), nil
}
