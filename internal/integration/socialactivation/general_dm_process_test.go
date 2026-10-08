//go:build postgres && socialintegration

package socialactivation_test

import (
	"encoding/json"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"
)

func Test6B_G21_G22_G23_G24_G25_G29_G36_G37_G38_G40ProductionProcesses(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	_, sender := f.live(100001)
	_, recipient := f.live(200001)
	_, recipient2 := f.live(200001)
	apiBin, rtBin := os.Getenv("GXB_I7A4D_API_BINARY"), os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if apiBin == "" || rtBin == "" {
		t.Fatal("exact candidate binaries required")
	}
	api, world := freeAddr(t), freeAddr(t)
	apiProc := startProcess(t, apiBin, api, world)
	rtProc := startProcess(t, rtBin, api, world)
	a := worldLogin(t, world, recipient, 2)
	b := worldLogin(t, world, recipient2, 2)
	code, body := postProcess(t, api, sender, 1, 513, map[string]any{"to_player_id": 200001, "message": "source-shaped 普通文字"})
	if code != 200 {
		t.Fatal(code, body)
	}
	for _, c := range []net.Conn{a, b} {
		frame := frameRead(t, c, mids.MIDChatFromPlayer)
		if e := rt.ValidateGeneralDM(frame.Params); e != nil {
			t.Fatal(e)
		}
		m, _ := frame.Params.(*amf3.Object).StrictMap()
		if len(m) != 10 || m["message"] != "source-shaped 普通文字" || m["player_type"] != m["from_player_type"] {
			t.Fatal(m)
		}
		if _, ok := m["player_id"]; ok {
			t.Fatal("invented player_id")
		}
		raw, _ := json.Marshal(m)
		t.Logf("RUNTIME_OBSERVED WORLD MID514 %s", raw)
	}
	if f.number(`SELECT count(*) FROM personal_dm_delivery WHERE status='WRITTEN_BEFORE_DEADLINE' AND completion_upper_at<(SELECT expires_at FROM personal_dm_intents WHERE operation_id=personal_dm_delivery.operation_id)`) != 1 || f.number(`SELECT count(*) FROM personal_dm_payloads`) != 0 {
		t.Fatal("200 without durable positive receipt")
	}
	for _, fields := range []map[string]any{
		{"to_player_id": 200001, "message": "invalid", "channel": "1"}, {"to_player_id": 200001, "message": "invalid", "channel": 2}, {"to_player_id": 200001, "message": "invalid", "selectType": 1}, {"to_player_id": 200001.25, "message": "invalid"}, {"to_player_id": 100001, "message": "self"}, {"to_player_id": 200001, "message": strings.Repeat("界", 141)}, {"to_player_id": 200001, "message": "   "}, {"to_player_id": 300001, "message": "unavailable"},
	} {
		code, body = postProcess(t, api, sender, 1, 513, fields)
		if code == 200 {
			t.Fatal("false stock echo", fields, body)
		}
	}
	for _, raw := range []string{
		`{"mid":513,"token":"` + sender + `","region":1,"to_player_id":200001,"to_player_id":200001,"message":"duplicate"}`,
		`{"mid":513,"token":"` + sender + `","region":1,"to_player_id":200001,"message":"\ud800"}`,
	} {
		res, e := http.Post("http://"+api+"/", "application/x-www-form-urlencoded", strings.NewReader(url.Values{"payload": {raw}}.Encode()))
		if e != nil {
			t.Fatal(e)
		}
		res.Body.Close()
		if res.StatusCode == 200 {
			t.Fatal("raw ambiguity accepted")
		}
	}
	// Durable acceptance directly through the real owners deliberately emits no NOTIFY.
	i := generalAccept(t, f, f.general())
	apiProc.Process.Kill()
	apiProc.Wait()
	apiProc = startProcess(t, apiBin, api, world)
	for _, c := range []net.Conn{a, b} {
		frame := frameRead(t, c, mids.MIDChatFromPlayer)
		if rt.ValidateGeneralDM(frame.Params) != nil {
			t.Fatal(frame)
		}
	}
	until := time.Now().Add(3 * time.Second)
	for f.text(`SELECT status FROM personal_dm_delivery WHERE operation_id=$1::uuid`, i.ID) != string(dm.WrittenBeforeDeadline) {
		if time.Now().After(until) {
			t.Fatal("API restart/missed hint receipt")
		}
		time.Sleep(10 * time.Millisecond)
	}
	// An owner epoch change never retargets old captured WORLD connections.
	rtProc.Process.Kill()
	rtProc.Wait()
	i = generalAccept(t, f, f.general())
	a.Close()
	b.Close()
	rtProc = startProcess(t, rtBin, api, world)
	a = worldLogin(t, world, recipient, 2)
	until = time.Now().Add(4 * time.Second)
	for f.text(`SELECT status FROM personal_dm_delivery WHERE operation_id=$1::uuid`, i.ID) != string(dm.AdmissionRetired) {
		if time.Now().After(until) {
			t.Fatal("old epoch not retired")
		}
		time.Sleep(20 * time.Millisecond)
	}
	a.SetReadDeadline(time.Now().Add(150 * time.Millisecond))
	one := make([]byte, 1)
	if n, e := a.Read(one); n != 0 || e == nil {
		t.Fatal("old intent retargeted", n, e)
	}
	if f.number(`SELECT count(*) FROM friend_dm_occurrences`) != 0 || f.number(`SELECT count(*) FROM player_social_roots`) != 0 {
		t.Fatal("General wrote Friend/history/Social roots")
	}
	t.Log("REAL_PG actual API/realtime: 513 waits for canonical actual write; two original WORLD514 handles; source render/storage aliases and NP; raw duplicate/surrogate finite rejection; missed NOTIFY; API restart; realtime epoch replacement never retargeted")
}
