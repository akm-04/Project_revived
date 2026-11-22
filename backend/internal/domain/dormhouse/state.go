package dormhouse

import (
	"encoding/hex"
	"strings"
	"time"
)

func ValidRevision(r string) bool {
	if len(r) != 64 || strings.ToLower(r) != r {
		return false
	}
	_, e := hex.DecodeString(r)
	return e == nil
}
func (r Room) Validate() error {
	if !r.Player.Valid() || r.ID <= 0 || r.ID > MaxWireID || r.TableID <= 0 || r.MainType < 1 || r.MainType > 4 || !ValidRevision(r.CreationRevision) || r.Floor < 1 || r.Position < 1 || r.Position > 6 || r.Comfort < 0 || r.ExpansionLevel < 0 || r.StateVersion < 1 || r.Layout == nil || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) || (!r.LastEnterAt.IsZero() && r.LastEnterAt.After(r.UpdatedAt)) {
		return ErrInvalidFacts
	}
	if r.Pending != nil {
		if _, e := r.Pending.Deadline(); e != nil || r.Pending.NextLevel != r.ExpansionLevel+1 {
			return ErrInvalidFacts
		}
	}
	return nil
}
func (f HeroFacts) Validate() error {
	if !f.Player.Valid() || f.PartnerID <= 0 || f.HouseID < 0 || f.HouseID > MaxWireID || f.StateVersion < 1 || f.LoungeFraction < 0 || f.LoungeFraction >= HourNumerator || f.UpdatedAt.IsZero() {
		return ErrInvalidFacts
	}
	for _, flag := range f.Equipment {
		if flag < 0 {
			return ErrInvalidFacts
		}
	}
	return nil
}

// roomsPerFloor matches the stock floor view (FloorViewWindow.lua:7), whose
// ground floor shows one slot fewer (checkTopFloorisFull, initCell).
const roomsPerFloor = 6

func floorRooms(floor int64) int64 {
	if floor == 1 {
		return roomsPerFloor - 1
	}
	return roomsPerFloor
}

// NewRoom checks the source gallery's slots per floor and the visible floor
// frontier. Floor/position are scoped to the particular key's room class.
func (c Catalog) NewRoom(root Root, rooms map[int64]Room, tableID, floor, pos int64, revision string, now time.Time) (Root, Room, error) {
	observedAt := now
	if root.UpdatedAt.After(observedAt) {
		observedAt = root.UpdatedAt
	}
	if root.Validate() != nil || !ValidRevision(revision) || now.IsZero() {
		return Root{}, Room{}, ErrInvalidFacts
	}
	rule, ok := c.Rooms[tableID]
	if !ok || rule.MainType == LoungeType || pos < 1 || pos > floorRooms(floor) || floor < 1 {
		return Root{}, Room{}, ErrInvalidFacts
	}
	count := int64(0)
	for _, r := range rooms {
		if r.MainType == rule.MainType {
			count++
			if r.Floor == floor && r.Position == pos {
				return Root{}, Room{}, ErrInvalidFacts
			}
		}
	}
	// Floor 1 holds roomsPerFloor-1 rooms, every higher floor roomsPerFloor; the
	// next floor opens once the floors below are full.
	maxFloor := 1 + (count+1)/roomsPerFloor
	if floor > maxFloor {
		return Root{}, Room{}, ErrInvalidFacts
	}
	if root.NextHouseID >= MaxWireID {
		return Root{}, Room{}, ErrInvalidFacts
	}
	layout := map[string]string{}
	if rule.Dresser > 0 {
		layout[strconvKey(rule.Dresser, 0, 0, 0)] = ""
	}
	room := Room{Player: root.Player, ID: root.NextHouseID, TableID: tableID, MainType: rule.MainType, CreationRevision: revision, Floor: floor, Position: pos, StateVersion: 1, Layout: layout, CreatedAt: now.UTC(), UpdatedAt: now.UTC()}
	v, e := c.ValidateLayout(tableID, 0, layout)
	if e != nil {
		return Root{}, Room{}, e
	}
	room.Comfort = v.Comfort
	if room.Validate() != nil {
		return Root{}, Room{}, ErrInvalidFacts
	}
	root.NextHouseID++
	root.StateVersion++
	root.UpdatedAt = observedAt.UTC()
	return root, room, nil
}
