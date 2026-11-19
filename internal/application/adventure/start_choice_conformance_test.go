package adventure

import (
	"context"
	"slices"
	"strconv"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/playerroot"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// startChoiceRevision is a valid exact content revision for the coherent read
// scope the builders open.
const startChoiceRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

// TestStartChoiceConformanceAdventureDefense STARTs 2431 twice for one
// monster position with a changed formation. ModeAdventureDefense is
// ClientSummaryAttested, so the second START must freeze a different
// fingerprint.
func TestStartChoiceConformanceAdventureDefense(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 100007, LogicalServerID: 1}
	campaign := d.DefenseCampaign{ID: 3, MinimumLevel: 1, MaximumLevel: 99, BattleIDs: []int64{11, 12, 13}, Gift: 1, Models: []int64{1, 2, 3}}
	content := startChoiceContent{adventure: d.Catalog{Campaigns: []d.DefenseCampaign{campaign}}}
	combat := &startChoiceCombat{}
	roomStore := &startChoiceRoomStore{}
	mode := newStartChoiceMode(at, content, combat, &startChoiceAdventureStore{}, roomStore)
	initial := startChoiceDefenseRoom(t, actor, at, campaign.ID)
	roomStore.room = initial
	if _, err := mode.StartDefense(context.Background(), actor, FightRequest{Formation: []int64{101, 102}}, 1,
		startChoiceOperation(t, ids.UUID{1}, at)); err != nil {
		t.Fatalf("first START: %v", err)
	}
	roomStore.room = initial
	if _, err := mode.StartDefense(context.Background(), actor, FightRequest{Formation: []int64{201, 202}}, 1,
		startChoiceOperation(t, ids.UUID{2}, at)); err != nil {
		t.Fatalf("second START: %v", err)
	}
	assertStartChoiceCaptured(t, cd.ModeAdventureDefense, combat.requests)
}

// TestStartChoiceConformanceAdventureIllusion STARTs 2421 twice for one
// occurrence with a changed formation. ModeAdventureIllusion is
// ClientSummaryAttested, so the second START must freeze a different
// fingerprint.
func TestStartChoiceConformanceAdventureIllusion(t *testing.T) {
	at := time.Date(2026, 11, 16, 12, 0, 0, 0, time.UTC)
	actor := identity.ActorContext{PlayerID: 100007, LogicalServerID: 1}
	event, ok := d.Profile(d.EventIllusion)
	if !ok {
		t.Fatal("adventure illusion event is not profiled")
	}
	occurrence, err := d.NewOccurrence("start-choice-occurrence", actor.PlayerID, event, at)
	if err != nil {
		t.Fatal(err)
	}
	fantasyCampaign := illusion.Campaign{ID: occurrence.SpecialData, CampaignType: 8, FightID: 11}
	content := startChoiceContent{fantasy: illusion.Catalog{Campaigns: []illusion.Campaign{fantasyCampaign}}}
	combat := &startChoiceCombat{}
	mode := newStartChoiceMode(at, content, combat, &startChoiceAdventureStore{occurrence: occurrence}, &startChoiceRoomStore{})
	if _, err := mode.StartSingle(context.Background(), actor, FightRequest{Formation: []int64{101, 102}},
		startChoiceOperation(t, ids.UUID{3}, at)); err != nil {
		t.Fatalf("first START: %v", err)
	}
	if _, err := mode.StartSingle(context.Background(), actor, FightRequest{Formation: []int64{201, 202}},
		startChoiceOperation(t, ids.UUID{4}, at)); err != nil {
		t.Fatalf("second START: %v", err)
	}
	assertStartChoiceCaptured(t, cd.ModeAdventureIllusion, combat.requests)
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

func startChoiceOperation(t *testing.T, id ids.UUID, at time.Time) operation.Context {
	t.Helper()
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: startChoiceRevision})
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: at, Policies: policies}
}

func newStartChoiceMode(at time.Time, content Content, combat Combat, adventureStore Store, roomStore *startChoiceRoomStore) Mode {
	timed := gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}}
	stubs := startChoiceStubs{}
	return Mode{
		Timed:          timed,
		Fresh:          startChoiceTx{},
		Store:          adventureStore,
		Content:        content,
		Functions:      startChoiceFunctions{},
		Directory:      startChoiceDirectory{},
		Guilds:         stubs,
		Heroes:         startChoiceRoster{},
		Pets:           stubs,
		Stats:          stubs,
		Combat:         combat,
		Costs:          stubs,
		Grants:         stubs,
		Opponents:      stubs,
		Wake:           stubs,
		Rooms:          sr.Service{Timed: timed, Fresh: startChoiceTx{}, Store: roomStore, Fence: startChoiceFence{}, Players: startChoiceRoots{}},
		RoomStore:      roomStore,
		Mail:           stubs,
		Partners:       stubs,
		HeroWire:       func(character.Hero) (map[string]any, error) { return nil, nil },
		BattleObserver: stubs,
	}
}

