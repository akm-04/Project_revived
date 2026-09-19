package realtimeauth

import (
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/domain/identity"
)

// PhysicalRole is deliberately limited to the three stock-client TCP socket
// roles. TEAM is a logical SERVICE projection and is never a fourth socket.
type PhysicalRole string

const (
	World   PhysicalRole = "WORLD"
	Guild   PhysicalRole = "GUILD"
	Service PhysicalRole = "SERVICE"

	ServiceRoomID int64 = 99999
)

func (r PhysicalRole) Valid() bool { return r == World || r == Guild || r == Service }

var (
	ErrInvalidRole       = errors.New("invalid physical realtime role")
	ErrRoomNotAuthorized = errors.New("realtime room not authorized for actor")
)

type Admission struct {
	Role   PhysicalRole
	RoomID int64
	Actor  identity.ActorContext
}

// AuthorizeRoom binds room admission to already-authenticated I3 actor context.
// A client-supplied region/room can never rebind actor identity.
func AuthorizeRoom(actor identity.ActorContext, role PhysicalRole, roomID, guildID int64) (Admission, error) {
	if !role.Valid() {
		return Admission{}, ErrInvalidRole
	}
	if actor.ContextID.UUID().IsZero() || !actor.LogicalServerID.Valid() || !actor.PlayerID.Valid() {
		return Admission{}, errors.New("invalid actor context")
	}
	allowed := false
	switch role {
	case World:
		allowed = roomID == int64(actor.LogicalServerID)
	case Service:
		allowed = roomID == ServiceRoomID
	case Guild:
		allowed = guildID > 0 && roomID == guildID
	}
	if !allowed {
		return Admission{}, fmt.Errorf("%w: role=%s room=%d", ErrRoomNotAuthorized, role, roomID)
	}
	return Admission{Role: role, RoomID: roomID, Actor: actor}, nil
}
