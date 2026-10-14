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
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	app "gxb.local/backend/v2/internal/application/course"
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

func TestI7C2EActualAPICourseAndRestartRoster(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	a, _, _ := courseFixture(t, p)
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

	cmd := start()
	running := true
	defer func() {
		if running {
			cmd.Process.Kill()
			cmd.Wait()
		}
	}()
	code, out := post(2130, map[string]any{})
	if code != 200 || out["log_infos"] == nil {
		t.Fatal("course room", code, out)
	}
	for _, step := range []struct {
		mid    int
		params map[string]any
	}{{2128, map[string]any{"partner_id": 1, "course_id": 100101}}, {2131, map[string]any{"partner_id": 1, "course_id": 100101}}, {2132, map[string]any{"partner_id": 1, "course_id": 100101}}, {2131, map[string]any{"partner_id": 1, "course_id": 100101}}, {2132, map[string]any{"partner_id": 1, "course_id": 100101}}, {2142, map[string]any{"partner_id": 1, "course_id": 100101}}, {2132, map[string]any{"partner_id": 1, "course_id": 100101}}, {2142, map[string]any{"partner_id": 1, "course_id": 100101}}, {2132, map[string]any{"partner_id": 1, "course_id": 100101}}, {2142, map[string]any{"partner_id": 1, "course_id": 100101}}, {2132, map[string]any{"partner_id": 1, "course_id": 100101}}, {2133, map[string]any{"partner_id": 1, "course_id": 100101, "skill_index": 1}}, {2140, map[string]any{"partner_id": 1, "course_id": 100101, "item_id": 50001423, "item_num": 1, "total_num": 20}}, {2135, map[string]any{"partner_id": 2}}, {2139, map[string]any{}}, {2137, map[string]any{}}} {
		code, out = post(step.mid, step.params)
		if code != 200 {
			t.Fatal(step.mid, code, out)
		}
		if (step.mid == 2137 || step.mid == 2139) && len(out["study_infos"].([]any)) != 1 {
			t.Fatal("giftfalseempty", out)
		}
	}
	for _, step := range []struct {
		mid    int
		params map[string]any
	}{{2129, map[string]any{"partner_id": 1}}, {2136, map[string]any{"partner_id": 2}}, {2135, map[string]any{"partner_id": 3}}, {2138, map[string]any{"partner_id": 3}}, {2131, map[string]any{"partner_id": 4, "course_id": 100101}}} {
		code, out = post(step.mid, step.params)
		if code != 200 {
			t.Fatal(step.mid, code, out)
		}
	}
	for i := 0; i < 5; i++ {
		code, out = post(2132, map[string]any{"partner_id": 4, "course_id": 100101})
		if code != 200 {
			t.Fatal("Superspeed", code, out)
		}
		if i < 4 {
			code, out = post(2142, map[string]any{"partner_id": 4, "course_id": 100101})
			if code != 200 {
				t.Fatal("Supercontinue", code, out)
			}
		}
	}
	code, out = post(2133, map[string]any{"partner_id": 4, "course_id": 100101, "skill_index": 4})
	if code != 200 {
		t.Fatal("Superbind", code, out)
	}
	code, out = post(49, map[string]any{})
	if code != 200 {
		t.Fatal("roster", code, out)
	}
	row := out["heros"].(map[string]any)["1"].(map[string]any)
	if row["courses"].([]any)[0] != float64(100101) || row["courses_progress"].([]any)[0] != float64(100) || row["courses_skill"].([]any)[0] != float64(1) || row["courses_exp"].([]any)[0] != float64(1250) {
		t.Fatal("course roster", row)
	}
	superRow := out["heros"].(map[string]any)["4"].(map[string]any)
	if superRow["courses_skill"].([]any)[0] != float64(4) {
		t.Fatal("Superroster", superRow)
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
	if dormStack(t, p, a, 160600001) != 18 {
		t.Fatal("restart debit")
	}
	code, out = post(2134, map[string]any{"partner_id": 4, "course_id": 100101})
	if code != 200 || out["return_items"] == nil {
		t.Fatal("forgetwire", code, out)
	}
	newAccount, newSession := uuid(), uuid()
	exec(t, p, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp()-interval '1 hour')`, newAccount.String(), newAccount.String())
	exec(t, p, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,$3,clock_timestamp()-interval '1 hour',clock_timestamp())`, newSession.String(), newAccount.String(), string(identity.AuthProductionPair))
	sidRaw := "i7c2e-sid-" + newSession.String()
	loginRaw := "i7c2e-login-" + newSession.String()
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
		t.Fatal("MID1course", code, out)
	}

}

type courseKillInput = display.Result

func TestI7C2EProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2E_KILL_INPUT")
	if file == "" {
		t.Skip("child only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in courseKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	at, _ := strconv.Atoi(os.Getenv("GXB_I7C2E_KILL_AT"))
	p := pool(t)
	_, e = courseService(p, &libraryKillDB{Beginner: p, at: int32(at), file: file + ".ready", committed: os.Getenv("GXB_I7C2E_KILL_COMMITTED") == "1"}).Command(ctx, in.Actor, app.Command{Family: app.Apply, PartnerID: 1, CourseID: 100101}, in.Operation)
	t.Fatal("returned past boundary", e)
}
func TestI7C2EProcessKillReopenPaidEnrollment(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, boundary := range []struct {
		at        int32
		committed bool
	}{{1, true}, {2, false}, {2, true}} {
		a, _, _ := courseFixture(t, p)
		in := courseKillInput{Actor: a, Operation: op()}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "dorm-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if boundary.committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C2EProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2E_KILL_INPUT="+file, "GXB_I7C2E_KILL_AT="+strconv.Itoa(int(boundary.at)), "GXB_I7C2E_KILL_COMMITTED="+flag)
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
		if dormStack(t, p, a, 160600001) != want {
			t.Fatal("commit visibility", boundary)
		}
		reopened := pool(t)
		result, e := courseService(reopened, reopened).Command(ctx, a, app.Command{Family: app.Apply, PartnerID: 1, CourseID: 100101}, in.Operation)
		if e != nil || result.OperationID != in.Operation.ID || dormStack(t, reopened, a, 160600001) != 19 {
			t.Fatal("reopen", boundary, result, e)
		}
		if len(courseFacts(t, reopened, a, 1).Facts.Courses) != 1 {
			t.Fatal("duplicate book")
		}
	}
}
