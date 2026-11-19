package memoir

import (
	"context"
	"slices"
	"strconv"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/march"
	d "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builder opens.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceMemoirBattle STARTs 2314 twice for the same grid
// and generation with a different living roster. ModeMemoirBattle sends no
// team choice, so the second START must freeze the same fingerprint.
func TestStartChoiceConformanceMemoirBattle(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	roster := &startChoiceRoster{heroes: []int64{101, 102}}
	combat := &startChoiceCombat{}
	mode := startChoiceMode(at, roster, combat)
	if _, err := mode.StartFight(context.Background(), actor, 2, startChoiceOperation(t, ids.UUID{1}, at)); err != nil {
		t.Fatalf("first START: %v", err)
	}
	roster.heroes = []int64{201, 202}
	if _, err := mode.StartFight(context.Background(), actor, 2, startChoiceOperation(t, ids.UUID{2}, at)); err != nil {
		t.Fatalf("second START: %v", err)
	}
	assertStartChoiceCaptured(t, cd.ModeMemoirBattle, combat.requests)
}

func assertStartChoiceCaptured(t *testing.T, key cd.ModeKey, requests []cb.StartRequest) {
	t.Helper()
	if len(requests) != 2 {
		t.Fatalf("%s captured %d START requests, want two", key, len(requests))
	}
	first, second := requests[0], requests[1]
	if first.Mode != key || second.Mode != key {
		t.Fatalf("%s built modes %q and %q", key, first.Mode, second.Mode)
	}
	if first.Locator != second.Locator || first.GenerationRef != second.GenerationRef {
		t.Fatalf("%s STARTed two different stages", key)
	}
	if slices.Equal(startChoiceInput(first), startChoiceInput(second)) {
		t.Fatalf("%s STARTed twice with the same choice", key)
	}
	rule := cd.MustMode(key).OnChoiceChange
	if rule != cd.ChoiceReplaysFrozen && rule != cd.ChoiceSupersedes {
		t.Fatalf("%s registered rule %q has no fingerprint expectation", key, rule)
	}
	wantEqual := rule == cd.ChoiceReplaysFrozen
	if equal := first.StartFingerprint == second.StartFingerprint; equal != wantEqual {
		t.Fatalf("%s registered rule %q: fingerprints equal=%v, want %v", key, rule, equal, wantEqual)
	}
}

func startChoiceInput(request cb.StartRequest) []int64 {
	identities := make([]int64, 0, len(request.Battle.TeamA)+len(request.Battle.PetsA))
	for _, participant := range request.Battle.TeamA {
		identities = append(identities, participant.Identity)
	}
	for _, participant := range request.Battle.PetsA {
		identities = append(identities, participant.Identity)
	}
	return identities
}

func startChoiceOperation(t *testing.T, id ids.UUID, at time.Time) operation.Context {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at, Policies: policies}
}

func startChoiceMode(at time.Time, roster *startChoiceRoster, combat *startChoiceCombat) Mode {
	state := startChoiceState()
	return Mode{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Fresh:       startChoiceTx{},
		Store:       startChoiceStore{state: state},
		Content:     startChoiceContent{},
		Fence:       startChoiceFence{},
		Functions:   startChoiceFunctions{},
		Heroes:      startChoiceHeroes{},
		HeroLocks:   startChoiceHeroLocks{},
		Roster:      roster,
		Pets:        startChoicePets{},
		Opponents:   startChoiceOpponents{},
		Combat:      combat,
		Grants:      startChoiceGrants{},
		Costs:       startChoiceCosts{},
		Energy:      startChoiceEnergy{},
		Exchange:    startChoiceExchange{},
		Receipts:    startChoiceReceipts{},
		ReceiptRead: startChoiceReceiptRead{},
	}
}

func startChoiceState() d.State {
	cells := make([]int64, d.BoardCells)
	cells[d.InitialPosition-1] = d.Road
	cells[1] = d.Monster
	cells[d.GuardianPosition-1] = d.Guardian
	cells[d.FinalPosition-1] = d.Endpoint
	open := map[int]int64{}
	for position := 1; position <= d.BoardCells; position++ {
		open[position] = 1
	}
	return d.State{
		Occurrence: "start-choice",
		Revision:   startChoiceRevision,
		Girl:       5,
		Floor:      1,
		Board: d.Board{
			Cells:    cells,
			Open:     open,
			Enemies:  map[int]int64{2: 11, d.GuardianPosition: 21},
			Position: d.InitialPosition,
		},
		Heroes:    map[int64]cd.ActorStatus{},
		Enemies:   map[int]d.EnemyCarry{},
		Opponents: map[int]march.Enemy{},
		MaxFloor:  map[int64]int{},
	}
}

