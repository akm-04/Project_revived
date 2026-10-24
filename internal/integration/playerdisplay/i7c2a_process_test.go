//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/foundation/tx"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"testing"
	"time"
)

type skillKillInput = display.Result

type skillKillDB struct {
	tx.Beginner
	file      string
	committed bool
}

func (d skillKillDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	tr, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return killDisplayTx{Tx: tr, file: d.file, committed: d.committed}, nil
}
func TestI7C2AProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2A_KILL_INPUT")
	if file == "" {
		t.Skip("child process only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in skillKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	p := pool(t)
	s := skillService(p, skillKillDB{Beginner: p, file: file + ".ready", committed: os.Getenv("GXB_I7C2A_KILL_COMMITTED") == "1"})
	if _, e = s.ChangeSkill(ctx, in.Actor, 1, 5, 50000005, in.Operation); e != nil {
		t.Fatal(e)
	}
	t.Fatal("returned past boundary")
}
func TestI7C2AProcessKillReopenRecovery(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, committed := range []bool{false, true} {
		a := actor(t, p)
		skillHero(t, p, a, rev, 11001144, 1)
		skillBook(t, p, a, 50000005)
		in := skillKillInput{Actor: a, Operation: op()}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "skill-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C2AProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2A_KILL_INPUT="+file, "GXB_I7C2A_KILL_COMMITTED="+flag)
		var log bytes.Buffer
		cmd.Stdout = &log
		cmd.Stderr = &log
		if e = cmd.Start(); e != nil {
			t.Fatal(e)
		}
		ready := false
		for end := time.Now().Add(time.Second * 10); time.Now().Before(end); {
			if _, e = os.Stat(file + ".ready"); e == nil {
				ready = true
				break
			}
			time.Sleep(time.Millisecond * 20)
		}
		cmd.Process.Kill()
		cmd.Wait()
		if !ready {
			t.Fatal("child boundary", log.String())
		}
		before := skillRead(t, p, a, 1)
		want := int64(1)
		if committed {
			want = 2
		}
		if before.StateVersion != want {
			t.Fatal("commit/abort reload", before)
		}
		// Reopened service must recover exact original outcome or safely execute the
		// definitely rolled-back original request, with one owner change in total.
		reopened := pool(t)
		r, e := skillService(reopened, reopened).ChangeSkill(ctx, a, 1, 5, 50000005, in.Operation)
		if e != nil || r.StateVersion != 2 || r.SkillIDs[4] != 60010144 {
			t.Fatal("reopen", r, e)
		}
		if h := skillRead(t, reopened, a, 1); h.StateVersion != 2 {
			t.Fatal(h)
		}
	}
}

func TestI7C2AActualAPIChoiceAndRestartRoster(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact API binary required")
	}
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 11001144, 1)
	skillBook(t, p, a, 50000005)
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
	code, out := post(2144, map[string]any{"partner_id": 1, "skill_index": 5, "skill_item": 50000005})
	if code != 200 || out["skill_ids"].([]any)[4] != float64(60010144) {
		t.Fatal("source MID2144", code, out)
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
	if h := skillRead(t, p, a, 1); h.RawSkills.ChoiceIDs[4] != 60010144 || h.StateVersion != 2 {
		t.Fatal("restart owner", h)
	}
}
