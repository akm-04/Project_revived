package socialview_test

import (
	"encoding/json"
	sv "gxb.local/backend/v2/internal/adapters/socialpresentation"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialpresence"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	domainsocialrecall "gxb.local/backend/v2/internal/domain/socialrecall"
	"testing"
	"time"
)

func TestRecallReloadFieldsUseStockShape(t *testing.T) {
	at := time.Unix(1700000000, 0).UTC()
	friend := sp.Player{Presentation: playerpresentation.Projected{Minimal: playerpresentation.Minimal{PlayerID: 200001, Name: "friend", Level: 7}}}
	r := sp.Result{ObservedAt: at,
		Friends:     []sp.Player{friend},
		Recall:      socialrecall.RecallBase{Doing: []socialrecall.RecallDoing{{PlayerID: 200001, RecallingTime: 1699999999}}, Done: []socialrecall.RecallDone{{PlayerID: 200001, Baseline: domainsocialrecall.Baseline{AcademyLevel: 51, OwnedHeroCount: 2, ChargeTotal: 100}, Current: domainsocialrecall.Baseline{AcademyLevel: 60, OwnedHeroCount: 4, ChargeTotal: 300}}}, Got: []identity.PlayerID{200001}, Awarded: []int64{100001}, Recalling: []identity.PlayerID{200001}},
		RecallNames: map[identity.PlayerID]string{200001: "friend"}}
	raw, err := json.Marshal(sv.MapBase(r))
	if err != nil {
		t.Fatal(err)
	}
	var body map[string]any
	if err := json.Unmarshal(raw, &body); err != nil {
		t.Fatal(err)
	}
	friendRow := body["friend_list"].([]any)[0].(map[string]any)
	if friendRow["recalling_friend"] != float64(1) {
		t.Fatalf("recalling_friend: %#v", friendRow)
	}
	doing := body["doing_recall"].([]any)[0].(map[string]any)
	if doing["player_id"] != float64(200001) || doing["player_name"] != "friend" || doing["recalling_time"] != float64(1699999999) {
		t.Fatalf("doing row: %#v", doing)
	}
	done := body["done_recall"].([]any)[0].(map[string]any)
	if done["player_id"] != float64(200001) || done["lev"] != float64(51) || done["cur_lev"] != float64(60) || done["partner_num"] != float64(2) || done["cur_partner_num"] != float64(4) || done["charge"] != float64(100) || done["cur_charge"] != float64(300) {
		t.Fatalf("done row: %#v", done)
	}
	if body["got_recall"].([]any)[0] != float64(200001) || body["recall_awarded"].([]any)[0] != float64(100001) {
		t.Fatalf("id arrays: %#v %#v", body["got_recall"], body["recall_awarded"])
	}
}

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
	if len(obj) != 14 {
		t.Fatalf("base keys %d %s", len(obj), raw)
	}
	if obj["count"] != float64(80) {
		t.Fatalf("friend capacity count %s", raw)
	}
	if v, ok := obj["list"].([]any); !ok || len(v) != 0 {
		t.Fatalf("legacy friend list %s", raw)
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
func TestC23TypeTenGuildInviteNoticeWireShape(t *testing.T) {
	at := time.Unix(1700000000, 0).UTC()
	inviter := sp.Player{Presentation: playerpresentation.Projected{Minimal: playerpresentation.Minimal{PlayerID: 200001, Name: "inviter", Level: 9}}}
	r := sp.Result{ObservedAt: at, Notices: []sp.Notified{{GuildID: 4242, GuildName: "Guild", Player: inviter, Notice: socialinbox.Notice{NoticeID: 77, NoticeType: 10, NoticeTime: at}}}}
	hidden, err := sv.MapList(r, sp.Notice)
	if err != nil {
		t.Fatal(err)
	}
	hiddenRaw, err := json.Marshal(hidden)
	if err != nil {
		t.Fatal(err)
	}
	if string(hiddenRaw) != "[]" {
		t.Fatalf("type10 listed while hidden: %s", hiddenRaw)
	}
	r.ShowGuildInviteNotices = true
	value, err := sv.MapList(r, sp.Notice)
	if err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	var rows []map[string]any
	if err := json.Unmarshal(raw, &rows); err != nil || len(rows) != 1 {
		t.Fatalf("notice rows %s %v", raw, err)
	}
	row := rows[0]
	if row["notice_id"] != float64(77) || row["notice_type"] != float64(10) || row["notice_time"] != float64(1700000000) || row["guild_id"] != float64(4242) || row["guild_name"] != "Guild" {
		t.Fatalf("type10 row %#v", row)
	}
	player := row["player_info"].(map[string]any)
	if player["player_id"] != float64(200001) || player["player_name"] != "inviter" {
		t.Fatalf("type10 player_info %#v", player)
	}
	if len(row) != 6 || len(player) != 10 {
		t.Fatalf("type10 field count row=%d player_info=%d %s", len(row), len(player), raw)
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
