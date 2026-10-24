//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"compress/zlib"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	app "gxb.local/backend/v2/internal/application/heroevolution"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
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

func TestI7C2IActualAPIBothCommandsInventoryRosterRestart(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, rev, svc := evolutionFixture(t, p)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	at := time.Now().Add(-time.Hour)
	for _, f := range []func() error{func() error { return (spiritstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, at) }, func() error { return (inscriptionstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, at) }, func() error { return (bookstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, at) }, func() error { return (librarystore.Store{}).EnsurePlayerRootTx(ctx, tr, a.PlayerID, at) }, func() error { return (dormstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, at) }, func() error { return (coursestore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, at) }} {
		if e = f(); e != nil {
			t.Fatal(e)
		}
	}
	for _, id := range []int64{1, 2} {
		h := skillRead(t, p, a, id)
		if e = (spiritstore.Store{}).EnsureHeroTx(ctx, tr, a.PlayerID, id, at); e != nil {
			t.Fatal(e)
		}
		if e = (inscriptionstore.Store{}).EnsureHeroTx(ctx, tr, a.PlayerID, id, at); e != nil {
			t.Fatal(e)
		}
		if e = (coursestore.Store{}).InitFreshHeroTx(ctx, tr, h.Ref(), at); e != nil {
			t.Fatal(e)
		}
		if e = (dormstore.Store{}).InitFreshHeroTx(ctx, tr, h.Ref(), at); e != nil {
			t.Fatal(e)
		}
		if _, e = (librarystore.Store{}).BackfillMissingHeroTx(ctx, tr, h.Ref(), at); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
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
		{2608, map[string]any{"partner_id": 1, "attr_id": 4, "add_num": 2, "cost_item": 40001001}, 200},
		{2608, map[string]any{"partner_id": 1, "attr_id": 4, "add_num": 18, "cost_item": 50005148}, 200},
		{2608, map[string]any{"partner_id": 1, "attr_id": 7, "add_num": 20, "cost_item": 50005149}, 200},
		{2608, map[string]any{"partner_id": 1, "attr_id": 8, "add_num": 20, "cost_item": 40001001}, 200},
		{2608, map[string]any{"partner_id": 1, "attr_id": 11, "add_num": 20, "cost_item": 40001001}, 200},
		{2608, map[string]any{"partner_id": 1, "attr_id": 26, "add_num": 20, "cost_item": 40001001}, 200},
		{2609, map[string]any{"partner_id": 1}, 200},
		{2608, map[string]any{"partner_id": 1, "attr_id": 4, "add_num": 3, "cost_item": 40001001}, 200},
		{2608, map[string]any{"partner_id": 2, "attr_id": 7, "add_num": 1, "cost_item": 41001}, 200},
		{2608, map[string]any{"partner_id": 1, "attr_id": 4, "add_num": 1, "cost_item": 41001}, 400},
		{2608, map[string]any{"partner_id": 1, "attr_id": 4, "add_num": true, "cost_item": 40001001}, 400},
		{2609, map[string]any{"partner_id": 1, "twice_awake_stage": 3}, 400},
		{2738, map[string]any{"mission_id": 1, "awake_type": 2}, 501},
	} {
		code, out := post(step.mid, step.params)
		if code != step.status {
			t.Fatal(step.mid, code, out)
		}
		if code == 200 {
			body, ok := out.(map[string]any)
			if !ok || body["evo_info"] == nil || body["extra_drops_"] != nil {
				t.Fatal("callback or duplicate cost projection", out)
			}
		}
	}
	code, inventory := post(81, map[string]any{})
	if code != 200 {
		t.Fatal(code, inventory)
	}
	bag := inventory.(map[string]any)
	if bag["sort_type"] == nil || bag["list"] == nil || len(bag["spirit_list"].([]any)) != 0 {
		t.Fatal("MID81", bag)
	}
	code, out := post(49, map[string]any{})
	if code != 200 {
		t.Fatal("roster", code, out)
	}
	row := out.(map[string]any)["heros"].(map[string]any)["1"].(map[string]any)
	if row["evo_stage"] != float64(2) || row["evo_attr_points"].(map[string]any)["4"] != float64(3) {
		t.Fatal("canonical evolution roster", row)
	}
	superRow := out.(map[string]any)["heros"].(map[string]any)["2"].(map[string]any)
	if superRow["evo_attr_points"].(map[string]any)["7"] != float64(1) {
		t.Fatal("Super roster", superRow)
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
	sidRaw := "i7c2i-sid-" + newSession.String()
	loginRaw := "i7c2i-login-" + newSession.String()
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

type evolutionKillInput = display.Result

func TestI7C2IProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2I_KILL_INPUT")
	if file == "" {
		t.Skip("child only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in evolutionKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	at, _ := strconv.Atoi(os.Getenv("GXB_I7C2I_KILL_AT"))
	p := pool(t)
	_, e = evolutionService(p, &libraryKillDB{Beginner: p, at: int32(at), file: file + ".ready", committed: os.Getenv("GXB_I7C2I_KILL_COMMITTED") == "1"}).Command(ctx, in.Actor, app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 2, CostItem: 40001001}, in.Operation)
	t.Fatal("returned past boundary", e)
}
func TestI7C2IProcessKillReopenAppliedPoints(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, boundary := range []struct {
		at        int32
		committed bool
	}{{1, true}, {2, false}, {2, true}} {
		a, _, _ := evolutionFixture(t, p)
		in := evolutionKillInput{Actor: a, Operation: op()}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "dorm-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if boundary.committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C2IProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2I_KILL_INPUT="+file, "GXB_I7C2I_KILL_AT="+strconv.Itoa(int(boundary.at)), "GXB_I7C2I_KILL_COMMITTED="+flag)
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
		want := int64(900)
		if boundary.at == 2 && boundary.committed {
			want = 898
		}
		if evolutionStock(t, p, a, 40001001) != want {
			t.Fatal("kill commit visibility", boundary)
		}
		reopened := pool(t)
		result, e := evolutionService(reopened, reopened).Command(ctx, a, app.Command{Family: app.Allocate, PartnerID: 1, AttrID: 4, Amount: 2, CostItem: 40001001}, in.Operation)
		if e != nil || result.OperationID != in.Operation.ID || evolutionStock(t, reopened, a, 40001001) != 898 || evolutionFacet(t, reopened, a, 1).Facts.Points["4"] != 2 {
			t.Fatal("kill/reopen exactly once", boundary, result, e)
		}
	}
}
