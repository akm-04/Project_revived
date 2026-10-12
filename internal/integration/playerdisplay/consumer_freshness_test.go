//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/generaldmstore"
	"gxb.local/backend/v2/internal/adapters/publicpresentation"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	dm "gxb.local/backend/v2/internal/application/generaldm"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func Test6CCanonicalFreshnessAndMissedNameCandidate(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	name := fmt.Sprintf("Fresh%d", a.PlayerID)
	if _, e := s.Execute(ctx, a, app.Command{Kind: "rename", Name: name}, op()); e != nil {
		t.Fatal(e)
	}
	// A dropped/corrupt projection must not lose the new canonical search candidate.
	exec(t, p, `UPDATE player_directory_profiles SET name='stale6C',lev=2,avatar_id=99,conquer_lev=11 WHERE player_id=$1`, int64(a.PlayerID))
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	rows, e := (publicpresentation.DiscoveryReader{}).ProfilesByExactNameTx(ctx, tr, name, 10)
	if e != nil || len(rows) != 1 || rows[0].PlayerID != a.PlayerID || rows[0].Name != name {
		t.Fatal(rows, e)
	}
	rows, e = (publicpresentation.DiscoveryReader{}).ProfilesByExactNameTx(ctx, tr, "stale6C", 10)
	if e != nil || len(rows) != 0 {
		t.Fatal("stale name still selects canonical player", rows, e)
	}
	r := socialpresentation.TransactionReader{}
	empty, e := r.ReadManyTx(ctx, tr, nil)
	if e != nil || !empty.ObservedAt.IsZero() || len(empty.Players) != 0 {
		t.Fatal("empty legacy batch", empty, e)
	}
	b, e := r.ReadManyTx(ctx, tr, []identity.PlayerID{a.PlayerID})
	if e != nil {
		t.Fatal(e)
	}
	m := b.Players[a.PlayerID].Minimal
	if m.Name != name || m.Level != 1 || m.AvatarID != 110001001 || m.ConquerLevel != 11 || m.TitleInfo != "@@@@" || m.BubbleInfo != "10001@0" {
		t.Fatal(m)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_profiles SET display_name=$2,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID), name+"N")
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	b, e = r.ReadManyTx(ctx, tr, []identity.PlayerID{a.PlayerID})
	if e != nil || b.Players[a.PlayerID].Minimal.Name != name+"N" {
		t.Fatal("canonical fallback after no hint", b, e)
	}
}

func Test6CTimedConsumerWithUnchangedVersionAndUnavailableOrigin(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	at := time.Now().UTC()
	origin := app.Origin{PlayerID: a.PlayerID, Key: "6C-component-origin", Owner: "test-double-not-qualified-upstream", Family: "bubble", CatalogID: 10002, Revision: rev, StateVersion: 1, EndTime: at.Unix() + 100}
	s.External = originProvider{o: origin}
	if _, e := s.Execute(ctx, a, app.Command{Kind: "bubble", ID: 10002}, op()); e != nil {
		t.Fatal(e)
	}
	before := state(t, p, a).Basis.Profile.StateVersion
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	reader := socialpresentation.TransactionReader{Display: s}
	for _, sec := range []int64{origin.EndTime - 1, origin.EndTime} {
		b, e := reader.ReadManyAtTx(ctx, tr, []identity.PlayerID{a.PlayerID}, time.Unix(sec, 0).UTC())
		if e != nil {
			t.Fatal(e)
		}
		want := "10001@0"
		if sec < origin.EndTime {
			want = fmt.Sprintf("10002@%d", origin.EndTime)
		}
		if b.Players[a.PlayerID].Minimal.BubbleInfo != want {
			t.Fatal(b, want)
		}
	}
	if _, e = (socialpresentation.TransactionReader{}).ReadManyAtTx(ctx, tr, []identity.PlayerID{a.PlayerID}, at); e == nil {
		t.Fatal("unqualified actual origin replaced by successful default")
	}
	if state(t, p, a).Basis.Profile.StateVersion != before {
		t.Fatal("expiry observation mutated ownership/version")
	}
	t.Log("Component double proves consumer time propagation only; actual external grant origin remains unqualified")
}

