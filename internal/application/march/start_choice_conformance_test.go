package march

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
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	summon "gxb.local/backend/v2/internal/domain/summon"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builder opens.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceMarch STARTs 340 twice for one pending stage with a
// changed formation. The mode refuses that change while the attempt is open
// (`sameFormation` at mode.go:243-246), so the registered rule must be the
// refusal even though the builder also hashes the formation.
func TestStartChoiceConformanceMarch(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	store := &startChoiceStore{run: startChoiceRun()}
	combat := &startChoiceCombat{}
	mode := startChoiceMode(at, store, combat)
	if _, err := mode.Start(context.Background(), actor, Fight{Formation: []int64{101}}, startChoiceOperation(t, ids.UUID{1}, at)); err != nil {
		t.Fatalf("first START: %v", err)
	}
	_, err := mode.Start(context.Background(), actor, Fight{Formation: []int64{201}}, startChoiceOperation(t, ids.UUID{2}, at))
	assertStartChoiceCaptured(t, cd.ModeMarch, combat.requests, err)
}

func assertStartChoiceCaptured(t *testing.T, key cd.ModeKey, requests []cb.StartRequest, second error) {
	t.Helper()
	rule := cd.MustMode(key).OnChoiceChange
	if rule == cd.ChoiceRefusedWhileOpen {
		if second == nil {
			t.Fatalf("%s accepted a changed choice while open", key)
		}
		if len(requests) != 1 {
			t.Fatalf("%s captured %d START requests, want only the first", key, len(requests))
		}
		if requests[0].Mode != key {
			t.Fatalf("%s built mode %q", key, requests[0].Mode)
		}
		return
	}
	if second != nil {
		t.Fatalf("%s second START: %v", key, second)
	}
	if len(requests) != 2 {
		t.Fatalf("%s captured %d START requests, want two", key, len(requests))
	}
	first, secondRequest := requests[0], requests[1]
	if first.Mode != key || secondRequest.Mode != key {
		t.Fatalf("%s built modes %q and %q", key, first.Mode, secondRequest.Mode)
	}
	if first.Locator != secondRequest.Locator || first.Battle.BattleID != secondRequest.Battle.BattleID {
		t.Fatalf("%s STARTed two different stages", key)
	}
	if slices.Equal(startChoiceInput(first), startChoiceInput(secondRequest)) {
		t.Fatalf("%s STARTed twice with the same choice", key)
	}
	if rule != cd.ChoiceReplaysFrozen && rule != cd.ChoiceSupersedes {
		t.Fatalf("%s registered rule %q has no fingerprint expectation", key, rule)
	}
	wantEqual := rule == cd.ChoiceReplaysFrozen
	if equal := first.StartFingerprint == secondRequest.StartFingerprint; equal != wantEqual {
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

func startChoiceRun() d.Run {
	return d.Run{Occurrence: "start-choice", Passed: 0,
		Enemies: []d.Enemy{{Heroes: map[string]map[string]any{}}}}
}

func startChoiceMode(at time.Time, store *startChoiceStore, combat *startChoiceCombat) Mode {
	return Mode{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Fresh:       startChoiceTx{},
		Store:       store,
		Content:     startChoiceContent{},
		Fence:       startChoiceFence{},
		Functions:   startChoiceFunctions{},
		Directory:   startChoiceDirectory{},
		HeroLocks:   startChoiceHeroLocks{},
		Heroes:      startChoiceHeroes{},
		Roster:      startChoiceRoster{},
		HeroWire:    func(character.Hero) (map[string]any, error) { return map[string]any{}, nil },
		Opponents:   startChoiceOpponents{},
		Stats:       startChoiceStats{},
		Combat:      combat,
		Facts:       startChoiceFacts{},
		Grants:      startChoiceGrants{},
		Costs:       startChoiceCosts{},
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

func (c *startChoiceCombat) AttestReportTx(context.Context, tx.Tx, cb.ReportRequest) (cb.SummaryAttested, error) {
	return cb.SummaryAttested{}, nil
}

type startChoiceStore struct {
	Store
	run d.Run
}

func (s *startChoiceStore) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (d.Run, bool, error) {
	return s.run, true, nil
}

func (s *startChoiceStore) LockTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (d.Run, error) {
	return s.run, nil
}

func (s *startChoiceStore) SaveTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, run d.Run, _ time.Time) error {
	s.run = run
	return nil
}

type startChoiceContent struct{}

func (startChoiceContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return startChoiceRevision, nil
}

func (startChoiceContent) MarchCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return d.Catalog{Policy: d.Policy{ResultWindow: 60, CandidateLimit: 3, Reagents: 1}}, nil
}

func (startChoiceContent) SummonCatalogTx(context.Context, tx.Queryer, string) (summon.Catalog, error) {
	return summon.Catalog{}, nil
}

func (startChoiceContent) HeroColorLevelsTx(context.Context, tx.Queryer, string) (map[int64]d.HeroColorLevels, error) {
	return map[int64]d.HeroColorLevels{}, nil
}

type startChoiceFence struct{}

func (startChoiceFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type startChoiceFunctions struct{}

func (startChoiceFunctions) ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error) {
	return player.FunctionEligibility{}, true, nil
}

type startChoiceDirectory struct{}

func (startChoiceDirectory) ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{Level: 100}, true, nil
}

type startChoiceHeroLocks struct{}

func (startChoiceHeroLocks) LockHeroByPartnerIDTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, id int64) (character.Hero, error) {
	return character.Hero{PartnerID: id, OriginTableID: id}, nil
}

type startChoiceHeroes struct{ Heroes }

func (startChoiceHeroes) LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}

type startChoiceRoster struct{}

func (startChoiceRoster) OverlayMID1(_ context.Context, _ tx.Queryer, _ identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	rows := map[string]any{}
	for _, id := range []int64{101, 201} {
		rows[strconv.FormatInt(id, 10)] = map[string]any{"lev": int64(100), "partner_id": id}
	}
	detail["49"] = map[string]any{"heros": rows}
	return nil
}

type startChoiceOpponents struct{ Opponents }

type startChoiceStats struct{ cb.Stats }

type startChoiceGrants struct{ Grants }

type startChoiceCosts struct{ i5.TxMaterialCostDebiter }

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
