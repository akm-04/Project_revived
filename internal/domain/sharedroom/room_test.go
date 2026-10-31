package sharedroom

import (
	"encoding/json"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

var testStart = time.Unix(1_000, 0).UTC()

func testRoom(t *testing.T, capacity int64, lease time.Duration) Room {
	t.Helper()
	room, err := NewRoom(7, "ILLUSION", 3, capacity, 10, testStart.Add(lease), json.RawMessage(`{"boss":10001}`), testStart)
	if err != nil {
		t.Fatal(err)
	}
	return room
}

func TestNewRoomSeatsOwnerAndValidates(t *testing.T) {
	room := testRoom(t, 3, time.Hour)
	if room.ID != 0 || room.Status != StatusOpen || room.StateVersion != 1 || room.NoticeVersion != 1 {
		t.Fatalf("room %+v", room)
	}
	if members := room.Members(); len(members) != 1 || members[0] != 10 {
		t.Fatalf("members %v", members)
	}
	if seat := room.Seats[0]; seat.Index != 0 || seat.Stage != SeatSeated || seat.Ready {
		t.Fatalf("owner seat %+v", seat)
	}
	if LockRank != 607 {
		t.Fatalf("lock rank %d", LockRank)
	}
}

func TestJoinFillsCapacityInSeatOrderAndIsIdempotent(t *testing.T) {
	room := testRoom(t, 2, time.Hour)
	if err := room.Join(11, testStart); err != nil {
		t.Fatal(err)
	}
	version := room.StateVersion
	if err := room.Join(11, testStart); err != nil || room.StateVersion != version {
		t.Fatalf("idempotent join err=%v version=%d", err, room.StateVersion)
	}
	if err := room.Join(12, testStart); !errors.Is(err, ErrFull) {
		t.Fatalf("over capacity %v", err)
	}
	if err := room.Leave(11, testStart); err != nil {
		t.Fatal(err)
	}
	if err := room.Join(12, testStart); err != nil {
		t.Fatalf("free seat join %v", err)
	}
	if err := room.Join(11, testStart); !errors.Is(err, ErrFull) {
		t.Fatalf("a left seat must not exceed capacity %v", err)
	}
	if members := room.Members(); len(members) != 2 || members[0] != 10 || members[1] != 12 {
		t.Fatalf("members %v", members)
	}
	if room.NoticeVersion <= version {
		t.Fatalf("notice %d version %d", room.NoticeVersion, version)
	}
}

func TestLeaveFreesTheSeatAndLastLeaveCloses(t *testing.T) {
	room := testRoom(t, 3, time.Hour)
	if err := room.Join(11, testStart); err != nil {
		t.Fatal(err)
	}
	if err := room.Leave(11, testStart); err != nil {
		t.Fatal(err)
	}
	if room.Status != StatusOpen || len(room.Members()) != 1 {
		t.Fatalf("after leave status=%s members=%v", room.Status, room.Members())
	}
	if err := room.Leave(11, testStart); err != nil {
		t.Fatalf("repeated leave %v", err)
	}
	if err := room.Join(12, testStart); err != nil || room.Seats[1].Index != 1 {
		t.Fatalf("rejoin free seat err=%v seats=%+v", err, room.Seats)
	}
	if err := room.Leave(10, testStart); err != nil {
		t.Fatal(err)
	}
	if room.Status != StatusClosed || room.ClosedAt == nil || len(room.Members()) != 0 {
		t.Fatalf("owner leave did not close %+v", room)
	}
	closedVersion, closedNotice := room.StateVersion, room.NoticeVersion
	if err := room.Leave(12, testStart); err != nil || room.StateVersion != closedVersion || room.NoticeVersion != closedNotice {
		t.Fatalf("leave on closed room err=%v versions %d/%d", err, room.StateVersion, room.NoticeVersion)
	}
}

func TestOwnerLeaveClosesAndClosedRoomsNeverReopen(t *testing.T) {
	room := testRoom(t, 3, time.Hour)
	if err := room.Join(11, testStart); err != nil {
		t.Fatal(err)
	}
	if err := room.Leave(10, testStart); err != nil {
		t.Fatal(err)
	}
	if room.Status != StatusClosed {
		t.Fatal("owner leave kept the room open")
	}
	if err := room.Join(11, testStart); !errors.Is(err, ErrClosed) {
		t.Fatalf("join closed %v", err)
	}
	if err := room.SetReady(11, true, testStart); !errors.Is(err, ErrClosed) {
		t.Fatalf("ready closed %v", err)
	}
	if err := room.Kick(10, 11, testStart); !errors.Is(err, ErrClosed) {
		t.Fatalf("kick closed %v", err)
	}
	if room.Expire(testStart.Add(2 * time.Hour)) {
		t.Fatal("closed room expired again")
	}
}

func TestKickBlocksRejoinForThisRoomOnly(t *testing.T) {
	room := testRoom(t, 3, time.Hour)
	if err := room.Join(11, testStart); err != nil {
		t.Fatal(err)
	}
	if err := room.Kick(11, 10, testStart); !errors.Is(err, ErrNotOwner) {
		t.Fatalf("non-owner kick %v", err)
	}
	if err := room.Kick(10, 11, testStart); err != nil {
		t.Fatal(err)
	}
	if err := room.Join(11, testStart); !errors.Is(err, ErrKicked) {
		t.Fatalf("kicked rejoin %v", err)
	}
	if err := room.Kick(10, 11, testStart); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("repeat kick %v", err)
	}
	other, err := NewRoom(7, "ILLUSION", 4, 3, 10, testStart.Add(time.Hour), json.RawMessage(`{}`), testStart)
	if err != nil {
		t.Fatal(err)
	}
	if err := other.Join(11, testStart); err != nil {
		t.Fatalf("kick leaked to another room %v", err)
	}
}

