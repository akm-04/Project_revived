package realtime

import (
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/protocol/amf3"
	cc "gxb.local/backend/v2/internal/protocol/realtime/chatschema"
	"io"
	"math/big"
	"strconv"
	"strings"
	"unicode/utf8"
)

const MaxStructuredJSONBytes = 8192

var ErrMalformedStructuredChat = errors.New("malformed finite structured chat")

// Bound lexical exponent work before exact rational validation (including underflow).
func structuredInteger(n json.Number) (int64, error) {
	text := string(n)
	if len(text) > 64 {
		return 0, ErrMalformedStructuredChat
	}
	if i := strings.IndexAny(text, "eE"); i >= 0 {
		e, err := strconv.Atoi(text[i+1:])
		if err != nil || e < -400 || e > 400 {
			return 0, ErrMalformedStructuredChat
		}
	}
	v, ok := new(big.Rat).SetString(text)
	if !ok || !v.IsInt() || !v.Num().IsInt64() {
		return 0, ErrMalformedStructuredChat
	}
	i := v.Num().Int64()
	if i < -MaxExactWireInteger || i > MaxExactWireInteger {
		return 0, ErrMalformedStructuredChat
	}
	return i, nil
}
func DecodeFiniteStructuredJSON(text string) (map[string]any, error) {
	bad := ErrMalformedStructuredChat
	if text == "" || len(text) > MaxStructuredJSONBytes || !utf8.ValidString(text) || !validStructuredEscapes(text) {
		return nil, bad
	}
	d := json.NewDecoder(strings.NewReader(text))
	d.UseNumber()
	keys, values := 0, 0
	var read func(int) (any, error)
	read = func(depth int) (any, error) {
		values++
		if depth > 4 || values > 512 {
			return nil, bad
		}
		token, e := d.Token()
		if e != nil {
			return nil, bad
		}
		switch v := token.(type) {
		case json.Delim:
			switch v {
			case '{':
				m := map[string]any{}
				for d.More() {
					k, e := d.Token()
					name, ok := k.(string)
					if e != nil || !ok {
						return nil, bad
					}
					if _, exists := m[name]; exists {
						return nil, bad
					}
					keys++
					if keys > 64 {
						return nil, bad
					}
					x, e := read(depth + 1)
					if e != nil {
						return nil, e
					}
					m[name] = x
				}
				end, e := d.Token()
				if e != nil || end != json.Delim('}') {
					return nil, bad
				}
				return m, nil
			case '[':
				a := []any{}
				for d.More() {
					if len(a) >= 64 {
						return nil, bad
					}
					x, e := read(depth + 1)
					if e != nil {
						return nil, e
					}
					a = append(a, x)
				}
				end, e := d.Token()
				if e != nil || end != json.Delim(']') {
					return nil, bad
				}
				return a, nil
			}
		case json.Number:
			return structuredInteger(v)
		case string:
			if !utf8.ValidString(v) {
				return nil, bad
			}
			return v, nil
		case bool:
			return v, nil
		}
		return nil, bad
	}
	v, e := read(1)
	if e != nil {
		return nil, e
	}
	var trailing any
	if d.Decode(&trailing) != io.EOF {
		return nil, bad
	}
	m, ok := v.(map[string]any)
	if !ok {
		return nil, bad
	}
	return m, nil
}
func schemaKeys(m map[string]any, keys ...string) bool {
	if len(m) != len(keys) {
		return false
	}
	for _, k := range keys {
		if _, ok := m[k]; !ok {
			return false
		}
	}
	return true
}
func sint(m map[string]any, k string, min int64) bool { v, ok := m[k].(int64); return ok && v >= min }
func constant(m map[string]any, k string, value int64) bool {
	v, ok := m[k].(int64)
	return ok && v == value
}
func stringField(m map[string]any, k string, max int) bool {
	s, ok := m[k].(string)
	return ok && utf8.RuneCountInString(s) <= max
}
func arrayField(m map[string]any, k string, min int64) bool {
	a, ok := m[k].([]any)
	if !ok {
		return false
	}
	for _, x := range a {
		v, ok := x.(int64)
		if !ok || v < min {
			return false
		}
	}
	return true
}
func profileField(v any) bool {
	m, ok := v.(map[string]any)
	return ok && schemaKeys(m, "player_id", "player_name", "lev", "avatar_id", "avatar_frame_id", "conquer_lev", "conquer_loop_id") && sint(m, "player_id", 1) && stringField(m, "player_name", 256) && sint(m, "lev", 1) && sint(m, "avatar_id", 0) && sint(m, "avatar_frame_id", 0) && sint(m, "conquer_lev", 0) && sint(m, "conquer_loop_id", 1)
}
func ParseStructuredMessage(text string, kind, channel int64) (cc.Selector, error) {
	bad := ErrMalformedStructuredChat
	m, e := DecodeFiniteStructuredJSON(text)
	if e != nil {
		return cc.Selector{}, e
	}
	if channel != 0 && channel != 2 && channel != 4 {
		return cc.Selector{}, bad
	}
	if kind >= 3 && kind != 7 && channel == 0 || kind == 7 && channel != 4 {
		return cc.Selector{}, bad
	}
	n := func(k string) int64 { v, _ := m[k].(int64); return v }
	s := cc.Selector{}
	switch kind {
	case 1:
		if _, peak := m["record_id"]; peak {
			_, attack := m["isAttack"].(bool)
			_, win := m["isWin"].(bool)
			if !schemaKeys(m, "player_id", "player_name", "enemy_name", "time", "isAttack", "record_id", "isWin", "attackInfo", "defendInfo") || !sint(m, "player_id", 1) || !stringField(m, "player_name", 256) || !stringField(m, "enemy_name", 256) || !sint(m, "time", 0) || !attack || !win || !sint(m, "record_id", 1) || !profileField(m["attackInfo"]) || !profileField(m["defendInfo"]) {
				return s, bad
			}
			s.Kind = cc.PeakReference
			s.Peak = &cc.RecordSelection{PlayerID: n("player_id"), RecordID: n("record_id")}
		} else {
			if !schemaKeys(m, "player_id", "player_name", "enemy_name", "time", "is_attack", "id") || !sint(m, "player_id", 1) || !stringField(m, "player_name", 256) || !stringField(m, "enemy_name", 256) || !sint(m, "time", 0) || !(constant(m, "is_attack", 0) || constant(m, "is_attack", 1)) || !sint(m, "id", 1) {
				return s, bad
			}
			s.Kind = cc.ArenaReference
			s.Arena = &cc.RecordSelection{PlayerID: n("player_id"), RecordID: n("id")}
		}
	case 2:
		if !schemaKeys(m, "player_id", "player_name", "share_gua", "rand_card_group", "card_group", "scratch_status") || !sint(m, "player_id", 1) || !stringField(m, "player_name", 256) || !constant(m, "share_gua", 1) || !arrayField(m, "rand_card_group", 1) || !arrayField(m, "card_group", 1) || !arrayField(m, "scratch_status", 0) {
			return s, bad
		}
		s.Kind = cc.ScratchShare
		s.Scratch = &cc.ScratchSelection{}
	case 3, 5, 8:
		if !schemaKeys(m, "room_id", "type", "boss_name", "room_lev") || !sint(m, "room_id", 1) || !constant(m, "type", kind) || !stringField(m, "boss_name", 256) || !sint(m, "room_lev", 1) {
			return s, bad
		}
		room := &cc.RoomSelection{RoomID: n("room_id")}
		switch kind {
		case 3:
			s.Kind = cc.IllusionInvitation
			s.Illusion = room
		case 5:
			s.Kind = cc.AdventureIllusionInvitation
			s.AdventureIllusion = room
		case 8:
			s.Kind = cc.RagnarokInvitation
			s.Ragnarok = room
		}
	case 4:
		if !schemaKeys(m, "room_id", "type", "chapter_id", "force") || !sint(m, "room_id", 1) || !constant(m, "type", 4) || !sint(m, "chapter_id", 1) || !sint(m, "force", 0) {
			return s, bad
		}
		s.Kind = cc.OccultInvitation
		s.Occult = &cc.RoomSelection{RoomID: n("room_id")}
	case 6:
		if !schemaKeys(m, "room_id", "type", "room_lev") || !sint(m, "room_id", 1) || !constant(m, "type", 6) || !sint(m, "room_lev", 1) {
			return s, bad
		}
		s.Kind = cc.DefenseInvitation
		s.Defense = &cc.RoomSelection{RoomID: n("room_id")}
	case 7:
		if !schemaKeys(m, "type", "message", "msgType", "selectType", "roomID", "camp") || !constant(m, "type", 7) || !constant(m, "selectType", 5) || !sint(m, "roomID", 0) || !sint(m, "camp", 0) {
			return s, bad
		}
		body := cc.CampSelection{DisplayRoomID: n("roomID"), ClaimedCamp: n("camp")}
		if constant(m, "msgType", 0) {
			if !stringField(m, "message", 40) || m["message"] == "" {
				return s, bad
			}
			body.Text = m["message"].(string)
		} else if constant(m, "msgType", 1) {
			if !sint(m, "message", 1) {
				return s, bad
			}
			body.IsEmoticon = true
			body.EmoticonID = n("message")
		} else {
			return s, bad
		}
		s.Kind = cc.CampMessage
		s.Camp = &body
	default:
		return s, bad
	}
	return s, nil
}

