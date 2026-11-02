package arena

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/identity"
	"time"
)

type TournamentView struct {
	Period TournamentPeriod
	Viewer identity.PlayerID
	Faces  map[identity.PlayerID]Face
	Rooms  []TournamentRoom
	At     time.Time
}

type CasualView struct {
	Period    CasualPeriod
	Viewer    identity.PlayerID
	Entry     *CasualEntry
	Rooms     []TournamentRoom
	Standings []CasualStanding
	Faces     map[identity.PlayerID]Face
	At        time.Time
}

type TournamentRoomView struct {
	Room   TournamentRoom
	Heroes [2]map[string]map[string]any
	Pets   [2]map[string]map[string]any
	Report json.RawMessage
	At     time.Time
}
