package stockruntime

import (
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

func NewGeneralSocialEventRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry([]rt.DirectRegistration{
		{MID: mids.MIDForceReload, Roles: []rt.Role{rt.World}, Validate: ValidateSocialReload},
		{MID: mids.MIDChatFromFriend, Roles: []rt.Role{rt.World}, Validate: rt.ValidateFriendDM},
		{MID: mids.MIDChatFromPlayer, Roles: []rt.Role{rt.World}, Validate: rt.ValidateGeneralDM},
	}, nil)
}
