package achievement

import (
	"context"
	"reflect"
	"strings"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type claimQueryer struct{}

func (claimQueryer) QueryRow(context.Context, string, ...any) tx.Row { panic("unexpected query") }

type claimTransaction struct{ claimQueryer }

func (claimTransaction) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return claimCommandTag{}, nil
}
func (claimTransaction) Commit(context.Context) error   { return nil }
func (claimTransaction) Rollback(context.Context) error { return nil }

type claimCommandTag struct{}

func (claimCommandTag) RowsAffected() int64 { return 1 }

type claimBeginner struct{ transaction tx.Tx }

func (b claimBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) { return b.transaction, nil }

type claimTime struct{ at time.Time }

func (t claimTime) Now(context.Context) (time.Time, error) { return t.at, nil }

type claimActive struct{ revision string }

func (a claimActive) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return a.revision, nil
}

type claimCounts struct{}

func (claimCounts) OwnedStateCountsTx(context.Context, ca.CoherentReadScope, identity.PlayerID, []int64) map[int64]int64 {
	return nil
}

type claimFence struct{}

func (claimFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type claimStacks struct{ quantities map[int64]int64 }

func (s claimStacks) ReadStackTx(_ context.Context, _ tx.Queryer, _ identity.PlayerID, itemID int64) (economy.StackState, bool, error) {
	quantity, found := s.quantities[itemID]
	return economy.StackState{ItemID: itemID, Quantity: quantity}, found, nil
}

type claimGrants struct{ stacks claimStacks }

func (g claimGrants) SettleGrantTx(_ context.Context, _ tx.Tx, _ identity.ActorContext, plan grant.Plan, _ operation.Context, _ i5.GrantTxOptions) (i5.GrantResult, error) {
	var out i5.GrantResult
	for _, line := range plan.Lines {
		g.stacks.quantities[line.ItemID] += line.Amount
		out.Awards = append(out.Awards, i5.Award{TableID: line.ItemID, ItemNum: line.Amount})
	}
	return out, nil
}

type claimReceipts struct {
	entries map[receipt.Identity]receipt.Receipt
}

func (r *claimReceipts) PutTx(_ context.Context, _ tx.Tx, value receipt.Receipt) (receipt.PutResult, error) {
	r.entries[value.Identity] = value
	return receipt.PutResult{Receipt: value, Inserted: true}, nil
}

func (r *claimReceipts) FindTx(_ context.Context, _ tx.Queryer, id receipt.Identity) (receipt.Receipt, bool, error) {
	value, found := r.entries[id]
	return value, found, nil
}

func (r *claimReceipts) Find(_ context.Context, id receipt.Identity) (receipt.Receipt, bool, error) {
	value, found := r.entries[id]
	return value, found, nil
}

type claimStore struct {
	Store
	root   d.Root
	claims map[int64]bool
}

func (s *claimStore) ReadRootTx(context.Context, tx.Queryer, identity.PlayerID, bool) (d.Root, bool, error) {
	return s.root, true, nil
}

func (s *claimStore) ReadStreaksTx(context.Context, tx.Queryer, identity.PlayerID) ([]d.Streak, error) {
	return nil, nil
}

func (s *claimStore) ReadClaimsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]bool, error) {
	out := make(map[int64]bool, len(s.claims))
	for id, claimed := range s.claims {
		out[id] = claimed
	}
	return out, nil
}

func (s *claimStore) PutClaimTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, level int64, _ string, _ ids.UUID, _ int64, _ time.Time) error {
	s.claims[level] = true
	return nil
}

type claimContent struct{ catalog d.Catalog }

func (c claimContent) AchievementCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return c.catalog, nil
}

func claimOperation(id byte) operation.Context {
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: strings.Repeat("a", 64)})
	if e != nil {
		panic(e)
	}
	return operation.Context{ID: ids.UUID{id}, StartedAt: time.Unix(1000, 0).UTC(), Policies: refs}
}

func newClaimFixture(t *testing.T) (Service, *claimStore, *claimStacks, identity.ActorContext) {
	t.Helper()
	at := time.Unix(1000, 0).UTC()
	revision := strings.Repeat("a", 64)
	player := identity.PlayerID(100001)
	store := &claimStore{
		root:   d.Root{PlayerID: player, ContentRevision: revision, PolicyID: d.Policy, StateVersion: 1, CreatedAt: at, UpdatedAt: at, CompleteTimes: [3]*time.Time{&at}},
		claims: map[int64]bool{},
	}
	stacks := &claimStacks{quantities: map[int64]int64{}}
	receipts := &claimReceipts{entries: map[receipt.Identity]receipt.Receipt{}}
	catalog := d.Catalog{
		SchemaVersion: 2,
		PolicyID:      "C4B_MARRIED_POPULATION_TIER_FACTS_V1",
		SelectedID:    d.SelectedID,
		Rows:          []d.Definition{{ID: d.SelectedID, Points: [3]int64{30000, 10000, 0}}},
		Levels: []d.Level{
			{ID: 5, PointCondition: 30000, Items: [][2]int64{{50001181, 3}}},
			{ID: 6, PointCondition: 40000, Items: [][2]int64{{50001181, 6}}},
		},
	}
	runtime := &Runtime{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: claimTime{at: at}}, Runner: tx.Runner{DB: claimBeginner{transaction: claimTransaction{}}}},
		Fresh:       claimQueryer{},
		Active:      claimActive{revision: revision},
		Counts:      claimCounts{},
		Fence:       claimFence{},
		Grants:      claimGrants{stacks: *stacks},
		Stacks:      *stacks,
		Receipts:    receipts,
		ReceiptRead: receipts,
	}
	service := Service{Store: store, Content: claimContent{catalog: catalog}, Runtime: runtime}
	return service, store, stacks, identity.ActorContext{PlayerID: player}
}

func TestClaimFirstAwardReportsPostClaimStackTotal(t *testing.T) {
	service, store, stacks, actor := newClaimFixture(t)

	first, e := service.Claim(context.Background(), actor, claimOperation(1))
	if e != nil {
		t.Fatal(e)
	}
	if first.Level != 5 || len(first.Awards) != 1 || first.Awards[0].TableID != 50001181 || first.Awards[0].ItemNum != 3 {
		t.Fatalf("a first item not held before the claim keeps its grant delta: %+v", first)
	}
	if stacks.quantities[50001181] != 3 {
		t.Fatalf("durable count %d", stacks.quantities[50001181])
	}

	later := time.Unix(2000, 0).UTC()
	store.root.CompleteTimes[1] = &later
	second, e := service.Claim(context.Background(), actor, claimOperation(2))
	if e != nil {
		t.Fatal(e)
	}
	if second.Level != 6 || len(second.Awards) != 1 || second.Awards[0].ItemNum != 9 {
		t.Fatalf("an already-held first item carries its post-claim total: %+v", second)
	}
	if stacks.quantities[50001181] != 9 {
		t.Fatalf("durable count %d", stacks.quantities[50001181])
	}

	replay, e := service.Claim(context.Background(), actor, claimOperation(2))
	if e != nil || !reflect.DeepEqual(replay, second) {
		t.Fatalf("replay %+v %v", replay, e)
	}
}
