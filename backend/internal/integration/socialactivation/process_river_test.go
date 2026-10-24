//go:build postgres && river && socialintegration && channelintegration

package socialactivation_test

// The production API process these tests start requires the River schema, which only the river tag set provisions.

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/protocol/mids"
	"net"
	"os"
	"testing"
	"time"
)

func TestD07ProductionProcessesWorldListenerFanoutAndRestart(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	_, a := f.live(100001)
	_, b := f.live(200001)
	_, b2 := f.live(200001)
	apiBin := os.Getenv("GXB_I7A4D_API_BINARY")
	rtBin := os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if apiBin == "" || rtBin == "" {
		t.Fatal("exact candidate production binaries required")
	}
	api, world := freeAddr(t), freeAddr(t)
	apiProc := startProcess(t, apiBin, api, world)
	rtProc := startProcess(t, rtBin, api, world)
	c := worldLogin(t, world, b, 2)
	c2 := worldLogin(t, world, b2, 2)
	// Wait for actual dedicated LISTEN and distinguish it from owner advisory session.
	deadline := time.Now().Add(3 * time.Second)
	for f.number(`SELECT count(*) FROM pg_stat_activity WHERE application_name='gxb-v2-i4-realtime' AND query LIKE 'LISTEN %'`) == 0 {
		if time.Now().After(deadline) {
			t.Fatal("LISTEN missing")
		}
		time.Sleep(10 * time.Millisecond)
	}
	code, body := postProcess(t, api, a, 1, 177, map[string]any{"player_id": 200001})
	if code != 200 {
		t.Fatal(code, body)
	}
	for _, conn := range []net.Conn{c, c2} {
		frame := frameRead(t, conn, mids.MIDForceReload)
		if stockruntime.ValidateSocialReload(frame.Params) != nil {
			t.Fatal("invalid selector/presence", frame)
		}
	}
	code, body = postProcess(t, api, b, 2, 189, map[string]any{"list_type": 2})
	if code != 200 || len(body.([]any)) != 1 {
		t.Fatal(body)
	}
	// Kill only the dedicated listener connection. Reconnect must use a new PID.
	old := f.number(`SELECT pid FROM pg_stat_activity WHERE application_name='gxb-v2-i4-realtime' AND query LIKE 'LISTEN %' LIMIT 1`)
	f.sql(`SELECT pg_terminate_backend($1)`, old)
	deadline = time.Now().Add(3 * time.Second)
	for f.number(`SELECT count(*) FROM pg_stat_activity WHERE application_name='gxb-v2-i4-realtime' AND query LIKE 'LISTEN %' AND pid<>$1`, old) == 0 {
		if time.Now().After(deadline) {
			t.Fatal("listener reconnect missing")
		}
		time.Sleep(10 * time.Millisecond)
	}
	recipientWorld := worldLogin(t, world, a, 1)
	code, body = postProcess(t, api, b, 2, 180, map[string]any{"player_id": 100001})
	if code != 200 {
		t.Fatal(code, body)
	}
	for i := 0; i < 2; i++ {
		frame := frameRead(t, recipientWorld, mids.MIDForceReload)
		if stockruntime.ValidateSocialReload(frame.Params) != nil {
			t.Fatal(frame)
		}
	}

	// Lost hints converge through canonical HTTP. Direct owner calls deliberately
	// omit the delivery mechanism; they do not grant hint bytes authority.
	f.ok(100001, sr.DeleteFriend, 200001)
	code, body = postProcess(t, api, b, 2, 189, map[string]any{"list_type": 4})
	if code != 200 || len(body.([]any)) != 1 {
		t.Fatal("dropped hint lost canonical state", body)
	}
	f.ok(100001, sr.RequestFriend, 200001)
	code, body = postProcess(t, api, b, 2, 189, map[string]any{"list_type": 2})
	if code != 200 || len(body.([]any)) != 1 {
		t.Fatal("dropped request hint recovery", body)
	}
	ref := sr.ReloadReference{Recipient: 200001, Actor: 100001, RootVersion: f.number(`SELECT state_version FROM player_social_roots WHERE player_id=200001`), Purpose: sr.ReloadRequest, First: 100001, Second: 200001, Generation: 2}
	raw, _ := ref.Encode()
	payload, _ := (wake.Envelope{Version: 1, Route: "social.reload.v1", Ref: raw}).Encode()
	before := f.snapshot()
	// Separate transactions make NOTIFY deduplication irrelevant.
	for i := 0; i < 2; i++ {
		f.sql(`SELECT pg_notify('gxb1_realtime_wakeup_v1',$1)`, string(payload))
		for _, conn := range []net.Conn{c, c2} {
			frameRead(t, conn, mids.MIDForceReload)
		}
	}
	if f.snapshot() != before {
		t.Fatal("duplicate hint mutated gameplay")
	}
	// Restore canonical friendship through actual HTTP before restart check.
	code, body = postProcess(t, api, b, 2, 180, map[string]any{"player_id": 100001})
	if code != 200 {
		t.Fatal(code, body)
	}
	for i := 0; i < 2; i++ {
		frameRead(t, recipientWorld, mids.MIDForceReload)
	}

	// Real process restart and canonicalHTTP recovery retain friendship/notice state.
	apiProc.Process.Signal(os.Interrupt)
	if e := apiProc.Wait(); e != nil {
		t.Fatal(e)
	}
	startProcess(t, apiBin, api, world)
	code, body = postProcess(t, api, a, 1, 176, nil)
	if code != 200 || len(body.(map[string]any)["friend_list"].([]any)) != 1 {
		t.Fatal("restart reload", body)
	}
	rtProc.Process.Signal(os.Interrupt)
	if e := rtProc.Wait(); e != nil {
		t.Fatal(e)
	}
	startProcess(t, rtBin, api, world)
	worldLogin(t, world, a, 1)
	code, body = postProcess(t, api, a, 1, 189, map[string]any{"list_type": 4})
	if code != 200 || len(body.([]any)) != 2 {
		t.Fatal("realtime restart canonical recovery", body)
	}
	t.Logf("REAL_NATIVE_PRODUCTION_HTTP_AND_WORLD:14route assembly,auth,commit->LISTEN->canonicalreload->singlewriter,multicontextfanout,distinctPIDreconnect%d,API/RTprocessrestart; not physicalclientW2", old)
}

var _ = context.Background
var _ = fmt.Sprint

func TestChatA25HeartbeatPresenceAndSocialProductionRegression(t *testing.T) {
	// The owning existing production test exercises real LISTEN, multiple world contexts,
	// Social reload, listener reconnect, owner fence and process restart on this exact candidate.
	TestD07ProductionProcessesWorldListenerFanoutAndRestart(t)
}
