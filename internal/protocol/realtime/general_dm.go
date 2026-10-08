package realtime

import (
	"errors"
	"gxb.local/backend/v2/internal/protocol/amf3"
)

var ErrMalformedGeneralDM = errors.New("malformed general personal message")

// Reuse the qualified ordinary channel envelope validator after checking the
// exact ten-field General514 namespace and mirrored player type.
func ValidateGeneralDM(v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return ErrMalformedGeneralDM
	}
	m, e := o.StrictMap()
	if e != nil || len(m) != 10 {
		return ErrMalformedGeneralDM
	}
	fields := map[string]string{"from_player_id": "player_id", "from_player_name": "player_name", "from_player_type": "player_type", "from_player_avatar_id": "avatar_id", "from_player_avatar_frame_id": "avatar_frame_id", "from_player_lev": "lev", "message": "message", "type": "type", "np_info": "np_info"}
	projected := &amf3.Object{}
	for k, dest := range fields {
		v, ok := m[k]
		if !ok {
			return ErrMalformedGeneralDM
		}
		projected.Properties = append(projected.Properties, amf3.Property{Name: dest, Value: v})
	}
	a, ok := privateInteger(m["from_player_type"])
	if !ok {
		return ErrMalformedGeneralDM
	}
	b, ok := privateInteger(m["player_type"])
	if !ok || a != b {
		return ErrMalformedGeneralDM
	}
	if e = ValidateOrdinaryChannelChat(projected); e != nil {
		return ErrMalformedGeneralDM
	}
	return nil
}
