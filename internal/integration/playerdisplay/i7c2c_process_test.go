//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"compress/zlib"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	app "gxb.local/backend/v2/internal/application/dormhouse"
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

func TestI7C2CActualAPIDormAndRestartRoster(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, _, catalog := dormFixture(t, p)
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
	code, out := post(2512, map[string]any{})
	if code != 200 || len(out["house_list"].([]any)) != 4 {
		t.Fatal("list", code, out)
	}
	key := dormKey(catalog, 2, true)
	code, out = post(2513, map[string]any{"key_item": key, "floor": 1, "pos": 1})
	if code != 200 {
		t.Fatal("open", code, out)
	}
	house := int64(out["house_info"].(map[string]any)["house_id"].(float64))
	code, out = post(2517, map[string]any{"house_id": house, "partner_ids": []int64{1}})
	if code != 200 {
		t.Fatal("enter", code, out)
	}
	code, out = post(2514, map[string]any{"house_id": house, "host_id": int64(a.PlayerID)})
	if code != 200 || out["item_record"] == nil {
		t.Fatal("detail", code, out)
	}
	code, out = post(2515, map[string]any{"house_id": house, "furniture_record": out["house_detail"].(map[string]any)["record"]})
	if code != 200 {
		t.Fatal("save", code, out)
	}
	code, out = post(2515, map[string]any{"house_id": house, "furniture_record": map[string]string{"50031013#999#1#0": ""}})
	if code != 400 || out["wrong_key"] != "50031013#999#1#0" {
		t.Fatal("layout error key", code, out)
	}
	exec(t, p, `UPDATE player_heroes SET color=16,level=99 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	skillBook(t, p, a, catalog.Equipment[10001001].Items[0])
	code, out = post(2516, map[string]any{"house_id": house, "index": 1})
	if code != 200 {
		t.Fatal("equip", code, out)
	}
	code, out = post(2693, map[string]any{"item_id": 50035007, "item_num": 1})
	if code != 200 || len(out["awards"].([]any)) != 1 {
		t.Fatal("exchange awards", code, out)
	}
	code, out = post(2513, map[string]any{"key_item": dormKey(catalog, 4, false), "floor": 1, "pos": 1})
	if code != 200 {
		t.Fatal("villa", code, out)
	}
	villa := int64(out["house_info"].(map[string]any)["house_id"].(float64))
	code, out = post(2694, map[string]any{"house_id": villa})
	if code != 200 || out["house_info"].(map[string]any)["expand_lev"] != float64(0) {
		t.Fatal("start", code, out)
	}
	code, out = post(2695, map[string]any{"house_id": villa})
	if code != 200 || out["house_info"].(map[string]any)["expand_lev"] != float64(1) {
		t.Fatal("finish", code, out)
	}
	code, out = post(49, map[string]any{})
	if code != 200 {
		t.Fatal("roster", code, out)
	}
	row := out["heros"].(map[string]any)["1"].(map[string]any)
	if int64(row["house_id"].(float64)) != house || len(row["house_equips"].([]any)) != 5 {
		t.Fatal("roster dorm", row)
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
	if dormStack(t, p, a, key) != 19 {
		t.Fatal("restart debit")
	}
}

type dormKillInput = display.Result

func TestI7C2CProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2C_KILL_INPUT")
	if file == "" {
		t.Skip("child only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in dormKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	at, _ := strconv.Atoi(os.Getenv("GXB_I7C2C_KILL_AT"))
	p := pool(t)
	_, e = dormService(p, &libraryKillDB{Beginner: p, at: int32(at), file: file + ".ready", committed: os.Getenv("GXB_I7C2C_KILL_COMMITTED") == "1"}).Command(ctx, in.Actor, app.Command{Family: app.Open, ItemID: 50035016, Floor: 1, Position: 1}, in.Operation)
	t.Fatal("returned past boundary", e)
}
func TestI7C2CProcessKillReopenRandomPaidAdmission(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, boundary := range []struct {
		at        int32
		committed bool
	}{{1, true}, {2, false}, {2, true}} {
		a, _, catalog := dormFixture(t, p)
		in := dormKillInput{Actor: a, Operation: op()}
		expected, e := catalog.SelectRoom(50035016, in.Operation)
		if e != nil {
			t.Fatal(e)
		}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "dorm-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if boundary.committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C2CProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2C_KILL_INPUT="+file, "GXB_I7C2C_KILL_AT="+strconv.Itoa(int(boundary.at)), "GXB_I7C2C_KILL_COMMITTED="+flag)
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
			want = 19
		}
		if dormStack(t, p, a, 50035016) != want {
			t.Fatal("commit visibility", boundary)
		}
		reopened := pool(t)
		result, e := dormService(reopened, reopened).Command(ctx, a, app.Command{Family: app.Open, ItemID: 50035016, Floor: 1, Position: 1}, in.Operation)
		if e != nil || result.OperationID != in.Operation.ID || dormStack(t, reopened, a, 50035016) != 19 {
			t.Fatal("reopen", boundary, result, e)
		}
		rooms, e := dormService(reopened, reopened).Owner.ListRoomsTx(ctx, reopened, a.PlayerID)
		if e != nil {
			t.Fatal(e)
		}
		if len(rooms) != 2 {
			t.Fatal("duplicate room", rooms)
		}
		for _, r := range rooms {
			if r.MainType == 2 && r.TableID != expected {
				t.Fatal("rerolled", r.TableID, expected)
			}
		}
	}
}
