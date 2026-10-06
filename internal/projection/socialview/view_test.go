package socialview_test

import (
	"encoding/json"
	sv "gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/socialpresence"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	"testing"
	"time"
)

func TestC22EmptyBaseAndShapeTypes(t *testing.T) {
	r := sp.Result{ObservedAt: time.Unix(1700000000, 0)}
	raw, e := json.Marshal(sv.MapBase(r))
	if e != nil {
		t.Fatal(e)
	}
	var obj map[string]any
	if e = json.Unmarshal(raw, &obj); e != nil {
		t.Fatal(e)
	}
	if len(obj) != 12 {
		t.Fatalf("base keys %d %s", len(obj), raw)
	}
	for _, k := range []string{"blacklist", "friend_list", "notice_list", "request_list", "offline_msg_list", "doing_recall", "done_recall", "got_recall", "recall_awarded"} {
		v, ok := obj[k].([]any)
		if !ok || len(v) != 0 {
			t.Fatal("empty array", k, obj[k])
		}
	}
	for _, k := range []sp.ListKind{sp.Friend, sp.Request, sp.Blacklist, sp.Notice} {
		v, e := sv.MapList(r, k)
		b, _ := json.Marshal(v)
		if e != nil || string(b) != "[]" {
			t.Fatal(k, string(b), e)
		}
	}
	v, _ := sv.MapSearch(r, sp.Modern)
	b, _ := json.Marshal(v)
	if string(b) != "[]" {
		t.Fatal(string(b))
	}
	b, _ = json.Marshal(sv.MapRecommend(r))
	if string(b) != `{"list":[]}` {
		t.Fatal(string(b))
	}
}
func TestC22CommonAndExtensionsExactNumericBooleanTypes(t *testing.T) {
	at := time.Unix(1234567, 0)
	p := sp.Player{Presentation: playerpresentation.Projected{Minimal: playerpresentation.Minimal{PlayerID: 200001, Name: "name", Level: 3, AvatarID: 4, AvatarFrameID: 5, ConquerLevel: 6, ConquerLoopID: 7, PlayerType: -8}, Presence: socialpresence.Observation{PlayerID: 200001, IsOnline: true, LatestConnectedAt: &at}}, OutgoingPending: true}
	r := sp.Result{Players: []sp.Player{p}, Friends: []sp.Player{p}}
	v, _ := sv.MapSearch(r, sp.Modern)
	b, _ := json.Marshal(v)
	var rows []map[string]any
	json.Unmarshal(b, &rows)
	if len(rows[0]) != 11 || rows[0]["is_online"] != float64(1) || rows[0]["last_time"] != float64(1234567) || rows[0]["is_send_apply"] != true {
		t.Fatal(string(b))
	}
	base := sv.MapBase(r)
	if base.Friends[0].IsSent || base.Friends[0].PlayerType != -8 {
		t.Fatal(base.Friends)
	}
}
func TestC13DecodeStrictRawTerm(t *testing.T) {
	for _, raw := range []string{`null`, `[]`, `{}`, `{"msg":true}`, `{"player_name":5}`, `{"msg":"x","extra":1}`, `{"msg":"x","player_name":"x"}`, `{"msg":"x","msg":"y"}`, `{"msg":"x"} {}`} {
		if _, e := sv.DecodeSearch([]byte(raw)); e == nil {
			t.Fatal("accepted malformed shape", raw)
		}
	}
	for _, raw := range []string{`{"msg":"  a  "}`, `{"player_name":"  a  "}`} {
		q, e := sv.DecodeSearch([]byte(raw))
		if e != nil || q.Term != "  a  " {
			t.Fatal(q, e)
		}
	}
}
