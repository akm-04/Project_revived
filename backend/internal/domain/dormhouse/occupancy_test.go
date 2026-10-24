package dormhouse

import (
	"reflect"
	"testing"
	"time"
)

func TestReparentHonorsBothCooldownsAndLoungeException(t *testing.T) {
	s := time.Unix(100000, 0).UTC()
	c := Catalog{Rooms: map[int64]RoomRule{1: {MainType: 1}, 2: {MainType: 2}}, Types: map[int64]TypeRule{1: {Residents: 5}, 2: {Residents: 1}}}
	rooms := map[int64]Room{1: {ID: 1, TableID: 1, Residents: []int64{10}, StateVersion: 1, UpdatedAt: s}, 2: {ID: 2, TableID: 2, StateVersion: 1, UpdatedAt: s}, 3: {ID: 3, TableID: 2, Residents: []int64{11}, StateVersion: 1, LastEnterAt: s, UpdatedAt: s}}
	empty, e := c.PlanResidents(rooms, 2, []int64{}, s)
	if e != nil || len(empty.ChangedRooms) != 0 {
		t.Fatal("empty state wrongly starts cooldown", empty, e)
	}
	saved := append([]int64(nil), rooms[1].Residents...)
	p, e := c.PlanResidents(rooms, 2, []int64{10}, s)
	if e != nil || p.Assignments[10] != 2 || len(p.Rooms[1].Residents) != 0 || !reflect.DeepEqual(rooms[1].Residents, saved) {
		t.Fatal(p, e)
	}
	if _, e = c.PlanResidents(p.Rooms, 1, []int64{10}, s.Add(time.Second)); e != ErrCooldown {
		t.Fatal("cooldown source bypass", e)
	}
	if _, e = c.PlanResidents(rooms, 2, []int64{11}, s.Add(time.Second)); e != ErrCooldown {
		t.Fatal("other source bypass", e)
	}
	p, e = c.PlanResidents(rooms, 2, []int64{11}, s.Add(24*time.Hour))
	if e != nil || p.Assignments[11] != 2 || len(p.Rooms[3].Residents) != 0 {
		t.Fatal(p, e)
	}
	noOp, e := c.PlanResidents(p.Rooms, 2, []int64{11}, s.Add(24*time.Hour))
	if e != nil || len(noOp.ChangedRooms) != 0 {
		t.Fatal("current state replay", noOp, e)
	}
	if _, e = c.PlanResidents(rooms, 1, []int64{10, 10}, s); e != ErrInvalidFacts {
		t.Fatal(e)
	}
}

func TestLoungeDesiredSetOrderConverges(t *testing.T) {
	s := time.Unix(100000, 0).UTC()
	c := Catalog{Rooms: map[int64]RoomRule{1: {MainType: 1}}, Types: map[int64]TypeRule{1: {Residents: 5}}}
	rooms := map[int64]Room{1: {ID: 1, TableID: 1, Residents: []int64{10, 11}, StateVersion: 1, UpdatedAt: s}}
	desired := []int64{11, 10}
	p, e := c.PlanResidents(rooms, 1, desired, s)
	if e != nil || len(p.ChangedRooms) != 0 || desired[0] != 11 {
		t.Fatal(p, e, desired)
	}
}
