package guildcampaign

import (
	"context"
	"slices"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builder opens.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceGuildCampaign STARTs 604 twice for one copy with a
// changed formation. ModeGuildCampaign is ClientSummaryAttested, so the second
// START must freeze a different fingerprint.
func TestStartChoiceConformanceGuildCampaign(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 7, LogicalServerID: 1}
	combat := &startChoiceCombat{}
	mode := startChoiceMode(at, combat)
	first := Fight{ChapterID: 1, CopyID: 1, CampaignType: 7, Formation: "101"}
	second := Fight{ChapterID: 1, CopyID: 1, CampaignType: 7, Formation: "201"}
	if _, err := mode.Start(context.Background(), actor, first, startChoiceOperation(t, ids.UUID{1}, at)); err != nil {
		t.Fatalf("first START: %v", err)
	}
	if _, err := mode.Start(context.Background(), actor, second, startChoiceOperation(t, ids.UUID{2}, at)); err != nil {
		t.Fatalf("second START: %v", err)
	}
	assertStartChoiceCaptured(t, cd.ModeGuildCampaign, combat.requests)
}

func assertStartChoiceCaptured(t *testing.T, key cd.ModeKey, requests []combat.StartRequest) {
	t.Helper()
	if len(requests) != 2 {
		t.Fatalf("%s captured %d START requests, want two", key, len(requests))
	}
	first, second := requests[0], requests[1]
	if first.Mode != key || second.Mode != key {
		t.Fatalf("%s built modes %q and %q", key, first.Mode, second.Mode)
	}
	if first.Locator != second.Locator || first.GenerationRef != second.GenerationRef || first.Battle.BattleID != second.Battle.BattleID {
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

func startChoiceInput(request combat.StartRequest) []int64 {
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

func startChoiceMode(at time.Time, combat *startChoiceCombat) Mode {
	return Mode{
		Service: Service{Runner: tx.Runner{DB: startChoiceBeginner{}}, Store: startChoiceChapterStore{}, Guilds: startChoiceGuilds{},
			Fence: startChoiceFence{}, Players: startChoicePlayers{}},
		ModeStore:  startChoiceModeStore{},
		Content:    startChoiceContent{},
		Settings:   Settings{AttemptsPerChapterDay: 3, BattleSeconds: 60},
		Combat:     combat,
		Grants:     startChoiceGrants{},
		Facts:      startChoiceFacts{},
		Directory:  startChoiceDirectory{},
		Roster:     startChoiceRoster{},
		Awakenings: startChoiceAwakenings{},
		Mail:       startChoiceMail{},
		Timed:      gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}},
		Fresh:      startChoiceTx{},
		Receipts:   stubResultReceipts{},
	}
}

// startChoiceCombat records the StartRequest the mode builder produced and
// answers like a frozen START.
type startChoiceCombat struct {
	ModeCombat
	requests []combat.StartRequest
}

func (c *startChoiceCombat) StartTx(_ context.Context, _ tx.Tx, _ ca.CoherentReadScope, request combat.StartRequest) (combat.Started, error) {
	c.requests = append(c.requests, request)
	return combat.Started{Attempt: cd.Attempt{ID: ids.UUID{byte(len(c.requests))}}}, nil
}

func (c *startChoiceCombat) AttestSummaryTx(context.Context, tx.Tx, combat.SummaryRequest) (combat.SummaryAttested, error) {
	return combat.SummaryAttested{}, nil
}

type startChoiceModeStore struct{ ModeStore }

func (startChoiceModeStore) LockMemberDayTx(context.Context, tx.Tx, identity.PlayerID, int64, int64) (int64, error) {
	return 0, nil
}

func (startChoiceModeStore) IsRegisteredTx(context.Context, tx.Queryer, int64, int64, identity.PlayerID) (bool, error) {
	return true, nil
}

func (startChoiceModeStore) LockCopyTx(context.Context, tx.Tx, int64, int64, int64) (d.Copy, bool, error) {
	return d.Copy{}, true, nil
}

func (startChoiceModeStore) SaveCopyTx(context.Context, tx.Tx, d.Copy) error { return nil }

type startChoiceChapterStore struct{ Store }

func (startChoiceChapterStore) LockChapterTx(context.Context, tx.Tx, int64, int64) (d.Chapter, bool, error) {
	return d.Chapter{}, true, nil
}

type startChoiceContent struct{}

func (startChoiceContent) ChapterInfo(int64) (ChapterInfo, bool) { return ChapterInfo{}, true }

func (startChoiceContent) ChapterOfCopy(int64) (int64, bool) { return 1, true }

func (startChoiceContent) CopyInfo(int64, int64) (CopyInfo, bool) {
	return CopyInfo{FightID: 11}, true
}

type startChoiceGuilds struct{ Guilds }

func (startChoiceGuilds) ReadMembership(context.Context, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{GuildID: 1}, true, nil
}

type startChoiceFence struct{}

func (startChoiceFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type startChoicePlayers struct{}

func (startChoicePlayers) LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error) {
	return nil, nil
}

type startChoiceGrants struct{ Grants }

type startChoiceFacts struct{}

func (startChoiceFacts) PrepareTx(context.Context, tx.Tx, identity.PlayerID, gen.TimedOperation) (context.Context, error) {
	return context.Background(), nil
}

func (startChoiceFacts) RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error {
	return nil
}

type startChoiceDirectory struct{ Directory }

type startChoiceRoster struct{ Roster }

type startChoiceAwakenings struct{ Awakenings }

type startChoiceMail struct{ Mailer }

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
