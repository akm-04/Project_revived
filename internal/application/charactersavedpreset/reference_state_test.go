package charactersavedpreset

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type referenceStateQueryer struct{}
type referenceStateRow struct{}

func (referenceStateQueryer) QueryRow(context.Context, string, ...any) tx.Row {
	return referenceStateRow{}
}
func (referenceStateQueryer) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, errors.New("unexpected exec")
}
func (referenceStateRow) Scan(...any) error { return errors.New("unexpected scan") }

type referenceStateStore struct {
	agg character.SavedPresetAggregate
}

func (s referenceStateStore) ReadSavedPresetAggregateTx(context.Context, tx.Queryer, identity.PlayerID) (character.SavedPresetAggregate, error) {
	return s.agg, nil
}

func referenceStateAggregate() character.SavedPresetAggregate {
	pid := identity.PlayerID(7)
	now := time.Unix(10, 0).UTC()
	pet := character.PetRef{PlayerID: pid, PetID: 9}
	return character.SavedPresetAggregate{
		Root: character.SavedPresetRoot{PlayerID: pid, StateVersion: 5, CreatedAt: now, UpdatedAt: now},
		Lanes: []character.SavedPresetLane{
			{Name: "presentation-only", Heroes: []character.HeroRef{{PlayerID: pid, PartnerID: 2}, {PlayerID: pid, PartnerID: 1}}, Pet: &pet},
			{Name: "second", Heroes: []character.HeroRef{{PlayerID: pid, PartnerID: 3}}},
		},
	}
}

func TestReferenceStateReaderExportsOrderedReferencesWithoutNames(t *testing.T) {
	agg := referenceStateAggregate()
	r := ReferenceStateReader{Store: referenceStateStore{agg: agg}}
	got, err := r.SavedPresetReferenceStateTx(context.Background(), referenceStateQueryer{}, agg.Root.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if got.PlayerID != agg.Root.PlayerID || got.StateVersion != 5 || len(got.Loadouts) != 2 {
		t.Fatalf("state=%+v", got)
	}
	if got.Loadouts[0].Heroes[0].PartnerID != 2 || got.Loadouts[0].Heroes[1].PartnerID != 1 || got.Loadouts[0].Pet == nil || got.Loadouts[0].Pet.PetID != 9 {
		t.Fatalf("first loadout=%+v", got.Loadouts[0])
	}
	if got.Loadouts[1].Pet != nil || got.Loadouts[1].Heroes[0].PartnerID != 3 {
		t.Fatalf("second loadout=%+v", got.Loadouts[1])
	}
}

func TestReferenceStateReaderDeepCopiesAggregate(t *testing.T) {
	agg := referenceStateAggregate()
	r := ReferenceStateReader{Store: referenceStateStore{agg: agg}}
	got, err := r.SavedPresetReferenceStateTx(context.Background(), referenceStateQueryer{}, agg.Root.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	agg.Lanes[0].Heroes[0].PartnerID = 99
	agg.Lanes[0].Pet.PetID = 88
	if got.Loadouts[0].Heroes[0].PartnerID != 2 || got.Loadouts[0].Pet.PetID != 9 {
		t.Fatalf("returned state aliased aggregate: %+v", got.Loadouts[0])
	}
}

func TestReferenceStateReaderAllowsEmptyAggregate(t *testing.T) {
	agg := referenceStateAggregate()
	agg.Lanes = nil
	r := ReferenceStateReader{Store: referenceStateStore{agg: agg}}
	got, err := r.SavedPresetReferenceStateTx(context.Background(), referenceStateQueryer{}, agg.Root.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if len(got.Loadouts) != 0 || got.StateVersion != 5 {
		t.Fatalf("state=%+v", got)
	}
}
