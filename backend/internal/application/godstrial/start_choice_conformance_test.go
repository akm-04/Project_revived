package godstrial

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
	"gxb.local/backend/v2/internal/domain/economy"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/spirit"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builder opens.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceGodsTrial STARTs 3092 twice for one campaign with a
// changed formation. ModeGodsTrial is ClientSummaryAttested, so the second
// START must freeze a different fingerprint.
func TestStartChoiceConformanceGodsTrial(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	store := &startChoiceStore{state: d.State{Wins: map[int64]int64{}}}
	combat := &startChoiceCombat{}
	mode := startChoiceMode(at, store, combat)
	if _, err := mode.Start(context.Background(), actor, Fight{Campaign: startChoiceCampaign, Formation: []int64{101}}, startChoiceOperation(t, ids.UUID{1}, at)); err != nil {
		t.Fatalf("first START: %v", err)
	}
	if _, err := mode.Start(context.Background(), actor, Fight{Campaign: startChoiceCampaign, Formation: []int64{201}}, startChoiceOperation(t, ids.UUID{2}, at)); err != nil {
		t.Fatalf("second START: %v", err)
	}
	assertStartChoiceCaptured(t, cd.ModeGodsTrial, combat.requests)
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

const startChoiceCampaign = 1001

func startChoiceOperation(t *testing.T, id ids.UUID, at time.Time) operation.Context {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at, Policies: policies}
}

func startChoiceMode(at time.Time, store *startChoiceStore, combat *startChoiceCombat) Mode {
	return Mode{
		Spirit:      startChoiceSpirit{},
		Progression: startChoiceProgression{},
		Mail:        startChoiceMail{},
		Energy:      startChoiceEnergy{},
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
		Facts:       startChoiceFacts{},
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
	return cb.Started{Attempt: cd.Attempt{ID: ids.UUID{byte(len(c.requests))}}, Package: &cd.StartPackage{Canonical: []byte("[]")}}, nil
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

func (startChoiceContent) GodsTrialCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return d.Catalog{SoftLimit: 2000, Stages: []d.Stage{{
		ID: startChoiceCampaign, Day: d.Weekday(modes.Day(time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC))),
		Level: 1, Battle: 11, WinCost: 20, LoseCost: 2, FirstBox: 1, RepeatBox: 2, Open: true,
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

type startChoiceSpirit struct{}

func (startChoiceSpirit) LockTrialInventoryTx(context.Context, tx.Tx, identity.PlayerID) (int64, error) {
	return 0, nil
}
func (startChoiceSpirit) ProviderRevision() string { return spirit.ReconstructionPolicy }

type startChoiceProgression struct{}

func (startChoiceProgression) ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error) {
	return player.Progression{Level: 100}, nil
}

type startChoiceMail struct{}

func (startChoiceMail) LockMailNamespaceCounterTx(context.Context, tx.Tx, identity.PlayerID, mail.Namespace) error {
	return nil
}

type startChoiceEnergy struct{}

func (startChoiceEnergy) TemporalBalanceTx(context.Context, tx.Tx, identity.PlayerID, string, operation.Context) (int64, error) {
	return 1000, nil
}

func (startChoiceEnergy) DebitTemporalTx(context.Context, tx.Tx, identity.PlayerID, string, int64, operation.Context) (economy.TemporalState, error) {
	return economy.TemporalState{}, nil
}

type startChoiceValues struct{}

func (startChoiceValues) SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error) {
	return i5.GrantResult{}, nil
}

type startChoiceFacts struct{}

func (startChoiceFacts) PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error) {
	return context.Background(), nil
}

func (startChoiceFacts) RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error {
	return nil
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
