package stockruntime

import (
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

// ValidateGuildFightNotice is push 36853's body (GuildMapDetailWindow.lua:44-49, MapWindow.lua:78-92).
func ValidateGuildFightNotice(value any) error {
	object, ok := value.(*amf3.Object)
	if !ok || object == nil {
		return rt.ErrInvalidS2CPayload
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 3 {
		return rt.ErrInvalidS2CPayload
	}
	for _, key := range []string{"copy_id", "chapter_id", "player_id"} {
		if number, ok := fields[key].(int64); !ok || number <= 0 {
			return rt.ErrInvalidS2CPayload
		}
	}
	return nil
}

func NewGuildFightNoticeRegistration() rt.DirectRegistration {
	return rt.DirectRegistration{MID: mids.MIDGuildFightNotice, Roles: []rt.Role{rt.World}, Validate: ValidateGuildFightNotice}
}
