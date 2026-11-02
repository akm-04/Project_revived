package sharedroom

import (
	"context"
	"encoding/json"
	"errors"
	"slices"
	"strings"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type testTag int64

func (t testTag) RowsAffected() int64 { return int64(t) }

type testRow struct{}

func (testRow) Scan(...any) error { return nil }

type testTx struct{}

func (*testTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return testTag(1), nil }
func (*testTx) QueryRow(context.Context, string, ...any) tx.Row             { return testRow{} }
func (*testTx) Commit(context.Context) error                                { return nil }
func (*testTx) Rollback(context.Context) error                              { return nil }

type testDB struct{}

func (*testDB) Begin(context.Context, tx.Options) (tx.Tx, error) { return &testTx{}, nil }

type testTime struct{ at time.Time }

func (t testTime) Now(context.Context) (time.Time, error) { return t.at, nil }

type wakeCall struct {
	roomID int64
	route  string
}

type fakeStore struct {
	rooms          map[int64]d.Room
	nextID         int64
	wakes          []wakeCall
	lockMismatches int
	expired        []int64
	listServer     identity.LogicalServerID
	listLimit      int
	saves          int
}

func newFakeStore() *fakeStore {
	return &fakeStore{rooms: map[int64]d.Room{}, nextID: 1}
}

func cloneRoom(room d.Room) d.Room {
	room.Seats = append([]d.Seat(nil), room.Seats...)
	room.Payload = append(json.RawMessage(nil), room.Payload...)
	return room
}

func (s *fakeStore) ReadRoomTx(_ context.Context, _ tx.Queryer, roomID int64) (d.Room, bool, error) {
	room, found := s.rooms[roomID]
	return cloneRoom(room), found, nil
}

func (s *fakeStore) ReadPlayerRoomTx(_ context.Context, _ tx.Queryer, player identity.PlayerID, family string, slot int64) (d.Room, bool, error) {
	for _, room := range s.rooms {
		if room.Status != d.StatusOpen || room.Family != family || room.Slot != slot {
			continue
		}
		for _, seat := range room.Seats {
			if seat.Player == player && seat.Stage == d.SeatSeated {
				return cloneRoom(room), true, nil
			}
		}
	}
	return d.Room{}, false, nil
}

func (s *fakeStore) LockRoomTx(_ context.Context, _ tx.Tx, roomID int64) (d.Room, bool, error) {
	room, found := s.rooms[roomID]
	if !found {
		return d.Room{}, false, nil
	}
	locked := cloneRoom(room)
	if s.lockMismatches > 0 {
		s.lockMismatches--
		locked.StateVersion++
	}
	return locked, true, nil
}

func (s *fakeStore) OpenRoomTx(_ context.Context, _ tx.Tx, room d.Room) (d.Room, error) {
	if err := room.Validate(); err != nil {
		return d.Room{}, err
	}
	room.ID = s.nextID
	s.nextID++
	s.rooms[room.ID] = cloneRoom(room)
	return cloneRoom(room), nil
}

func (s *fakeStore) SaveRoomTx(_ context.Context, _ tx.Tx, room d.Room) error {
	if err := room.Validate(); err != nil {
		return err
	}
	if _, found := s.rooms[room.ID]; !found {
		return d.ErrNotFound
	}
	s.saves++
	s.rooms[room.ID] = cloneRoom(room)
	return nil
}

func (s *fakeStore) ExpiredRoomIDsTx(_ context.Context, _ tx.Queryer, server identity.LogicalServerID, _ time.Time, limit int) ([]int64, error) {
	s.listServer, s.listLimit = server, limit
	return append([]int64(nil), s.expired...), nil
}

func (s *fakeStore) WakeRoomTx(_ context.Context, _ tx.Tx, roomID int64, route string) error {
	s.wakes = append(s.wakes, wakeCall{roomID: roomID, route: route})
	return nil
}

type fakeFence struct{ calls int }

func (f *fakeFence) FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error {
	f.calls++
	return nil
}

type fakePlayers struct {
	calls [][]identity.PlayerID
}

func (p *fakePlayers) LockPlayerRootsTx(_ context.Context, _ tx.Tx, _ identity.LogicalServerID, players []identity.PlayerID) ([]playerroot.Root, error) {
	p.calls = append(p.calls, append([]identity.PlayerID(nil), players...))
	return nil, nil
}

var testAt = time.Unix(10_000, 0).UTC()

func testService(store *fakeStore) (Service, *fakeFence, *fakePlayers) {
	fence, players := &fakeFence{}, &fakePlayers{}
	return Service{
		Timed:   gen.TimedRunner{Binder: gen.Binder{Time: testTime{at: testAt}}, Runner: tx.Runner{DB: &testDB{}}},
		Fresh:   &testTx{},
		Store:   store,
		Fence:   fence,
		Players: players,
	}, fence, players
}

func testOperation(t *testing.T) operation.Context {
	t.Helper()
	id, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return operation.Context{ID: id, StartedAt: testAt}
}

func actor(player int64) identity.ActorContext {
	return identity.ActorContext{PlayerID: identity.PlayerID(player), LogicalServerID: 7}
}

func illusionFamily() Family {
	return Family{Name: "ILLUSION", Slot: 3, Route: "illusion.notice.v1"}
}

func openRoom(t *testing.T, service Service) d.Room {
	t.Helper()
	room, err := service.Open(context.Background(), actor(10), OpenRequest{Family: illusionFamily(), Capacity: 3, Lease: time.Hour, Payload: json.RawMessage(`{"boss":10001}`)}, testOperation(t))
	if err != nil {
		t.Fatal(err)
	}
	return room
}

func TestOpenWakesAndRefusesASecondRoom(t *testing.T) {
	store := newFakeStore()
	service, fence, _ := testService(store)
	room := openRoom(t, service)
	if room.ID != 1 || fence.calls != 1 {
		t.Fatalf("room=%+v fence=%d", room, fence.calls)
	}
	if len(store.wakes) != 1 || store.wakes[0] != (wakeCall{roomID: 1, route: "illusion.notice.v1"}) {
		t.Fatalf("wakes %+v", store.wakes)
	}
	if _, err := service.Open(context.Background(), actor(10), OpenRequest{Family: illusionFamily(), Capacity: 3, Lease: time.Hour, Payload: json.RawMessage(`{}`)}, testOperation(t)); !errors.Is(err, ErrAlreadyInRoom) {
		t.Fatalf("second open %v", err)
	}
}

func TestJoinReadyAndAdmission(t *testing.T) {
	store := newFakeStore()
	service, _, players := testService(store)
	openRoom(t, service)
	if _, err := service.Join(context.Background(), actor(11), illusionFamily(), 1, testOperation(t)); err != nil {
		t.Fatal(err)
	}
	wakes := len(store.wakes)
	if _, err := service.Join(context.Background(), actor(11), illusionFamily(), 1, testOperation(t)); err != nil || len(store.wakes) != wakes {
		t.Fatalf("idempotent join err=%v wakes=%d", err, len(store.wakes))
	}
	last := players.calls[len(players.calls)-1]
	if !slices.Equal(last, []identity.PlayerID{10, 11}) {
		t.Fatalf("roots not ascending: %v", last)
	}
	if _, err := service.SetReady(context.Background(), actor(10), illusionFamily(), true, testOperation(t)); err != nil {
		t.Fatal(err)
	}
	binding := AdmissionBinding{Store: store, Family: "ILLUSION", Slot: 3}
	scope := admissionScope(t)
	if err := binding.AdmitTx(context.Background(), &testTx{}, scope, cb.Admission{Convener: 10, Members: []identity.PlayerID{10, 11}}); !errors.Is(err, cd.ErrRoomRefused) {
		t.Fatalf("not all ready must refuse: %v", err)
	}
	if _, err := service.SetReady(context.Background(), actor(11), illusionFamily(), true, testOperation(t)); err != nil {
		t.Fatal(err)
	}
	if err := binding.AdmitTx(context.Background(), &testTx{}, scope, cb.Admission{Convener: 10, Members: []identity.PlayerID{10, 11}}); err != nil {
		t.Fatalf("admit %v", err)
	}
	if err := binding.AdmitTx(context.Background(), &testTx{}, scope, cb.Admission{Convener: 10, Members: []identity.PlayerID{11, 10}}); !errors.Is(err, cd.ErrRoomRefused) {
		t.Fatalf("seat order must be exact: %v", err)
	}
	if err := binding.AdmitTx(context.Background(), &testTx{}, scope, cb.Admission{Convener: 10, Members: []identity.PlayerID{10}}); !errors.Is(err, cd.ErrRoomRefused) {
		t.Fatalf("partial roster must refuse: %v", err)
	}
}

func admissionScope(t *testing.T) ca.CoherentReadScope {
	t.Helper()
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: &testTx{}, Operation: testOperation(t), Attempt: 1, Options: tx.Options{Isolation: tx.Serializable, ReadOnly: true}}, strings.Repeat("a", 64), testAt)
	if err != nil {
		t.Fatal(err)
	}
	return scope
}

