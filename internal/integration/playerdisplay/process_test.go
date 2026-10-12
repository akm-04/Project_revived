//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func displayToken(t *testing.T, p *pg.Pool, a identity.ActorContext) string {
	raw, e := identity.DeriveGameplayBearer([]byte("i7b2b-fixture-bearer-key-00001"), identity.GameplayContext{ID: a.ContextID, ContextGeneration: a.ContextGeneration})
	if e != nil {
		t.Fatal(e)
	}
	digest, e := identity.DigestGameplayBearer([]byte("i7b2b-fixture-digest-key-00001"), raw)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO gameplay_context_credentials(credential_id,context_id,session_id,digest,credential_generation,derivation_key_id,issued_at)VALUES($1,$2,$3,$4,1,'i7b2b-native',clock_timestamp())`, uuid().String(), a.ContextID.UUID().String(), a.SessionID.UUID().String(), digest[:])
	return raw
}
func TestDisplayMID1OwnerReloadProjection(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	exec(t, p, `INSERT INTO player_story_cursors(player_id,updated_at)VALUES($1,clock_timestamp())`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_guide_return_state(player_id,updated_at)VALUES($1,clock_timestamp())`, int64(a.PlayerID))
	if _, e := s.Execute(ctx, a, app.Command{Kind: "avatar", ID: 110001002, Icon: 10002004, Category: 1}, op()); e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	projection := i5store.BootstrapProjection{Display: s, Content: contentstore.Store{}, Privileges: i5.BaselinePrivilegeProvider{}, MaxHeroColor: i5.PreservationMaxHeroColorProvider{}}
	detail := map[string]any{"17": map[string]any{}}
	if e = projection.OverlayMID1(ctx, tr, a, false, time.Now().UTC(), detail); e != nil {
		t.Fatal(e)
	}
	mid := detail["17"].(map[string]any)
	if mid["avatar_id"] != int64(10002004) || mid["exp"] != int64(37) || mid["title_info"] == nil || mid["bubble_info"] == nil {
		t.Fatal(mid)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}

// Real PostgreSQL snapshot/relocation, exact API subprocess, and restart. This
// qualifies display database recovery; unchanged media blobs use inherited5B proof.
func TestDisplayActualAPIAndRelocatedDatabaseRestore(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact candidate process binary required")
	}
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	bearer := displayToken(t, p, a)
	s := service(p, p)
	original := op()
	purchase := app.Command{Kind: "purchase", ID: 110005001}
	if _, e := s.Execute(ctx, a, purchase, original); e != nil {
		t.Fatal(e)
	}
	// Preserve recipient and unresolved admission as independent durable state.
	b := actor(t, p)
	broken := service(p, p)
	broken.Receipts = failReceipt{broken.Receipts}
	if _, e := broken.Execute(ctx, b, purchase, op()); e == nil {
		t.Fatal("pending fixture failure expected")
	}
	listener, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	addr := listener.Addr().String()
	listener.Close()
	origin := "http://" + addr
	targetDSN := os.Getenv("GXB_I7B6A_DSN")
	assets := t.TempDir()
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
			cmd.Process.Signal(os.Interrupt)
			cmd.Wait()
		}
	}()
	for _, test := range []struct {
		mid    int
		fields map[string]any
		status int
	}{{119, map[string]any{}, 200}, {656, map[string]any{"id": 120001007}, 200}, {23, map[string]any{"player_name": "ProcessName"}, 200}, {98, map[string]any{"table_id": 110001002, "avatar_id": 10002004, "avatar_type": 1}, 200}, {100, map[string]any{"avatar_frame_id": 120001001}, 200}, {2492, map[string]any{"title_id": 0, "unique_id": 0}, 200}, {2494, map[string]any{"bubble_id": 10001}, 200}, {2490, map[string]any{}, 503}, {2493, map[string]any{}, 503}, {98, map[string]any{"table_id": 110001002, "avatar_id": 110001002, "avatar_type": 1}, 400}, {23, map[string]any{"player_name": "Forged", "player_id": int64(a.PlayerID)}, 400}} {
		code, out := post(test.mid, test.fields)
		if code != test.status {
			t.Fatal("source MID", test.mid, code, out)
		}
	}
	// Receipt remained bound to original operation despite later HTTP assignments.
	if _, e = s.Execute(ctx, a, purchase, original); e != nil {
		t.Fatal(e)
	}
	cmd.Process.Signal(os.Interrupt)
	cmd.Wait()
	running = false
	dump := filepath.Join(t.TempDir(), "display.dump")
	tool := func(name string, args ...string) {
		out, e := osexec.Command(name, args...).CombinedOutput()
		if e != nil {
			t.Fatal(name, e, string(out))
		}
	}
	tool("pg_dump", "--format=custom", "--file", dump, targetDSN)
	u, e := url.Parse(targetDSN)
	if e != nil {
		t.Fatal(e)
	}
	newDB := "display_restore_" + strings.ReplaceAll(uuid().String(), "-", "")
	tool("createdb", "--maintenance-db", targetDSN, newDB)
	u.Path = "/" + newDB
	targetDSN = u.String()
	tool("pg_restore", "--no-owner", "--dbname", targetDSN, dump)
	restored, e := pg.Open(ctx, targetDSN, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer restored.Close()
	recovered := service(restored, restored)
	if _, e = recovered.Execute(ctx, a, purchase, original); e != nil {
		t.Fatal("restored positive receipt", e)
	}
	if state(t, restored, a).Selection.AvatarTableID != 110001002 {
		t.Fatal("lost selection")
	}
	var amount, pending int64
	if e = restored.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount); e != nil || amount != 324 {
		t.Fatal(amount, e)
	}
	if e = restored.QueryRow(ctx, `SELECT count(*) FROM player_display_admissions WHERE player_id=$1 AND state='PENDING'`, int64(b.PlayerID)).Scan(&pending); e != nil || pending != 1 {
		t.Fatal(pending, e)
	}
	if _, e = recovered.Execute(ctx, b, purchase, op()); e != app.ErrUnresolved {
		t.Fatal("restored guarded cancel", e)
	}
	cmd = start()
	running = true
	code, out := post(119, map[string]any{})
	if code != 200 || len(out["player_name_list"].([]any)) != 12 {
		t.Fatal("relocated API", code, out)
	}
	t.Log(fmt.Sprintf("EXACT_API source routes/restart; PostgreSQL dump/relocated restore receipts, selections, pending admissions; restored amount=%d", amount))
}

