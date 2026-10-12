//go:build postgres && linux

package profilemedia_test

import (
	"bytes"
	"context"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	backup "gxb.local/backend/v2/internal/adapters/profilemediabackup"
	port "gxb.local/backend/v2/internal/application/profileasset"
	asset "gxb.local/backend/v2/internal/domain/profileasset"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type holdDB struct {
	tx.Beginner
	file      string
	committed bool
}
type holdTx struct {
	tx.Tx
	file      string
	committed bool
}

func (d holdDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	tr, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return holdTx{tr, d.file, d.committed}, nil
}
func (t holdTx) Commit(c context.Context) error {
	if t.committed {
		if e := t.Tx.Commit(c); e != nil {
			return e
		}
	}
	if e := os.WriteFile(t.file, []byte("ready"), 0600); e != nil {
		return e
	}
	<-c.Done()
	return c.Err()
}

type killPayload struct {
	Actor     actorTransport
	Operation operation.Context
	Committed bool
}

func TestMediaKilledHelper(t *testing.T) {
	file := os.Getenv("GXB_I7B5B_KILL_CHILD")
	if file == "" {
		t.Skip("OSkillhelper only")
	}
	var v killPayload
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	if e = json.Unmarshal(raw, &v); e != nil {
		t.Fatal(e)
	}
	p := pool(t)
	a := decodeActor(t, v.Actor)
	b := blobs(t)
	_, e = publish(t, mediaService(p, holdDB{p, file + ".ready", v.Committed}, b), a, pngBytes(t, 81), v.Operation)
	if e != nil {
		t.Fatal(e)
	}
}
func TestMediaProcessKillBeforeAndAfterCommit(t *testing.T) {
	p := pool(t)
	installed(t, p)
	b := blobs(t)
	for _, commit := range []bool{false, true} {
		a := actor(t, p)
		o := op()
		file := filepath.Join(t.TempDir(), "kill.json")
		raw, _ := json.Marshal(killPayload{encodeActor(a), o, commit})
		if e := os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		cmd := exec.Command(os.Args[0], "-test.run=^TestMediaKilledHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7B5B_CHILD=kill", "GXB_I7B5B_KILL_CHILD="+file)
		var output bytes.Buffer
		cmd.Stdout = &output
		cmd.Stderr = &output
		if e := cmd.Start(); e != nil {
			t.Fatal(e)
		}
		defer func() { _ = cmd.Process.Kill() }()
		ready := false
		for end := time.Now().Add(10 * time.Second); time.Now().Before(end); {
			if _, e := os.Stat(file + ".ready"); e == nil {
				ready = true
				break
			}
			time.Sleep(20 * time.Millisecond)
		}
		if !ready {
			_ = cmd.Process.Kill()
			_ = cmd.Wait()
			t.Fatal("helper neverreachedcommitboundary", output.String())
		}
		if e := cmd.Process.Kill(); e != nil {
			t.Fatal(e)
		}
		_ = cmd.Wait()
		// Reopen storage in a different process instance; OS leases have ended but
		// the durable pin must still cover an unresolved database outcome.
		reopened, e := blobstore.NewLocal(os.Getenv("GXB_I7B5B_ASSET_ROOT"))
		if e != nil {
			t.Fatal(e)
		}
		s := mediaService(p, p, reopened)
		h, found, e := s.Media.ReadMediaHistoryTx(ctx, p, o.ID)
		if e != nil {
			t.Fatal(e)
		}
		if found != commit {
			t.Fatal("wrongdurableDBoutcome", found, commit)
		}
		before := countPins(t, b)
		gc, e := maintenance(s).Collect(ctx)
		if e != nil {
			t.Fatal(e)
		}
		if commit {
			if gc.ResolvedPins != 1 || countPins(t, b) != before-1 || h.RootVersion != 1 {
				t.Fatal("positivekill recovery", gc)
			}
		} else {
			if gc.ResolvedPins != 0 || countPins(t, b) != before {
				t.Fatal("receiptmiss removedpin", gc)
			}
		}
	}
}
func TestMediaMaintenanceExcludesPublication(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)
	entered := make(chan struct{})
	release := make(chan struct{})
	done := make(chan error, 1)
	go func() {
		done <- b.WithMaintenance(ctx, func(port.Maintenance) error { close(entered); <-release; return nil })
	}()
	<-entered
	c, cancel := context.WithTimeout(ctx, 100*time.Millisecond)
	defer cancel()
	_, e := b.Prepare(c, bytes.NewReader(pngBytes(t, 87)), asset.Reservation{Operation: uuid(), Actor: a.PlayerID, Server: a.LogicalServerID})
	if e == nil {
		t.Fatal("publisherenteredEXlease")
	}
	close(release)
	if e = <-done; e != nil {
		t.Fatal(e)
	}
	_ = upload(t, s, a, pngBytes(t, 87), op())
	if e = maintenance(s).Validate(ctx); e != nil {
		t.Fatal(e)
	}
}
func pgCommand(t *testing.T, name string, args ...string) {
	t.Helper()
	cmd := exec.Command(name, args...)
	out, e := cmd.CombinedOutput()
	if e != nil {
		t.Fatal(name, e, string(out))
	}
}
func TestMediaJointBackupRelocatedRestoreAndIntegrity(t *testing.T) {
	p := pool(t)
	installed(t, p)
	b := blobs(t)
	s := mediaService(p, p, b)
	a := actor(t, p)
	originalOp := op()
	saved := upload(t, s, a, pngBytes(t, 91), originalOp)
	bundle := filepath.Join(t.TempDir(), "joint")
	dsn := os.Getenv("GXB_I7B5B_DSN")
	if e := backup.Backup(ctx, maintenance(s), bundle, true, func(c context.Context, path string) error {
		cmd := exec.CommandContext(c, "pg_dump", "--format=custom", "--no-owner", "--file", path, dsn)
		out, e := cmd.CombinedOutput()
		if e != nil {
			t.Log(string(out))
		}
		return e
	}); e != nil {
		t.Fatal("jointbackup", e)
	}
	if _, e := backup.VerifyFiles(bundle); e != nil {
		t.Fatal(e)
	}
	dbname := "restored_" + strings.ReplaceAll(uuid().String(), "-", "")
	pgCommand(t, "createdb", "--maintenance-db", dsn, dbname)
	uri, e := url.Parse(dsn)
	if e != nil {
		t.Fatal(e)
	}
	uri.Path = "/" + dbname
	restoredDSN := uri.String()
	rp, e := pg.Open(ctx, restoredDSN, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer rp.Close()
	destination := filepath.Join(t.TempDir(), "relocated-assets")
	if e = backup.RestoreIntoEmpty(ctx, bundle, destination, true, func(c context.Context, path string) error {
		cmd := exec.CommandContext(c, "pg_restore", "--exit-on-error", "--no-owner", "--dbname", restoredDSN, path)
		out, e := cmd.CombinedOutput()
		if e != nil {
			t.Log(string(out))
		}
		return e
	}); e != nil {
		t.Fatal("jointrestore", e)
	}
	rb, e := blobstore.NewLocal(destination)
	if e != nil {
		t.Fatal(e)
	}
	rs := mediaService(rp, rp, rb)
	if e = backup.VerifyRestored(ctx, maintenance(rs), bundle); e != nil {
		t.Fatal("restoredtypedcoherence", e)
	}
	if got := current(t, rp, a); got.Reference != saved.History.Reference || got.RootVersion != saved.History.RootVersion {
		t.Fatal("restorelostref/URL/version")
	}
	replay, e, cleanup := rs.Publish(ctx, a, saved.History.Reference.Asset, nil, originalOp)
	if e != nil || cleanup != nil || replay != saved {
		t.Fatal("restoredknownoutcome", e)
	}
	f, e := rb.OpenValidated(ctx, saved.History.Reference.Asset)
	if e != nil {
		t.Fatal(e)
	}
	raw, e := io.ReadAll(f)
	f.Close()
	if e != nil || !bytes.Equal(raw, pngBytes(t, 91)) {
		t.Fatal("relocatedbytes")
	}
	// Replay the exact prebackup operation from restored receipt/history while
	// retaining its URL. Its operation context is recovered from the test outcome
	// separately below, and no new reference is assigned during verification.
	path := filepath.Join(destination, "blobs", saved.History.Reference.Asset.SHA256+".png")
	original, e := os.ReadFile(path)
	if e != nil {
		t.Fatal(e)
	}
	if e = os.Remove(path); e != nil {
		t.Fatal(e)
	}
	if e = maintenance(rs).Validate(ctx); e == nil {
		t.Fatal("missingreferencedbytes accepted")
	}
	if e = os.WriteFile(path, []byte("corrupt"), 0400); e != nil {
		t.Fatal(e)
	}
	if e = maintenance(rs).Validate(ctx); e == nil {
		t.Fatal("corruptreferencedbytes accepted")
	}
	if e = os.Remove(path); e != nil {
		t.Fatal(e)
	}
	if e = os.WriteFile(path, original, 0400); e != nil {
		t.Fatal(e)
	}
	if e = backup.VerifyRestored(ctx, maintenance(rs), bundle); e != nil {
		t.Fatal(e)
	}
	if e = backup.RestoreIntoEmpty(ctx, bundle, destination, true, func(context.Context, string) error { return nil }); e == nil {
		t.Fatal("overwrite existing store accepted")
	}
	if e = backup.Backup(ctx, maintenance(s), filepath.Join(t.TempDir(), "not-offline"), false, func(context.Context, string) error { return nil }); e == nil {
		t.Fatal("livehotbackup accepted")
	}
}
func TestMediaActualAPIProcess(t *testing.T) {
	binary := os.Getenv("GXB_I7B5B_API_BINARY")
	if binary == "" {
		t.Skip("final frozen exact API binary required")
	}
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	_, bearer := token(t, p, a)
	listener, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	addr := listener.Addr().String()
	listener.Close()
	origin := "http://" + addr
	targetDSN := os.Getenv("GXB_I7B5B_DSN")
	targetRoot := os.Getenv("GXB_I7B5B_ASSET_ROOT")
	start := func() *exec.Cmd {
		cmd := exec.Command(binary)
		cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+targetDSN, "GXB_HTTP_ADDR="+addr, "GXB_PUBLIC_ENGINE_URL="+origin+"/engine", "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT=19001", "GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001", "GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001", "GXB_REDEEM_DIGEST_SECRET=i7b5b-fixture-redeem-key-00001", "GXB_DERIVATION_KEY_ID=i7b2b-native", "GXB_PROFILE_MEDIA_ROOT="+targetRoot, "GXB_PROFILE_MEDIA_PUBLIC_ORIGIN="+origin)
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
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
		raw, _ := os.ReadFile(log.Name())
		t.Fatal("APIstartup", string(raw))
		return nil
	}
	cmd := start()
	stopped := false
	defer func() {
		if !stopped {
			_ = cmd.Process.Signal(os.Interrupt)
			_ = cmd.Wait()
		}
	}()
	raw := pngBytes(t, 95)
	resp, e := multipartRequest(t, origin+"/engine", bearer, raw, nil)
	if e != nil {
		t.Fatal(e)
	}
	var body map[string]any
	json.NewDecoder(resp.Body).Decode(&body)
	resp.Body.Close()
	if resp.StatusCode != 200 {
		t.Fatal("actualupload", resp.StatusCode, body)
	}
	path, ok := body["avatar_file_path"].(string)
	if !ok {
		t.Fatal("actualwire")
	}
	_ = cmd.Process.Signal(os.Interrupt)
	_ = cmd.Wait()
	stopped = true
	maintBinary := os.Getenv("GXB_I7B5B_MAINT_BINARY")
	if maintBinary != "" {
		bundle := filepath.Join(t.TempDir(), "api-joint-bundle")
		runMaint := func(dsn, root string, args ...string) {
			c := exec.Command(maintBinary, args...)
			c.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+dsn, "GXB_PROFILE_MEDIA_ROOT="+root)
			out, e := c.CombinedOutput()
			if e != nil {
				t.Fatal("actualmaintenanceCLI", e, string(out))
			}
		}
		runMaint(targetDSN, targetRoot, "-mode", "backup", "-bundle", bundle, "-offline")
		dbname := "api_restore_" + strings.ReplaceAll(uuid().String(), "-", "")
		pgCommand(t, "createdb", "--maintenance-db", targetDSN, dbname)
		uri, e := url.Parse(targetDSN)
		if e != nil {
			t.Fatal(e)
		}
		uri.Path = "/" + dbname
		targetDSN = uri.String()
		targetRoot = filepath.Join(t.TempDir(), "api-relocated-assets")
		runMaint(targetDSN, targetRoot, "-mode", "restore", "-bundle", bundle, "-offline")
		runMaint(targetDSN, targetRoot, "-mode", "verify")
		runMaint(targetDSN, targetRoot, "-mode", "gc")
	} else {
		t.Log("workingAPIrestart only; finalexactCLI jointrestore required")
	}
	cmd = start()
	stopped = false
	resp, e = http.Get(path)
	if e != nil {
		t.Fatal(e)
	}
	got, e := io.ReadAll(resp.Body)
	resp.Body.Close()
	if e != nil || resp.StatusCode != 200 || !bytes.Equal(raw, got) {
		t.Fatal("actualrestartGET", e)
	}
}
