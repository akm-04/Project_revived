package occult

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"testing"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakeFunctions struct{ open bool }

func (f fakeFunctions) ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error) {
	return player.FunctionEligibility{}, f.open, nil
}

type fakeDirectory struct{ level int64 }

func (f fakeDirectory) ProfileTx(_ context.Context, _ tx.Queryer, id identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{PlayerID: id, Name: "p", Level: f.level}, true, nil
}

type fakeAwakening struct {
	drop    *objective.AwakeFrozenDrop
	current bool
}

func (f fakeAwakening) FreezeAwakeningOccultMaterialTx(context.Context, tx.Queryer, identity.PlayerID, []i5.MaterialRoute) (*objective.AwakeFrozenDrop, error) {
	return f.drop, nil
}

func (f fakeAwakening) CheckAwakeningOccultMaterialTx(context.Context, tx.Queryer, identity.PlayerID, objective.AwakeFrozenDrop) (bool, error) {
	return f.current, nil
}

func loadCatalog(t *testing.T) d.Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/occult_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog d.Catalog
	if err = json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	return catalog
}

func actor() identity.ActorContext {
	return identity.ActorContext{PlayerID: 100001, LogicalServerID: 1}
}

func TestFunction67AtLevel85IsRefusedOtherwise(t *testing.T) {
	catalog := loadCatalog(t)
	at := time.Unix(1700000000, 0).UTC()
	cases := []struct {
		name      string
		open      bool
		level     int64
		wantAllow bool
	}{{"closed function", false, 100, false}, {"level 84", true, 84, false}, {"level 85", true, 85, true}}
	for _, c := range cases {
		mode := Mode{Functions: fakeFunctions{open: c.open}, Directory: fakeDirectory{level: c.level}}
		err := mode.admit(context.Background(), nil, actor(), catalog, at)
		if c.wantAllow && err != nil || !c.wantAllow && !errors.Is(err, d.ErrRefused) {
			t.Fatalf("%s: err=%v", c.name, err)
		}
	}
}

func TestFragmentIsFrozenOnlyForAnActiveRouteAndRevalidatedAtSettle(t *testing.T) {
	catalog := loadCatalog(t)
	occurrence := objective.AwakeInstance{Mission: 1171001, Type: 1, OwnerID: 7, Generation: 3, Revision: "ab"}
	drop := &objective.AwakeFrozenDrop{Occurrence: occurrence, ItemID: 60001170, Rate: 10000, Count: 1}
	view := &roomView{catalog: catalog, state: d.NewRun(2, d.SingleCampaignType)}
	scope := gen.TimedScope{}

	none := Mode{Awakening: fakeAwakening{}}
	if err := none.freezeFragment(context.Background(), scope, actor(), view); err != nil || view.state.Frozen != nil {
		t.Fatalf("no active mission must freeze nothing: %v %v", err, view.state.Frozen)
	}
	if fragment, err := none.frozenFragment(context.Background(), scope, actor(), view); fragment != nil || err != nil {
		t.Fatalf("nothing pinned must pay nothing: %v %v", fragment, err)
	}

	pinned := Mode{Awakening: fakeAwakening{drop: drop, current: true}}
	if err := pinned.freezeFragment(context.Background(), scope, actor(), view); err != nil || len(view.state.Frozen) != 1 {
		t.Fatalf("freeze: %v %v", err, view.state.Frozen)
	}
	fragment, err := pinned.frozenFragment(context.Background(), scope, actor(), view)
	if err != nil || fragment == nil || *fragment != (d.Reward{ItemID: 60001170, Quantity: 1}) {
		t.Fatalf("fragment=%v err=%v", fragment, err)
	}

	moved := Mode{Awakening: fakeAwakening{drop: drop, current: false}}
	if fragment, err = moved.frozenFragment(context.Background(), scope, actor(), view); fragment != nil || err != nil {
		t.Fatalf("a finished or replaced occurrence must pay nothing: %v %v", fragment, err)
	}

	foreign := &roomView{catalog: catalog, state: d.NewRun(3, d.SingleCampaignType), room: view.room}
	foreign.state.Frozen = view.state.Frozen
	if fragment, err = pinned.frozenFragment(context.Background(), scope, actor(), foreign); fragment != nil || err != nil {
		t.Fatalf("a foreign chapter must pay nothing: %v %v", fragment, err)
	}
}

func TestStateBodyWithoutRoomCarriesBaseInfoAndTickets(t *testing.T) {
	catalog := loadCatalog(t)
	scores := d.Scores{"2": 17}
	body, err := Mode{}.stateBody(context.Background(), nil, actor(), catalog, scores, i5.OccultTickets{Tickets: 2, Progress: 1500}, nil)
	if err != nil {
		t.Fatal(err)
	}
	base := body["base_info"].(map[string]any)
	points := base["max_points"].([]int64)
	if body["occult_ticket"] != int64(2) || base["cost_energy"] != int64(1500) || base["room_id"] != int64(0) || len(points) != 6 || points[1] != 17 {
		t.Fatalf("body=%v", body)
	}
	if _, inRoom := body["room_info"]; inRoom {
		t.Fatal("no room, no room_info")
	}
}

func TestSubIdIsOneBasedAndBounded(t *testing.T) {
	campaign := d.Campaign{FightIDs: []int64{9902201, 9902202}}
	for subID, valid := range map[int64]bool{0: false, 1: true, 2: true, 3: false} {
		_, err := stageOf(campaign, subID)
		if valid != (err == nil) {
			t.Fatalf("sub %d err=%v", subID, err)
		}
	}
}
