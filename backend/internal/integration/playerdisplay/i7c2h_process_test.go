//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"compress/zlib"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	app "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/domain/identity"
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

func TestI7C2HActualAPIAllNineCommandsInventoryRosterRestart(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, _, svc := spiritFixture(t, p)
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
	post := func(mid int, fields map[string]any) (int, any) {
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
		var out any
		if e = json.NewDecoder(resp.Body).Decode(&out); e != nil {
			t.Fatal(e)
		}
		return resp.StatusCode, out
	}

	_ = svc
	cmd := start()
	running := true
	defer func() {
		if running {
			cmd.Process.Kill()
			cmd.Wait()
		}
	}()
	for _, step := range []struct {
		mid    int
		params map[string]any
		status int
	}{
		{3090, map[string]any{"spirit_id": 1}, 200}, {3091, map[string]any{"spirit_id": 1}, 200}, {3094, map[string]any{"partner_id": 1, "spirit_id": 1, "pos": 1}, 200}, {3113, map[string]any{"name": "First", "collocation": "1|4|0|0|0|0"}, 200}, {3112, map[string]any{}, 200}, {3115, map[string]any{"id": 1, "partner_id": 2}, 200}, {3095, map[string]any{"partner_id": 2}, 200}, {3114, map[string]any{"id": 1}, 200}, {3089, map[string]any{"spirit_id": 1, "spirit_ids": []int64{6}}, 200}, {3094, map[string]any{"partner_id": 1, "spirit_id": 1, "pos": 1}, 200}, {3094, map[string]any{"partner_id": 1, "spirit_id": 1, "pos": true}, 400}, {3113, map[string]any{"name": "bad", "collocation": "1|0|0"}, 400}, {3098, map[string]any{}, 501}, {3088, map[string]any{}, 501}} {
		code, out := post(step.mid, step.params)
		if code != step.status {
			t.Fatal(step.mid, code, out)
		}
		if step.mid == 3112 {
			if rows, ok := out.([]any); !ok || len(rows) != 1 {
				t.Fatal("raw program array", out)
			}
		}
	}
	code, inventory := post(81, map[string]any{})
	if code != 200 {
		t.Fatal(code, inventory)
	}
	bag := inventory.(map[string]any)
	if bag["sort_type"] == nil || bag["list"] == nil || len(bag["spirit_list"].([]any)) != 14 {
		t.Fatal("MID81", bag)
	}
	code, out := post(49, map[string]any{})
	if code != 200 {
		t.Fatal("roster", code, out)
	}
	row := out.(map[string]any)["heros"].(map[string]any)["1"].(map[string]any)
	if row["spirit_item"].([]any)[0].(map[string]any)["spirit_id"] != float64(1) {
		t.Fatal("materialized reload", row)
	}
	before, _ := json.Marshal(out)
	cmd.Process.Kill()
	cmd.Wait()
	running = false
	cmd = start()
	running = true
	code, out = post(49, map[string]any{})
	after, _ := json.Marshal(out)
	if code != 200 || !bytes.Equal(before, after) {
		t.Fatal("restart", code, out)
	}
	newAccount, newSession := uuid(), uuid()
	exec(t, p, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp()-interval '1 hour')`, newAccount.String(), newAccount.String())
	exec(t, p, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,$3,clock_timestamp()-interval '1 hour',clock_timestamp())`, newSession.String(), newAccount.String(), string(identity.AuthProductionPair))
	sidRaw := "i7c2h-sid-" + newSession.String()
	loginRaw := "i7c2h-login-" + newSession.String()
	for _, c := range []struct{ kind, label, raw string }{{"SID", "sid", sidRaw}, {"LOGIN_TOKEN", "login_token", loginRaw}} {
		d, e := identity.DigestCredential([]byte("i7b2b-fixture-digest-key-00001"), c.label, c.raw)
		if e != nil {
			t.Fatal(e)
		}
		exec(t, p, `INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,clock_timestamp()-interval '1 minute')`, uuid().String(), newSession.String(), c.kind, d[:])
	}
	code, out = post(18, map[string]any{"sid": sidRaw, "login_token": loginRaw})
	if code != 200 {
		t.Fatal("account observation", code, out)
	}

	code, out = post(1, map[string]any{"sid": sidRaw, "login_token": loginRaw})
	if code != 200 || out.(map[string]any)["detail"] == nil || out.(map[string]any)["detail"].(map[string]any)["2137"] == nil || out.(map[string]any)["detail"].(map[string]any)["81"].(map[string]any)["spirit_list"] == nil {
		t.Fatal("MID1inscription", code, out)
	}

}

type spiritKillInput = display.Result

func TestI7C2HProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2H_KILL_INPUT")
	if file == "" {
		t.Skip("child only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in spiritKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	at, _ := strconv.Atoi(os.Getenv("GXB_I7C2H_KILL_AT"))
	p := pool(t)
	_, e = spiritService(p, &libraryKillDB{Beginner: p, at: int32(at), file: file + ".ready", committed: os.Getenv("GXB_I7C2H_KILL_COMMITTED") == "1"}).Command(ctx, in.Actor, app.Command{Family: app.Enhance, SpiritID: 1, SpiritIDs: []int64{6}}, in.Operation)
	t.Fatal("returned past boundary", e)
}
func TestI7C2HProcessKillReopenPaidRebuild(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, boundary := range []struct {
		at        int32
		committed bool
	}{{1, true}, {2, false}, {2, true}} {
		a, _, _ := spiritFixture(t, p)
		in := spiritKillInput{Actor: a, Operation: op()}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "dorm-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if boundary.committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C2HProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2H_KILL_INPUT="+file, "GXB_I7C2H_KILL_AT="+strconv.Itoa(int(boundary.at)), "GXB_I7C2H_KILL_COMMITTED="+flag)
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
		want := int64(100000000)
		if boundary.at == 2 && boundary.committed {
			want = 99500000
		}
		if libraryAmount(t, p, a, "mana") != want {
			t.Fatal("kill commit visibility", boundary)
		}
		reopened := pool(t)
		result, e := spiritService(reopened, reopened).Command(ctx, a, app.Command{Family: app.Enhance, SpiritID: 1, SpiritIDs: []int64{6}}, in.Operation)
		if e != nil || result.OperationID != in.Operation.ID || libraryAmount(t, reopened, a, "mana") != 99500000 || spiritRoot(t, reopened, a).Facts.Instances[1].EXP != 20000 {
			t.Fatal("kill/reopen exactly once", boundary, result, e)
		}
	}
}
