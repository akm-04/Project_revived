package arena

import (
	"gxb.local/backend/v2/internal/foundation/ids"
	"strconv"
	"strings"
)

func (room TournamentRoom) SelectionKey() string {
	return room.Identifier.String() + "/" + strconv.Itoa(room.Selection.Team)
}

func ParseSelectionKey(raw string) (ids.UUID, int, error) {
	parts := strings.Split(raw, "/")
	if len(parts) != 2 {
		return ids.UUID{}, 0, ErrInvalid
	}
	identifier, err := ids.ParseUUID(parts[0])
	if err != nil || identifier.IsZero() {
		return ids.UUID{}, 0, ErrInvalid
	}
	team, err := strconv.Atoi(parts[1])
	if err != nil || team < 1 || team > SelectionTeamCount || strconv.Itoa(team) != parts[1] {
		return ids.UUID{}, 0, ErrInvalid
	}
	return identifier, team, nil
}