func Test6CImmutableLegacyAndFutureDMPayloadNativeReload(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a, b := actor(t, p), actor(t, p)
	at := time.Now().UTC().Truncate(time.Microsecond)
	legacy := dm.Intent{ID: uuid().String(), Sender: int64(a.PlayerID), Recipient: int64(b.PlayerID), Message: "historic6C", SenderName: "Legacy", SenderAvatarID: 110001001, SenderLevel: 1, AcceptedAt: at, ExpiresAt: at.Add(dm.IntentLifetime), Bindings: []dm.Binding{{ContextID: b.ContextID.UUID().String(), ContextGeneration: 1, SessionID: b.SessionID.UUID().String(), SessionLiveness: 1, ContextLiveness: 1, RealtimeInstanceID: uuid().String(), ConnectionGeneration: 1, OwnerFence: 1, LogicalServerID: 1}}, Status: dm.Pending, StateVersion: 1, LastObservedAt: at}
	legacy.Digest = dm.Digest(legacy.Sender, legacy.Recipient, legacy.Message)
	store := generaldmstore.Store{}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = store.InsertTx(ctx, tr, legacy); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	raw, _ := json.Marshal(legacy)
	var digest string
	if e = p.QueryRow(ctx, `SELECT payload_binding_digest FROM personal_dm_intents WHERE operation_id=$1::uuid`, legacy.ID).Scan(&digest); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_profiles SET display_name='new6C',avatar_id=10002004,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
	old, ok, e := store.Find(ctx, p, legacy.ID)
	again, _ := json.Marshal(old)
	if e != nil || !ok || !bytes.Equal(raw, again) {
		t.Fatal("historic payload reprojected/digest changed", old, e)
	}
	future := legacy
	future.ID = uuid().String()
	future.SenderName = "new6C"
	future.SenderAvatarID = 10002004
	future.SenderTitleInfo = "1001@0@0"
	future.SenderBubbleInfo = "10002@1700000010"
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = store.InsertTx(ctx, tr, future); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	next, ok, e := store.Find(ctx, p, future.ID)
	if e != nil || !ok || next.SenderTitleInfo != future.SenderTitleInfo || next.SenderBubbleInfo != future.SenderBubbleInfo {
		t.Fatal(next, e)
	}
	var after string
	if e = p.QueryRow(ctx, `SELECT payload_binding_digest FROM personal_dm_intents WHERE operation_id=$1::uuid`, legacy.ID).Scan(&after); e != nil || after != digest {
		t.Fatal("historic digest rewritten", digest, after, e)
	}
	// Restore the actual persisted old/new snapshot encodings in another owned
	// database. This is transport-payload recovery, not a media or migration gate.
	base, e := url.Parse(os.Getenv("GXB_I7B6A_DSN"))
	if e != nil {
		t.Fatal(e)
	}
	name := "i7b6c_payload_" + strings.ReplaceAll(uuid().String(), "-", "")
	target := *base
	target.Path = "/" + name
	run := func(cmd string, args ...string) {
		t.Helper()
		out, e := osexec.Command(cmd, args...).CombinedOutput()
		if e != nil {
			t.Fatalf("%s: %v %s", cmd, e, out)
		}
	}
	run("psql", base.String(), "-v", "ON_ERROR_STOP=1", "-c", "CREATE DATABASE "+name)
	t.Cleanup(func() {
		osexec.Command("psql", base.String(), "-v", "ON_ERROR_STOP=1", "-c", "DROP DATABASE "+name+" WITH (FORCE)").Run()
	})
	dump := filepath.Join(t.TempDir(), "payload.dump")
	run("pg_dump", "--format=custom", "--file", dump, base.String())
	run("pg_restore", "--no-owner", "--no-privileges", "--dbname", target.String(), dump)
	restored, e := pg.Open(context.Background(), target.String(), pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer restored.Close()
	for _, want := range []dm.Intent{legacy, future} {
		got, ok, e := store.Find(ctx, restored, want.ID)
		if e != nil || !ok || got.SenderName != want.SenderName || got.SenderTitleInfo != want.SenderTitleInfo || got.SenderBubbleInfo != want.SenderBubbleInfo || got.ExpiresAt != want.ExpiresAt || len(got.Bindings) != len(want.Bindings) {
			t.Fatal("restored snapshot changed", got, e)
		}
	}
	if e = restored.QueryRow(ctx, `SELECT payload_binding_digest FROM personal_dm_intents WHERE operation_id=$1::uuid`, legacy.ID).Scan(&after); e != nil || after != digest {
		t.Fatal("restore rewrote historic binding digest", after, e)
	}
	t.Log("Actual PG payload compatibility/persistence; direct owner fixture does not prove online delivery or origin semantics")
}
