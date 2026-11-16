package occult

import (
	"context"
	"slices"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builders open.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceOccultSolo attests 2372 twice for one stage with a
// changed formation, which is where 2379's START is built. ModeOccultSolo is
// ClientSummaryAttested, so the second START must freeze a different
// fingerprint.
func TestStartChoiceConformanceOccultSolo(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	view := &roomView{room: sharedroom.Room{ID: 9, LogicalServerID: 1}, at: at}
	campaign := d.Campaign{ID: 5, FightIDs: []int64{11}}
	combat := &startChoiceCombat{}
	mode := Mode{Combat: combat}
	first := startChoiceScope(t, ids.UUID{1}, at)
	second := startChoiceScope(t, ids.UUID{2}, at)
	if _, err := mode.attest(context.Background(), first, actor, view, campaign,
		SettleRequest{Star: 1, Formation: []int64{101, 102}}, 0); err != nil {
		t.Fatalf("first START: %v", err)
	}
	if _, err := mode.attest(context.Background(), second, actor, view, campaign,
		SettleRequest{Star: 1, Formation: []int64{201, 202}}, 0); err != nil {
		t.Fatalf("second START: %v", err)
	}
	assertStartChoiceCaptured(t, cd.ModeOccultSolo, combat.requests)
}

// TestStartChoiceConformanceOccultTeam STARTs the team fight twice for one
// stage and round with changed picks. ModeOccultTeam is ServerReport, so the
// second START must freeze the same fingerprint.
func TestStartChoiceConformanceOccultTeam(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	view := &roomView{
		room: sharedroom.Room{ID: 9, LogicalServerID: 1, Seats: []sharedroom.Seat{
			{Index: 0, Player: 7, Stage: sharedroom.SeatSeated},
			{Index: 1, Player: 8, Stage: sharedroom.SeatSeated},
		}},
		state: d.RunState{Stages: map[string][]d.StageState{"5": {{HP: 100}}}},
		at:    at,
	}
	campaign := d.Campaign{ID: 5, FightIDs: []int64{11}}
	firstTeam := d.TeamFight{CampaignID: 5, SubID: 1, StartPlayer: 7, Round: 1, Picks: map[string]d.TeamPick{
		"7": {Heroes: []int64{101}},
		"8": {Heroes: []int64{201, 202}},
	}}
	secondTeam := d.TeamFight{CampaignID: 5, SubID: 1, StartPlayer: 7, Round: 1, Picks: map[string]d.TeamPick{
		"7": {Heroes: []int64{301}},
		"8": {Heroes: []int64{401, 402}},
	}}
	combat := &startChoiceCombat{}
	mode := Mode{Combat: combat}
	first := startChoiceScope(t, ids.UUID{3}, at)
	second := startChoiceScope(t, ids.UUID{4}, at)
	if _, err := mode.startTeamAttempt(context.Background(), first, actor, view, firstTeam, campaign); err != nil {
		t.Fatalf("first START: %v", err)
	}
	if _, err := mode.startTeamAttempt(context.Background(), second, actor, view, secondTeam, campaign); err != nil {
		t.Fatalf("second START: %v", err)
	}
	assertStartChoiceCaptured(t, cd.ModeOccultTeam, combat.requests)
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
	if len(request.Battle.Formation) > 0 {
		return request.Battle.Formation
	}
	identities := make([]int64, 0, len(request.Battle.TeamA)+len(request.Battle.PetsA))
	for _, participant := range request.Battle.TeamA {
		identities = append(identities, participant.Identity)
	}
	for _, participant := range request.Battle.PetsA {
		identities = append(identities, participant.Identity)
	}
	return identities
}

func startChoiceScope(t *testing.T, id ids.UUID, at time.Time) gen.TimedScope {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	timed, err := gen.NewTimedOperation(operation.Context{ID: id, StartedAt: at, Policies: policies}, at)
	if err != nil {
		t.Fatal(err)
	}
	return gen.TimedScope{Tx: startChoiceTx{}, Operation: timed, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}
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

func (c *startChoiceCombat) MonsterWaves(int64) ([][]cb.Participant, error) { return nil, nil }

func (c *startChoiceCombat) AttestSummaryTx(context.Context, tx.Tx, cb.SummaryRequest) (cb.SummaryAttested, error) {
	return cb.SummaryAttested{}, nil
}

func (c *startChoiceCombat) SnapshotTx(context.Context, tx.Queryer, ids.UUID) (cd.Snapshot, error) {
	return cd.Snapshot{}, nil
}

type startChoiceTx struct{}

func (startChoiceTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (startChoiceTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (startChoiceTx) Commit(context.Context) error                                { return nil }
func (startChoiceTx) Rollback(context.Context) error                              { return nil }
