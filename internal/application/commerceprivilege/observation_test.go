package commerceprivilege

import (
	"context"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type observationStore struct{ state d.State }

func (s observationStore) ReadPrivilegeTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.State, bool, error) {
	return s.state, true, nil
}
func (observationStore) SavePrivilegeTx(context.Context, tx.Tx, int64, d.State) error { return nil }
func (observationStore) ReadCardsTx(context.Context, tx.Queryer, identity.PlayerID) (d.Cards, error) {
	return d.Cards{}, nil
}
func (observationStore) ReadVIPClaimedTx(context.Context, tx.Queryer, identity.PlayerID) ([]int64, error) {
	return nil, nil
}
func (observationStore) ChargeTuningTx(context.Context, tx.Queryer) (d.ChargeTuning, bool, error) {
	return d.ChargeTuning{}, false, nil
}

type observationContent struct{ catalog d.Catalog }

func (c observationContent) PrivilegeCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return c.catalog, nil
}
func (observationContent) ChargeCatalogTx(context.Context, tx.Queryer, string) (d.ChargeCatalog, error) {
	return d.ChargeCatalog{}, nil
}

type observationQueryer struct{}

func (observationQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }
func (observationQueryer) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, nil
}
func (observationQueryer) Commit(context.Context) error   { return nil }
func (observationQueryer) Rollback(context.Context) error { return nil }

// K2/K7: the provider observes a stored forward fact at that fact, so its
// callers can validate the snapshot at ObservedAt instead of the decision time.
func TestProviderObservesAForwardDatedStateAtItsStoredTime(t *testing.T) {
	const pid = identity.PlayerID(100001)
	revision := strings.Repeat("a", 64)
	at := time.Date(2026, 11, 21, 10, 0, 0, 0, time.UTC)
	observed := at.Add(8 * time.Hour)
	rows := make([]d.Threshold, 16)
	for index := range rows {
		rows[index] = d.Threshold{Level: int64(index), Charge: int64(index) * 100, SkillCap: 10}
	}
	provider := Provider{
		Store: observationStore{state: d.State{
			PlayerID: pid, LogicalServerID: 1, Charge: 350, VIPLevel: 3,
			MonthlyState: d.MonthlyAbsent, ContentRevision: revision,
			PolicyVersion: d.ManualPolicy, OriginClass: d.ManualClass,
			Issuer: "native-privilege", Reason: "native-privilege", StateVersion: 1,
			CreatedAt: at, UpdatedAt: observed,
		}},
		Content: observationContent{catalog: d.Catalog{SchemaVersion: 1, PolicyID: d.CatalogPolicy, Rows: rows}},
	}
	snapshot, err := provider.ReadCosmeticPrivilegeTx(context.Background(), observationQueryer{}, pid, revision, at)
	if err != nil {
		t.Fatalf("forward-dated privilege refused: %v", err)
	}
	if !snapshot.ObservedAt.Equal(observed) {
		t.Fatalf("ObservedAt = %v, want %v", snapshot.ObservedAt, observed)
	}
	if snapshot.State.VIPLevel != 3 || snapshot.SkillPointCap != 10 {
		t.Fatalf("snapshot = %+v", snapshot)
	}
}
