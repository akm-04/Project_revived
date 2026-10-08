//go:build postgres && socialintegration

package socialactivation_test

import (
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	"os"
	"os/exec"
	"testing"
	"time"
)

func Test7B_ProductionGiftHTTPNotifyListenerAndRecovery(t *testing.T) {
	f, _, a, b := giftFixture(t)
	_, sender := f.live(a.PlayerID)
	_, recipient := f.live(b.PlayerID)
	apiBin, rtBin := os.Getenv("GXB_I7A4D_API_BINARY"), os.Getenv("GXB_I7A4D_REALTIME_BINARY")
	if apiBin == "" || rtBin == "" {
		t.Fatal("exact candidate server binaries required")
	}
	api, world := freeAddr(t), freeAddr(t)
	apiProc := startProcess(t, apiBin, api, world)
	rtProc := startProcess(t, rtBin, api, world)
	senderWorld := worldLogin(t, world, sender, 1)
	recipientWorld := worldLogin(t, world, recipient, 2)
	deadline := time.Now().Add(3 * time.Second)
	for f.number(`SELECT count(*) FROM pg_stat_activity WHERE application_name='gxb-v2-i4-realtime' AND query LIKE 'LISTEN %'`) == 0 {
		if time.Now().After(deadline) {
			t.Fatal("dedicated listener missing")
		}
		time.Sleep(10 * time.Millisecond)
	}
	status, body := postProcess(t, api, sender, 1, 183, map[string]any{"player_id": 200001})
	if status != 200 || len(body.(map[string]any)) != 0 {
		t.Fatal(status, body)
	}
	frame := frameRead(t, senderWorld, mids.MIDForceReload)
	if stockruntime.ValidateSocialReload(frame.Params) != nil {
		t.Fatal(frame)
	}
	m, _ := frame.Params.(*amf3.Object).StrictMap()
	if m["friend_list"] == nil {
		t.Fatal(m)
	}
	frame = frameRead(t, recipientWorld, mids.MIDForceReload)
	m, _ = frame.Params.(*amf3.Object).StrictMap()
	if m["friend_notice"] == nil {
		t.Fatal(m)
	}
	status, body = postProcess(t, api, recipient, 2, 176, nil)
	if status != 200 {
		t.Fatal(status, body)
	}
	base := body.(map[string]any)
	ns := base["notice_list"].([]any)
	if len(ns) != 1 || ns[0].(map[string]any)["notice_type"] != float64(4) {
		t.Fatal(base)
	}
	id := ns[0].(map[string]any)["notice_id"]
	status, body = postProcess(t, api, sender, 1, 189, map[string]any{"list_type": 1})
	if status != 200 || !body.([]any)[0].(map[string]any)["is_sent"].(bool) {
		t.Fatal(status, body)
	}
	// Actual listener connection replacement still reuses the sole reference bus.
	old := f.number(`SELECT pid FROM pg_stat_activity WHERE application_name='gxb-v2-i4-realtime' AND query LIKE 'LISTEN %' LIMIT 1`)
	f.sql(`SELECT pg_terminate_backend($1)`, old)
	deadline = time.Now().Add(3 * time.Second)
	for f.number(`SELECT count(*) FROM pg_stat_activity WHERE application_name='gxb-v2-i4-realtime' AND query LIKE 'LISTEN %' AND pid<>$1`, old) == 0 {
		if time.Now().After(deadline) {
			t.Fatal("listener did not reconnect")
		}
		time.Sleep(10 * time.Millisecond)
	}
	status, body = postProcess(t, api, recipient, 2, 184, map[string]any{"notice_ids": []any{id, id}})
	if status != 200 || body.(map[string]any)["econom_"] != nil || body.(map[string]any)["economy_"].(map[string]any)["friendship_coin"] != float64(5) {
		t.Fatal(status, body)
	}
	// Reopen actual API and realtime processes; pure reload sees retained value.
	apiProc.Process.Kill()
	apiProc.Wait()
	apiProc = startProcess(t, apiBin, api, world)
	rtProc.Process.Kill()
	rtProc.Wait()
	rtProc = startProcess(t, rtBin, api, world)
	_ = apiProc
	_ = rtProc
	status, body = postProcess(t, api, recipient, 2, 176, nil)
	if status != 200 || body.(map[string]any)["receive_gift_count"] != float64(1) || len(body.(map[string]any)["notice_list"].([]any)) != 0 {
		t.Fatal(status, body)
	}
	status, _ = postProcess(t, api, recipient, 2, 184, map[string]any{"notice_ids": []any{id}})
	if status == 200 || f.number(`SELECT amount FROM player_currency_balances WHERE player_id=200001 AND resource_key='friendship_coin'`) != 5 {
		t.Fatal("process restart recredited")
	}
	t.Log("ACTUAL_BINARY_HTTP183 -> committedPGNOTIFYg1 -> dedicatedLISTEN -> WORLDconnWriter;184absolute namedscalar;API/realtime processrestart preservescounts/value")
}

func Test7B_ExplicitDeploymentActivationPreservesStartupContract(t *testing.T) {
	if os.Getenv("GXB_I7A7B_DEPLOYMENT_MODE") == "" {
		t.Skip("explicit populated35upgrade database only")
	}
	f := existing(t)
	old := "66dddbab1c548555e244c670bc994e9a17c604ba5462e38eb6610c956943b3af"
	if f.number(`SELECT count(*) FROM gxb_content_revisions WHERE revision_id=$1`, old) != 1 {
		t.Fatal("accepted35 immutable revision unavailable")
	}
	// A qualified old activation restored into this disposable fixture. Generic
	// API startup must preserve it; only the explicit owning command may switch.
	f.sql(`UPDATE gxb_content_activation SET revision_id=$1,activation_version=activation_version+1,activated_by='qualified-old-pointer-fixture'`, old)
	_, token := f.live(100001)
	api, world := freeAddr(t), freeAddr(t)
	bin := os.Getenv("GXB_I7A4D_API_BINARY")
	activationBin := os.Getenv("GXB_I7A7B_ACTIVATION_BINARY")
	if bin == "" || activationBin == "" {
		t.Fatal("exact binaries required")
	}
	proc := startProcess(t, bin, api, world)
	if f.text(`SELECT revision_id FROM gxb_content_activation`) != old {
		t.Fatal("API startup switched oldpointer")
	}
	status, _ := postProcess(t, api, token, 1, 183, map[string]any{"player_id": 200001})
	if status != 501 {
		t.Fatal("partial gift group exposed", status)
	}
	status, body := postProcess(t, api, token, 1, 184, map[string]any{"notice_ids": []any{}})
	if status != 200 {
		t.Fatal("legacy relation184 unavailable", status, body)
	}
	cmd := exec.Command(activationBin)
	cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+os.Getenv("GXB_I7A4D_TEST_DSN"))
	raw, e := cmd.CombinedOutput()
	if e != nil {
		t.Fatal(e, string(raw))
	}
	if f.text(`SELECT revision_id FROM gxb_content_activation`) != "808226509f62cf9dbb540cf0c845cab1fffe7f85aaf5a984452b01b894f01565" {
		t.Fatal("owning activation failed", string(raw))
	}
	proc.Process.Kill()
	proc.Wait()
	startProcess(t, bin, api, world)
	status, body = postProcess(t, api, token, 1, 183, map[string]any{"player_id": 200001})
	if status != 200 {
		t.Fatal("full group did not activate", status, body)
	}
	t.Log("ACTUAL_BINARY startup retains restored qualified35pointer; legacy184works/Gift183off; explicit deployment ownercommand activates exactcatalog; restart enables completeGroup")
}
