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

// SelectIllusion is xyd.FriendMsgSelectType.ILLUSION: the stock client's
// team-room chat routed through CHAT_TO_FRIEND. MaxSelectType is RAGNAROK.
const (
	SelectSocialSystem int64 = 0
	SelectIllusion     int64 = 1
	MaxSelectType      int64 = 6
)

type Message struct {
	Kind       int64
	Text       string
	EmoticonID int64
	// SelectType zero is omitted from Canonical, preserving ordinary DM bytes.
	SelectType int64
}

func (m Message) Canonical() (string, error) {
	if m.SelectType < SelectSocialSystem || m.SelectType > MaxSelectType {
		return "", ErrMalformed
	}
	var value any
	switch m.Kind {
	case 0:
		if m.Text == "" || !utf8.ValidString(m.Text) || utf8.RuneCountInString(m.Text) > 140 || m.EmoticonID != 0 {
			return "", ErrMalformed
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
	m, e := finitejson.Decode(text, 2048, 2, 16, 3)
	if e != nil {
		return Message{}, e
	}
	if len(m) < 2 || len(m) > 3 {
		return Message{}, ErrMalformed
	}
	for k := range m {
		if k != "message" && k != "msgType" && k != "selectType" {
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
