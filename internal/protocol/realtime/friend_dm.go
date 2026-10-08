package realtime

import (
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"math"
	"unicode/utf8"
)

func privateInteger(v any) (int64, bool) {
	switch n := v.(type) {
	case int:
		return int64(n), true
	case int32:
		return int64(n), true
	case int64:
		return n, n >= -MaxExactWireInteger && n <= MaxExactWireInteger
	case float64:
		return int64(n), !math.IsNaN(n) && !math.IsInf(n, 0) && n == math.Trunc(n) && n >= -float64(MaxExactWireInteger) && n <= float64(MaxExactWireInteger)
	}
	return 0, false
}
func ValidateFriendDM(v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return ErrInvalidS2CPayload
	}
	m, e := o.StrictMap()
	if e != nil || len(m) != 3 {
		return ErrInvalidS2CPayload
	}
	pid, ok := privateInteger(m["friend_id"])
	if !ok || pid < 1 {
		return ErrInvalidS2CPayload
	}
	at, ok := privateInteger(m["time"])
	if !ok || at < 0 {
		return ErrInvalidS2CPayload
	}
	message, ok := m["message"].(string)
	if !ok {
		return ErrInvalidS2CPayload
	}
	fields, e := finitejson.Decode(message, 2048, 2, 16, 3)
	if e != nil || len(fields) < 2 || len(fields) > 3 {
		return ErrInvalidS2CPayload
	}
	for k := range fields {
		if k != "message" && k != "msgType" && k != "selectType" {
			return ErrInvalidS2CPayload
		}
	}
	if selector, exists := fields["selectType"]; exists {
		v, ok := selector.(int64)
		if !ok || v != 0 {
			return ErrInvalidS2CPayload
		}
	}
	kind, ok := fields["msgType"].(int64)
	if !ok {
		return ErrInvalidS2CPayload
	}
	switch kind {
	case 0:
		text, ok := fields["message"].(string)
		if !ok || text == "" || utf8.RuneCountInString(text) > 140 {
			return ErrInvalidS2CPayload
		}
	case 1:
		id, ok := fields["message"].(int64)
		if !ok || id < 1 {
			return ErrInvalidS2CPayload
		}
	default:
		return ErrInvalidS2CPayload
	}
	return nil
}
