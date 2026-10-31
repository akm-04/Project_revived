// Package sharedroom owns family-neutral rooms: membership, ordered seats,
// readiness, lifecycle, lease and the state/notice versions. Family-specific
// data stays opaque in Payload and the core never branches on a family.
package sharedroom

import (
	"bytes"
	"cmp"
	"encoding/json"
	"errors"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const (
	// LockRank is the row-lock rank of an open room and its seats (D365).
	LockRank uint16 = 607
	// MaxSeats matches the combat member limit; raise both together.
	MaxSeats        = 8
	MaxFamilyLength = 64
)

var (
	ErrInvalid   = errors.New("shared room: invalid room")
	ErrClosed    = errors.New("shared room: room is closed")
	ErrExpired   = errors.New("shared room: room lease expired")
	ErrFull      = errors.New("shared room: room is full")
	ErrKicked    = errors.New("shared room: player was kicked from this room")
	ErrNotOwner  = errors.New("shared room: actor is not the owner")
	ErrNotSeated = errors.New("shared room: player is not seated")
	ErrNotFound  = errors.New("shared room: room not found")
)

type Status string

const (
	StatusOpen   Status = "OPEN"
	StatusClosed Status = "CLOSED"
)

type SeatStage string

const (
	SeatSeated SeatStage = "SEATED"
	SeatLeft   SeatStage = "LEFT"
	SeatKicked SeatStage = "KICKED"
)

// Seat is one ordered slot of a room. A left or kicked player keeps their row,
// so a kick stays durable for the lifetime of the room.
type Seat struct {
	Index    int
	Player   identity.PlayerID
	Stage    SeatStage
	Ready    bool
	JoinedAt time.Time
}

// Room is one family slot room. A closed room keeps its final state and is
// never reopened.
type Room struct {
	ID              int64
	LogicalServerID identity.LogicalServerID
	Family          string
	Slot            int64
	Owner           identity.PlayerID
	Capacity        int64
	Status          Status
	Seats           []Seat
	ExpiresAt       time.Time
	StateVersion    int64
	NoticeVersion   int64
	Payload         json.RawMessage
	CreatedAt       time.Time
	UpdatedAt       time.Time
	ClosedAt        *time.Time
}

// NewRoom opens a room with its owner in the first seat.
func NewRoom(serverID identity.LogicalServerID, family string, slot, capacity int64, owner identity.PlayerID, expiresAt time.Time, payload json.RawMessage, at time.Time) (Room, error) {
	room := Room{
		LogicalServerID: serverID,
		Family:          family,
		Slot:            slot,
		Owner:           owner,
		Capacity:        capacity,
		Status:          StatusOpen,
		Seats:           []Seat{{Index: 0, Player: owner, Stage: SeatSeated, JoinedAt: at}},
		ExpiresAt:       expiresAt,
		StateVersion:    1,
		NoticeVersion:   1,
		Payload:         append(json.RawMessage(nil), payload...),
		CreatedAt:       at,
		UpdatedAt:       at,
	}
	if err := room.Validate(); err != nil {
		return Room{}, err
	}
	return room, nil
}

func (r Room) Validate() error {
	if r.ID < 0 || !r.LogicalServerID.Valid() || !validFamily(r.Family) || r.Slot < 0 || !r.Owner.Valid() ||
		r.Capacity < 1 || r.Capacity > MaxSeats || r.ExpiresAt.IsZero() || r.CreatedAt.IsZero() || r.UpdatedAt.IsZero() ||
		r.StateVersion < 1 || r.NoticeVersion < 1 || !validPayload(r.Payload) {
		return ErrInvalid
	}
	switch r.Status {
	case StatusOpen:
		if r.ClosedAt != nil {
			return ErrInvalid
		}
	case StatusClosed:
		if r.ClosedAt == nil {
			return ErrInvalid
		}
	default:
		return ErrInvalid
	}
	seenPlayers := make(map[identity.PlayerID]struct{}, len(r.Seats))
	seenIndexes := make(map[int]struct{}, len(r.Seats))
	seated := 0
	ownerSeated := false
	for _, seat := range r.Seats {
		if !seat.Player.Valid() || seat.Index < 0 || seat.Index >= MaxSeats || !validStage(seat.Stage) || (seat.Stage != SeatSeated && seat.Ready) {
			return ErrInvalid
		}
		if _, duplicate := seenPlayers[seat.Player]; duplicate {
			return ErrInvalid
		}
		seenPlayers[seat.Player] = struct{}{}
		if seat.Player == r.Owner && seat.Stage == SeatSeated {
			ownerSeated = true
		}
		if seat.Stage != SeatSeated {
			continue
		}
		if _, duplicate := seenIndexes[seat.Index]; duplicate {
			return ErrInvalid
		}
		seenIndexes[seat.Index] = struct{}{}
		seated++
	}
	if seated > int(r.Capacity) {
		return ErrInvalid
	}
	if r.Status == StatusOpen && !ownerSeated {
		return ErrInvalid
	}
	if r.Status == StatusClosed && seated != 0 {
		return ErrInvalid
	}
	return nil
}

// Members returns the seated players in seat order.
func (r Room) Members() []identity.PlayerID {
	members := make([]identity.PlayerID, 0, len(r.Seats))
	for _, seat := range r.Seats {
		if seat.Stage == SeatSeated {
			members = append(members, seat.Player)
		}
	}
	return members
}

// Join seats a player in the lowest free slot. Rejoining an already seated
// player is idempotent; a player kicked from this room can never rejoin it.
func (r *Room) Join(player identity.PlayerID, at time.Time) error {
	if err := r.enter(at); err != nil {
		return err
	}
	if !player.Valid() {
		return ErrInvalid
	}
	if index := r.seatIndex(player); index >= 0 {
		switch r.Seats[index].Stage {
		case SeatSeated:
			return nil
		case SeatKicked:
			return ErrKicked
		}
		if r.activeCount() >= int(r.Capacity) {
			return ErrFull
		}
		slot, ok := r.freeIndex()
		if !ok {
			return ErrFull
		}
		r.Seats[index].Index, r.Seats[index].Stage, r.Seats[index].Ready, r.Seats[index].JoinedAt = slot, SeatSeated, false, at
		r.sortSeats()
		r.touch(at)
		return nil
	}
	if r.activeCount() >= int(r.Capacity) {
		return ErrFull
	}
	slot, ok := r.freeIndex()
	if !ok {
		return ErrFull
	}
	r.Seats = append(r.Seats, Seat{Index: slot, Player: player, Stage: SeatSeated, JoinedAt: at})
	r.sortSeats()
	r.touch(at)
	return nil
}

// Leave removes a player. The owner leaving closes the room, and so does the
// last seated player leaving. Leaving a closed or absent seat is a no-op.
func (r *Room) Leave(player identity.PlayerID, at time.Time) error {
	if r.Status == StatusClosed {
		return nil
	}
	if !at.Before(r.ExpiresAt) {
		r.close(at)
		return nil
	}
	index := r.seatIndex(player)
	if index < 0 || r.Seats[index].Stage != SeatSeated {
		return nil
	}
	if player == r.Owner {
		r.close(at)
		return nil
	}
	r.Seats[index].Stage, r.Seats[index].Ready = SeatLeft, false
	if r.activeCount() == 0 {
		r.close(at)
		return nil
	}
	r.touch(at)
	return nil
}

// Kick removes a seated player on the owner's order and blocks that player from
// rejoining this room.
func (r *Room) Kick(actor, target identity.PlayerID, at time.Time) error {
	if err := r.enter(at); err != nil {
		return err
	}
	if actor != r.Owner {
		return ErrNotOwner
	}
	if target == r.Owner || !target.Valid() {
		return ErrInvalid
	}
	index := r.seatIndex(target)
	if index < 0 || r.Seats[index].Stage != SeatSeated {
		return ErrNotSeated
	}
	r.Seats[index].Stage, r.Seats[index].Ready = SeatKicked, false
	r.touch(at)
	return nil
}

// SetPayload replaces the family's opaque room state and stamps a new
// state/notice version so the wakeup carries the change.
func (r *Room) SetPayload(payload json.RawMessage, at time.Time) error {
	if r.Status == StatusClosed {
		return ErrClosed
	}
	if !validPayload(payload) {
		return ErrInvalid
	}
	r.Payload = append(json.RawMessage(nil), payload...)
	r.touch(at)
	return nil
}

func (r *Room) SetReady(player identity.PlayerID, ready bool, at time.Time) error {
	if err := r.enter(at); err != nil {
		return err
	}
	index := r.seatIndex(player)
	if index < 0 || r.Seats[index].Stage != SeatSeated {
		return ErrNotSeated
	}
	if r.Seats[index].Ready == ready {
		return nil
	}
	r.Seats[index].Ready = ready
	r.touch(at)
	return nil
}

// Expire closes an open room whose lease has ended and reports the close.
func (r *Room) Expire(at time.Time) bool {
	if r.Status != StatusOpen || at.Before(r.ExpiresAt) {
		return false
	}
	r.close(at)
	return true
}

func (r *Room) enter(at time.Time) error {
	if r.Status == StatusClosed {
		return ErrClosed
	}
	if !at.Before(r.ExpiresAt) {
		return ErrExpired
	}
	return nil
}

func (r *Room) close(at time.Time) {
	for index := range r.Seats {
		if r.Seats[index].Stage == SeatSeated {
			r.Seats[index].Stage, r.Seats[index].Ready = SeatLeft, false
		}
	}
	r.Status = StatusClosed
	stamp := at.UTC()
	r.ClosedAt = &stamp
	r.touch(at)
}

func (r *Room) touch(at time.Time) {
	r.StateVersion++
	r.NoticeVersion++
	r.UpdatedAt = at
}

func (r *Room) seatIndex(player identity.PlayerID) int {
	for index, seat := range r.Seats {
		if seat.Player == player {
			return index
		}
	}
	return -1
}

func (r *Room) activeCount() int {
	count := 0
	for _, seat := range r.Seats {
		if seat.Stage == SeatSeated {
			count++
		}
	}
	return count
}

func (r *Room) freeIndex() (int, bool) {
	used := make([]bool, MaxSeats)
	for _, seat := range r.Seats {
		if seat.Stage == SeatSeated && seat.Index >= 0 && seat.Index < MaxSeats {
			used[seat.Index] = true
		}
	}
	for index := range used {
		if !used[index] {
			return index, true
		}
	}
	return 0, false
}

func (r *Room) sortSeats() {
	slices.SortFunc(r.Seats, func(first, second Seat) int {
		if order := cmp.Compare(first.Index, second.Index); order != 0 {
			return order
		}
		return cmp.Compare(first.Player, second.Player)
	})
}

func validFamily(family string) bool {
	return family != "" && len(family) <= MaxFamilyLength
}

func validStage(stage SeatStage) bool {
	switch stage {
	case SeatSeated, SeatLeft, SeatKicked:
		return true
	default:
		return false
	}
}

func validPayload(payload json.RawMessage) bool {
	trimmed := bytes.TrimSpace(payload)
	return json.Valid(trimmed) && len(trimmed) > 0 && trimmed[0] == '{'
}
