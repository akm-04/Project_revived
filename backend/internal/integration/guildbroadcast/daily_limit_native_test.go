//go:build postgres && river

package guildbroadcast_test

import (
	"context"
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
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

type fixedDecisionTime struct{ at time.Time }

func (f *fixedDecisionTime) Now(context.Context) (time.Time, error) { return f.at, nil }

func TestGuildBroadcastDailyLimitResetsAtGameDayBoundary(t *testing.T) {
	dsn := os.Getenv("GXB_C1_10_DSN")
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
	at := time.Now().UTC().Add(-time.Minute).Truncate(time.Second)
	pids, actor := dailyLimitFixture(t, c, p, at, pol.GuildCoreRevision)
	gid := dailyLimitGuild(t, c, p, pids, at, pol.GuildCoreRevision)
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	runner := tx.Runner{DB: p}
	clockAuthority := &fixedDecisionTime{at: time.Now().UTC().Truncate(time.Second)}
	svc := app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: clockAuthority}, Runner: runner}, Reads: runner, Fresh: p, Store: guildbroadcaststore.Store{}, Guild: guildstore.Store{Queryer: p}, Names: i4store.PlayerRootLocker{}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}, Enqueue: queue, DailyLimit: 5}
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: bundle.RevisionID()})
	if e != nil {
		t.Fatal(e)
	}
	newOperation := func() operation.Context {
		o, e := factory.New(refs)
		if e != nil {
			t.Fatal(e)
		}
		return o
	}
	request := gb.Request{Title: "daily title", Content: "daily body"}
	var last operation.Context
	for i := 0; i < 5; i++ {
		last = newOperation()
		if _, e = svc.Submit(c, actor, request, last); e != nil {
			t.Fatalf("broadcast %d refused: %v", i+1, e)
		}
	}
	freshOp := newOperation()
	if _, e = svc.Submit(c, actor, request, freshOp); !errors.Is(e, app.ErrDailyLimit) {
		t.Fatalf("sixth broadcast err=%v, want ErrDailyLimit", e)
	}
	day := modes.Day(clockAuthority.at)
	if count := dailyLimitSourceCount(t, c, p, gid, day); count != 5 {
		t.Fatalf("day %d sources=%d, want 5", day, count)
	}
	if _, e = svc.Submit(c, actor, request, last); e != nil {
		t.Fatalf("replay of the fifth broadcast refused: %v", e)
	}
	nextDay := modes.DayBegins(day + 1)
	clockAuthority.at = nextDay
	if _, e = svc.Submit(c, actor, request, newOperation()); e != nil {
		t.Fatalf("first broadcast of the next game day refused: %v", e)
	}
	if count := dailyLimitSourceCount(t, c, p, gid, day); count != 5 {
		t.Fatalf("old day sources=%d after reset, want 5", count)
	}
	if count := dailyLimitSourceCount(t, c, p, gid, modes.Day(nextDay)); count != 1 {
		t.Fatalf("next day sources=%d, want 1", count)
	}
}

func dailyLimitSourceCount(t *testing.T, c context.Context, p *postgres.Pool, gid guild.ID, day int64) int {
	t.Helper()
	var count int
	if e := p.QueryRow(c, `SELECT count(*) FROM guild_broadcast_sources WHERE guild_id=$1 AND decision_at>=$2 AND decision_at<$3`, int64(gid), modes.DayBegins(day), modes.DayBegins(day+1)).Scan(&count); e != nil {
		t.Fatal(e)
	}
	return count
}

func dailyLimitFixture(t *testing.T, c context.Context, p *postgres.Pool, at time.Time, revision string) ([]identity.PlayerID, identity.ActorContext) {
	t.Helper()
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	var first int64
	if e = x.QueryRow(c, `UPDATE logical_servers SET next_player_id=next_player_id+2,state_version=state_version+1 WHERE logical_server_id=1 AND next_player_id+2<=max_player_id RETURNING next_player_id-2`).Scan(&first); e != nil {
		t.Fatal(e)
	}
	pids := []identity.PlayerID{identity.PlayerID(first), identity.PlayerID(first + 1)}
	var account ids.UUID
	var session ids.UUID
	var contextID ids.UUID
	for i, pid := range pids {
		id, _ := ids.NewUUID()
		if i == 0 {
			account = id
		}
		if _, e = x.Exec(c, `INSERT INTO accounts(account_id,status,created_at,account_uid) VALUES($1::uuid,'ACTIVE',$2,$3)`, id.String(), at, id.String()); e != nil {
			t.Fatal(e)
		}
		if _, e = x.Exec(c, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) VALUES($1,$2::uuid,1,$3,'c1-10-daily-limit')`, int64(pid), id.String(), at); e != nil {
			t.Fatal(e)
		}
		if _, e = x.Exec(c, `INSERT INTO player_directory_profiles(player_id,name,created_at,updated_at) VALUES($1,'daily limit name',$2,$2)`, int64(pid), at); e != nil {
			t.Fatal(e)
		}
	}
	session, _ = ids.NewUUID()
	contextID, _ = ids.NewUUID()
	if _, e = x.Exec(c, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at) VALUES($1::uuid,$2::uuid,'c1-10-native',$3,$3)`, session.String(), account.String(), at); e != nil {
		t.Fatal(e)
	}
	if _, e = x.Exec(c, `INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at) VALUES($1::uuid,$2::uuid,$3::uuid,1,$4,1,$5)`, contextID.String(), session.String(), account.String(), int64(pids[0]), at); e != nil {
		t.Fatal(e)
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	accountID, _ := identity.AccountIDFrom(account)
	sessionID, _ := identity.SessionIDFrom(session)
	actorContextID, _ := identity.ContextIDFrom(contextID)
	actor := identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID(account.String()), SessionID: sessionID, ContextID: actorContextID, LogicalServerID: 1, PlayerID: pids[0], ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
	return pids, actor
}

func dailyLimitGuild(t *testing.T, c context.Context, p *postgres.Pool, pids []identity.PlayerID, at time.Time, revision string) guild.ID {
	t.Helper()
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(context.Background())
	gdb := guildstore.Store{Queryer: p}
	serial, version, e := gdb.LockAllocatorTx(c, x, 1, at)
	if e != nil {
		t.Fatal(e)
	}
	gid := guild.ID(1000000 + serial)
	g := guild.Guild{ID: gid, LogicalServerID: 1, Name: fmt.Sprintf("daily%d", gid), Icon: 1, ApplyType: guild.ApplyByApplication, MinAllowLevel: 1, PolicyRevision: revision, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	if e = gdb.InsertGuildTx(c, x, g); e != nil {
		t.Fatal(e)
	}
	if e = gdb.AdvanceAllocatorTx(c, x, 1, serial, version, at); e != nil {
		t.Fatal(e)
	}
	for i, pid := range pids {
		role := guild.Member
		if i == 0 {
			role = guild.Leader
		}
		membership := guild.Membership{PlayerID: pid, GuildID: gid, Role: role, JoinedAt: at, MembershipVersion: 1, StateVersion: 1, UpdatedAt: at}
		if e = gdb.InsertMembershipTx(c, x, membership); e != nil {
			t.Fatal(e)
		}
		if e = gdb.AppendMembershipEventTx(c, x, guild.MembershipEvent{PlayerID: pid, GuildID: gid, Kind: guild.EventJoin, OccurredAt: at, ActorPlayerID: pid, PolicyRevision: revision}, ids.UUID{}); e != nil {
			t.Fatal(e)
		}
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	return gid
}
