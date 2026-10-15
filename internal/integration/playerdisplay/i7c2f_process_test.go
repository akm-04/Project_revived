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
	app "gxb.local/backend/v2/internal/application/inscription"
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

func TestI7C2FActualAPIRecoveryRosterAndRestart(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, _, svc := inscriptionFixture(t, p)
	rev := installed(t, p)
	h := skillHero(t, p, a, rev, 11001, 4)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (bookstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, time.Now().Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = (librarystore.Store{}).EnsurePlayerRootTx(ctx, tr, a.PlayerID, time.Now().Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	for _, id := range []int64{1, 2, 3, 4} {
		h := skillRead(t, p, a, id)
		if id == 4 {
			if e = (inscriptionstore.Store{}).EnsureHeroTx(ctx, tr, a.PlayerID, id, time.Now().Add(-time.Hour)); e != nil {
				t.Fatal(e)
			}
			if e = (coursestore.Store{}).InitFreshHeroTx(ctx, tr, h.Ref(), time.Now().Add(-time.Hour)); e != nil {
				t.Fatal(e)
			}
		}
		if e = (dormstore.Store{}).InitFreshHeroTx(ctx, tr, h.Ref(), time.Now().Add(-time.Hour)); e != nil {
			t.Fatal(e)
		}
		if _, e = (librarystore.Store{}).BackfillMissingHeroTx(ctx, tr, h.Ref(), time.Now().Add(-time.Hour)); e != nil {
			t.Fatal(e)
		}
	}
	_ = h
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

	insCmd(t, svc, a, app.Command{Family: app.Insert, PartnerID: 1, ItemID: 160100101})
	r := insCmd(t, svc, a, app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 10, CostType: 1})
	chosen := insIDs(t, r)[0]
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
		{1405, map[string]any{"item_id": chosen}, 200},
		{1403, map[string]any{"partner_id": 1, "item_id": 160100101}, 200},
		{1404, map[string]any{"item_id": 160100101, "resolve_num": 1}, 200},
		{1406, map[string]any{}, 200}, {1407, map[string]any{}, 200},
		{1400, map[string]any{"inscript_id": 10001, "make_num": 1}, 503},
		{1401, map[string]any{"item_id": 160100101, "rebuild_num": 1, "cost_type": 1}, 503},
		{1402, map[string]any{"partner_id": 1, "item_id": 160100102, "replace_item_id": 160100101}, 503},
		{1406, map[string]any{}, 200},
		{1400, map[string]any{"inscript_id": 10001, "make_num": true}, 400},
		{1402, map[string]any{"partner_id": 1, "item_id": 160100102, "proposal_nonce": 1}, 400},
	} {
		code, out := post(step.mid, step.params)
		if code != step.status {
			t.Fatal(step.mid, code, out)
		}
		if code == 200 {
			if out["economy_"] == nil || out["extra_drops_"] != nil {
				t.Fatal("sideband/double award", step.mid, out)
			}
			if step.mid == 1407 {
				xs, ok := out["currency_change"].([]any)
				if !ok || len(xs) != 3 {
					t.Fatal("exchange rows", out)
				}
			}
		}
	}
	// Missing eligibility is rejected before admission and cannot fence recovery.
	code, out := post(49, map[string]any{})
	if code != 200 {
		t.Fatal("roster", code, out)
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
		t.Fatal("restart roster", code, out)
	}
	newAccount, newSession := uuid(), uuid()
	exec(t, p, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp()-interval '1 hour')`, newAccount.String(), newAccount.String())
	exec(t, p, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,$3,clock_timestamp()-interval '1 hour',clock_timestamp())`, newSession.String(), newAccount.String(), string(identity.AuthProductionPair))
	sidRaw := "i7c2f-sid-" + newSession.String()
	loginRaw := "i7c2f-login-" + newSession.String()
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
	if code != 200 || out["detail"] == nil || out["detail"].(map[string]any)["2137"] == nil {
		t.Fatal("MID1inscription", code, out)
	}

}

type inscriptionKillInput = display.Result

func TestI7C2FProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2F_KILL_INPUT")
	if file == "" {
		t.Skip("child only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in inscriptionKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	at, _ := strconv.Atoi(os.Getenv("GXB_I7C2F_KILL_AT"))
	p := pool(t)
	_, e = inscriptionService(p, &libraryKillDB{Beginner: p, at: int32(at), file: file + ".ready", committed: os.Getenv("GXB_I7C2F_KILL_COMMITTED") == "1"}).Command(ctx, in.Actor, app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 10, CostType: 1}, in.Operation)
	t.Fatal("returned past boundary", e)
}
func TestI7C2FProcessKillReopenPaidRebuild(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, boundary := range []struct {
		at        int32
		committed bool
	}{{1, true}, {2, false}, {2, true}} {
		a, _, _ := inscriptionFixture(t, p)
		in := inscriptionKillInput{Actor: a, Operation: op()}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "dorm-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if boundary.committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C2FProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2F_KILL_INPUT="+file, "GXB_I7C2F_KILL_AT="+strconv.Itoa(int(boundary.at)), "GXB_I7C2F_KILL_COMMITTED="+flag)
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
		want := int64(10001000)
		if boundary.at == 2 && boundary.committed {
			want = 10000800
		}
		if libraryAmount(t, p, a, "crystal") != want {
			t.Fatal("commit visibility", boundary)
		}
		reopened := pool(t)
		result, e := inscriptionService(reopened, reopened).Command(ctx, a, app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 10, CostType: 1}, in.Operation)
		if e != nil || result.OperationID != in.Operation.ID || libraryAmount(t, reopened, a, "crystal") != 10000800 {
			t.Fatal("reopen", boundary, result, e)
		}
		if insRoot(t, reopened, a).Facts.Pending == nil || len(insRoot(t, reopened, a).Facts.Pending.Candidates) != 10 {
			t.Fatal("duplicate book")
		}
	}
}
