package dormhouse

import (
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// BUGS: a full ground floor (5 rooms) must open floor 2; higher floors hold 6.
func TestNewRoomFloorCapacityFollowsStockFloorView(t *testing.T) {
	now := time.Date(2026, 11, 21, 2, 0, 0, 0, time.UTC)
	revision := strings.Repeat("a", 64)
	c := Catalog{Rooms: map[int64]RoomRule{7: {MainType: 2, Length: 8, Width: 8, Height: 7}}, Types: map[int64]TypeRule{2: {Residents: 1}}}
	root := Root{Player: identity.PlayerID(1), NextHouseID: 2, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	rooms := map[int64]Room{}
	open := func(floor, pos int64) error {
		next, room, e := c.NewRoom(root, rooms, 7, floor, pos, revision, now)
		if e == nil {
			root, rooms[room.ID] = next, room
		}
		return e
	}
	if open(1, 6) == nil {
		t.Fatal("ground floor has five rooms")
	}
	for pos := int64(1); pos <= 4; pos++ {
		if e := open(1, pos); e != nil {
			t.Fatal(pos, e)
		}
	}
	if open(2, 1) == nil {
		t.Fatal("floor 2 opened before the ground floor is full")
	}
	if e := open(1, 5); e != nil {
		t.Fatal(e)
	}
	for pos := int64(1); pos <= 5; pos++ {
		if e := open(2, pos); e != nil {
			t.Fatal("floor 2 after a full ground floor", pos, e)
		}
	}
	if open(3, 1) == nil {
		t.Fatal("floor 3 opened before floor 2 is full")
	}
	if e := open(2, 6); e != nil {
		t.Fatal(e)
	}
	if e := open(3, 1); e != nil {
		t.Fatal("floor 3 after a full floor 2", e)
	}
}
