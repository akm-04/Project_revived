//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/foundation/tx"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"strconv"
	"sync/atomic"
	"testing"
	"time"
)

func TestI7C2BActualAPILibraryAndRestartRoster(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, _ := libraryFixture(t, p, true)
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
	running := true
	defer func() {
		if running {
			cmd.Process.Kill()
			cmd.Wait()
		}
	}()
	code, out := post(852, map[string]any{"partner_id": 1, "cost_id": 1})
	if code != 200 || len(out["feed_add"].([]any)) != 6 {
		t.Fatal("source MID852", code, out)
	}
	for _, mid := range []int{836, 2784, 853} {
		code, out = post(mid, func() map[string]any {
			if mid == 853 {
				return map[string]any{"partner_id": 1}
			}
			return map[string]any{}
		}())
		if code != 200 {
			t.Fatal(mid, code, out)
		}
	}
	code, out = post(854, map[string]any{"partner_id": 1})
	if code != 200 || len(out["feed_attrs"].([]any)) != 6 {
		t.Fatal("save wire", code, out)
	}
	for _, mid := range []int{49, 836, 853} {
		code, out = post(mid, map[string]any{"player_id": int64(a.PlayerID) + 1, "partner_id": 1})
		if code == 200 {
			t.Fatal("foreign library", mid, out)
		}
	}
	code, out = post(840, map[string]any{"partner_id": 1, "gift_id": 50005013, "gift_num": 1})
	if code != 200 || out["favor_degree"] != float64(2000) {
		t.Fatal("gift wire", code, out)
	}
	code, out = post(72, map[string]any{"partner_id": 1})
	if code != 200 {
		t.Fatal("normal claim wire", code, out)
	}
	code, out = post(2785, map[string]any{"id": 1})
	if code == 200 {
		t.Fatal("ineligible special", out)
	}
	code, out = post(49, map[string]any{})
	if code != 200 {
		t.Fatal("MID49", code, out)
	}
	before, _ := json.Marshal(out)
	cmd.Process.Signal(os.Interrupt)
	cmd.Wait()
	running = false
	cmd = start()
	running = true
	code, out = post(49, map[string]any{})
	after, _ := json.Marshal(out)
	if code != 200 || !bytes.Equal(before, after) {
		t.Fatal("restart roster", code, out, string(before))
	}
	if f := libraryFacts(t, p, a); f.Pending != nil || f.Applied == ([6]int64{}) || !f.Married {
		t.Fatal("restart canonical facts", f)
	}
}

// Process death at retained admission or economic COMMIT tests persistence,
// separate from in-process ACK-loss injection.
type libraryKillInput = display.Result

type libraryKillDB struct {
	tx.Beginner
	n         atomic.Int32
	at        int32
	file      string
	committed bool
}

func (d *libraryKillDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	tr, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	if d.n.Add(1) == d.at {
		return killDisplayTx{Tx: tr, file: d.file, committed: d.committed}, nil
	}
	return tr, nil
}
func TestI7C2BProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2B_KILL_INPUT")
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
	at, _ := strconv.Atoi(os.Getenv("GXB_I7C2B_KILL_AT"))
	p := pool(t)
	_, e = libraryService(p, &libraryKillDB{Beginner: p, at: int32(at), file: file + ".ready", committed: os.Getenv("GXB_I7C2B_KILL_COMMITTED") == "1"}).Command(ctx, in.Actor, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, in.Operation)
	t.Fatal("returned past boundary", e)
}
func TestI7C2BProcessKillReopenPaidAdmission(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, caseID := range []struct {
		at        int32
		committed bool
	}{{1, true}, {2, false}, {2, true}} {
		a, _ := libraryFixture(t, p, true)
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
		cmd := osexec.Command(exe, "-test.run=^TestI7C2BProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2B_KILL_INPUT="+file, "GXB_I7C2B_KILL_AT="+strconv.Itoa(int(caseID.at)), "GXB_I7C2B_KILL_COMMITTED="+flag)
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
		want := int64(5000000)
		if caseID.at == 2 && caseID.committed {
			want = 4500000
		}
		if libraryAmount(t, p, a, "mana") != want {
			t.Fatal("commit visibility", caseID)
		}
		reopened := pool(t)
		s := libraryService(reopened, reopened)
		r, e := s.Command(ctx, a, app.Command{Family: app.Feed, PartnerID: 1, Value: 1}, in.Operation)
		if e != nil || r.OperationID != in.Operation.ID || libraryAmount(t, p, a, "mana") != 4500000 {
			t.Fatal("recovered exact operation", caseID, r, e)
		}
	}
}
