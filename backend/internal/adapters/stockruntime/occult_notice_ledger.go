package stockruntime

import (
	"slices"

	app "gxb.local/backend/v2/internal/application/occult"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
)

// roomObservation is what the last wakeup of a room showed, so the next one
// pushes only what changed. The first sight of a room, or of a member, records
// without pushing: the ROOM_CHANGE of that wakeup already carries it.
// shortcut: in memory, so a realtime restart skips the changes of one wakeup;
// 2362 stays authoritative for the client.
type roomObservation struct {
	events    int64
	pushes    int64
	pushSeen  bool
	positions map[identity.PlayerID]int64
	online    map[identity.PlayerID]bool
}

type positionMove struct {
	Player   identity.PlayerID
	Position int64
}

type onlineChange struct {
	Player identity.PlayerID
	Online bool
}

func (l *RoomNoticeLedger) observe(room int64) (*roomObservation, bool) {
	seen, known := l.observed[room]
	if !known {
		seen = &roomObservation{positions: map[identity.PlayerID]int64{}, online: map[identity.PlayerID]bool{}}
		l.observed[room] = seen
	}
	return seen, known
}

func (l *RoomNoticeLedger) newEvents(room int64, events []d.EventRecord) []d.EventRecord {
	l.mu.Lock()
	defer l.mu.Unlock()
	seen, known := l.observe(room)
	var fresh []d.EventRecord
	for _, event := range events {
		if known && event.Sequence > seen.events {
			fresh = append(fresh, event)
		}
		seen.events = max(seen.events, event.Sequence)
	}
	return fresh
}

func (l *RoomNoticeLedger) movedPositions(room int64, positions map[identity.PlayerID]int64) []positionMove {
	l.mu.Lock()
	defer l.mu.Unlock()
	seen, _ := l.observe(room)
	var moved []positionMove
	for player, position := range positions {
		previous, tracked := seen.positions[player]
		seen.positions[player] = position
		if tracked && previous != position {
			moved = append(moved, positionMove{Player: player, Position: position})
		}
	}
	slices.SortFunc(moved, func(left, right positionMove) int { return int(left.Player - right.Player) })
	return moved
}

func (l *RoomNoticeLedger) changedOnline(room int64, states map[identity.PlayerID]bool) []onlineChange {
	l.mu.Lock()
	defer l.mu.Unlock()
	seen, _ := l.observe(room)
	var changed []onlineChange
	for player, online := range states {
		previous, tracked := seen.online[player]
		seen.online[player] = online
		if tracked && previous != online {
			changed = append(changed, onlineChange{Player: player, Online: online})
		}
	}
	slices.SortFunc(changed, func(left, right onlineChange) int { return int(left.Player - right.Player) })
	return changed
}

// newPushes returns the room pushes not yet sent; the first sight of a room only
// records the newest sequence.
func (l *RoomNoticeLedger) newPushes(room int64, pushes []app.RoomPush) []app.RoomPush {
	l.mu.Lock()
	defer l.mu.Unlock()
	seen, _ := l.observe(room)
	known := seen.pushSeen
	seen.pushSeen = true
	var fresh []app.RoomPush
	for _, push := range pushes {
		if known && push.Sequence > seen.pushes {
			fresh = append(fresh, push)
		}
		seen.pushes = max(seen.pushes, push.Sequence)
	}
	return fresh
}
