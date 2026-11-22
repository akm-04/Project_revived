// Package friendmessage owns the finite ordinary private payload vocabulary.
// Lexical integer/Unicode validation is derived from the qualified I7A-5B
// codec, with the selected private parser budgets (2048 bytes, depth2,nodes16).
package friendmessage

import (
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"unicode/utf8"
)

var ErrMalformed = errors.New("malformed ordinary private message")

// SelectIllusion, SelectOccult, SelectAdventureIllusion and
// SelectAdventureDefense are the stock client's team-room chat routed through
// CHAT_TO_FRIEND. SelectWarCamp and SelectRagnarok stay refused.
const (
	SelectSocialSystem      int64 = 0
	SelectIllusion          int64 = 1
	SelectOccult            int64 = 2
	SelectAdventureIllusion int64 = 3
	SelectAdventureDefense  int64 = 4
	SelectWarCamp           int64 = 5
	SelectRagnarok          int64 = 6
	MaxSelectType           int64 = 6
)

type Message struct {
	Kind       int64
	Text       string
	EmoticonID int64
	// SelectType zero is omitted from Canonical, preserving ordinary DM bytes.
	SelectType int64
	// RoomID is the stock group-chat room, when the client sent one. A sent 0
	// is the stock window's "no room" default and is kept so the recipient
	// window's roomID comparison still matches; HasRoomID separates it from an
	// ordinary two-key body.
	RoomID    int64
	HasRoomID bool
}

func (m Message) Canonical() (string, error) {
	if m.SelectType < SelectSocialSystem || m.SelectType > MaxSelectType || (m.HasRoomID && m.RoomID < 0) {
		return "", ErrMalformed
	}
	var value any
	switch m.Kind {
	case 0:
		if m.Text == "" || !utf8.ValidString(m.Text) || utf8.RuneCountInString(m.Text) > 140 || m.EmoticonID != 0 {
			return "", ErrMalformed
		}
		if m.HasRoomID {
			value = struct {
				Kind       int64  `json:"msgType"`
				Text       string `json:"message"`
				SelectType int64  `json:"selectType,omitempty"`
				RoomID     int64  `json:"roomID"`
			}{0, m.Text, m.SelectType, m.RoomID}
			break
		}
		value = struct {
			Kind       int64  `json:"msgType"`
			Text       string `json:"message"`
			SelectType int64  `json:"selectType,omitempty"`
		}{0, m.Text, m.SelectType}
	case 1:
		if m.EmoticonID < 1 || m.EmoticonID > 9007199254740991 || m.Text != "" {
			return "", ErrMalformed
		}
		if m.HasRoomID {
			value = struct {
				Kind       int64 `json:"msgType"`
				ID         int64 `json:"message"`
				SelectType int64 `json:"selectType,omitempty"`
				RoomID     int64 `json:"roomID"`
			}{1, m.EmoticonID, m.SelectType, m.RoomID}
			break
		}
		value = struct {
			Kind       int64 `json:"msgType"`
			ID         int64 `json:"message"`
			SelectType int64 `json:"selectType,omitempty"`
		}{1, m.EmoticonID, m.SelectType}
	default:
		return "", ErrMalformed
	}
	b, e := json.Marshal(value)
	if e != nil || len(b) > 2048 {
		return "", ErrMalformed
	}
	return string(b), nil
}
func Decode(text string) (Message, error) {
	m, e := finitejson.Decode(text, 2048, 2, 16, 4)
	if e != nil {
		return Message{}, e
	}
	if len(m) < 2 || len(m) > 4 {
		return Message{}, ErrMalformed
	}
	for k := range m {
		if k != "message" && k != "msgType" && k != "selectType" && k != "roomID" {
			return Message{}, ErrMalformed
		}
	}
	out := Message{}
	if v, exists := m["selectType"]; exists {
		n, ok := v.(int64)
		if !ok || n < SelectSocialSystem || n > MaxSelectType {
			return Message{}, ErrMalformed
		}
		out.SelectType = n
	}
	if v, exists := m["roomID"]; exists {
		n, ok := v.(int64)
		if !ok || n < 0 {
			return Message{}, ErrMalformed
		}
		out.RoomID, out.HasRoomID = n, true
	}
	kind, ok := m["msgType"].(int64)
	if !ok {
		return Message{}, ErrMalformed
	}
	out.Kind = kind
	switch kind {
	case 0:
		out.Text, ok = m["message"].(string)
	case 1:
		out.EmoticonID, ok = m["message"].(int64)
	default:
		return out, ErrMalformed
	}
	if !ok {
		return Message{}, ErrMalformed
	}
	_, e = out.Canonical()
	return out, e
}

func ExactInteger(n json.Number) (int64, error) { return finitejson.ExactInteger(n) }
func ValidateUnicodeEscapes(s string) bool      { return finitejson.ValidateUnicodeEscapes(s) }
