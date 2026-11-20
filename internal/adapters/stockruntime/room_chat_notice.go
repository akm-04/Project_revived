package stockruntime

import "gxb.local/backend/v2/internal/protocol/amf3"

// roomChatFrame is the one direct 516 a room wakeup publishes to an addressee.
func roomChatFrame(sender int64, message string, at int64) *amf3.Object {
	return &amf3.Object{Properties: []amf3.Property{
		{Name: "friend_id", Value: sender},
		{Name: "message", Value: message},
		{Name: "time", Value: at},
	}}
}
