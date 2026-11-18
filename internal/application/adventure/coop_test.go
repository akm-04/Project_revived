package adventure

import (
	"context"
	"slices"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TestA133CoopResultSettlesFrozenRoster proves RESULT settles and mails every
// member the START froze, not the room's live seats. The store steps the room
// from the three-seat START roster to the two-seat post-leave roster while the
// attempt resolves, exactly as a voluntary leave between START and RESULT does.
func TestA133CoopResultSettlesFrozenRoster(t *testing.T) {
	at := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	a := identity.ActorContext{PlayerID: 100007, LogicalServerID: 1}
	b := identity.ActorContext{PlayerID: 100008, LogicalServerID: 1}
	c := identity.ActorContext{PlayerID: 100009, LogicalServerID: 1}
	frozen := []identity.PlayerID{a.PlayerID, b.PlayerID, c.PlayerID}
	started := coopTestRoom(t, at, a.PlayerID, frozen)
	left := coopTestRoom(t, at, a.PlayerID, []identity.PlayerID{a.PlayerID, c.PlayerID})
	roomStore := &startChoiceRoomStore{room: started}
	combat := &coopRosterCombat{attempt: ids.UUID{7}, frozen: frozen, report: []byte(`{"fighter":{}}`),
		onResolve: func() { roomStore.room = left }}
	adventureStore := &coopAdventureStore{}
	mailbox := &coopMailRecorder{}
	mode := newCoopTestMode(at, startChoiceContent{fantasy: illusion.Catalog{Campaigns: []illusion.Campaign{{ID: 9001, FightID: 21}}}},
		combat, adventureStore, mailbox, roomStore)

	if _, err := mode.StartCoop(context.Background(), a, startChoiceOperation(t, ids.UUID{9}, at)); err != nil {
		t.Fatal("RESULT:", err)
	}
	want := []identity.PlayerID{a.PlayerID, b.PlayerID, c.PlayerID}
	if !slices.Equal(combat.settled, want) {
		t.Fatalf("settled %v, want the frozen roster %v", combat.settled, want)
	}
	if !slices.Equal(mailbox.recipients, want) {
		t.Fatalf("mailed %v, want the frozen roster %v", mailbox.recipients, want)
	}
	if !slices.Equal(adventureStore.members, []int64{int64(a.PlayerID), int64(b.PlayerID), int64(c.PlayerID)}) {
		t.Fatalf("report members %v, want the frozen roster", adventureStore.members)
	}
	if slices.Contains(combat.settled, b.PlayerID) == false {
		t.Fatal("the departed member got no settlement")
	}
}

func newCoopTestMode(at time.Time, content Content, combat Combat, store Store, mailbox Mail, roomStore *startChoiceRoomStore) Mode {
	timed := gen.TimedRunner{Binder: gen.Binder{Time: startChoiceClock{at: at}}, Runner: tx.Runner{DB: startChoiceBeginner{}}}
	stubs := startChoiceStubs{}
	return Mode{Timed: timed, Fresh: startChoiceTx{}, Store: store, Content: content,
		Functions: startChoiceFunctions{}, Directory: startChoiceDirectory{}, Guilds: stubs, Heroes: startChoiceRoster{}, Pets: stubs,
		Stats: stubs, Combat: combat, Costs: stubs, Grants: stubs, Opponents: stubs, Wake: stubs,
		Rooms:     sr.Service{Timed: timed, Fresh: startChoiceTx{}, Store: roomStore, Fence: startChoiceFence{}, Players: startChoiceRoots{}},
		RoomStore: roomStore, Mail: mailbox, Partners: stubs,
		HeroWire: func(character.Hero) (map[string]any, error) { return nil, nil }}
}

func coopTestRoom(t *testing.T, at time.Time, owner identity.PlayerID, seated []identity.PlayerID) sharedroom.Room {
	t.Helper()
	state := d.RoomState{RoomType: d.RoomTypeIllusion, SpecialData: 9001, MasterLevel: 70, Phase: "SELECTING"}
	seats := make([]sharedroom.Seat, 0, d.IllusionCoopSeats)
	for _, member := range []identity.PlayerID{100007, 100008, 100009} {
		stage := sharedroom.SeatLeft
		if slices.Contains(seated, member) {
			stage = sharedroom.SeatSeated
			state.SetPick(int64(member), d.RoomPick{Heroes: []int64{101, 102}})
		}
		seats = append(seats, sharedroom.Seat{Player: member, Stage: stage, Ready: stage == sharedroom.SeatSeated, JoinedAt: at})
	}
	payload, err := state.Encode()
	if err != nil {
		t.Fatal(err)
	}
	return sharedroom.Room{ID: 7, LogicalServerID: 1, Family: RoomFamily, Slot: IllusionSlot, Owner: owner,
		Capacity: d.IllusionCoopSeats, Status: sharedroom.StatusOpen, Seats: seats, ExpiresAt: at.Add(time.Hour),
		StateVersion: 1, NoticeVersion: 1, Payload: payload, CreatedAt: at, UpdatedAt: at}
}

type coopRosterCombat struct {
	Combat
	attempt   ids.UUID
	frozen    []identity.PlayerID
	report    []byte
	settled   []identity.PlayerID
	onResolve func()
}

func (c *coopRosterCombat) StartTx(context.Context, tx.Tx, ca.CoherentReadScope, cb.StartRequest) (cb.Started, error) {
	return cb.Started{Attempt: cd.Attempt{ID: c.attempt}}, nil
}

func (c *coopRosterCombat) Resolve(context.Context, operation.Context, ids.UUID) (cb.Resolved, error) {
	if c.onResolve != nil {
		c.onResolve()
	}
	return cb.Resolved{}, nil
}

func (c *coopRosterCombat) TerminalTx(context.Context, tx.Tx, cb.TerminalRequest) (cb.Settled, error) {
	return cb.Settled{Resolved: cb.Resolved{Report: c.report}}, nil
}

func (c *coopRosterCombat) AttemptMembersTx(context.Context, tx.Queryer, ids.UUID) ([]identity.PlayerID, error) {
	return c.frozen, nil
}

func (c *coopRosterCombat) MonsterWaves(int64) ([][]cb.Participant, error) { return nil, nil }

func (c *coopRosterCombat) SettleMemberTx(_ context.Context, _ tx.Tx, request cb.MemberSettleRequest) (cb.MemberSettled, error) {
	if !slices.Contains(c.frozen, request.Member) {
		return cb.MemberSettled{}, cd.ErrInvalid
	}
	c.settled = append(c.settled, request.Member)
	return cb.MemberSettled{}, nil
}

type coopAdventureStore struct {
	Store
	members []int64
}

func (s *coopAdventureStore) InsertReportTx(_ context.Context, _ tx.Tx, _ string, _ int64, _ int64, members []int64, _ string, _ time.Time) error {
	s.members = append([]int64(nil), members...)
	return nil
}

func (s *coopAdventureStore) ReadOccurrenceTx(context.Context, tx.Queryer, identity.PlayerID, int64) (d.Occurrence, bool, error) {
	return d.Occurrence{}, false, nil
}

type coopMailRecorder struct {
	Mail
	recipients []identity.PlayerID
}

func (m *coopMailRecorder) DeliverTx(_ context.Context, _ tx.Tx, request i5.SettlementMailRequest) (mail.Record, bool, error) {
	m.recipients = append(m.recipients, request.Recipient)
	return mail.Record{}, false, nil
}
