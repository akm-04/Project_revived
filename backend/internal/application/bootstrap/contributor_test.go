package bootstrap

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type claimContributor struct {
	name   string
	claims []string
}

func (c claimContributor) Name() string     { return c.name }
func (c claimContributor) Claims() []string { return c.claims }
func (c claimContributor) OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error {
	return nil
}

func TestProjectionClaimsRejectCollisions(t *testing.T) {
	if err := ValidateDetailContributors([]MID1DetailContributor{
		claimContributor{name: "a", claims: []string{"17.lev"}},
		claimContributor{name: "b", claims: []string{"17.lev"}},
	}); err == nil {
		t.Fatal("expected exact claim collision")
	}
	if err := ValidateDetailContributors([]MID1DetailContributor{
		claimContributor{name: "a", claims: []string{"368"}},
		claimContributor{name: "b", claims: []string{"368.total"}},
	}); err == nil {
		t.Fatal("expected parent/child claim collision")
	}
	if err := ValidateDetailContributors([]MID1DetailContributor{
		claimContributor{name: "a", claims: []string{"17.lev"}},
		claimContributor{name: "b", claims: []string{"17.exp"}},
	}); err != nil {
		t.Fatal(err)
	}
}

type fakeBootstrapTx struct{}

func (fakeBootstrapTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (fakeBootstrapTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (fakeBootstrapTx) Commit(context.Context) error                                { return nil }
func (fakeBootstrapTx) Rollback(context.Context) error                              { return nil }

type persistContributor struct {
	name     string
	required bool
	order    *[]string
	err      error
}

func (c persistContributor) Name() string   { return c.name }
func (c persistContributor) Required() bool { return c.required }
func (c persistContributor) PersistCharacterBootstrap(context.Context, tx.Tx, logicalserver.BootstrapContext) error {
	*c.order = append(*c.order, c.name)
	return c.err
}
func TestPersistenceContributorsAreDeterministicAndRequired(t *testing.T) {
	var order []string
	cs := []CharacterBootstrapPersistenceContributor{
		persistContributor{name: "one", required: true, order: &order},
		persistContributor{name: "two", required: true, order: &order},
	}
	if err := ApplyPersistenceContributors(context.Background(), fakeBootstrapTx{}, logicalserver.BootstrapContext{}, cs); err != nil {
		t.Fatal(err)
	}
	if len(order) != 2 || order[0] != "one" || order[1] != "two" {
		t.Fatalf("order=%v", order)
	}
	if err := ValidatePersistenceContributors([]CharacterBootstrapPersistenceContributor{persistContributor{name: "optional", required: false, order: &order}}); err == nil {
		t.Fatal("optional contributor must fail closed until policy is frozen")
	}
	order = nil
	boom := errors.New("boom")
	err := ApplyPersistenceContributors(context.Background(), fakeBootstrapTx{}, logicalserver.BootstrapContext{}, []CharacterBootstrapPersistenceContributor{
		persistContributor{name: "one", required: true, order: &order, err: boom}, persistContributor{name: "two", required: true, order: &order},
	})
	if !errors.Is(err, boom) || len(order) != 1 {
		t.Fatalf("err=%v order=%v", err, order)
	}
}