func TestJoinRefusesASecondRoomKickedRejoinAndFullRoom(t *testing.T) {
	store := newFakeStore()
	service, _, _ := testService(store)
	openRoom(t, service)
	if _, err := service.Join(context.Background(), actor(11), illusionFamily(), 1, testOperation(t)); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Join(context.Background(), actor(12), Family{Name: "ILLUSION", Slot: 3, Route: "illusion.notice.v1"}, 1, testOperation(t)); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Join(context.Background(), actor(13), illusionFamily(), 1, testOperation(t)); !errors.Is(err, d.ErrFull) {
		t.Fatalf("full room %v", err)
	}
	other, err := service.Open(context.Background(), actor(20), OpenRequest{Family: illusionFamily(), Capacity: 2, Lease: time.Hour, Payload: json.RawMessage(`{}`)}, testOperation(t))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.Join(context.Background(), actor(12), illusionFamily(), other.ID, testOperation(t)); !errors.Is(err, ErrAlreadyInRoom) {
		t.Fatalf("must not hold two rooms in one family slot: %v", err)
	}
}

func TestKickBlocksRejoinAndOwnerLeaveCloses(t *testing.T) {
	store := newFakeStore()
	service, _, _ := testService(store)
	openRoom(t, service)
	if _, err := service.Join(context.Background(), actor(11), illusionFamily(), 1, testOperation(t)); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Kick(context.Background(), actor(11), illusionFamily(), 10, testOperation(t)); !errors.Is(err, d.ErrNotOwner) {
		t.Fatalf("non-owner kick %v", err)
	}
	if _, err := service.Kick(context.Background(), actor(10), illusionFamily(), 11, testOperation(t)); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Join(context.Background(), actor(11), illusionFamily(), 1, testOperation(t)); !errors.Is(err, d.ErrKicked) {
		t.Fatalf("kicked rejoin %v", err)
	}
	left, err := service.Leave(context.Background(), actor(10), illusionFamily(), testOperation(t))
	if err != nil || !left.Closed || left.Room.Status != d.StatusClosed {
		t.Fatalf("owner leave %+v %v", left, err)
	}
	room := store.rooms[1]
	if len(room.Members()) != 0 {
		t.Fatalf("closed room still seated %+v", room)
	}
}

