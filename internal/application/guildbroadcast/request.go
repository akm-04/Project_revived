package guildbroadcast

import (
	"gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/foundation/finitejson"
)

// DecodeRequest retains raw duplicate-key and Unicode evidence before building
// a typed request. The raw bound includes fully escaped valid string inputs.
func DecodeRequest(raw []byte) (guildbroadcast.Request, error) {
	m, e := finitejson.Decode(string(raw), 5500, 2, 3, 2)
	if e != nil || len(m) != 2 {
		return guildbroadcast.Request{}, guildbroadcast.ErrText
	}
	title, ok := m["title"].(string)
	if !ok {
		return guildbroadcast.Request{}, guildbroadcast.ErrText
	}
	body, ok := m["content"].(string)
	if !ok {
		return guildbroadcast.Request{}, guildbroadcast.ErrText
	}
	r := guildbroadcast.Request{Title: title, Content: body}
	return r, r.Validate()
}
