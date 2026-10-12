//go:build postgres && river && socialintegration && channelintegration

package socialactivation_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	"os"
	"syscall"
	"testing"
	"time"
)

func canonical6CFixture(f *fixture, pids ...identity.PlayerID) {
	for _, pid := range pids {
		f.player(pid)
		f.sql(`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,1,37,1,$2)`, int64(pid), f.at)
		f.sql(`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,$2)`, int64(pid), f.at)
		f.sql(`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,$2)`, int64(pid), f.at)
	}
}

func Test6CActualProcessesFreshSendSearchImmutableDMReconnectPrivacy(t *testing.T) {
	f := fresh(t)
	canonical6CFixture(f, 100001, 200001)
	original, sender := f.live(100001)
	_, recipient := f.live(200001)
	apiBin, rtBin := os.Getenv("GXB_I7A4D_API_BINARY"), os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if apiBin == "" || rtBin == "" {
		t.Fatal("exact combined candidate API/realtime binaries required")
	}
	api, world := freeAddr(t), freeAddr(t)
	t.Setenv("GXB_PROFILE_MEDIA_ROOT", t.TempDir())
	t.Setenv("GXB_PROFILE_MEDIA_PUBLIC_ORIGIN", "http://"+api)
	startProcess(t, apiBin, api, world)
	realtime := startProcess(t, rtBin, api, world)
	a := worldLogin(t, world, sender, 1)
	b := worldLogin(t, world, recipient, 2)
	post := func(token string, region int64, mid int, fields map[string]any) any {
		code, body := postProcess(t, api, token, region, mid, fields)
		if code != 200 {
			t.Fatal(mid, code, body)
		}
		return body
	}
	post(sender, 1, 23, map[string]any{"player_name": "Fresh6C"})
	post(sender, 1, 98, map[string]any{"table_id": 110001002, "avatar_id": 10002004, "avatar_type": 1})
	f.sql(`UPDATE player_directory_profiles SET name='stale6C',avatar_id=99,lev=2 WHERE player_id=100001`)
	body := post(recipient, 2, 188, map[string]any{"msg": "Fresh6C"})
	rows, ok := body.([]any)
	if !ok || len(rows) != 1 {
		t.Fatal("canonical name candidate lost", body)
	}
	row := rows[0].(map[string]any)
	if row["player_id"] != float64(100001) || row["player_name"] != "Fresh6C" || row["avatar_id"] != float64(10002004) || row["lev"] != float64(1) {
		t.Fatal(row)
	}
	sendChat(t, a, "6Cfreshworld", 0)
	m := readChat(t, a, "6Cfreshworld")
	if m["player_name"] != "Fresh6C" || m["avatar_id"] != float64(10002004) {
		t.Fatal(m)
	}
	post(sender, 1, 513, map[string]any{"to_player_id": 200001, "message": "6CfreshDM"})
	dmFrame := frameRead(t, b, mids.MIDChatFromPlayer)
	dmMap, e := dmFrame.Params.(*amf3.Object).StrictMap()
	if e != nil || dmMap["from_player_name"] != "Fresh6C" || dmMap["from_player_avatar_id"] != float64(10002004) {
		t.Fatal(dmMap, e)
	}
	var np map[string]any
	if e = json.Unmarshal([]byte(dmMap["np_info"].(string)), &np); e != nil || np["title_info"] != "@@@@" || np["bubble_info"] != "10001@0" {
		t.Fatal(np, e)
	}
	// Pause only this disposable realtime process. Capture old sender facts, then
	// mutate the owner before any delivery, and recover without a NOTIFY hint.
	if e = realtime.Process.Signal(syscall.SIGSTOP); e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() { realtime.Process.Signal(syscall.SIGCONT) })
	service := f.general()
	operation := f.op()
	intent, e := service.Accept(ctx, 100001, 200001, "6ColdCaptured", operation)
	if e != nil {
		t.Fatal(e)
	}
	post(sender, 1, 23, map[string]any{"player_name": "Next6C"})
	known, e := service.Accept(ctx, 100001, 200001, "6ColdCaptured", operation)
	if e != nil || known.ID != intent.ID || known.SenderName != "Fresh6C" {
		t.Fatal("known operation reprojected", known, e)
	}
	stored, found, e := service.Store.Find(ctx, f.p, intent.ID)
	if e != nil || !found || stored.SenderName != "Fresh6C" || stored.SenderBubbleInfo != intent.SenderBubbleInfo {
		t.Fatal(stored, e)
	}
	if e = realtime.Process.Signal(syscall.SIGCONT); e != nil {
		t.Fatal(e)
	}
	dmFrame = frameRead(t, b, mids.MIDChatFromPlayer)
	dmMap, e = dmFrame.Params.(*amf3.Object).StrictMap()
	if e != nil || dmMap["message"] != "6ColdCaptured" || dmMap["from_player_name"] != "Fresh6C" {
		t.Fatal("historic intent refreshed", dmMap, e)
	}
	until := time.Now().Add(2 * time.Second)
	for f.text(`SELECT status FROM personal_dm_delivery WHERE operation_id=$1::uuid`, intent.ID) != "WRITTEN_BEFORE_DEADLINE" {
		if time.Now().After(until) {
			t.Fatal("missing actual-write receipt")
		}
		time.Sleep(10 * time.Millisecond)
	}
	if e = realtime.Process.Kill(); e != nil {
		t.Fatal(e)
	}
	realtime.Wait()
	closedChat(t, a)
	closedChat(t, b)
	realtime = startProcess(t, rtBin, api, world)
	a = worldLogin(t, world, sender, 1)
	sendChat(t, a, "6CafterReconnect", 0)
	m = readChat(t, a, "6CafterReconnect")
	if m["player_name"] != "Next6C" {
		t.Fatal(m)
	}
	// Retiring the original context denies a later new publication.
	f.sql(`UPDATE gameplay_contexts SET ended_at=clock_timestamp(),end_reason='LOGOUT',liveness_version=liveness_version+1 WHERE context_id=$1::uuid`, original.ContextID.UUID().String())
	sendChat(t, a, "6Cretired", 0)
	closedChat(t, a)
	_, sender = f.live(100001)
	// Both block directions deny profile feedback. GeneralDM's inherited
	// recipient-directed privacy rule is retained rather than made bilateral.
	for _, actor := range []struct {
		token          string
		region, target int64
	}{{sender, 1, 200001}, {recipient, 2, 100001}} {
		post(actor.token, actor.region, 185, map[string]any{"player_id": actor.target})
		code, body := postProcess(t, api, sender, 1, 1830, map[string]any{"to_player_id": 200001})
		if code == 200 {
			t.Fatal("feedback bypassed directed block", actor, body)
		}
		post(actor.token, actor.region, 186, map[string]any{"player_id": actor.target})
	}
	// Previously required producers remain explicit failures, not synthesized data.
	for _, request := range []struct {
		mid    int
		fields map[string]any
	}{{2490, map[string]any{}}, {1829, map[string]any{"to_player_id": 200001, "sub_type": 2}}} {
		code, body := postProcess(t, api, sender, 1, request.mid, request.fields)
		if code == 200 {
			t.Fatal("missing required producer returned success", request, body)
		}
	}
	t.Log("RUNTIME_OBSERVED exact API/realtime: canonical new sends/search, captured oldDM after owner change, missed-hint scan, positive write receipt, reconnect/context retirement, both directed profile blocks, provider failure")
}