func TestVersionChangeRetriesTheCommand(t *testing.T) {
	store := newFakeStore()
	service, fence, _ := testService(store)
	openRoom(t, service)
	before := fence.calls
	store.lockMismatches = 1
	if _, err := service.Join(context.Background(), actor(11), illusionFamily(), 1, testOperation(t)); err != nil {
		t.Fatalf("retry did not converge: %v", err)
	}
	if fence.calls != before+2 {
		t.Fatalf("fence calls %d before %d", fence.calls, before)
	}
	if room := store.rooms[1]; !slices.Contains(room.Members(), identity.PlayerID(11)) {
		t.Fatalf("room %+v", room)
	}
}

func TestExpiredEntryIsRefusedAndReconcileCloses(t *testing.T) {
	store := newFakeStore()
	service, _, _ := testService(store)
	openRoom(t, service)
	store.rooms[1] = func() d.Room {
		room := store.rooms[1]
		room.ExpiresAt = testAt.Add(-time.Second)
		room.UpdatedAt = testAt
		return room
	}()
	if _, err := service.Join(context.Background(), actor(11), illusionFamily(), 1, testOperation(t)); !errors.Is(err, d.ErrExpired) {
		t.Fatalf("expired join %v", err)
	}
	store.expired = []int64{1, 99}
	reconciler := Reconciler{Service: service, Server: 7, Routes: map[string]string{"ILLUSION": "illusion.notice.v1"}}
	timed, err := gen.NewTimedOperation(testOperation(t), testAt)
	if err != nil {
		t.Fatal(err)
	}
	out, err := reconciler.Reconcile(context.Background(), timed, 10)
	if err != nil {
		t.Fatal(err)
	}
	if out.Scanned != 2 || out.Settled != 1 || out.Noops != 1 || out.Wakeups != 1 {
		t.Fatalf("reconcile %+v", out)
	}
	if store.listServer != 7 || store.listLimit != 10 {
		t.Fatalf("list scope %d/%d", store.listServer, store.listLimit)
	}
	if room := store.rooms[1]; room.Status != d.StatusClosed || len(store.wakes) == 0 || store.wakes[len(store.wakes)-1].roomID != 1 {
		t.Fatalf("expired room %+v wakes %+v", room, store.wakes)
	}
	again, err := reconciler.Reconcile(context.Background(), timed, 10)
	if err != nil {
		t.Fatal(err)
	}
	if again.Settled != 0 || again.Noops != 2 {
		t.Fatalf("second reconcile %+v", again)
	}
}

