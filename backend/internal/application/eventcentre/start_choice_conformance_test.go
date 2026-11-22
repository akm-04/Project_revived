package eventcentre

import (
	"context"
	"reflect"
	"testing"
	"time"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
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

// TestStartChoiceConformanceEventCentreBoard reads 1083 twice for one due
// notice-board mission. The leader and partners are frozen at receive
// (eventcentre/board.go:205); BoardInfo never starts a mission whose stored
// attempt is set (eventcentre/board.go:325-329) and startBoardAttempt reads the
// stored mission (eventcentre/board.go:455-457), so the second read starts no
// second combat attempt.
func TestStartChoiceConformanceEventCentreBoard(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	owner := &startChoiceOwner{root: startChoiceRoot(at)}
	combat := &startChoiceCombat{}
	observer := &startChoiceObserver{}
	service := startChoiceService(at, owner, combat, observer)
	if _, err := service.BoardInfo(context.Background(), actor, startChoiceOperation(t, ids.UUID{1}, at)); err != nil {
		t.Fatalf("first 1083: %v", err)
	}
	if !reflect.DeepEqual(observer.partners, []int64{1, 2}) {
		t.Fatalf("settled mission observation %v, want the frozen leader and partner", observer.partners)
	}
	if len(combat.requests) != 1 {
		t.Fatalf("captured %d START requests, want one", len(combat.requests))
	}
	request := combat.requests[0]
	if request.Mode != cd.ModeEventCentreBoard {
		t.Fatalf("built mode %q", request.Mode)
	}
	if len(request.Battle.TeamA) != 2 || request.Battle.TeamA[0].Identity != 1 || request.Battle.TeamA[1].Identity != 2 {
		t.Fatalf("frozen team %+v", request.Battle.TeamA)
	}
	if _, err := service.BoardInfo(context.Background(), actor, startChoiceOperation(t, ids.UUID{2}, at)); err != nil {
		t.Fatalf("second 1083: %v", err)
	}
	if len(combat.requests) != 1 {
		t.Fatalf("a repeated 1083 opened %d combat attempts, want the stored one", len(combat.requests))
	}
}

func startChoiceRoot(at time.Time) ec.Root {
	facts := Seed()
	facts.Board.Doing = []ec.BoardMission{{MissionID: 10001, Leader: 1, Partners: []int64{2}, StartAt: at.Add(-time.Minute).Unix(), Type: ec.BoardTaskTypeNormal, AwardID: 1}}
	return ec.Root{Player: 7, Version: 1, Revision: startChoiceRevision, Facts: facts, CreatedAt: at.Add(-time.Hour), UpdatedAt: at.Add(-time.Hour)}
}

type startChoiceObserver struct {
	partners []int64
}

func (o *startChoiceObserver) ObserveBattleTx(_ context.Context, _ tx.Tx, _ identity.PlayerID, partners []int64, _ time.Time) error {
	o.partners = append([]int64(nil), partners...)
	return nil
}

func startChoiceService(at time.Time, owner *startChoiceOwner, combat *startChoiceCombat, observer BattleObserver) Service {
	return Service{
		Timed:          gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Reads:          tx.Runner{DB: startChoiceBeginner{}},
		Owner:          owner,
		Book:           startChoiceBook{},
		Content:        startChoiceContent{},
		Pets:           startChoicePets{},
		Players:        startChoicePlayers{},
		Fence:          startChoiceFence{},
		Costs:          startChoiceCosts{},
		Grants:         startChoiceGrants{},
		Receipts:       startChoiceReceipts{},
		Heroes:         startChoiceHeroes{},
		Levels:         startChoiceLevels{},
		Stats:          startChoiceStats{},
		Combat:         combat,
		Facts:          startChoiceFacts{},
		BattleObserver: observer,
	}
}

// startChoiceCombat records the StartRequest the board builder produced and
// settles every due mission as a report-backed loss.
type startChoiceCombat struct {
	BoardCombat
	requests []appcombat.StartRequest
}

func (c *startChoiceCombat) StartTx(_ context.Context, _ tx.Tx, _ ca.CoherentReadScope, request appcombat.StartRequest) (appcombat.Started, error) {
	c.requests = append(c.requests, request)
	return appcombat.Started{Attempt: cd.Attempt{ID: ids.UUID{byte(len(c.requests))}}}, nil
}

func (c *startChoiceCombat) Resolve(context.Context, operation.Context, ids.UUID) (appcombat.Resolved, error) {
	return appcombat.Resolved{}, nil
}

func (c *startChoiceCombat) TerminalTx(context.Context, tx.Tx, appcombat.TerminalRequest) (appcombat.Settled, error) {
	return appcombat.Settled{Resolved: appcombat.Resolved{Report: []byte(`{}`)}}, nil
}

type startChoiceOwner struct {
	OwnerPort
	root ec.Root
}

func (o *startChoiceOwner) LockRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, bool, error) {
	return o.root, true, nil
}

func (o *startChoiceOwner) SaveRootTx(_ context.Context, _ tx.Tx, root Root, _ int64) error {
	o.root = root
	return nil
}

func (*startChoiceOwner) InsertBoardReportTx(context.Context, tx.Tx, identity.PlayerID, int64, string, time.Time) error {
	return nil
}

func (*startChoiceOwner) DeleteBoardReportsExceptTx(context.Context, tx.Tx, identity.PlayerID, []int64) error {
	return nil
}

type startChoiceContent struct{ ContentPort }

func (startChoiceContent) WorkshopInputsActive(context.Context) (string, bool, error) {
	return startChoiceRevision, true, nil
}

func (startChoiceContent) WorkshopInputsTx(context.Context, tx.Queryer, string) (Catalog, error) {
	return Catalog{Missions: map[int64]ec.MissionRule{10001: {ID: 10001, HeroID: 1, FightID: 9001, Duration: 10, EnemyIDs: []int64{1, 2, 3, 4, 5}}}}, nil
}

type startChoiceBook struct{ BookPort }

func (startChoiceBook) BookInputsTx(context.Context, tx.Queryer, appbook.InputScope) (appbook.Inputs, error) {
	return appbook.Inputs{}, nil
}

type startChoicePets struct{ PetPort }

type startChoicePlayers struct{ playerroot.TxLocker }

func (startChoicePlayers) LockPlayerRootsTx(_ context.Context, _ tx.Tx, server identity.LogicalServerID, players []identity.PlayerID) ([]playerroot.Root, error) {
	return []playerroot.Root{{PlayerID: players[0], LogicalServerID: server}}, nil
}

type startChoiceFence struct{ ActorFence }

func (startChoiceFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type startChoiceCosts struct{ CostPort }

type startChoiceGrants struct{ GrantPort }

type startChoiceReceipts struct{ receipt.Store }

type startChoiceHeroes struct{ BoardHeroes }

func (startChoiceHeroes) ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error) {
	return nil, nil
}

type startChoiceLevels struct{ BoardLevels }

func (startChoiceLevels) ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error) {
	return player.Progression{Level: 60}, nil
}

type startChoiceStats struct{ BoardStats }

type startChoiceFacts struct{ FactsPort }

func (startChoiceFacts) PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error) {
	return context.Background(), nil
}

func (startChoiceFacts) RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error {
	return nil
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

func startChoiceOperation(t *testing.T, id ids.UUID, at time.Time) operation.Context {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at, Policies: policies}
}
