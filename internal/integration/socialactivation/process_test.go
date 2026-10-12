//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	wake "gxb.local/backend/v2/internal/application/realtimewakeup"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func freeAddr(t *testing.T) string {
	l, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	a := l.Addr().String()
	l.Close()
	return a
}
func startProcess(t *testing.T, binary, api, world string) *exec.Cmd {
	t.Helper()
	cmd := exec.Command(binary)
	cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+os.Getenv("GXB_I7A4D_TEST_DSN"), "GXB_PUBLIC_ENGINE_URL=http://"+api+"/", "GXB_HTTP_ADDR="+api, "GXB_REALTIME_ADDR="+world, "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT="+strings.Split(world, ":")[1], "GXB_CREDENTIAL_DIGEST_SECRET="+string(digestSecret), "GXB_GAMEPLAY_BEARER_SECRET="+string(bearerSecret), "GXB_REDEEM_DIGEST_SECRET=i7a4d-redeem-fixture-secret-long", "GXB_DERIVATION_KEY_ID=fixture")
	log, e := os.Create(filepath.Join(t.TempDir(), filepath.Base(binary)+".log"))
	if e != nil {
		t.Fatal(e)
	}
	cmd.Stdout = log
	cmd.Stderr = log
	if e := cmd.Start(); e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() {
		if cmd.ProcessState == nil {
			cmd.Process.Signal(os.Interrupt)
			done := make(chan struct{})
			go func() { cmd.Wait(); close(done) }()
			select {
			case <-done:
			case <-time.After(8 * time.Second):
				cmd.Process.Kill()
				<-done
			}
		}
		log.Close()
	})
	addr := api
	if strings.Contains(filepath.Base(binary), "realtime") {
		addr = world
	}
	deadline := time.Now().Add(8 * time.Second)
	for time.Now().Before(deadline) {
		c, e := net.DialTimeout("tcp", addr, 50*time.Millisecond)
		if e == nil {
			c.Close()
			return cmd
		}
		time.Sleep(20 * time.Millisecond)
	}
	b, _ := os.ReadFile(log.Name())
	t.Fatalf("process did not listen: %s", b)
	return nil
}
func frameRead(t *testing.T, c net.Conn, want uint16) rt.Frame {
	t.Helper()
	c.SetReadDeadline(time.Now().Add(4 * time.Second))
	h := make([]byte, rt.HeaderBytes)
	if _, e := io.ReadFull(c, h); e != nil {
		t.Fatal(e)
	}
	// Stock header: big endian payload length at bytes0..3.
	length := int(binary.BigEndian.Uint32(h[:4]))
	if length < 0 || length > 65536 {
		t.Fatalf("invalid frame length %d", length)
	}
	rest := make([]byte, length)
	if _, e := io.ReadFull(c, rest); e != nil {
		t.Fatal(e)
	}
	dec, _ := rt.NewStreamDecoder(limits.Default())
	out, e := dec.Feed(append(h, rest...))
	if e != nil || len(out) != 1 || out[0].MID != want {
		t.Fatal(out, e)
	}
	return out[0]
}
func worldLogin(t *testing.T, addr, token string, region int64) net.Conn {
	t.Helper()
	c, e := net.Dial("tcp", addr)
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(func() { c.Close() })
	b, e := rt.EncodeFrame(rt.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{{Name: "token", Value: token}, {Name: "region", Value: region}, {Name: "room_id", Value: region}}}})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = c.Write(b); e != nil {
		t.Fatal(e)
	}
	frameRead(t, c, mids.MIDChatRoomEntered)
	return c
}
func postProcess(t *testing.T, addr, token string, region int64, mid int, fields map[string]any) (int, any) {
	t.Helper()
	m := map[string]any{"mid": mid, "token": token, "region": region, "v_": "source", "app_v": "source", "platform": 3}
	for k, v := range fields {
		m[k] = v
	}
	raw, _ := json.Marshal(m)
	res, e := http.Post("http://"+addr+"/", "application/x-www-form-urlencoded", strings.NewReader(url.Values{"payload": {string(raw)}}.Encode()))
	if e != nil {
		t.Fatal(e)
	}
	defer res.Body.Close()
	var body any
	if e := json.NewDecoder(res.Body).Decode(&body); e != nil {
		t.Fatal(e)
	}
	return res.StatusCode, body
}
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

func TestD13UnknownWakeupFailsClosedAndJoinsUnauthenticatedSocket(t *testing.T) {
	f := fresh(t)
	api, world := freeAddr(t), freeAddr(t)
	p := startProcess(t, os.Getenv("GXB_I7A4D_REALTIME_BINARY"), api, world)
	idle, e := net.Dial("tcp", world)
	if e != nil {
		t.Fatal(e)
	}
	defer idle.Close()
	deadline := time.Now().Add(3 * time.Second)
	for f.number(`SELECT count(*)FROM pg_stat_activity WHERE application_name='gxb-v2-i4-realtime' AND query LIKE 'LISTEN %'`) == 0 {
		if time.Now().After(deadline) {
			t.Fatal("listener absent")
		}
		time.Sleep(10 * time.Millisecond)
	}
	f.sql(`SELECT pg_notify('gxb1_realtime_wakeup_v1','{"v":1,"route":"unregistered.v1","ref":"r"}')`)
	done := make(chan error, 1)
	go func() { done <- p.Wait() }()
	select {
	case e := <-done:
		if e == nil {
			t.Fatal("unknown route reported normal exit")
		}
	case <-time.After(3 * time.Second):
		t.Fatal("fatal listener did not join idle socket")
	}
	idle.SetReadDeadline(time.Now().Add(time.Second))
	_, e = idle.Read(make([]byte, 1))
	if e == nil {
		t.Fatal("unauthenticated connection retained")
	}
	if f.number(`SELECT count(*)FROM pg_locks l JOIN pg_stat_activity a USING(pid)WHERE a.application_name='gxb-v2-i4-realtime' AND l.locktype='advisory'`) != 0 {
		t.Fatal("owner guard leaked")
	}
	t.Log("REAL_PG unknownroute ->production fatal shutdown joins preauth read,listener andwriters beforeowner guardrelease")
}
