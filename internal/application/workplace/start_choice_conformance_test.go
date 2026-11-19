package workplace

import (
	"context"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/broadcast"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/statrules"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builders open.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceWorkplace STARTs 531 twice for one team. The
// nonce-less dispatch request is the stage (recon `nonce_less_dispatch`): an
// equivalent repeat replays the stored team without a second combat attempt,
// and a changed partner set is refused at jobs.go:36-37 before the builder.
func TestStartChoiceConformanceWorkplace(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	store := &startChoiceStore{}
	combat := &startChoiceCombat{}
	mode := startChoiceMode(at, store, combat)
	request := Dispatch{Team: 1, Job: 10, Partners: []int64{101}, SP: 0}
	first, err := mode.Dispatch(context.Background(), actor, request, startChoiceOperation(t, ids.UUID{1}, at))
	if err != nil {
		t.Fatalf("first START: %v", err)
	}
	repeat, err := mode.Dispatch(context.Background(), actor, request, startChoiceOperation(t, ids.UUID{2}, at))
	if err != nil {
		t.Fatalf("repeated START: %v", err)
	}
	if !reflect.DeepEqual(first, repeat) {
		t.Fatalf("an equivalent repeated START did not replay the stored team: %v / %v", first, repeat)
	}
	changed := request
	changed.Partners = []int64{201}
	_, changedErr := mode.Dispatch(context.Background(), actor, changed, startChoiceOperation(t, ids.UUID{3}, at))
	assertStartChoiceCaptured(t, cd.ModeWorkplace, combat.requests, changedErr)
}

func assertStartChoiceCaptured(t *testing.T, key cd.ModeKey, requests []cb.StartRequest, changedErr error) {
	t.Helper()
	rule := cd.MustMode(key).OnChoiceChange
	switch rule {
	case cd.ChoiceReplaysFrozen:
		if len(requests) != 1 {
			t.Fatalf("%s froze %d attempts for one stage, want one", key, len(requests))
		}
		if changedErr == nil {
			t.Fatalf("%s accepted a changed request as the same nonce-less stage", key)
		}
	case cd.ChoiceSupersedes:
		if changedErr != nil {
			t.Fatalf("%s refused a superseding START: %v", key, changedErr)
		}
		if len(requests) != 2 || requests[0].StartFingerprint == requests[1].StartFingerprint {
			t.Fatalf("%s did not freeze a new fingerprint on the changed choice", key)
		}
	default:
		t.Fatalf("%s registered rule %q has no fingerprint expectation", key, rule)
	}
	if requests[0].Mode != key {
		t.Fatalf("%s built mode %q", key, requests[0].Mode)
	}
	if len(startChoiceInput(requests[0])) == 0 {
		t.Fatalf("%s froze no participants", key)
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

func startChoiceMode(at time.Time, store *startChoiceStore, combat *startChoiceCombat) Mode {
	return Mode{
		Timed:          gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Fresh:          startChoiceTx{},
		Store:          store,
		Content:        startChoiceContent{},
		Fence:          startChoiceFence{},
		Functions:      startChoiceFunctions{},
		Directory:      startChoiceDirectory{},
		Campaigns:      startChoiceCampaigns{},
		Heroes:         startChoiceHeroes{},
		HeroLocks:      startChoiceHeroLocks{},
		HeroWire:       func(character.Hero) (map[string]any, error) { return map[string]any{}, nil },
		Opponents:      startChoiceOpponents{},
		Combat:         combat,
		Stats:          startChoiceStats{},
		Values:         startChoiceValues{},
		Privileges:     startChoicePrivileges{},
		Facts:          startChoiceFacts{},
		Receipts:       startChoiceReceipts{},
		ReceiptRead:    startChoiceReceiptRead{},
		Rental:         startChoiceRental{},
		Broadcast:      startChoiceBroadcast{},
		BattleObserver: startChoiceObserver{},
	}
}

type startChoiceObserver struct{}

func (startChoiceObserver) ObserveBattleTx(context.Context, tx.Tx, identity.PlayerID, []int64, time.Time) error {
	return nil
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

func (startChoiceContent) HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error) {
	return character.NormalHero, nil
}

func (startChoiceContent) WorkplaceCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return d.Catalog{
		Locations: []d.Location{{ID: 1, Jobs: []int64{10}, MaxMembers: 10, BaseTime: 60, ChestRate: 0, EnemyRate: 100}},
		Jobs:      []d.Job{{ID: 10, Product: 1, Chests: [][2]int64{{1, 1}}, RequireType: 1, Require: 1}},
		Crew:      []d.Crew{{BaseID: 101, Location: 1}, {BaseID: 201, Location: 1}},
		Formula:   d.Formula{Base: 100, Products: map[int64]d.Rate{1: {Numerator: 1, Denominator: 1}}, TraitAmounts: map[int64]int64{}},
		VIP:       []d.Rate{{Numerator: 1, Denominator: 1}},
		Policy:    d.Policy{MaxCombatCrew: 5, BonusLevel: 42, CampaignType: 6, BattleID: 113001, AttemptLifetime: 36000, DiaryLimit: 10},
	}, nil
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

type startChoiceCampaigns struct{}

func (startChoiceCampaigns) ReadTx(context.Context, tx.Queryer, identity.PlayerID) (campaign.Record, error) {
	return campaign.Record{}, nil
}

type startChoiceHeroes struct{}

func (startChoiceHeroes) LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}

type startChoiceHeroLocks struct{}

func (startChoiceHeroLocks) LockHeroByPartnerIDTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, id int64) (character.Hero, error) {
	return character.Hero{PartnerID: id, OriginTableID: id, Level: 1, Star: 1}, nil
}

type startChoiceOpponents struct{}

func (startChoiceOpponents) WorkplaceOpponentTx(context.Context, tx.Queryer, int64) ([]cb.Participant, error) {
	return nil, nil
}

type startChoiceStats struct{ cb.Stats }

func (startChoiceStats) HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error) {
	return publicstats.Result{Stats: statrules.Result{Force: 10}}, nil
}

type startChoiceValues struct{}

func (startChoiceValues) WorkplaceSPTx(context.Context, tx.Tx, identity.PlayerID, operation.Context) (economy.MaterializedTemporal, error) {
	return economy.MaterializedTemporal{}, nil
}

func (startChoiceValues) DebitTemporalTx(context.Context, tx.Tx, identity.PlayerID, string, int64, operation.Context) (economy.TemporalState, error) {
	return economy.TemporalState{}, nil
}

func (startChoiceValues) SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, i5.GrantTxOptions) (i5.GrantResult, error) {
	return i5.GrantResult{}, nil
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

type startChoiceRental struct{}

func (startChoiceRental) HeroOfferedTx(context.Context, tx.Queryer, identity.PlayerID, int64) (bool, error) {
	return false, nil
}

type startChoiceBroadcast struct{}

func (startChoiceBroadcast) EmitTx(context.Context, tx.Tx, broadcast.Message) error { return nil }

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
