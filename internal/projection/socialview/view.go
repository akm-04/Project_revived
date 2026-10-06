// Package socialview maps committed application results to source-shaped DTOs.
// It neither selects candidates nor reads or owns durable state.
package socialview

import (
	"bytes"
	"encoding/json"
	"io"
	"unicode/utf8"
)

type Common struct {
	PlayerID      int64  `json:"player_id"`
	PlayerName    string `json:"player_name"`
	Level         int64  `json:"lev"`
	AvatarID      int64  `json:"avatar_id"`
	AvatarFrameID int64  `json:"avatar_frame_id"`
	ConquerLevel  int64  `json:"conquer_lev"`
	ConquerLoopID int64  `json:"conquer_loop_id"`
	PlayerType    int64  `json:"player_type"`
	IsOnline      int    `json:"is_online"`
	LastTime      int64  `json:"last_time"`
}
type Friend struct {
	Common
	IsSent bool `json:"is_sent"`
}
type SearchPlayer struct {
	Common
	IsSendApply bool `json:"is_send_apply"`
}
type Request struct {
	Common
	Message string `json:"request_msg"`
	At      int64  `json:"request_time"`
}
type Notice struct {
	ID     int64  `json:"notice_id"`
	Type   int16  `json:"type"`
	At     int64  `json:"notice_time"`
	Player Common `json:"player_info"`
}
type Base struct {
	ServerTime   int64     `json:"server_time"`
	Blacklist    []Common  `json:"blacklist"`
	Friends      []Friend  `json:"friend_list"`
	Notices      []Notice  `json:"notice_list"`
	Requests     []Request `json:"request_list"`
	Offline      []any     `json:"offline_msg_list"`
	SendCount    int       `json:"send_gift_count"`
	ReceiveCount int       `json:"receive_gift_count"`
	Doing        []any     `json:"doing_recall"`
	Done         []any     `json:"done_recall"`
	Got          []any     `json:"got_recall"`
	Awarded      []any     `json:"recall_awarded"`
}

func common(p Player) Common {
	m, o := p.Minimal, p.Presence
	v := Common{PlayerID: int64(m.PlayerID), PlayerName: m.Name, Level: m.Level, AvatarID: m.AvatarID, AvatarFrameID: m.AvatarFrameID, ConquerLevel: m.ConquerLevel, ConquerLoopID: m.ConquerLoopID, PlayerType: m.PlayerType}
	if o.IsOnline {
		v.IsOnline = 1
		v.LastTime = o.LatestConnectedAt.Unix()
	} else if o.LastSeenAt != nil {
		v.LastTime = o.LastSeenAt.Unix()
	}
	return v
}
func MapBase(r Result) Base {
	v := Base{ServerTime: r.ObservedAt.Unix(), Blacklist: []Common{}, Friends: []Friend{}, Notices: []Notice{}, Requests: []Request{}, Offline: []any{}, Doing: []any{}, Done: []any{}, Got: []any{}, Awarded: []any{}}
	for _, p := range r.Blocks {
		v.Blacklist = append(v.Blacklist, common(p))
	}
	for _, p := range r.Friends {
		v.Friends = append(v.Friends, Friend{Common: common(p)})
	}
	for _, p := range r.Requests {
		v.Requests = append(v.Requests, Request{Common: common(p.Player), Message: p.Message, At: p.At.Unix()})
	}
	for _, p := range r.Notices {
		v.Notices = append(v.Notices, Notice{ID: int64(p.ID), Type: p.Type, At: p.At.Unix(), Player: common(p.Player)})
	}
	return v
}
func MapList(r Result, k ListKind) (any, error) {
	v := MapBase(r)
	switch k {
	case FriendList:
		return v.Friends, nil
	case RequestList:
		return v.Requests, nil
	case BlacklistList:
		return v.Blacklist, nil
	case NoticeList:
		return v.Notices, nil
	default:
		return nil, ErrInvalidRead
	}
}
func players(r Result) []SearchPlayer {
	v := []SearchPlayer{}
	for _, p := range r.Players {
		v = append(v, SearchPlayer{Common: common(p), IsSendApply: p.OutgoingPending})
	}
	return v
}
func MapSearch(r Result, m SearchMode) (any, error) {
	v := players(r)
	if m == Modern {
		return v, nil
	}
	if m == Legacy && len(v) == 1 {
		return v[0], nil
	}
	return nil, ErrInvalidRead
}

type Recommendations struct {
	List []SearchPlayer `json:"list"`
}

func MapRecommend(r Result) Recommendations { return Recommendations{List: players(r)} }

// DecodeSearch is a pure component seam for eventual stock integration. No
// dispatcher or route is activated. Duplicate/unknown keys fail whole input.
func DecodeSearch(raw []byte) (SearchQuery, error) {
	if !utf8.Valid(raw) {
		return SearchQuery{}, ErrInvalidRead
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	tok, e := d.Token()
	if e != nil || tok != json.Delim('{') {
		return SearchQuery{}, ErrInvalidRead
	}
	q := SearchQuery{}
	count := 0
	for d.More() {
		k, e := d.Token()
		if e != nil {
			return q, ErrInvalidRead
		}
		key, ok := k.(string)
		if !ok || count != 0 {
			return q, ErrInvalidRead
		}
		switch key {
		case "msg":
			q.Mode = Modern
		case "player_name":
			q.Mode = Legacy
		default:
			return q, ErrInvalidRead
		}
		tok, e = d.Token()
		if e != nil {
			return q, ErrInvalidRead
		}
		q.Term, ok = tok.(string)
		if !ok {
			return q, ErrInvalidRead
		}
		count++
	}
	tok, e = d.Token()
	if e != nil || tok != json.Delim('}') || count != 1 {
		return q, ErrInvalidRead
	}
	if _, e = d.Token(); e != io.EOF {
		return q, ErrInvalidRead
	}
	if e = q.Validate(); e != nil {
		return q, e
	}
	return q, nil
}
