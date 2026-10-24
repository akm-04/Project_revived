//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"compress/zlib"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	app "gxb.local/backend/v2/internal/application/bookskill"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"mime/multipart"
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

func TestI7C2DActualAPIBooksAndRestartRoster(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, _, _ := bookFixture(t, p)
	rev := installed(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
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
		var requestBody bytes.Buffer
		contentType := "application/x-www-form-urlencoded"
		if mid == 2515 {
			var compressed bytes.Buffer
			zw := zlib.NewWriter(&compressed)
			zw.Write(raw)
			zw.Close()
			mw := multipart.NewWriter(&requestBody)
			part, e := mw.CreateFormField("payload")
			if e != nil {
				t.Fatal(e)
			}
			part.Write(compressed.Bytes())
			mw.Close()
			contentType = mw.FormDataContentType()
		} else {
			requestBody.WriteString(url.Values{"payload": {string(raw)}}.Encode())
		}
		resp, e := http.Post(origin+"/engine", contentType, &requestBody)
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
	code, out := post(1056, map[string]any{})
	if code != 200 || out["building_list"] == nil {
		t.Fatal("buildings", code, out)
	}
	for _, step := range []struct {
		mid    int
		params map[string]any
	}{{83, map[string]any{"item_id": 130001001, "item_num": 1}}, {1059, map[string]any{}}, {1060, map[string]any{"skill_id": 10010001}}, {1078, map[string]any{"skill_id": 10010001}}, {1079, map[string]any{}}, {1057, map[string]any{"type": 4}}, {1058, map[string]any{"type": 4}}, {1057, map[string]any{"type": 4}}, {1077, map[string]any{"type": 4}}, {1080, map[string]any{"type": 4}}, {1060, map[string]any{"skill_id": 10010004}}, {1061, map[string]any{"skill_id": 10010004}}} {
		code, out = post(step.mid, step.params)
		if code != 200 {
			t.Fatal(step.mid, code, out)
		}
	}
	code, out = post(49, map[string]any{})
	if code != 200 {
		t.Fatal("roster", code, out)
	}
	row := out["heros"].(map[string]any)["1"].(map[string]any)
	if row["book_shelf_lev"] != float64(2) || row["skill_book_info"].(map[string]any)["10010001"] != float64(1) {
		t.Fatal("roster book", row)
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
		t.Fatal("restart", code, out)
	}
	if dormStack(t, p, a, 130001001) != 1 {
		t.Fatal("restart debit")
	}
}

type bookKillInput = display.Result

func TestI7C2DProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2D_KILL_INPUT")
	if file == "" {
		t.Skip("child only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in bookKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	at, _ := strconv.Atoi(os.Getenv("GXB_I7C2D_KILL_AT"))
	p := pool(t)
	_, e = bookService(p, &libraryKillDB{Beginner: p, at: int32(at), file: file + ".ready", committed: os.Getenv("GXB_I7C2D_KILL_COMMITTED") == "1"}).Command(ctx, in.Actor, app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1}, in.Operation)
	t.Fatal("returned past boundary", e)
}
func TestI7C2DProcessKillReopenRandomPaidAdmission(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, boundary := range []struct {
		at        int32
		committed bool
	}{{1, true}, {2, false}, {2, true}} {
		a, _, _ := bookFixture(t, p)
		in := bookKillInput{Actor: a, Operation: op()}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "dorm-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if boundary.committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C2DProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2D_KILL_INPUT="+file, "GXB_I7C2D_KILL_AT="+strconv.Itoa(int(boundary.at)), "GXB_I7C2D_KILL_COMMITTED="+flag)
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
			t.Fatal("boundary", boundary, log.String())
		}
		want := int64(20)
		if boundary.at == 2 && boundary.committed {
			want = 0
		}
		if dormStack(t, p, a, 140001001) != want {
			t.Fatal("commit visibility", boundary)
		}
		reopened := pool(t)
		result, e := bookService(reopened, reopened).Command(ctx, a, app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1}, in.Operation)
		if e != nil || result.OperationID != in.Operation.ID || dormStack(t, reopened, a, 140001001) != 0 {
			t.Fatal("reopen", boundary, result, e)
		}
		if dormStack(t, reopened, a, 130001001) != 1 {
			t.Fatal("duplicate book")
		}
	}
}