func startChoiceDefenseRoom(t *testing.T, actor identity.ActorContext, at time.Time, campaignID int64) sharedroom.Room {
	t.Helper()
	state := d.RoomState{CampaignID: campaignID, MasterLevel: 70, Phase: "OPEN", Busy: make([]d.BusyState, d.DefenseMonsterCount)}
	state.Busy[0] = d.BusyState{Player: int64(actor.PlayerID), Type: 1}
	payload, err := state.Encode()
	if err != nil {
		t.Fatal(err)
	}
	return sharedroom.Room{
		ID: 5, LogicalServerID: actor.LogicalServerID, Family: RoomFamily, Slot: DefenseSlot,
		Owner: actor.PlayerID, Capacity: d.DefenseRoomCapacity, Status: sharedroom.StatusOpen,
		Seats:     []sharedroom.Seat{{Index: 0, Player: actor.PlayerID, Stage: sharedroom.SeatSeated, JoinedAt: at}},
		ExpiresAt: at.Add(time.Hour), StateVersion: 1, NoticeVersion: 1, Payload: payload,
		CreatedAt: at, UpdatedAt: at,
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

func (c *startChoiceCombat) MonsterWaves(int64) ([][]cb.Participant, error) { return nil, nil }

type startChoiceAdventureStore struct {
	Store
	occurrence d.Occurrence
}

func (s *startChoiceAdventureStore) ReadOccurrenceTx(context.Context, tx.Queryer, identity.PlayerID, int64) (d.Occurrence, bool, error) {
	return s.occurrence, true, nil
}

type startChoiceRoomStore struct {
	sr.Store
	room sharedroom.Room
}

func (s *startChoiceRoomStore) ReadPlayerRoomTx(context.Context, tx.Queryer, identity.PlayerID, string, int64) (sharedroom.Room, bool, error) {
	return s.room, true, nil
}

func (s *startChoiceRoomStore) LockRoomTx(context.Context, tx.Tx, int64) (sharedroom.Room, bool, error) {
	return s.room, true, nil
}

func (s *startChoiceRoomStore) SaveRoomTx(_ context.Context, _ tx.Tx, room sharedroom.Room) error {
	s.room = room
	return nil
}

func (s *startChoiceRoomStore) WakeRoomTx(context.Context, tx.Tx, int64, string) error { return nil }

type startChoiceContent struct {
	Content
	adventure d.Catalog
	fantasy   illusion.Catalog
}

func (c startChoiceContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return startChoiceRevision, nil
}

func (c startChoiceContent) AdventureCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error) {
	return c.adventure, nil
}

func (c startChoiceContent) IllusionCatalogTx(context.Context, tx.Queryer, string) (illusion.Catalog, error) {
	return c.fantasy, nil
}

type startChoiceFunctions struct{}

func (startChoiceFunctions) ReadFunctionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64) (player.FunctionEligibility, bool, error) {
	return player.FunctionEligibility{}, true, nil
}

type startChoiceDirectory struct{}

func (startChoiceDirectory) ProfileTx(_ context.Context, _ tx.Queryer, id identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{PlayerID: id, Level: 70}, true, nil
}

type startChoiceRoster struct{}

func (startChoiceRoster) OverlayMID1(_ context.Context, _ tx.Queryer, _ identity.ActorContext, _ bool, _ time.Time, detail map[string]any) error {
	heroes := map[string]any{}
	for _, id := range []int64{101, 102, 201, 202} {
		heroes[strconv.FormatInt(id, 10)] = map[string]any{"partner_id": id, "table_id": id}
	}
	detail["49"] = map[string]any{"heros": heroes}
	return nil
}

// startChoiceStubs fills the ports neither START path touches.
type startChoiceStubs struct {
	Guilds
	Stats
	Costs
	Grants
	Opponents
	Wake
	Mail
	Partners
	Roster
	BattleObserver
}

type startChoiceFence struct{}

func (startChoiceFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	return nil
}

type startChoiceRoots struct{}

func (startChoiceRoots) LockPlayerRootsTx(context.Context, tx.Tx, identity.LogicalServerID, []identity.PlayerID) ([]playerroot.Root, error) {
	return nil, nil
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
