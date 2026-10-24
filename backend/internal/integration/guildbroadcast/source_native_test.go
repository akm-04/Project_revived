//go:build postgres && river

package guildbroadcast_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildbroadcaststore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/guild"
	gb "gxb.local/backend/v2/internal/domain/guildbroadcast"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"sync"
	"testing"
	"time"
)

type countedDBTime struct {
	Inner    gen.TimeAuthority
	Calls    int
	Override *time.Time
}

func (v *countedDBTime) Now(c context.Context) (time.Time, error) {
	v.Calls++
	if v.Override != nil {
		return *v.Override, nil
	}
	return v.Inner.Now(c)
}

type captureSourceStore struct {
	guildbroadcaststore.Store
	Captured gb.Source
	mu       sync.Mutex
}

func (v *captureSourceStore) InsertSourceTx(c context.Context, t tx.Tx, s gb.Source, r ids.UUID) error {
	v.mu.Lock()
	v.Captured = s
	v.mu.Unlock()
	return v.Store.InsertSourceTx(c, t, s, r)
}

type failSecondQueue struct {
	Q     obligation.Queue
	Calls int
}

func (v *failSecondQueue) InsertTx(c context.Context, t tx.Tx, o obligation.Obligation) error {
	v.Calls++
	if v.Calls == 2 {
		return errors.New("injected second recipient enqueue failure")
	}
	return v.Q.InsertTx(c, t, o)
}
func TestRealGuildBroadcastSourceTransaction(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8_WORKING_DSN")
	if dsn == "" {
		t.Skip("explicit disposable migrated PostgreSQL/River DSN required")
	}
	c, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	factory := operation.Factory{Clock: clock.System{}}
	op, e := factory.New(policy.Set{})
	if e != nil {
		t.Fatal(e)
	}
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	registryService := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if _, e = registryService.EnsureBuiltinInstalled(c, op, bundle); e != nil {
		t.Fatal(e)
	}
	pol, e := (contentstore.Store{}).ReadBroadcastPolicy(c, p, bundle.RevisionID())
	if e != nil {
		t.Fatal(e)
	}
	at, e := (postgres.AuthoritativeTime{Queryer: p}).Now(c)
	if e != nil {
		t.Fatal(e)
	}
	at = at.Add(-time.Second)
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	var first int64
	if e = x.QueryRow(c, `UPDATE logical_servers SET next_player_id=next_player_id+2,state_version=state_version+1 WHERE logical_server_id=1 AND next_player_id+2<=max_player_id RETURNING next_player_id-2`).Scan(&first); e != nil {
		t.Fatal(e)
	}
	var aid ids.UUID
	pids := []identity.PlayerID{identity.PlayerID(first), identity.PlayerID(first + 1)}
	for i, pid := range pids {
		id, _ := ids.NewUUID()
		if i == 0 {
			aid = id
		}
		if _, e = x.Exec(c, `INSERT INTO accounts(account_id,status,created_at,account_uid) VALUES($1::uuid,'ACTIVE',$2,$3)`, id.String(), at, id.String()); e != nil {
			t.Fatal(e)
		}
		if _, e = x.Exec(c, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,1,$3,'guild-source-fixture')`, int64(pid), id.String(), at); e != nil {
			t.Fatal(e)
		}
		if _, e = x.Exec(c, `INSERT INTO player_directory_profiles(player_id,name,created_at,updated_at) VALUES($1,'saved canonical name',$2,$2)`, int64(pid), at); e != nil {
			t.Fatal(e)
		}
	}
	session, _ := ids.NewUUID()
	ctxID, _ := ids.NewUUID()
	if _, e = x.Exec(c, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1::uuid,$2::uuid,'native-guild-source',$3,$3)`, session.String(), aid.String(), at); e != nil {
		t.Fatal(e)
	}
	if _, e = x.Exec(c, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at) VALUES($1::uuid,$2::uuid,$3::uuid,1,$4,1,$5)`, ctxID.String(), session.String(), aid.String(), int64(pids[0]), at); e != nil {
		t.Fatal(e)
	}
	gdb := guildstore.Store{Queryer: p}
	serial, ver, e := gdb.LockAllocatorTx(c, x, 1, at)
	if e != nil {
		t.Fatal(e)
	}
	gid := guild.ID(1000000 + serial)
	g := guild.Guild{ID: gid, LogicalServerID: 1, Name: fmt.Sprintf("g%d", gid), Icon: 1, ApplyType: guild.ApplyByApplication, MinAllowLevel: 1, PolicyRevision: pol.GuildCoreRevision, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	if e = gdb.InsertGuildTx(c, x, g); e != nil {
		t.Fatal(e)
	}
	if e = gdb.AdvanceAllocatorTx(c, x, 1, serial, ver, at); e != nil {
		t.Fatal(e)
	}
	for i, pid := range pids {
		role := guild.Member
		if i == 0 {
			role = guild.Leader
		}
		m := guild.Membership{PlayerID: pid, GuildID: gid, Role: role, JoinedAt: at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: at}
		if e = gdb.InsertMembershipTx(c, x, m); e != nil {
			t.Fatal(e)
		}
		if e = gdb.AppendMembershipEventTx(c, x, guild.MembershipEvent{PlayerID: pid, GuildID: gid, Kind: guild.EventJoin, OccurredAt: at, ActorPlayerID: pid, PolicyRevision: pol.GuildCoreRevision}, op.ID); e != nil {
			t.Fatal(e)
		}
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	account, _ := identity.AccountIDFrom(aid)
	sess, _ := identity.SessionIDFrom(session)
	cid, _ := identity.ContextIDFrom(ctxID)
	actor := identity.ActorContext{AccountID: account, AccountUID: identity.AccountUID(aid.String()), SessionID: sess, ContextID: cid, LogicalServerID: 1, PlayerID: pids[0], ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	runner := tx.Runner{DB: p}
	svc := app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: runner}, Reads: runner, Fresh: p, Store: guildbroadcaststore.Store{}, Guild: gdb, Names: i4store.PlayerRootLocker{}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}, Enqueue: queue}
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: bundle.RevisionID()})
	if e != nil {
		t.Fatal(e)
	}
	newOp := func() operation.Context {
		o, e := factory.New(refs)
		if e != nil {
			t.Fatal(e)
		}
		return o
	}
	request := gb.Request{Title: "  title ", Content: "\t body \n"}
	badOp := newOp()
	failed := svc
	failed.Enqueue = &failSecondQueue{Q: queue}
	if _, e = failed.Submit(c, actor, request, badOp); e == nil {
		t.Fatal("failed enqueue committed source")
	}
	var count int
	if e = p.QueryRow(c, `SELECT count(*) FROM guild_broadcast_sources WHERE source_id=$1::uuid`, badOp.ID.String()).Scan(&count); e != nil || count != 0 {
		t.Fatal("source rollback", count, e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'semantic_key' LIKE $1`, badOp.ID.String()+":%").Scan(&count); e != nil || count != 0 {
		t.Fatal("atomic River rollback", count, e)
	}
	capture := &captureSourceStore{}
	svc.Store = capture
	goodOp := newOp()
	out, e := svc.Submit(c, actor, request, goodOp)
	if e != nil || out.RecipientCount != 2 {
		t.Fatal(out, e)
	}
	source, ok, e := (guildbroadcaststore.Store{}).ReadSourceTx(c, p, goodOp.ID)
	if e != nil || !ok || source.Request != request || source.LeaderName != "saved canonical name" || len(source.Recipients) != 2 || source.Recipients[0].JoinEventID == source.Recipients[1].JoinEventID || !source.Operation.StartedAt.Equal(goodOp.StartedAt) {
		before, _ := json.Marshal(capture.Captured)
		after, _ := json.Marshal(source)
		t.Logf("SOURCE_CANONICAL_BEFORE=%s\nSOURCE_CANONICAL_AFTER=%s", before, after)
		t.Fatal("source snapshots", source, ok, e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE queue='guild_materialization' AND args->>'queue'='guild.materialization' AND args->>'semantic_key' LIKE $1`, goodOp.ID.String()+":%").Scan(&count); e != nil || count != 2 {
		t.Fatal("atomic exact jobs", count, e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM mail_records WHERE source_kind='GUILD_BROADCAST' AND source_key=$1`, goodOp.ID.String()).Scan(&count); e != nil || count != 0 {
		t.Fatal("source wrote target Mail", count, e)
	}
	// Race two first submissions of one internal occurrence. Every caller must
	// either observe the same complete committed source or surface conservative
	// uncertainty; a source uniqueness failure cannot manufacture another source.
	firstRaceOp := newOp()
	start := make(chan struct{})
	raceResults := make(chan error, 2)
	for i := 0; i < 2; i++ {
		go func() {
			<-start
			r, e := svc.Submit(c, actor, request, firstRaceOp)
			if e == nil && (r.SourceID != firstRaceOp.ID || r.RecipientCount != 2) {
				e = errors.New("fresh concurrent source identity changed")
			}
			raceResults <- e
		}()
	}
	close(start)
	for i := 0; i < 2; i++ {
		if e := <-raceResults; e != nil {
			t.Fatal("first same-occurrence race", e)
		}
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'semantic_key' LIKE $1`, firstRaceOp.ID.String()+":%").Scan(&count); e != nil || count != 2 {
		t.Fatal("first occurrence race extra jobs", count, e)
	}
	// Concurrent exact occurrences remain source replays, not fresh broadcasts.
	var wg sync.WaitGroup
	results := make(chan error, 8)
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			r, e := svc.Submit(c, actor, request, goodOp)
			if e == nil && r != out {
				e = errors.New("concurrent replay result changed")
			}
			results <- e
		}()
	}
	wg.Wait()
	close(results)
	for e := range results {
		if e != nil {
			t.Fatal("concurrent exact source replay", e)
		}
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'semantic_key' LIKE $1`, goodOp.ID.String()+":%").Scan(&count); e != nil || count != 2 {
		t.Fatal("concurrent replay enqueued again", count, e)
	}
	// Database time is sampled once; a backwards bound instant rejects newer
	// Guild/member/name snapshots before any semantic or River write.
	past := at.Add(-time.Second)
	clockProbe := &countedDBTime{Inner: postgres.AuthoritativeTime{Queryer: p}, Override: &past}
	stale := svc
	stale.Timed.Binder.Time = clockProbe
	staleOp := newOp()
	if _, e = stale.Submit(c, actor, request, staleOp); !errors.Is(e, app.ErrStale) || clockProbe.Calls != 1 {
		t.Fatal("stale bound database time", clockProbe.Calls, e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM guild_broadcast_sources WHERE source_id=$1::uuid`, staleOp.ID.String()).Scan(&count); e != nil || count != 0 {
		t.Fatal("stale snapshot mutated source", count, e)
	}
	// Conservative directory timestamp rejects a fresh submit with a future
	// projection while a committed occurrence retains its original snapshot.
	if _, e = fixtureExec(c, p, `UPDATE player_directory_profiles SET name='later name',updated_at=clock_timestamp()+interval '1 hour',state_version=state_version+1 WHERE player_id=$1`, int64(pids[0])); e != nil {
		t.Fatal(e)
	}
	if _, e = svc.Submit(c, actor, request, newOp()); !errors.Is(e, app.ErrStale) {
		t.Fatal("future name snapshot admitted", e)
	}
	retained, e := svc.Submit(c, actor, request, goodOp)
	if e != nil || retained != out {
		t.Fatal("committed name snapshot replay", retained, e)
	}
	if _, e = fixtureExec(c, p, `UPDATE player_directory_profiles SET updated_at=clock_timestamp(),state_version=state_version+1 WHERE player_id=$1`, int64(pids[0])); e != nil {
		t.Fatal(e)
	}
	// Even with an identical body, supplied operation policy refs may not
	// contradict the policies durably bound to this exact occurrence.
	wrong := goodOp
	wrong.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: "wrong"})
	if _, e = svc.Submit(c, actor, request, wrong); !errors.Is(e, app.ErrConflict) {
		t.Fatal("known occurrence policy contradiction accepted", e)
	}
	if os.Getenv("GXB_I7A8_FULL_ROSTER_PROBE") != "" {
		rosterTx, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		defer rosterTx.Rollback(context.Background())
		var extraFirst int64
		if e = rosterTx.QueryRow(c, `UPDATE logical_servers SET next_player_id=next_player_id+49,state_version=state_version+1 WHERE logical_server_id=1 AND next_player_id+49<=max_player_id RETURNING next_player_id-49`).Scan(&extraFirst); e != nil {
			t.Fatal(e)
		}
		rosterAt, e := (postgres.AuthoritativeTime{Queryer: p}).Now(c)
		if e != nil {
			t.Fatal(e)
		}
		for i := int64(0); i < 49; i++ {
			id, _ := ids.NewUUID()
			pid := identity.PlayerID(extraFirst + i)
			if _, e = rosterTx.Exec(c, `INSERT INTO accounts(account_id,status,created_at,account_uid) VALUES($1::uuid,'ACTIVE',$2,$3)`, id.String(), rosterAt, id.String()); e != nil {
				t.Fatal(e)
			}
			if _, e = rosterTx.Exec(c, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,1,$3,'full-roster-source-fixture')`, int64(pid), id.String(), rosterAt); e != nil {
				t.Fatal(e)
			}
			member := guild.Membership{PlayerID: pid, GuildID: gid, Role: guild.Member, JoinedAt: rosterAt, MembershipVersion: 1, StateVersion: 1, UpdatedAt: rosterAt}
			if e = gdb.InsertMembershipTx(c, rosterTx, member); e != nil {
				t.Fatal(e)
			}
			if e = gdb.AppendMembershipEventTx(c, rosterTx, guild.MembershipEvent{PlayerID: pid, GuildID: gid, Kind: guild.EventJoin, OccurredAt: rosterAt, ActorPlayerID: pid, PolicyRevision: pol.GuildCoreRevision}, op.ID); e != nil {
				t.Fatal(e)
			}
		}
		if e = rosterTx.Commit(c); e != nil {
			t.Fatal(e)
		}
		tooManyOp := newOp()
		if _, e = svc.Submit(c, actor, request, tooManyOp); !errors.Is(e, app.ErrConflict) {
			t.Fatal("51-member corrupt overflow accepted", e)
		}
		if e = p.QueryRow(c, `SELECT count(*) FROM guild_broadcast_sources WHERE source_id=$1::uuid`, tooManyOp.ID.String()).Scan(&count); e != nil || count != 0 {
			t.Fatal("overflow source wrote", count, e)
		}
		remove, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		defer remove.Rollback(context.Background())
		if e = gdb.DeleteMembershipTx(c, remove, identity.PlayerID(extraFirst+48), gid, 1); e != nil {
			t.Fatal(e)
		}
		if e = remove.Commit(c); e != nil {
			t.Fatal(e)
		}
		fullOp := newOp()
		full, e := svc.Submit(c, actor, request, fullOp)
		if e != nil || full.RecipientCount != 50 {
			t.Fatal("full50 roster closure", full, e)
		}
		stored, ok, e := (guildbroadcaststore.Store{}).ReadSourceTx(c, p, fullOp.ID)
		if e != nil || !ok || len(stored.Recipients) != 50 {
			t.Fatal("full50 immutable recipients", ok, e)
		}
		for i, m := range stored.Recipients {
			if i > 0 && stored.Recipients[i-1].PlayerID >= m.PlayerID {
				t.Fatal("unsorted roster")
			}
			if m.JoinEventID <= 0 {
				t.Fatal("incarnation missing")
			}
		}
		if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'semantic_key' LIKE $1`, fullOp.ID.String()+":%").Scan(&count); e != nil || count != 50 {
			t.Fatal("full roster atomic jobs", count, e)
		}
		t.Log("REAL full50 roster/root/membership/JOIN closure and50 atomic River jobs;51 overflow rejects before source mutation")
	}
	// The authenticated committed same operation replays before current role.
	if _, e = fixtureExec(c, p, `UPDATE guild_memberships SET role=0,state_version=state_version+1,membership_version=membership_version+1,updated_at=clock_timestamp() WHERE player_id=$1`, int64(pids[0])); e != nil {
		t.Fatal(e)
	}
	replay, e := svc.Submit(c, actor, request, goodOp)
	if e != nil || replay != out {
		t.Fatal("same source after leader departure", replay, e)
	}
	changed := request
	changed.Content = "changed"
	if _, e = svc.Submit(c, actor, changed, goodOp); !errors.Is(e, app.ErrConflict) {
		t.Fatal("same occurrence changed body accepted", e)
	}
	if _, e = svc.Submit(c, actor, request, newOp()); !errors.Is(e, app.ErrLeader) {
		t.Fatal("fresh nonleader admitted", e)
	}
	t.Log("real authenticated source/roster/JOIN/name/context + atomic River rollback/commit + committed replay after role change + conflict/nonleader proof verified; concurrent exact replay/one DB time sample/backwards snapshot/future name/policy contradiction also verified; complete frozen candidate gate NOT_RUN")
}