func TestExpiryClosesAndBlocksEntry(t *testing.T) {
	room := testRoom(t, 3, time.Hour)
	late := testStart.Add(time.Hour)
	if err := room.Join(11, late); !errors.Is(err, ErrExpired) {
		t.Fatalf("join expired %v", err)
	}
	if err := room.SetReady(10, true, late); !errors.Is(err, ErrExpired) {
		t.Fatalf("ready expired %v", err)
	}
	if !room.Expire(late) {
		t.Fatal("expiry did not close")
	}
	if room.Status != StatusClosed || room.ClosedAt == nil {
		t.Fatalf("expired room %+v", room)
	}
	if room.Expire(late.Add(time.Hour)) {
		t.Fatal("expired room closed twice")
	}
	if err := room.Join(11, late); !errors.Is(err, ErrClosed) {
		t.Fatalf("join after expiry %v", err)
	}
}

func TestLastLeaveCloses(t *testing.T) {
	room := testRoom(t, 3, time.Hour)
	if err := room.Join(11, testStart); err != nil {
		t.Fatal(err)
	}
	if err := room.Leave(10, testStart); err != nil {
		t.Fatal(err)
	}
	if room.Status != StatusClosed || len(room.Members()) != 0 {
		t.Fatalf("owner leave %+v", room)
	}
	second := testRoom(t, 3, time.Hour)
	if err := second.Join(11, testStart); err != nil {
		t.Fatal(err)
	}
	if err := second.Leave(11, testStart); err != nil {
		t.Fatal(err)
	}
	if second.Status != StatusOpen || len(second.Members()) != 1 {
		t.Fatalf("member leave closed the room %+v", second)
	}
	if err := second.Leave(10, testStart); err != nil {
		t.Fatal(err)
	}
	if second.Status != StatusClosed {
		t.Fatal("last leave did not close")
	}
}

func TestReadyIsIdempotentAndRequiresASeat(t *testing.T) {
	room := testRoom(t, 3, time.Hour)
	if err := room.Join(11, testStart); err != nil {
		t.Fatal(err)
	}
	if err := room.SetReady(12, true, testStart); !errors.Is(err, ErrNotSeated) {
		t.Fatalf("stranger ready %v", err)
	}
	if err := room.SetReady(11, true, testStart); err != nil || !room.Seats[1].Ready {
		t.Fatalf("ready err=%v", err)
	}
	version := room.StateVersion
	if err := room.SetReady(11, true, testStart); err != nil || room.StateVersion != version {
		t.Fatalf("idempotent ready err=%v version=%d", err, room.StateVersion)
	}
	if err := room.Kick(10, 11, testStart); err != nil {
		t.Fatal(err)
	}
	if room.Seats[1].Ready {
		t.Fatal("kicked seat stayed ready")
	}
}

func TestValidateRejectsMalformedRooms(t *testing.T) {
	base := testRoom(t, 3, time.Hour)
	cases := map[string]func(*Room){
		"bad family":    func(r *Room) { r.Family = "" },
		"bad capacity":  func(r *Room) { r.Capacity = 9 },
		"bad payload":   func(r *Room) { r.Payload = json.RawMessage(`[1]`) },
		"no owner seat": func(r *Room) { r.Seats[0].Stage = SeatLeft },
		"duplicate index": func(r *Room) {
			r.Seats = append(r.Seats, Seat{Index: 0, Player: 11, Stage: SeatSeated, JoinedAt: testStart})
		},
		"duplicate player": func(r *Room) {
			r.Seats = append(r.Seats, Seat{Index: 1, Player: 10, Stage: SeatSeated, JoinedAt: testStart})
		},
		"closed with seat": func(r *Room) {
			stamp := testStart
			r.Status, r.ClosedAt = StatusClosed, &stamp
		},
		"open with closed stamp": func(r *Room) {
			stamp := testStart
			r.ClosedAt = &stamp
		},
		"ready while left": func(r *Room) { r.Seats[0].Stage, r.Seats[0].Ready = SeatLeft, true },
	}
	for name, mutate := range cases {
		room := base
		room.Seats = append([]Seat(nil), base.Seats...)
		mutate(&room)
		if err := room.Validate(); !errors.Is(err, ErrInvalid) {
			t.Fatalf("%s: %v", name, err)
		}
	}
}

func TestInvalidPlayersAreRefused(t *testing.T) {
	room := testRoom(t, 3, time.Hour)
	if err := room.Join(0, testStart); !errors.Is(err, ErrInvalid) {
		t.Fatalf("invalid player %v", err)
	}
	if err := room.Kick(10, identity.PlayerID(0), testStart); !errors.Is(err, ErrInvalid) {
		t.Fatalf("invalid kick target %v", err)
	}
}