type ChannelChatIngress struct {
	Request  ChannelChatRequest
	Selector *cc.Selector
}

func ParseChannelChatIngress(v any) (ChannelChatIngress, error) {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return ChannelChatIngress{}, ErrMalformedChannelChat
	}
	m, e := o.StrictMap()
	if e != nil {
		return ChannelChatIngress{}, ErrMalformedChannelChat
	}
	kind := int64(0)
	if n, has := m["type"]; has {
		var ok bool
		kind, ok = exactChatInteger(n)
		if !ok || kind < 0 || kind > 8 {
			return ChannelChatIngress{}, ErrMalformedChannelChat
		}
	}
	if kind == 0 {
		r, e := ParseChannelChat(v)
		return ChannelChatIngress{Request: r}, e
	}
	message, ok := m["message"].(string)
	if !ok {
		return ChannelChatIngress{}, ErrMalformedStructuredChat
	}
	clone := &amf3.Object{Properties: append([]amf3.Property(nil), o.Properties...)}
	for i := range clone.Properties {
		if clone.Properties[i].Name == "message" {
			clone.Properties[i].Value = "x"
		}
	}
	r, e := ParseChannelChat(clone)
	if e != nil {
		return ChannelChatIngress{}, e
	}
	selector, e := ParseStructuredMessage(message, kind, r.Channel)
	if e != nil {
		return ChannelChatIngress{}, e
	}
	r.Message = message
	return ChannelChatIngress{Request: r, Selector: &selector}, nil
}
func StructuredWireType(k cc.Kind) int64 {
	switch k {
	case cc.ArenaReference, cc.PeakReference:
		return 1
	case cc.ScratchShare:
		return 2
	case cc.IllusionInvitation:
		return 3
	case cc.OccultInvitation:
		return 4
	case cc.AdventureIllusionInvitation:
		return 5
	case cc.DefenseInvitation:
		return 6
	case cc.CampMessage:
		return 7
	case cc.RagnarokInvitation:
		return 8
	}
	return -1
}
func ProjectStructuredMessage(v cc.Structured, channel int64) (string, error) {
	m := map[string]any{}
	n := 0
	for _, has := range []bool{v.Arena != nil, v.Peak != nil, v.Scratch != nil, v.Illusion != nil, v.Occult != nil, v.AdventureIllusion != nil, v.Defense != nil, v.Camp != nil, v.Ragnarok != nil} {
		if has {
			n++
		}
	}
	if n != 1 {
		return "", ErrMalformedStructuredChat
	}
	prof := func(p cc.Profile) map[string]any {
		return map[string]any{"player_id": p.PlayerID, "player_name": p.Name, "lev": p.Level, "avatar_id": p.AvatarID, "avatar_frame_id": p.AvatarFrameID, "conquer_lev": p.ConquerLevel, "conquer_loop_id": p.ConquerLoopID}
	}
	switch v.Kind {
	case cc.ArenaReference:
		if v.Arena == nil {
			return "", ErrMalformedStructuredChat
		}
		p := v.Arena
		attack := 0
		if p.IsAttack {
			attack = 1
		}
		m = map[string]any{"player_id": p.PlayerID, "player_name": p.PlayerName, "enemy_name": p.EnemyName, "time": p.Time, "is_attack": attack, "id": p.RecordID}
	case cc.PeakReference:
		if v.Peak == nil {
			return "", ErrMalformedStructuredChat
		}
		p := v.Peak
		m = map[string]any{"player_id": p.PlayerID, "player_name": p.PlayerName, "enemy_name": p.EnemyName, "time": p.Time, "isAttack": p.IsAttack, "isWin": p.IsWin, "record_id": p.RecordID, "attackInfo": prof(p.Attack), "defendInfo": prof(p.Defense)}
	case cc.ScratchShare:
		if v.Scratch == nil {
			return "", ErrMalformedStructuredChat
		}
		p := v.Scratch
		m = map[string]any{"player_id": p.PlayerID, "player_name": p.PlayerName, "share_gua": 1, "rand_card_group": p.RandomCards, "card_group": p.Cards, "scratch_status": p.ScratchStatus}
	case cc.IllusionInvitation, cc.AdventureIllusionInvitation, cc.RagnarokInvitation:
		p := v.Illusion
		if v.Kind == cc.AdventureIllusionInvitation {
			p = v.AdventureIllusion
		}
		if v.Kind == cc.RagnarokInvitation {
			p = v.Ragnarok
		}
		if p == nil {
			return "", ErrMalformedStructuredChat
		}
		m = map[string]any{"room_id": p.RoomID, "type": StructuredWireType(v.Kind), "boss_name": p.BossName, "room_lev": p.Level}
	case cc.OccultInvitation:
		if v.Occult == nil {
			return "", ErrMalformedStructuredChat
		}
		p := v.Occult
		m = map[string]any{"room_id": p.RoomID, "type": 4, "chapter_id": p.ChapterID, "force": p.Force}
	case cc.DefenseInvitation:
		if v.Defense == nil {
			return "", ErrMalformedStructuredChat
		}
		p := v.Defense
		m = map[string]any{"room_id": p.RoomID, "type": 6, "room_lev": p.Level}
	case cc.CampMessage:
		if v.Camp == nil {
			return "", ErrMalformedStructuredChat
		}
		p := v.Camp
		var body any = p.Text
		msgtype := 0
		if p.IsEmoticon {
			body = p.EmoticonID
			msgtype = 1
		}
		m = map[string]any{"type": 7, "message": body, "msgType": msgtype, "selectType": 5, "roomID": p.DisplayRoomID, "camp": p.CampID}
	default:
		return "", ErrMalformedStructuredChat
	}
	encoded, e := json.Marshal(m)
	if e != nil {
		return "", e
	}
	message := string(encoded)
	if _, e = ParseStructuredMessage(message, StructuredWireType(v.Kind), channel); e != nil {
		return "", e
	}
	return message, nil
}
func ValidateChannelChat(v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return ErrInvalidS2CPayload
	}
	m, e := o.StrictMap()
	if e != nil {
		return ErrInvalidS2CPayload
	}
	kind, ok := exactChatInteger(m["type"])
	if !ok || kind < 0 || kind > 8 {
		return ErrInvalidS2CPayload
	}
	if kind == 0 {
		return ValidateOrdinaryChannelChat(v)
	}
	message, ok := m["message"].(string)
	if !ok {
		return ErrInvalidS2CPayload
	}
	// Validate canonical sender/np_info through the unchanged ordinary envelope contract.
	clone := &amf3.Object{Properties: append([]amf3.Property(nil), o.Properties...)}
	for i := range clone.Properties {
		switch clone.Properties[i].Name {
		case "type":
			clone.Properties[i].Value = float64(0)
		case "message":
			clone.Properties[i].Value = "x"
		}
	}
	if e := ValidateOrdinaryChannelChat(clone); e != nil {
		return e
	}
	channel := int64(4)
	if _, e := ParseStructuredMessage(message, kind, channel); e != nil {
		return ErrInvalidS2CPayload
	}
	return nil
}

