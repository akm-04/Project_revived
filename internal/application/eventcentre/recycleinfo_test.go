package eventcentre

import (
	"context"
	"testing"
	"time"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type a129Content struct{ catalog Catalog }

func (a129Content) WorkshopInputsActive(context.Context) (string, bool, error) { return "", false, nil }
func (c a129Content) WorkshopInputsTx(context.Context, tx.Queryer, string) (Catalog, error) {
	return c.catalog, nil
}

type a129Books struct{ level int64 }

func (b a129Books) BookInputsTx(context.Context, tx.Queryer, appbook.InputScope) (appbook.Inputs, error) {
	return appbook.Inputs{Applied: book.State{Buildings: map[int64]book.Building{3: {Level: b.level}}}}, nil
}

func a129Catalog() Catalog {
	return Catalog{
		Recycle: map[int64]ec.RecycleRule{1: {Level: 1, EnergyLimit: 1000}, 2: {Level: 2, EnergyLimit: 2000}},
		Misc:    ec.Misc{SaturationInit: 10000, SaturationSeconds: 15},
	}
}

// A type-3 speed-up raises the level before the projection runs. The snapshot
// caps at the new limit but keeps the old near-saturated energy, so the client
// cannot show zero or an over-limit value.
func TestA129RecycleInfoUsesTheNewLevelLimit(t *testing.T) {
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	owner := &makeInfoOwner{exists: true, root: makeInfoRoot(at)}
	owner.root.Facts.Recycle = ec.RecycleState{Energy: 11000, EnergyAt: at}
	service := Service{Owner: owner, Book: a129Books{level: 2}, Content: a129Content{catalog: a129Catalog()}}
	trash, err := service.RecycleInfoTx(context.Background(), nil, 1, makeInfoRoot(at).Revision, at)
	if err != nil {
		t.Fatal(err)
	}
	if trash["energy"] != int64(11000) || trash["energy_time"] != at.Unix() {
		t.Fatalf("near-saturated snapshot = %#v", trash)
	}
	if owner.root.Facts.Recycle.Energy != 11000 {
		t.Fatal("RecycleInfoTx saved the settled clone")
	}
}

// An account with no event-centre root yet must see the canonical full energy
// at its current (already upgraded) level, matching the next MID 1072 read.
func TestA129RecycleInfoSeedsFullAtTheNewLimit(t *testing.T) {
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	owner := &makeInfoOwner{}
	service := Service{Owner: owner, Book: a129Books{level: 2}, Content: a129Content{catalog: a129Catalog()}}
	trash, err := service.RecycleInfoTx(context.Background(), nil, 1, makeInfoRoot(at).Revision, at)
	if err != nil {
		t.Fatal(err)
	}
	if trash["energy"] != int64(12000) || trash["energy_time"] != at.Unix() {
		t.Fatalf("fresh snapshot = %#v", trash)
	}
}
