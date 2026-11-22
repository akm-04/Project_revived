package dormhouse

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

// ComfortFact is the typed per-player input the Ranking owner orders. Room
// comfort includes the lounge row (house 1), which is an ordinary owned room.
type ComfortFact struct {
	Player                identity.PlayerID
	Value, RootVersion    int64
	RoomsDigest, Revision string
	ObservedAt            time.Time
}

func (f ComfortFact) Validate(at time.Time) error {
	if !f.Player.Valid() || f.Value < 0 || f.Value > MaxWireID || f.RootVersion < 1 || !validDigest(f.RoomsDigest) || !ValidRevision(f.Revision) || !f.ObservedAt.Equal(at) {
		return ErrInvalidFacts
	}
	return nil
}

func validDigest(value string) bool {
	raw, e := hex.DecodeString(value)
	return e == nil && len(raw) == sha256.Size && hex.EncodeToString(raw) == value
}

type comfortRoom struct {
	HouseID, Comfort, StateVersion int64
}

func BuildComfortFact(player identity.PlayerID, rooms map[int64]Room, rootVersion int64, revision string, at time.Time) (ComfortFact, error) {
	var out ComfortFact
	if !player.Valid() || rootVersion < 1 || !ValidRevision(revision) || at.IsZero() {
		return out, ErrInvalidFacts
	}
	houseIDs := make([]int64, 0, len(rooms))
	for id, room := range rooms {
		if room.Validate() != nil || room.Player != player || room.ID != id {
			return out, ErrInvalidFacts
		}
		houseIDs = append(houseIDs, id)
	}
	sort.Slice(houseIDs, func(i, j int) bool { return houseIDs[i] < houseIDs[j] })
	rows := make([]comfortRoom, 0, len(houseIDs))
	total := int64(0)
	for _, id := range houseIDs {
		comfort := rooms[id].Comfort
		if total > MaxWireID-comfort {
			return out, ErrInvalidFacts
		}
		total += comfort
		rows = append(rows, comfortRoom{HouseID: id, Comfort: comfort, StateVersion: rooms[id].StateVersion})
	}
	raw, e := json.Marshal(rows)
	if e != nil {
		return out, ErrInvalidFacts
	}
	digest := sha256.Sum256(raw)
	out = ComfortFact{Player: player, Value: total, RootVersion: rootVersion, RoomsDigest: hex.EncodeToString(digest[:]), Revision: revision, ObservedAt: at.UTC()}
	return out, out.Validate(at)
}
