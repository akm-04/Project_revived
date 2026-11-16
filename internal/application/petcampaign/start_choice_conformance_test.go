package petcampaign

import (
	"context"
	"slices"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
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

// TestStartChoiceConformancePetCampaign STARTs 819 twice for one floor with a
// changed formation. ModePetCampaign is ClientSummaryAttested, so the second
// START must freeze a different fingerprint.
func TestStartChoiceConformancePetCampaign(t *testing.T) {
	combat := startChoiceStarts(t, Fight{Campaign: startChoiceFloor, Formation: []int64{101}}, Fight{Campaign: startChoiceFloor, Formation: []int64{201}})
	assertStartChoiceCaptured(t, cd.ModePetCampaign, combat.requests)
}

// TestStartChoiceConformancePetCampaignPractice STARTs the practice mode twice
// for one floor with a changed formation. The practice generation and request
// both carry the choice, so the fingerprints differ.
func TestStartChoiceConformancePetCampaignPractice(t *testing.T) {
	combat := startChoiceStarts(t, Fight{Campaign: startChoiceFloor, Formation: []int64{101}, Practice: true}, Fight{Campaign: startChoiceFloor, Formation: []int64{201}, Practice: true})
	assertStartChoiceCaptured(t, cd.ModePetCampaignPractice, combat.requests)
}

func startChoiceStarts(t *testing.T, first, second Fight) *startChoiceCombat {
	t.Helper()
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	store := &startChoiceStore{state: startChoiceState(at)}
	combat := &startChoiceCombat{}
	mode := startChoiceMode(at, store, combat)
	if _, err := mode.Start(context.Background(), actor, first, startChoiceOperation(t, ids.UUID{1}, at)); err != nil {
		t.Fatalf("first START: %v", err)
	}
	if _, err := mode.Start(context.Background(), actor, second, startChoiceOperation(t, ids.UUID{2}, at)); err != nil {
		t.Fatalf("second START: %v", err)
	}
	return combat
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
	if first.Locator != second.Locator || first.Battle.BattleID != second.Battle.BattleID {
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

const startChoiceFloor = 2001

func startChoiceOperation(t *testing.T, id ids.UUID, at time.Time) operation.Context {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at, Policies: policies}
}

func startChoiceState(at time.Time) d.State {
	return d.State{Initialized: true, Day: modes.Day(at), Max: 100, TestFormation: map[int64]string{}}
}

func startChoiceMode(at time.Time, store *startChoiceStore, combat *startChoiceCombat) Mode {
	return Mode{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Fresh:       startChoiceTx{},
		Store:       store,
		Content:     startChoiceContent{},
		Fence:       startChoiceFence{},
		Functions:   startChoiceFunctions{},
		Heroes:      startChoiceHeroes{},
		HeroLocks:   startChoiceHeroLocks{},
		Pets:        startChoicePets{},
		Combat:      combat,
		Rules:       startChoiceRules{},
		Values:      startChoiceValues{},
		Costs:       startChoiceCosts{},
		Privileges:  startChoicePrivileges{},
		Facts:       startChoiceFacts{},
		Awakening:   startChoiceAwakening{},
		Receipts:    startChoiceReceipts{},
		ReceiptRead: startChoiceReceiptRead{},
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

func (c *startChoiceCombat) AttestSummaryTx(context.Context, tx.Tx, cb.SummaryRequest) (cb.SummaryAttested, error) {
	return cb.SummaryAttested{}, nil
}

type startChoiceStore struct {
	Store
	state d.State
}

func (s *startChoiceStore) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.State, bool, error) {
	return s.state, true, nil
}

func (s *startChoiceStore) LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.State, error) {
	return s.state, nil
}

func (s *startChoiceStore) SaveTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, state d.State, _ time.Time) error {
	s.state = state
	return nil
}

type startChoiceContent struct{}

func (startChoiceContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return startChoiceRevision, nil
}

func (startChoiceContent) PetCampaignCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return d.Catalog{Ticket: 100, PracticeMana: 10, Floors: []d.Floor{{
		ID: startChoiceFloor, Number: 1, Type: 2, Fight: 11,
	}}}, nil
}

type startChoiceFence struct{}

func (startChoiceFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type startChoiceFunctions struct{}

func (startChoiceFunctions) ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error) {
	return player.FunctionEligibility{}, true, nil
}

type startChoiceHeroes struct{}

func (startChoiceHeroes) LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}

type startChoiceHeroLocks struct{}

func (startChoiceHeroLocks) LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error) {
	return character.Hero{}, nil
}

type startChoicePets struct{}

func (startChoicePets) LockCampaignPetTx(context.Context, tx.Tx, identity.PlayerID, int64) error {
	return nil
}

type startChoiceRules struct{}

func (startChoiceRules) ID() string                  { return "start-choice-rules" }
func (startChoiceRules) SourceArchiveSHA256() string { return startChoiceRevision }
func (startChoiceRules) FighterClass(string, int64) (string, bool, bool) {
	return "warrior", true, true
}
func (startChoiceRules) BattleLineup(int64) ([][]int64, []int64, error) { return nil, nil, nil }

type startChoiceValues struct{ Values }

type startChoiceCosts struct{}

func (startChoiceCosts) DebitMaterialCostTx(context.Context, tx.Tx, identity.PlayerID, i5.MaterialCost, operation.Context) (i5.MaterialDebitResult, error) {
	return i5.MaterialDebitResult{}, nil
}

type startChoicePrivileges struct{}

func (startChoicePrivileges) SnapshotTx(context.Context, tx.Queryer, identity.PlayerID, time.Time) (i5.PrivilegeSnapshot, error) {
	return i5.PrivilegeSnapshot{}, nil
}

type startChoiceFacts struct{}

func (startChoiceFacts) PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error) {
	return context.Background(), nil
}

func (startChoiceFacts) RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error {
	return nil
}

type startChoiceAwakening struct{}

func (startChoiceAwakening) FreezeAwakeningPetMaterialTx(context.Context, tx.Queryer, identity.PlayerID, []i5.MaterialRoute) (*objective.AwakeFrozenDrop, error) {
	return nil, nil
}

func (startChoiceAwakening) CheckAwakeningPetMaterialTx(context.Context, tx.Queryer, identity.PlayerID, objective.AwakeFrozenDrop) (bool, error) {
	return false, nil
}

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
