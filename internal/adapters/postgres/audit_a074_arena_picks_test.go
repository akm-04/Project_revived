//go:build postgres

package postgres

import (
	"context"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/arena"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type auditPicksContent struct{ app.Content }

func (auditPicksContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return "revision", nil
}
func (auditPicksContent) ArenaCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return d.Catalog{}, nil
}
func (auditPicksContent) ArenaTemplatesTx(context.Context, tx.Queryer, string) (d.Templates, error) {
	return d.Templates{}, nil
}

type auditPicksStore struct{ app.Store }

func (auditPicksStore) ReadPlayerTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.Player, bool, error) {
	return d.Player{}, false, nil
}

// No database is opened: the production pool guard must reject any attempt to
// acquire a second connection before its nil raw pool can be touched.
func TestAuditA074ArenaPicksUsesCallerConnection(t *testing.T) {
	previousStrict := strictOneConnection
	strictOneConnection = true
	t.Cleanup(func() { strictOneConnection = previousStrict })
	service := app.Service{
		Timed: gen.TimedRunner{Binder: gen.Binder{Time: AuthoritativeTime{Queryer: &Pool{}}}, Runner: tx.Runner{DB: oneTxDB{}}},
		Fresh: oneTx{}, Store: auditPicksStore{}, Content: auditPicksContent{},
		Fence: struct{ app.Fence }{}, Costs: struct{ i5.TxMaterialCostDebiter }{},
		Grants: struct{ app.Grants }{}, Values: struct{ app.Values }{}, Mail: struct{ app.Mail }{},
		Achievements: struct{ app.Achievements }{}, Facts: struct{ app.Facts }{}, Combat: struct{ app.Combat }{},
		Heroes: struct{ app.Roster }{}, Pets: struct{ app.Roster }{}, OwnedHeroes: struct{ app.OwnedHeroReader }{},
		Directory: struct{ app.Directory }{}, Guilds: struct{ app.Guilds }{}, Servers: struct{ app.Servers }{},
		Receipts: struct{ receipt.Store }{}, ReceiptRead: struct{ receipt.Reader }{},
	}
	currentOperation := operation.Context{ID: ids.UUID{1}, StartedAt: time.Unix(100, 0).UTC(), EntropySeed: [32]byte{9}}
	_, err := service.Timed.Runner.Run(context.Background(), currentOperation, app.Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		if !tx.HoldsConnection(ctx) {
			t.Fatal("fixture did not enter a runner transaction")
		}
		_, err := service.SeasonPicksTx(ctx, scope.Tx, 7)
		return err
	})
	if err != nil {
		t.Fatalf("roster Arena picks inside caller transaction: %v", err)
	}
}
