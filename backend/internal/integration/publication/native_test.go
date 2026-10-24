//go:build postgres

package publication_test

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/publicationstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/publication"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	proj "gxb.local/backend/v2/internal/projection/publication"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

type sqlTime struct {
	p  tx.Queryer
	at time.Time
}

func (s sqlTime) Now(c context.Context) (time.Time, error) {
	var t time.Time
	e := s.p.QueryRow(c, "SELECT $1::timestamptz", s.at).Scan(&t)
	return t, e
}
func op(t *testing.T) operation.Context {
	t.Helper()
	o, e := (operation.Factory{Clock: clock.System{}}).New(policy.Set{})
	if e != nil {
		t.Fatal(e)
	}
	return o
}
func uid() ids.UUID {
	u, e := ids.NewUUID()
	if e != nil {
		panic(e)
	}
	return u
}
func actor(t *testing.T, p *postgres.Pool) identity.ActorContext {
	t.Helper()
	c := context.Background()
	a, s, g := uid(), uid(), uid()
	var id int64
	tr, e := p.Begin(c, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(c)
	e = tr.QueryRow(c, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&id)
	if e != nil {
		t.Fatal(e)
	}
	for _, q := range []struct {
		s string
		a []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{a.String(), a.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'native9')`, []any{id, a.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'native9',clock_timestamp(),clock_timestamp())`, []any{s.String(), a.String()}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,1,$4,1,clock_timestamp())`, []any{g.String(), s.String(), a.String(), id}},
	} {
		if _, e = tr.Exec(c, q.s, q.a...); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(c); e != nil {
		t.Fatal(e)
	}
	aid, _ := identity.AccountIDFrom(a)
	sid, _ := identity.SessionIDFrom(s)
	cid, _ := identity.ContextIDFrom(g)
	return identity.ActorContext{AccountID: aid, AccountUID: identity.AccountUID(a.String()), SessionID: sid, ContextID: cid, LogicalServerID: 1, PlayerID: identity.PlayerID(id), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func service(p *postgres.Pool, at time.Time) app.Service {
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: sqlTime{p, at}}, Runner: tx.Runner{DB: p}}, Store: publicationstore.Store{}, PlayerRoots: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Evidence: p}
}
func picture(at time.Time) pub.Set {
	return pub.Set{ID: uid(), Family: pub.Picture, ServerID: 1, StartsAt: at, Items: []pub.Item{{Picture: &pub.PictureItem{Weight: 2}}, {Picture: &pub.PictureItem{Weight: 1}}}}
}
func install(t *testing.T, s app.Service, x ...pub.Set) {
	t.Helper()
	if e := s.Install(context.Background(), op(t), pub.Catalog{Sets: x}); e != nil {
		t.Fatal(e)
	}
}
func read(t *testing.T, s app.Service, a identity.ActorContext) app.View {
	t.Helper()
	v, e := s.Read(context.Background(), op(t), pub.Picture, a.LogicalServerID, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	return v
}
func marker(t *testing.T, p *postgres.Pool, a identity.ActorContext, id ids.UUID) bool {
	t.Helper()
	v, e := (publicationstore.Store{}).MarkerTx(context.Background(), p, a.PlayerID, id)
	if e != nil {
		t.Fatal(e)
	}
	return v
}

type hookStore struct {
	app.Store
	selected func()
	mark     func(context.Context, tx.Tx) error
	selects  atomic.Int32
}

func (h *hookStore) SelectTx(c context.Context, q tx.Queryer, f string, s identity.LogicalServerID, at time.Time) (pub.Set, bool, error) {
	v, ok, e := h.Store.SelectTx(c, q, f, s, at)
	h.selects.Add(1)
	if h.selected != nil {
		h.selected()
	}
	return v, ok, e
}
func (h *hookStore) MarkTx(c context.Context, t tx.Tx, p identity.PlayerID, s ids.UUID, at time.Time) error {
	if h.mark != nil {
		if e := h.mark(c, t); e != nil {
			return e
		}
	}
	return h.Store.MarkTx(c, t, p, s, at)
}

type faultDB struct {
	tx.Beginner
	after  bool
	begins atomic.Int32
}
type faultTx struct {
	tx.Tx
	after bool
}

func (d *faultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	d.begins.Add(1)
	t, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return faultTx{t, d.after}, nil
}
func (t faultTx) Commit(c context.Context) error {
	if t.after {
		if e := t.Tx.Commit(c); e != nil {
			return e
		}
	}
	return errors.New("injected lost COMMIT reply")
}
func TestPublicationNative(t *testing.T) {
	dsn := os.Getenv("GXB_I7A9_DSN")
	if dsn == "" {
		t.Skip("native9 requires explicit disposable database")
	}
	c := context.Background()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 16, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	if e = (publicationstore.Store{}).CheckSchema(c, p); e != nil {
		t.Fatal(e)
	}
	a, b := actor(t, p), actor(t, p)
	var nativeTime time.Time
	nativeTime, e = (postgres.AuthoritativeTime{Queryer: p}).Now(c)
	if e != nil || nativeTime.IsZero() {
		t.Fatal(nativeTime, e)
	}
	at := nativeTime.Add(time.Hour).Truncate(time.Microsecond)
	t.Run("schedule_expiry_no_resurrection_scope", func(t *testing.T) {
		A := picture(at)
		A.ServerID = 0
		endA := at.Add(time.Hour)
		A.EndsAt = &endA
		B := picture(at.Add(10 * time.Second))
		B.ServerID = 0
		endB := at.Add(20 * time.Second)
		B.EndsAt = &endB
		install(t, service(p, at), A, B)
		for _, x := range []struct {
			delta   time.Duration
			id      ids.UUID
			visible bool
		}{{-time.Microsecond, ids.UUID{}, false}, {0, A.ID, true}, {10 * time.Second, B.ID, true}, {20 * time.Second, B.ID, false}, {21 * time.Second, B.ID, false}} {
			v := read(t, service(p, at.Add(x.delta)), a)
			if v.Visible != x.visible || (!v.Set.ID.IsZero() && v.Set.ID != x.id) {
				t.Fatalf("boundary %v: %+v", x.delta, v)
			}
		}
		S := picture(at.Add(12 * time.Second))
		S.ServerID = 1
		endS := at.Add(15 * time.Second)
		S.EndsAt = &endS
		install(t, service(p, at), S)
		v := read(t, service(p, at.Add(16*time.Second)), a)
		if v.Visible || v.Set.ID != S.ID {
			t.Fatal("expired server scope incorrectly falls back", v)
		}
	})
	at = at.Add(2 * time.Hour)
	t.Run("idempotent_import_wire_marker_isolation", func(t *testing.T) {
		s := service(p, at)
		A := picture(at)
		ann := pub.Set{ID: uid(), Family: pub.Announcement, StartsAt: at, Items: []pub.Item{{Announcement: &pub.Section{Title: "source", Contents: []string{"line"}}}}}
		board := pub.Set{ID: uid(), Family: pub.Board, StartsAt: at, Items: []pub.Item{{Board: &pub.BoardItem{ID: 900001, Title: "board", StartDate: "2026-10-10", Content: "one|two"}}}}
		install(t, s, A, ann, board)
		install(t, s, A)
		changed := A
		changed.Items = []pub.Item{{Picture: &pub.PictureItem{Weight: 3}}}
		if e = s.Install(c, op(t), pub.Catalog{Sets: []pub.Set{changed}}); !errors.Is(e, pub.ErrRevisionConflict) {
			t.Fatal("UUID overwrite", e)
		}
		var wg sync.WaitGroup
		errch := make(chan error, 8)
		for range 8 {
			wg.Add(1)
			go func() { defer wg.Done(); errch <- s.Mark(c, op(t), a) }()
		}
		wg.Wait()
		close(errch)
		for e := range errch {
			if e != nil {
				t.Fatal(e)
			}
		}
		v := read(t, s, a)
		if !v.Visible || !v.HasRead || len(proj.Picture(v)["contents"].([]pub.PictureItem)) != 2 {
			t.Fatal("manual contents lost", v)
		}
		if read(t, s, b).HasRead {
			t.Fatal("other player read leaked")
		}
		var count int
		if e = p.QueryRow(c, "SELECT count(*) FROM publication_picture_reads WHERE player_id=$1 AND set_id=$2", int64(a.PlayerID), A.ID.String()).Scan(&count); e != nil || count != 1 {
			t.Fatal(count, e)
		}
		av, e := s.Read(c, op(t), pub.Announcement, 0, 0)
		if e != nil {
			t.Fatal(e)
		}
		m, e := proj.Announcement(av)
		if e != nil {
			t.Fatal(e)
		}
		var decoded map[string][]pub.Section
		if e = json.Unmarshal([]byte(m["contents"].(string)), &decoded); e != nil || len(decoded["contents"]) != 1 {
			t.Fatal(m, e)
		}
		bv, e := s.Read(c, op(t), pub.Board, 1, a.PlayerID)
		if e != nil {
			t.Fatal(e)
		}
		bm, e := proj.Board(bv)
		if e != nil {
			t.Fatal(e)
		}
		row := bm["contents"].([]map[string]any)[0]
		if row["notice_id"] != row["table_id"] {
			t.Fatal(row)
		}
		var detail map[string]any
		if e = json.Unmarshal([]byte(row["content"].(string)), &detail); e != nil || detail["content"] != "one|two" {
			t.Fatal(row, e)
		}
	})
	at = at.Add(2 * time.Hour)
	t.Run("replacement_overlaps_bound_read", func(t *testing.T) {
		s := service(p, at)
		A := picture(at)
		B := picture(at)
		install(t, s, A)
		selected, release := make(chan struct{}), make(chan struct{})
		var once sync.Once
		h := &hookStore{Store: s.Store, selected: func() { once.Do(func() { close(selected); <-release }) }}
		s.Store = h
		done := make(chan error, 1)
		go func() { done <- s.Mark(c, op(t), a) }()
		<-selected
		install(t, service(p, at), B)
		close(release)
		if e = <-done; e != nil {
			t.Fatal(e)
		}
		if !marker(t, p, a, A.ID) || marker(t, p, a, B.ID) || read(t, service(p, at), a).HasRead {
			t.Fatal("mixed replacement marker")
		}
		if e = service(p, at).Mark(c, op(t), a); e != nil {
			t.Fatal(e)
		}
		if !marker(t, p, a, B.ID) {
			t.Fatal("new request did not mark current B")
		}
	})
	at = at.Add(2 * time.Hour)
	t.Run("definite_abort_pins_identity_and_time", func(t *testing.T) {
		s := service(p, at)
		A := picture(at)
		B := picture(at)
		install(t, s, A)
		var calls atomic.Int32
		h := &hookStore{Store: s.Store}
		h.mark = func(c context.Context, tr tx.Tx) error {
			if calls.Add(1) == 1 {
				installWithoutTest := service(p, at)
				if e := installWithoutTest.Install(c, op(t), pub.Catalog{Sets: []pub.Set{B}}); e != nil {
					return e
				}
				_, e := tr.Exec(c, `DO $$ BEGIN RAISE EXCEPTION 'abort' USING ERRCODE='40001'; END $$`)
				return e
			}
			return nil
		}
		s.Store = h
		if e = s.Mark(c, op(t), a); e != nil {
			t.Fatal(e)
		}
		if h.selects.Load() != 1 || calls.Load() != 2 || !marker(t, p, a, A.ID) || marker(t, p, a, B.ID) {
			t.Fatal("retry retargeted", h.selects.Load(), calls.Load())
		}
		var markedAt time.Time
		if e = p.QueryRow(c, "SELECT read_at FROM publication_picture_reads WHERE player_id=$1 AND set_id=$2", int64(a.PlayerID), A.ID.String()).Scan(&markedAt); e != nil || !markedAt.Equal(at) {
			t.Fatal("time drift", markedAt, e)
		}
	})
	at = at.Add(2 * time.Hour)
	t.Run("lost_commit_present_absent_never_blind_replay", func(t *testing.T) {
		for _, after := range []bool{true, false} {
			s := service(p, at)
			A := picture(at)
			install(t, s, A)
			db := &faultDB{Beginner: p, after: after}
			s.Timed.Runner.DB = db
			e := s.Mark(c, op(t), b)
			if after && e != nil {
				t.Fatal(e)
			}
			if !after && e == nil {
				t.Fatal("uncommitted unknown claimed success")
			}
			if db.begins.Load() != 1 || marker(t, p, b, A.ID) != after {
				t.Fatal("blind replay or false reconciliation", db.begins.Load(), after)
			}
			at = at.Add(time.Second)
		}
	})
}

// Explicit process fixture preparation; never counted as a product gate.
func TestPreparePublicationProcess(t *testing.T) {
	dsn := os.Getenv("GXB_I7A9_DSN")
	if dsn == "" || os.Getenv("GXB_I7A9_PREPARE_PROCESS") != "1" {
		t.Skip("explicit process fixture preparation only")
	}
	c := context.Background()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	r := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, e = r.EnsureBuiltinInstalled(c, op(t), bundle); e != nil {
		t.Fatal(e)
	}
	if _, e = r.BootstrapActivationIfMissing(c, op(t), bundle); e != nil {
		t.Fatal(e)
	}
}
