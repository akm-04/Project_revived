//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"strconv"
	"testing"
	"time"
)

func TestI7C4BActualAPIRingAndRestartFacts(t *testing.T) {
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
	before := achievementRoot(t, p, a)
	cmd.Process.Signal(os.Interrupt)
	cmd.Wait()
	cmd = start()
	after := achievementRoot(t, p, a)
	if before.Progress != after.Progress || before.StateVersion != after.StateVersion || !before.CompleteTimes[0].Equal(*after.CompleteTimes[0]) {
		t.Fatal("restart changed earned facts")
	}
	code, out = post(840, map[string]any{"partner_id": 1, "gift_id": 50001112, "gift_num": 1})
	if code != 200 || achievementEvents(t, p, a) != 1 {
		t.Fatal("actual noop", code, out)
	}
}

func TestI7C4BProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C4B_KILL_INPUT")
	if file == "" {
		t.Skip("child only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in libraryKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	at, _ := strconv.Atoi(os.Getenv("GXB_I7C4B_KILL_AT"))
	p := pool(t)
	_, e = achievementLibraryService(p, &libraryKillDB{Beginner: p, at: int32(at), file: file + ".ready", committed: os.Getenv("GXB_I7C4B_KILL_COMMITTED") == "1"}).Command(ctx, in.Actor, app.Command{Family: app.Gift, PartnerID: 1, Value: 50001112}, in.Operation)
	t.Fatal("returned past boundary", e)
}

func TestI7C4BProcessKillReopenMarriageFact(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, caseID := range []struct {
		at        int32
		committed bool
	}{{1, true}, {2, false}, {2, true}} {
		a, _ := achievementFixture(t, p, true)
		favorForMarriage(t, p, a, 1)
		in := libraryKillInput{Actor: a, Operation: op()}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "library-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if caseID.committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C4BProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C4B_KILL_INPUT="+file, "GXB_I7C4B_KILL_AT="+strconv.Itoa(int(caseID.at)), "GXB_I7C4B_KILL_COMMITTED="+flag)
		var log bytes.Buffer
		cmd.Stdout = &log
		cmd.Stderr = &log
		if e = cmd.Start(); e != nil {
			t.Fatal(e)
		}
		ready := false
		for end := time.Now().Add(10 * time.Second); time.Now().Before(end); {
			if _, e = os.Stat(file + ".ready"); e == nil {
				ready = true
				break
			}
			time.Sleep(20 * time.Millisecond)
		}
		cmd.Process.Kill()
		cmd.Wait()
		if !ready {
			t.Fatal("boundary", caseID, log.String())
		}
		want := 0
		if caseID.at == 2 && caseID.committed {
			want = 1
		}
		if achievementEvents(t, p, a) != want || libraryFacts(t, p, a).Married != (want == 1) {
			t.Fatal("atomic commit visibility", caseID)
		}
		reopened := pool(t)
		s := achievementLibraryService(reopened, reopened)
		r, e := s.Command(ctx, a, app.Command{Family: app.Gift, PartnerID: 1, Value: 50001112}, in.Operation)
		if e != nil || r.OperationID != in.Operation.ID || achievementEvents(t, p, a) != 1 || achievementRoot(t, p, a).Progress != 1 {
			t.Fatal("recovered exact operation", caseID, r, e)
		}
	}
}
