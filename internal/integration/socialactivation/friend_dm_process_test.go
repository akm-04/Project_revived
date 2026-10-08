//go:build postgres && socialintegration

package socialactivation_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/protocol/mids"
 "gxb.local/backend/v2/internal/protocol/amf3"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"
)

func dmOffline(t *testing.T, body any) []any {
	t.Helper()
	m, ok := body.(map[string]any)
	if !ok {
		t.Fatal(body)
	}
	messages, ok := m["offline_msg_list"].([]any)
	if !ok {
		t.Fatal("non-array private projection", body)
	}
	return messages
}
func Test6A_G26_G28_G30_G31_G32_G38_G39ProductionProcesses(t *testing.T) {
	f, _ := dmPair(t)
	_, sender := f.live(100001)
	_, recipient := f.live(200001)
	_, recipient2 := f.live(200001)
	apiBin, rtBin := os.Getenv("GXB_I7A4D_API_BINARY"), os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if apiBin == "" || rtBin == "" {
		t.Fatal("exact candidate production binaries required")
	}
	api, world := freeAddr(t), freeAddr(t)
	startProcess(t, apiBin, api, world)
	rtProc := startProcess(t, rtBin, api, world)
	target := worldLogin(t, world, recipient, 2)
	target2 := worldLogin(t, world, recipient2, 2)
	senderWorld := worldLogin(t, world, sender, 1)
	code, body := postProcess(t, api, sender, 1, 515, map[string]any{"player_id": 200001, "msg": `{"message":"source-shaped","msgType":0}`})
	if code != 200 {
		t.Fatal(code, body)
	}
	for _, c := range []net.Conn{target, target2} {
		frame := frameRead(t, c, mids.MIDChatFromFriend)
		if rt.ValidateFriendDM(frame.Params) != nil {
			t.Fatal("live schema", frame)
		}
 m,_:=frame.Params.(*amf3.Object).StrictMap();raw,_:=json.Marshal(m);t.Logf("RUNTIME_OBSERVED WORLD MID516 %s",raw)
	}
	deadline := time.Now().Add(3 * time.Second)
	for f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='TRANSPORT_WRITE_RECORDED'`) == 0 {
		if time.Now().After(deadline) {
			t.Fatal("actual writes not finalized")
		}
		time.Sleep(10 * time.Millisecond)
	}
	senderWorld.SetReadDeadline(time.Now().Add(150 * time.Millisecond))
	one := []byte{0}
	if _, e := senderWorld.Read(one); e == nil {
		t.Fatal("unexpected sender echo")
	}
	code, body = postProcess(t, api, recipient, 2, 176, nil)
	if code != 200 || len(dmOffline(t, body)) != 0 {
		t.Fatal("live occurrence redrained", code, body)
	}
	for _, msg := range []string{`{"message":"report","msgType":2}`, `{"message":"mode","msgType":0,"selectType":1}`, `{"message":"room","msgType":0,"roomID":1}`, `{"message":"duplicate","msgType":0,"msgType":0}`, `{"message":"surrogate\ud800","msgType":0}`} {
		code, body = postProcess(t, api, sender, 1, 515, map[string]any{"player_id": 200001, "msg": msg})
		if code == 200 {
			t.Fatal("false echo rejection", code, body)
		}
	}
	// Routine unavailable private command must be non200, including error_code-only200 negative shape.
	code, body = postProcess(t, api, sender, 1, 515, map[string]any{"player_id": 300001, "msg": `{"message":"missing recipient","msgType":0}`})
	if code == 200 {
		t.Fatal("unavailable200 would trigger stock echo", body)
	}
	// Scoped raw duplicate outer detection must happen before map collapse.
	raw := `{"mid":515,"token":"` + sender + `","region":1,"player_id":200001,"player_id":200001,"msg":"{\"message\":\"bad\",\"msgType\":0}"}`
	result, e := http.Post("http://"+api+"/", "application/x-www-form-urlencoded", strings.NewReader(url.Values{"payload": {raw}}.Encode()))
	if e != nil {
		t.Fatal(e)
	}
	result.Body.Close()
	if result.StatusCode == 200 {
		t.Fatal("outer duplicate accepted")
	}
	target.Close()
	target2.Close()
	senderWorld.Close()
	// Missed notification: kill the realtime owner and accept durably while it is down.
	rtProc.Process.Kill()
	rtProc.Wait()
	code, body = postProcess(t, api, sender, 1, 515, map[string]any{"player_id": 200001, "msg": `{"message":"offline","msgType":0}`})
	if code != 200 {
		t.Fatal(code, body)
	}
	code, body = postProcess(t, api, recipient, 2, 176, nil)
	messages := dmOffline(t, body)
	if code != 200 || len(messages) != 1 {
		t.Fatal(code, body)
	}
	m := messages[0].(map[string]any)
	if len(m) != 3 || m["player_id"] != float64(100001) {
		t.Fatal("typed176", m)
	}
 observed,_:=json.Marshal(messages);t.Logf("RUNTIME_OBSERVED HTTP176 offline_msg_list %s",observed)
	var inner map[string]any
	if json.Unmarshal([]byte(m["message"].(string)), &inner) != nil || inner["message"] != "offline" {
		t.Fatal(m)
	}
	// Pending without a hint is recovered by startup/periodic scan after restart.
	code, body = postProcess(t, api, sender, 1, 515, map[string]any{"player_id": 200001, "msg": `{"message":"restart periodic","msgType":0}`})
	if code != 200 {
		t.Fatal(code, body)
	}
	rtProc = startProcess(t, rtBin, api, world)
	target = worldLogin(t, world, recipient, 2)
	frame := frameRead(t, target, mids.MIDChatFromFriend)
	if rt.ValidateFriendDM(frame.Params) != nil {
		t.Fatal(frame)
	}
	old := f.number(`SELECT pid FROM pg_stat_activity WHERE application_name='gxb-v2-i4-realtime' AND query LIKE 'LISTEN %' LIMIT 1`)
	f.sql(`SELECT pg_terminate_backend($1)`, old)
	code, body = postProcess(t, api, sender, 1, 515, map[string]any{"player_id": 200001, "msg": `{"message":"listener recovery","msgType":0}`})
	if code != 200 {
		t.Fatal(code, body)
	}
	frame = frameRead(t, target, mids.MIDChatFromFriend)
	if rt.ValidateFriendDM(frame.Params) != nil {
		t.Fatal(frame)
	}
	t.Log("REAL_PG + actual API/realtime binaries: target WORLD multiple sockets, writer completion, no sender echo, non200/source-shaped rejection, listener loss, owner death/restart, missed-hint periodic recovery, typed516/176")
	_ = stockruntime.ValidateSocialReload
}