func ValidateChannelChatForRole(role Role, v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return ErrInvalidS2CPayload
	}
	m, e := o.StrictMap()
	if e != nil {
		return ErrInvalidS2CPayload
	}
	kind, ok := exactChatInteger(m["type"])
	if !ok {
		return ErrInvalidS2CPayload
	}
	if kind == 0 {
		return nil
	}
	channel := int64(-1)
	switch role {
	case World:
		channel = 0
	case Guild:
		channel = 2
	case Service:
		channel = 4
	}
	text, ok := m["message"].(string)
	if !ok {
		return ErrInvalidS2CPayload
	}
	if _, e := ParseStructuredMessage(text, kind, channel); e != nil {
		return ErrWrongS2CRole
	}
	return nil
}

// JSON's standard decoder replaces unpaired UTF16 surrogates. Reject that lossy input.
func validStructuredEscapes(s string) bool {
	quoted := false
	for i := 0; i < len(s); i++ {
		if s[i] == '"' {
			quoted = !quoted
			continue
		}
		if !quoted || s[i] != '\\' {
			continue
		}
		i++
		if i >= len(s) {
			return false
		}
		if s[i] != 'u' {
			continue
		}
		if i+4 >= len(s) {
			return false
		}
		v, e := strconv.ParseUint(s[i+1:i+5], 16, 16)
		if e != nil {
			return false
		}
		i += 4
		if v >= 0xDC00 && v <= 0xDFFF {
			return false
		}
		if v >= 0xD800 && v <= 0xDBFF {
			if i+6 >= len(s) || s[i+1:i+3] != `\u` {
				return false
			}
			low, e := strconv.ParseUint(s[i+3:i+7], 16, 16)
			if e != nil || low < 0xDC00 || low > 0xDFFF {
				return false
			}
			i += 6
		}
	}
	return true
}