type killDisplayDB struct {
	tx.Beginner
	n         int
	file      string
	committed bool
}
type killDisplayTx struct {
	tx.Tx
	file      string
	committed bool
}

func (d *killDisplayDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	tr, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	d.n++
	if d.n == 3 {
		return killDisplayTx{tr, d.file, d.committed}, nil
	}
	return tr, nil
}
func (t killDisplayTx) Commit(c context.Context) error {
	if t.committed {
		if e := t.Tx.Commit(c); e != nil {
			return e
		}
	}
	if e := os.WriteFile(t.file, []byte("semantic-commit-boundary"), 0600); e != nil {
		return e
	}
	select {}
}
func TestDisplayKillHelper(t *testing.T) {
	file := os.Getenv("GXB_I7B6A_KILL_INPUT")
	if file == "" {
		t.Skip("process helper")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in app.Result
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	p := pool(t)
	s := service(p, &killDisplayDB{Beginner: p, file: file + ".ready", committed: os.Getenv("GXB_I7B6A_KILL_COMMITTED") == "1"})
	if _, e = s.Execute(ctx, in.Actor, in.Command, in.Operation); e != nil {
		t.Fatal(e)
	}
	t.Fatal("helper returned past kill boundary")
}
func TestDisplayProcessKillValueCommitBoundaries(t *testing.T) {
	p := pool(t)
	installed(t, p)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, committed := range []bool{false, true} {
		a := actor(t, p)
		s := service(p, p)
		if _, e = s.Execute(ctx, a, app.Command{Kind: "rename", Name: "Initial"}, op()); e != nil {
			t.Fatal(e)
		}
		in := app.Result{Actor: a, Command: app.Command{Kind: "rename", Name: "AfterKill"}, Operation: op()}
		raw, e := json.Marshal(in)
		if e != nil {
			t.Fatal(e)
		}
		file := filepath.Join(t.TempDir(), "kill-input.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		cmd := osexec.Command(exe, "-test.run=^TestDisplayKillHelper$", "-test.v")
		flag := "0"
		if committed {
			flag = "1"
		}
		cmd.Env = append(os.Environ(), "GXB_I7B6A_KILL_INPUT="+file, "GXB_I7B6A_KILL_COMMITTED="+flag)
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
			t.Fatal("child boundary", log.String())
		}
		if committed {
			if _, e = s.Execute(ctx, a, in.Command, in.Operation); e != nil {
				t.Fatal("committed kill receipt", e)
			}
		} else {
			if _, e = s.Execute(ctx, a, in.Command, op()); e != app.ErrUnresolved {
				t.Fatal("uncommitted kill guarded cancel", e)
			}
			if _, e = s.Execute(ctx, a, in.Command, op()); e != nil {
				t.Fatal("fresh after canceled killed body", e)
			}
		}
		var amount int64
		if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount); e != nil || amount != 900 {
			t.Fatal("kill exactly once debit", amount, e)
		}
	}
}
