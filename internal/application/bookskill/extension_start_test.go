package bookskill

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type a44Values struct{}

func (a44Values) ReadScalarTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.ScalarBalance, bool, error) {
	return economy.ScalarBalance{}, false, nil
}

func (a44Values) ListStacksTx(context.Context, tx.Queryer, identity.PlayerID) ([]economy.StackState, error) {
	return nil, nil
}

func TestExtensionBuildingStartPersistsLevelOneOnlyAfterValidatedPlan(t *testing.T) {
	t.Run("invalid plan leaves no row", func(t *testing.T) {
		catalog := a44Catalog(true)
		delete(catalog.Buildings, [2]int64{2, 1})
		service, owner, content, at := a44Service(catalog)
		_, err := service.apply(context.Background(), nil, identity.ActorContext{}, Admission{
			Operation:       operation.Context{},
			DecisionAt:      at,
			Command:         Command{Family: Start, Type: 2},
			ContentRevision: a44Revision,
		})
		if err == nil {
			t.Fatal("start with missing catalog rule succeeded")
		}
		if _, exists := owner.root.Facts.Buildings[2]; exists || owner.writes != 0 {
			t.Fatal("failed start persisted its lazy building row")
		}
		if len(content.reads) != 1 {
			t.Fatalf("catalog reads = %v", content.reads)
		}
	})

	t.Run("validated plan creates pinned level one", func(t *testing.T) {
		service, owner, _, at := a44Service(a44Catalog(true))
		service.Values = a44Values{}
		_, err := service.apply(context.Background(), nil, identity.ActorContext{}, Admission{
			Operation:       operation.Context{},
			DecisionAt:      at,
			Command:         Command{Family: Start, Type: 2},
			ContentRevision: a44Revision,
		})
		if err != nil {
			t.Fatal(err)
		}
		building, exists := owner.root.Facts.Buildings[2]
		if !exists || building.Level != 1 || building.CatalogRevision != a44Revision || building.Job == nil || building.Job.Target != 2 || building.Job.Revision != a44Revision {
			t.Fatalf("persisted extension building = %+v, exists %v", building, exists)
		}
		if owner.writes != 1 {
			t.Fatalf("root writes = %d, want 1", owner.writes)
		}
	})
}
