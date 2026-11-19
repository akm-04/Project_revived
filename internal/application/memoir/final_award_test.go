package memoir

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/campaign"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/march"
	d "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type finalAwardFixture struct {
	mode     Mode
	store    *finalAwardStore
	grants   *finalAwardGrants
	receipts *finalAwardReceipts
}

func newFinalAwardFixture(t *testing.T) finalAwardFixture {
	t.Helper()
	at := time.Date(2026, 11, 19, 12, 0, 0, 0, time.UTC)
	store := &finalAwardStore{state: finalAwardState()}
	grants := &finalAwardGrants{}
	receipts := &finalAwardReceipts{stored: map[string]receipt.Receipt{}}
	mode := Mode{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Fresh:       startChoiceTx{},
		Store:       store,
		Content:     finalAwardContent{catalog: finalAwardCatalog()},
		Fence:       startChoiceFence{},
		Functions:   startChoiceFunctions{},
		Heroes:      startChoiceHeroes{},
		HeroLocks:   startChoiceHeroLocks{},
		Roster:      &startChoiceRoster{},
		Pets:        startChoicePets{},
		Opponents:   startChoiceOpponents{},
		Combat:      &startChoiceCombat{},
		Grants:      grants,
		Costs:       startChoiceCosts{},
		Energy:      startChoiceEnergy{},
		Exchange:    startChoiceExchange{},
		Receipts:    receipts,
		ReceiptRead: receipts,
	}
	return finalAwardFixture{mode: mode, store: store, grants: grants, receipts: receipts}
}

func finalAwardState() d.State {
	cells := make([]int64, d.BoardCells)
	for index := range cells {
		cells[index] = d.Road
	}
	cells[d.FinalPosition-1] = d.Endpoint
	return d.State{
		Occurrence: "final-award",
		Revision:   startChoiceRevision,
		Girl:       5,
		Floor:      3,
		Board: d.Board{
			Cells:       cells,
			Open:        map[int]int64{d.InitialPosition: 1},
			Enemies:     map[int]int64{},
			Position:    d.InitialPosition,
			GuardianWon: true,
		},
		Heroes:    map[int64]cd.ActorStatus{},
		Enemies:   map[int]d.EnemyCarry{},
		Opponents: map[int]march.Enemy{},
		Drops:     []campaign.Item{},
		MaxFloor:  map[int64]int{},
	}
}

func finalAwardCatalog() d.Catalog {
	return d.Catalog{
		BigKey:      1,
		SmallKey:    2,
		Floors:      []d.Floor{{ID: 1}, {ID: 2}, {ID: 3}},
		Gifts:       []d.Gift{{ID: 900, Box: 1}, {ID: 901, Box: 2, Items: [][2]int64{{500, 1}}}},
		Boxes:       []d.Box{{ID: 1, Rows: []d.Drop{{Item: 200, Amount: 1, Rate: 0}}}, {ID: 2, Rows: []d.Drop{{Item: 201, Amount: 1, Rate: 0}}}},
		FinalGifts:  []int64{900, 901},
		ReviveCosts: []int64{1},
	}
}

type finalAwardStore struct {
	Store
	state     d.State
	tuning    d.Tuning
	found     bool
	tuningErr error
}

func (store *finalAwardStore) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.State, bool, error) {
	return store.state, true, nil
}

func (store *finalAwardStore) LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.State, error) {
	return store.state, nil
}

func (store *finalAwardStore) SaveTx(context.Context, tx.Tx, identity.PlayerID, d.State, time.Time) error {
	return nil
}

func (store *finalAwardStore) TuningTx(context.Context, tx.Queryer) (d.Tuning, bool, error) {
	return store.tuning, store.found, store.tuningErr
}

type finalAwardContent struct {
	Content
	catalog d.Catalog
}

func (finalAwardContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return startChoiceRevision, nil
}

func (content finalAwardContent) MemoirCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return content.catalog, nil
}

type finalAwardGrants struct {
	Grants
	awards []i5.Award
	calls  int
}

func (grants *finalAwardGrants) SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error) {
	grants.calls++
	return i5.GrantResult{Awards: append([]i5.Award(nil), grants.awards...)}, nil
}

type finalAwardReceipts struct {
	stored map[string]receipt.Receipt
}

func finalAwardReceiptKey(id receipt.Identity) string {
	return id.OwnerKind + "|" + id.OwnerKey + "|" + id.Domain + "|" + id.Operation + "|" + id.SemanticKey
}

