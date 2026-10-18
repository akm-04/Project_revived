//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"testing"
	"time"
)

func TestI7C4CActualAPIMetricSelectionReadAndRestart(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, _ := achievementFixture(t, p, true)
	favorForMarriage(t, p, a, 1)
	bearer := displayToken(t, p, a)
	listener, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	addr := listener.Addr().String()
	listener.Close()
	origin := "http://" + addr
	targetDSN := os.Getenv("GXB_I7B6A_DSN")
	assets := filepath.Join(t.TempDir(), "private-media")
	if _, e := blobstore.NewLocal(assets); e != nil {
		t.Fatal(e)
	}
	start := func() *osexec.Cmd {
		cmd := osexec.Command(binary)
		cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+targetDSN, "GXB_HTTP_ADDR="+addr, "GXB_PUBLIC_ENGINE_URL="+origin+"/engine", "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT=19001", "GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001", "GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001", "GXB_REDEEM_DIGEST_SECRET=i7b5b-fixture-redeem-key-00001", "GXB_DERIVATION_KEY_ID=i7b2b-native", "GXB_PROFILE_MEDIA_ROOT="+assets, "GXB_PROFILE_MEDIA_PUBLIC_ORIGIN="+origin)
		log, e := os.CreateTemp(t.TempDir(), "api-log")
		if e != nil {
			t.Fatal(e)
		}
		t.Cleanup(func() { log.Close() })
		cmd.Stdout = log
		cmd.Stderr = log
		if e = cmd.Start(); e != nil {
			t.Fatal(e)
		}
		for end := time.Now().Add(10 * time.Second); time.Now().Before(end); {
			resp, e := http.Get(origin + "/profile-media/missing")
			if e == nil {
				resp.Body.Close()
				return cmd
			}
			time.Sleep(30 * time.Millisecond)
		}
		cmd.Process.Kill()
		cmd.Wait()
		raw, _ := os.ReadFile(log.Name())
		t.Fatal("startup", string(raw))
		return nil
	}
	post := func(mid int, fields map[string]any) (int, map[string]any) {
		fields["mid"] = mid
		fields["token"] = bearer
		fields["region"] = 1
		raw, _ := json.Marshal(fields)
		resp, e := http.Post(origin+"/engine", "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {string(raw)}}.Encode()))
		if e != nil {
			t.Fatal(e)
		}
		defer resp.Body.Close()
		var out map[string]any
		if e = json.NewDecoder(resp.Body).Decode(&out); e != nil {
			t.Fatal(e)
		}
		return resp.StatusCode, out
	}

	cmd := start()
	defer func() { cmd.Process.Kill(); cmd.Wait() }()
	code, out := post(840, map[string]any{"partner_id": 1, "gift_id": 50001112, "gift_num": 1})
	if code != 200 || achievementRoot(t, p, a).Progress != 1 || achievementEvents(t, p, a) != 1 {
		t.Fatal("actualMID840", code, out)
	}
	code, out = post(1831, map[string]any{"show_types": []int64{1010, 1011}})
	if code != 200 {
		t.Fatal("metricselection", code, out)
	}
	selected, ok := out["show_types"].(map[string]any)
	if !ok || selected["1010"] != float64(1) {
		t.Fatal("metricselectionvalue", out)
	}
	code, out = post(1829, map[string]any{"to_player_id": int64(a.PlayerID), "sub_type": 1})
	if code != 200 {
		t.Fatal("selectedread", code, out)
	}
	selected, ok = out["show_types"].(map[string]any)
	if !ok || selected["1010"] != float64(1) {
		t.Fatal("currentmetric", out)
	}
	code, out = post(1840, map[string]any{})
	if code != 200 {
		t.Fatal("creationdiscovery", code, out)
	}
	all, ok := out["all_show_types"].(map[string]any)
	if !ok || len(all) != 1 || all["1011"] == nil {
		t.Fatal("full11 accidentallyactivated", out)
	}
	cmd.Process.Signal(os.Interrupt)
	cmd.Wait()
	cmd = start()
	code, out = post(1829, map[string]any{"to_player_id": int64(a.PlayerID), "sub_type": 1})
	if code != 200 {
		t.Fatal("restartread", code, out)
	}
	selected, ok = out["show_types"].(map[string]any)
	if !ok || selected["1010"] != float64(1) {
		t.Fatal("restartmetric", out)
	}
	code, out = post(1831, map[string]any{"show_types": []int64{1004}})
	if code == 200 {
		t.Fatal("partialachievement fullmetric", out)
	}
}