func TestAdmissionRefusesClosedExpiredAndMissingRooms(t *testing.T) {
	store := newFakeStore()
	service, _, _ := testService(store)
	op := testOperation(t)
	binding := AdmissionBinding{Store: store, Family: "ILLUSION", Slot: 3}
	admission := cb.Admission{Convener: 10, Members: []identity.PlayerID{10}}
	if err := binding.AdmitTx(context.Background(), &testTx{}, admissionScope(t), admission); !errors.Is(err, cd.ErrRoomRefused) {
		t.Fatalf("missing room %v", err)
	}
	openRoom(t, service)
	if _, err := service.SetReady(context.Background(), actor(10), illusionFamily(), true, op); err != nil {
		t.Fatal(err)
	}
	if err := binding.AdmitTx(context.Background(), &testTx{}, admissionScope(t), admission); err != nil {
		t.Fatalf("admit %v", err)
	}
	store.rooms[1] = func() d.Room {
		room := store.rooms[1]
		room.ExpiresAt = testAt.Add(-time.Second)
		return room
	}()
	if err := binding.AdmitTx(context.Background(), &testTx{}, admissionScope(t), admission); !errors.Is(err, cd.ErrRoomRefused) {
		t.Fatalf("expired admit %v", err)
	}
	store.rooms[1] = func() d.Room {
		room := store.rooms[1]
		room.ExpiresAt = testAt.Add(time.Hour)
		return room
	}()
	if _, err := service.Leave(context.Background(), actor(10), illusionFamily(), op); err != nil {
		t.Fatal(err)
	}
	if err := binding.AdmitTx(context.Background(), &testTx{}, admissionScope(t), admission); !errors.Is(err, cd.ErrRoomRefused) {
		t.Fatalf("closed admit %v", err)
	}
}

func TestUpdateAppliesPayloadAfterRootsAndBeforeTheRoomLock(t *testing.T) {
	store := newFakeStore()
	service, _, _ := testService(store)
	openRoom(t, service)
	before, applied := false, false
	_, err := service.Update(context.Background(), actor(10), UpdateRequest{Family: illusionFamily(),
		Before: func(_ context.Context, _ tx.Tx, room d.Room, _ time.Time) error {
			before = room.ID == 1
			return nil
		},
		Apply: func(_ context.Context, _ gen.TimedScope, room *d.Room) error {
			applied = true
			return room.SetPayload(json.RawMessage(`{"stage":1}`), testAt)
		},
	}, testOperation(t))
	if err != nil || !before || !applied {
		t.Fatalf("update err=%v before=%v applied=%v", err, before, applied)
	}
	if string(store.rooms[1].Payload) != `{"stage":1}` || len(store.wakes) != 2 {
		t.Fatalf("payload=%s wakes=%+v", store.rooms[1].Payload, store.wakes)
	}
}

func TestFamilyValidationAndUnavailableService(t *testing.T) {
	service, _, _ := testService(newFakeStore())
	for name, family := range map[string]Family{
		"no name":  {Slot: 1, Route: "r"},
		"no route": {Name: "ILLUSION", Slot: 1},
		"bad slot": {Name: "ILLUSION", Slot: -1, Route: "r"},
	} {
		if _, err := service.Join(context.Background(), actor(10), family, 1, testOperation(t)); !errors.Is(err, ErrInvalidFamily) {
			t.Fatalf("%s: %v", name, err)
		}
	}
	if _, err := (Service{}).Leave(context.Background(), actor(10), illusionFamily(), testOperation(t)); !errors.Is(err, ErrUnavailable) {
		t.Fatalf("unavailable %v", err)
	}
}

func TestAdmissionRouterAndConvenerFirst(t *testing.T) {
	store := newFakeStore()
	service, _, _ := testService(store)
	openRoom(t, service)
	for _, player := range []identity.PlayerID{10, 11} {
		if player == 11 {
			if _, err := service.Join(context.Background(), actor(11), illusionFamily(), 1, testOperation(t)); err != nil {
				t.Fatal(err)
			}
		}
		if _, err := service.SetReady(context.Background(), actor(int64(player)), illusionFamily(), true, testOperation(t)); err != nil {
			t.Fatal(err)
		}
	}
	scope := admissionScope(t)
	router := AdmissionRouter{"ILLUSION": {Store: store, Family: "ILLUSION", Slot: 3}, "OCCULT": {Store: store, Family: "ILLUSION", Slot: 3, ConvenerFirst: true}}
	member := cb.Admission{Convener: 11, Members: []identity.PlayerID{11, 10}, Locator: cd.Locator{DomainKind: "OCCULT"}}
	if err := router.AdmitTx(context.Background(), &testTx{}, scope, member); err != nil {
		t.Fatalf("any seated convener may start a convener-first family: %v", err)
	}
	member.Locator.DomainKind = "ILLUSION"
	if err := router.AdmitTx(context.Background(), &testTx{}, scope, member); !errors.Is(err, cd.ErrRoomRefused) {
		t.Fatalf("seat order family must refuse: %v", err)
	}
	member.Locator.DomainKind = "UNKNOWN"
	if err := router.AdmitTx(context.Background(), &testTx{}, scope, member); !errors.Is(err, cd.ErrRoomRefused) {
		t.Fatalf("unknown domain must refuse: %v", err)
	}
}