func startChoiceCatalog() d.Catalog {
	return d.Catalog{
		BigKey:      1,
		SmallKey:    2,
		Floors:      []d.Floor{{ID: 1, Energy: []int64{1, 1, 1}, Scroll: []int64{0, 0, 0}}},
		Girls:       []d.Girl{{ID: 5, Scroll: 1, Boxes: [][]int64{{1, 1, 1}, {1, 1, 1}, {1, 1, 1}}}},
		Fights:      map[int64][][]int64{11: {{9001}}},
		ReviveCosts: []int64{1},
	}
}

// startChoiceCombat records the StartRequest the mode builder produced and
// answers like a frozen START.
type startChoiceCombat struct {
	Combat
	requests []cb.StartRequest
}

func (c *startChoiceCombat) StartTx(_ context.Context, _ tx.Tx, _ ca.CoherentReadScope, request cb.StartRequest) (cb.Started, error) {
	c.requests = append(c.requests, request)
	return cb.Started{Attempt: cd.Attempt{ID: ids.UUID{byte(len(c.requests))}}}, nil
}

type startChoiceStore struct {
	Store
	state d.State
}

func (s startChoiceStore) LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.State, error) {
	return s.state, nil
}

func (startChoiceStore) TuningTx(context.Context, tx.Queryer) (d.Tuning, bool, error) {
	return d.Tuning{}, false, nil
}

func (startChoiceStore) SaveTx(context.Context, tx.Tx, identity.PlayerID, d.State, time.Time) error {
	return nil
}

type startChoiceContent struct{ Content }

func (startChoiceContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return startChoiceRevision, nil
}

func (startChoiceContent) MemoirCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return startChoiceCatalog(), nil
}

type startChoiceFence struct{}

func (startChoiceFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type startChoiceFunctions struct{}

func (startChoiceFunctions) ReadFunctionEligibilityTx(_ context.Context, _ tx.Queryer, id identity.PlayerID, function int64) (player.FunctionEligibility, bool, error) {
	return player.FunctionEligibility{PlayerID: id, FunctionID: function}, true, nil
}

type startChoiceHeroes struct{}

func (startChoiceHeroes) LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}

type startChoiceHeroLocks struct{}

func (startChoiceHeroLocks) LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error) {
	return character.Hero{}, nil
}

type startChoiceRoster struct {
	heroes []int64
}

func (r *startChoiceRoster) OverlayMID1(_ context.Context, _ tx.Queryer, _ identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	rows := map[string]any{}
	for _, identifier := range r.heroes {
		rows[strconv.FormatInt(identifier, 10)] = map[string]any{"partner_id": identifier, "table_id": identifier}
	}
	detail["49"] = map[string]any{"heros": rows}
	return nil
}

type startChoicePets struct{}

func (startChoicePets) OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error {
	return nil
}

type startChoiceOpponents struct{ Opponents }

type startChoiceGrants struct{ Grants }

type startChoiceCosts struct{ i5.TxMaterialCostDebiter }

type startChoiceEnergy struct{ i5.TxTemporalDebiter }

func (startChoiceEnergy) DebitTemporalTx(context.Context, tx.Tx, identity.PlayerID, string, int64, operation.Context) (economy.TemporalState, error) {
	return economy.TemporalState{}, nil
}

type startChoiceExchange struct{ i5.TxMaterialExchange }

type startChoiceReceipts struct{}

func (startChoiceReceipts) FindTx(context.Context, tx.Queryer, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

func (startChoiceReceipts) PutTx(context.Context, tx.Tx, receipt.Receipt) (receipt.PutResult, error) {
	return receipt.PutResult{}, nil
}

type startChoiceReceiptRead struct{}

func (startChoiceReceiptRead) Find(context.Context, receipt.Identity) (receipt.Receipt, bool, error) {
	return receipt.Receipt{}, false, nil
}

type startChoiceTx struct{}

func (startChoiceTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (startChoiceTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (startChoiceTx) Commit(context.Context) error                                { return nil }
func (startChoiceTx) Rollback(context.Context) error                              { return nil }

type startChoiceBeginner struct{}

func (startChoiceBeginner) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return startChoiceTx{}, nil
}

type startChoiceClock struct{ at time.Time }

func (c startChoiceClock) Now(context.Context) (time.Time, error) { return c.at, nil }