func (store *finalAwardReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	record, found := store.stored[finalAwardReceiptKey(id)]
	return record, found, nil
}

func (store *finalAwardReceipts) PutTx(_ context.Context, _ tx.Tx, record receipt.Receipt) (receipt.PutResult, error) {
	store.stored[finalAwardReceiptKey(record.Identity)] = record
	return receipt.PutResult{Receipt: record, Inserted: true}, nil
}

func (store *finalAwardReceipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	record, found := store.stored[finalAwardReceiptKey(id)]
	return record, found, nil
}

func (fixture finalAwardFixture) operation(t *testing.T) operation.Context {
	t.Helper()
	return startChoiceOperation(t, ids.UUID{9}, time.Date(2026, 11, 19, 12, 0, 0, 0, time.UTC))
}

func TestFinalAwardEmptyDrawOmitsAwardsKey(t *testing.T) {
	fixture := newFinalAwardFixture(t)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	operationContext := fixture.operation(t)
	response, err := fixture.mode.FinalAward(context.Background(), actor, d.FinalPosition, 900, operationContext)
	if err != nil {
		t.Fatal(err)
	}
	if _, present := response["awards"]; present {
		t.Fatalf("empty draw still carries awards: %#v", response["awards"])
	}
	if fixture.grants.calls != 0 {
		t.Fatalf("empty draw settled %d grants", fixture.grants.calls)
	}
	replayed, err := fixture.mode.FinalAward(context.Background(), actor, d.FinalPosition, 900, operationContext)
	if err != nil {
		t.Fatal(err)
	}
	first, _ := cd.CanonicalJSON(response)
	second, _ := cd.CanonicalJSON(replayed)
	if string(first) != string(second) {
		t.Fatalf("replay diverged:\n%s\n%s", first, second)
	}
}

func TestFinalAwardNonEmptyKeepsAwardsKey(t *testing.T) {
	fixture := newFinalAwardFixture(t)
	fixture.grants.awards = []i5.Award{{TableID: 500, ItemNum: 1}}
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	operationContext := fixture.operation(t)
	response, err := fixture.mode.FinalAward(context.Background(), actor, d.FinalPosition, 901, operationContext)
	if err != nil {
		t.Fatal(err)
	}
	rows, present := response["awards"].([]map[string]any)
	if !present || len(rows) != 1 || rows[0]["table_id"] != int64(500) || rows[0]["item_num"] != int64(1) {
		t.Fatalf("non-empty draw awards %#v", response["awards"])
	}
	replayed, err := fixture.mode.FinalAward(context.Background(), actor, d.FinalPosition, 901, operationContext)
	if err != nil {
		t.Fatal(err)
	}
	first, _ := cd.CanonicalJSON(response)
	second, _ := cd.CanonicalJSON(replayed)
	if string(first) != string(second) {
		t.Fatalf("replay diverged:\n%s\n%s", first, second)
	}
}

type unitUniform struct{}

func (unitUniform) Uniform(uint64) uint64 { return 0 }

func TestMemoirCatalogAppliesOperatorTuningAndFallsBackToSource(t *testing.T) {
	fixture := newFinalAwardFixture(t)
	source := finalAwardCatalog()
	fixture.store.tuning = d.Tuning{Version: 1, BoxRates: map[string]map[string]int64{"1": {"200": 10000}}}
	fixture.store.found = true
	tuned, err := fixture.mode.catalog(context.Background(), nil, startChoiceRevision)
	if err != nil {
		t.Fatal(err)
	}
	if got := tuned.Draw(1, unitUniform{}); len(got) != 1 || got[0].ItemID != 200 || got[0].Num != 1 {
		t.Fatalf("operator tuning did not reach the draw: %#v", got)
	}
	if got := source.Draw(1, unitUniform{}); len(got) != 0 {
		t.Fatalf("source draw changed: %#v", got)
	}

	fixture.store.tuning = d.Tuning{Version: 2, BoxRates: map[string]map[string]int64{"1": {"200": -1}}}
	served, err := fixture.mode.catalog(context.Background(), nil, startChoiceRevision)
	if err != nil || !reflect.DeepEqual(served, source) {
		t.Fatalf("invalid overlay served %#v, err %v", served.Boxes, err)
	}

	fixture.store.tuningErr = errors.New("operator tuning row unreadable")
	served, err = fixture.mode.catalog(context.Background(), nil, startChoiceRevision)
	if err != nil || !reflect.DeepEqual(served, source) {
		t.Fatalf("unreadable overlay served a mutated catalog, err %v", err)
	}
}
