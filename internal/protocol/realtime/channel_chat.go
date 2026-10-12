package realtime

import (
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	"io"
	"math"
	"strconv"
	"strings"
	"unicode/utf8"
)

var ErrMalformedChannelChat = errors.New("malformed ordinary channel chat")

const MaxExactWireInteger int64 = 1<<53 - 1

// ChannelChatRequest never retains the optional legacy bearer/token.
type ChannelChatRequest struct {
	Message   string
	Channel   int64
	Type      int64
	Region    int64
	HasRegion bool
}

func exactChatInteger(v any) (int64, bool) {
	n, ok := strictInteger(v)
	return n, ok && n >= -MaxExactWireInteger && n <= MaxExactWireInteger
}
func validChatText(s string) bool {
	return s != "" && utf8.ValidString(s) && utf8.RuneCountInString(s) <= 140
}
func ParseChannelChat(v any) (ChannelChatRequest, error) {
	bad := ErrMalformedChannelChat
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return ChannelChatRequest{}, bad
	}
	m, err := o.StrictMap()
	if err != nil {
		return ChannelChatRequest{}, bad
	}
	for k := range m {
		switch k {
		case "message", "channel", "type", "token", "region":
		default:
			return ChannelChatRequest{}, bad
		}
	}
	msg, ok := m["message"].(string)
	if !ok || !validChatText(msg) {
		return ChannelChatRequest{}, bad
	}
	channel, ok := exactChatInteger(m["channel"])
	if !ok || (channel != 0 && channel != 2 && channel != 4) {
		return ChannelChatRequest{}, bad
	}
	r := ChannelChatRequest{Message: msg, Channel: channel}
	if v, exists := m["type"]; exists {
		n, ok := exactChatInteger(v)
		if !ok || n < 0 || n > 8 {
			return ChannelChatRequest{}, bad
		}
		r.Type = n
	}
	if v, exists := m["region"]; exists {
		n, ok := exactChatInteger(v)
		if !ok || n <= 0 {
			return ChannelChatRequest{}, bad
		}
		r.Region = n
		r.HasRegion = true
	}
	if v, exists := m["token"]; exists {
		s, ok := v.(string)
		if !ok || !utf8.ValidString(s) {
			return ChannelChatRequest{}, bad
		}
	}
	return r, nil
}
func NewChannelChatEventRegistry() (EventRegistry, error) {
	r, e := NewEventRegistry([]DirectRegistration{{MID: mids.MIDChatMessage, Roles: []Role{World, Guild, Service}, Validate: ValidateChannelChat}}, nil)
	if e != nil {
		return r, e
	}
	schema := r.direct[mids.MIDChatMessage]
	schema.validateRole = ValidateChannelChatForRole
	r.direct[mids.MIDChatMessage] = schema
	return r, nil
}
func ValidateOrdinaryChannelChat(v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return ErrInvalidS2CPayload
	}
	m, err := o.StrictMap()
	if err != nil || len(m) != 9 {
		return ErrInvalidS2CPayload
	}
	for _, k := range []string{"player_id", "player_name", "message", "player_type", "type", "avatar_id", "avatar_frame_id", "lev", "np_info"} {
		if _, ok := m[k]; !ok {
			return ErrInvalidS2CPayload
		}
	}
	for _, k := range []string{"player_id", "player_type", "type", "avatar_id", "avatar_frame_id", "lev"} {
		n, ok := exactChatInteger(m[k])
		if !ok || (k != "player_type" && n < 0) || (k == "player_id" || k == "lev") && n < 1 || k == "type" && n != 0 {
			return ErrInvalidS2CPayload
		}
	}
	name, ok := m["player_name"].(string)
	if !ok || !utf8.ValidString(name) {
		return ErrInvalidS2CPayload
	}
	msg, ok := m["message"].(string)
	if !ok || !validChatText(msg) {
		return ErrInvalidS2CPayload
	}
	np, ok := m["np_info"].(string)
	if !ok || !utf8.ValidString(np) {
		return ErrInvalidS2CPayload
	}
	d := json.NewDecoder(strings.NewReader(np))
	d.UseNumber()
	start, err := d.Token()
	if err != nil || start != json.Delim('{') {
		return ErrInvalidS2CPayload
	}
	seen := map[string]bool{}
	for d.More() {
		token, err := d.Token()
		if err != nil {
			return ErrInvalidS2CPayload
		}
		k, ok := token.(string)
		if !ok || seen[k] {
			return ErrInvalidS2CPayload
		}
		seen[k] = true
		var value any
		if d.Decode(&value) != nil {
			return ErrInvalidS2CPayload
		}
		switch k {
		case "title_info":
			text, ok := value.(string)
			if !ok || !validChatCosmeticString(text, true) {
				return ErrInvalidS2CPayload
			}
		case "bubble_info":
			text, ok := value.(string)
			if !ok || !validChatCosmeticString(text, false) {
				return ErrInvalidS2CPayload
			}
		case "conquer_lev", "conquer_loop_id":
			n, ok := value.(json.Number)
			if !ok {
				return ErrInvalidS2CPayload
			}
			v, err := n.Int64()
			if err != nil || v < 0 || v > MaxExactWireInteger {
				return ErrInvalidS2CPayload
			}
		default:
			return ErrInvalidS2CPayload
		}
	}
	end, err := d.Token()
	if err != nil || end != json.Delim('}') || len(seen) != 4 {
		return ErrInvalidS2CPayload
	}
	var trailing any
	if d.Decode(&trailing) != io.EOF {
		return ErrInvalidS2CPayload
	}
	return nil
}

// IsExactChatNumber is used by the canonical presentation adapter before conversion to AMF double.
func IsExactChatNumber(n int64) bool {
	return n >= -MaxExactWireInteger && n <= MaxExactWireInteger && !math.IsInf(float64(n), 0)
}

// The protocol boundary validates transport grammar independently of gameplay.
func validChatCosmeticString(s string, title bool) bool {
	if title && s == "@@@@" {
		return true
	}
	parts := strings.Split(s, "@")
	n := 2
	if title {
		n = 3
	}
	if len(parts) != n {
		return false
	}
	for i, p := range parts {
		v, e := strconv.ParseInt(p, 10, 64)
		if e != nil || v < 0 || v > MaxExactWireInteger || strconv.FormatInt(v, 10) != p || i == 0 && v == 0 {
			return false
		}
	}
	return true
}
