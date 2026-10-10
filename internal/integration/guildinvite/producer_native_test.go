//go:build postgres && river

package guildinvite_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

type failAfterEnqueue struct{ Queue obligation.Queue }

func (q failAfterEnqueue) InsertTx(c context.Context, t tx.Tx, o obligation.Obligation) error {
	if e := q.Queue.InsertTx(c, t, o); e != nil {
		return e
	}
	return errors.New("injected after real transactional River insertion")
}

func TestWorkingP2ActualFiveProducerHooksAndAtomicRiverRollback(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8B_SOURCE_DSN")
	if dsn == "" {
		t.Skip("fresh disposable38 source-only working database required")
	}
	c, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	if e = riveradapter.ValidateDeployment(c, p.Raw()); e != nil {
		t.Fatal(e)
	}
	content := contentstore.Store{}
	reg := registry.Service{Runner: tx.Runner{DB: p}, Repo: content, Fresh: p, Providers: registry.DefaultProviderSet()}
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	old, ok, e := content.ReadActivation(c, p)
	if e != nil || !ok {
		t.Fatal(old, ok, e)
	}
	if _, e = reg.EnsureBuiltinInstalled(c, mustOp(t, policy.Set{}), bundle); e != nil {
		t.Fatal(e)
	}
	still, ok, e := content.ReadActivation(c, p)
	if e != nil || !ok || old != still {
		t.Fatal("installation advanced active pointer", old, still, e)
	}
	if _, has, e := content.ReadInvitePolicy(c, p, old.RevisionID); e != nil || has {
		t.Fatal("older active catalog invented Invite capability", has, e)
	}
	// Explicit disposable test activation qualifies the source bundle only.
	// It is not API/consumer/worker readiness or a production activation claim.
	if _, e = reg.ActivateBuiltin(c, mustOp(t, policy.Set{}), bundle, old, "working-source-native-test"); e != nil {
		t.Fatal(e)
	}
	artifact, e := guildpolicy.LoadBuiltin()
	if e != nil {
		t.Fatal(e)
	}
	binding, e := guildpolicybridge.FromBuiltin(artifact)
	if e != nil {
		t.Fatal(e)
	}
	store := guildinvitestore.Store{}
	gs := guildstore.Store{Queryer: p}
	kernel := kernelstore.Store{}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	reader := app.SourceReader{Store: store, Bindings: gs, Receipts: kernel, Content: content}
	projection := app.SourceService{Reads: tx.Runner{DB: p}, Store: store, Bindings: gs, History: kernel, Reader: reader, Content: content, Queryer: p, Enqueue: queue}
	i5 := appi5.CrossOwner{Store: i5store.Store{}}
	service := guildcore.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: gs, Fencer: i5store.Store{}, PlayerRoots: i4store.PlayerRootLocker{}, Level: i5, Scalar: i5, LevelAndScalar: i5, Receipts: kernel, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding, InviteProjection: &projection}
	fixture, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer fixture.Rollback(c)
	var first int64
	if e = fixture.QueryRow(c, `UPDATE logical_servers SET next_player_id=next_player_id+8,state_version=state_version+1 WHERE logical_server_id=1 AND next_player_id+8<=max_player_id RETURNING next_player_id-8`).Scan(&first); e != nil {
		t.Fatal(e)
	}
	at := time.Now().UTC().Add(-time.Second)
	actors := make([]identity.ActorContext, 8)
	for i := range actors {
		pid := identity.PlayerID(first + int64(i))
		aid, _ := ids.NewUUID()
		sid, _ := ids.NewUUID()
		cid, _ := ids.NewUUID()
		for _, statement := range []struct {
			sql  string
			args []any
		}{
			{`INSERT INTO accounts(account_id,status,created_at,account_uid)VALUES($1::uuid,'ACTIVE',$2,$3)`, []any{aid.String(), at, aid.String()}},
			{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2::uuid,1,$3,'working-source8b-fixture')`, []any{int64(pid), aid.String(), at}},
			{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,80,0,1,$2)`, []any{int64(pid), at}},
			{`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,$2)`, []any{int64(pid), at}},
			{`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',10000,1,$2)`, []any{int64(pid), at}},
			{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1::uuid,$2::uuid,'working-source8b-fixture',$3,$3)`, []any{sid.String(), aid.String(), at}},
			{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1::uuid,$2::uuid,$3::uuid,1,$4,1,$5)`, []any{cid.String(), sid.String(), aid.String(), int64(pid), at}},
		} {
			if _, e = fixture.Exec(c, statement.sql, statement.args...); e != nil {
				t.Fatal(e)
			}
		}
		a, _ := identity.AccountIDFrom(aid)
		session, _ := identity.SessionIDFrom(sid)
		contextID, _ := identity.ContextIDFrom(cid)
		actors[i] = identity.ActorContext{AccountID: a, AccountUID: identity.AccountUID(aid.String()), SessionID: session, ContextID: contextID, LogicalServerID: 1, PlayerID: pid, ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
	}
	if e = fixture.Commit(c); e != nil {
		t.Fatal(e)
	}
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: bundle.RevisionID()})
	if e != nil {
		t.Fatal(e)
	}
	// The named operations below are retained so their full immutable source
	// evidence can be read through the actual owner/content ports after commit.
	opCreateA := mustOp(t, refs)
	a, e := service.Create(c, actors[0], guildcore.CreateRequest{Name: "nativeA", Icon: binding.Policy.GuildIcons[0]}, opCreateA)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = reader.ReadMarkerEvidenceTx(c, p, opCreateA.ID); e != nil {
		t.Fatal("Create marker", e)
	}
	opInvite := mustOp(t, refs)
	if _, e = service.Invite(c, actors[0], actors[1].PlayerID, opInvite); e != nil {
		t.Fatal(e)
	}
	source, e := reader.ReadIssueEvidenceTx(c, p, opInvite.ID)
	if e != nil {
		t.Fatal(e)
	}
	if source.Tuple.Generation != 1 {
		t.Fatal("unexpected initial retained generation", source.Tuple.Generation)
	}
	if retry, e := service.Invite(c, actors[0], actors[1].PlayerID, mustOp(t, refs)); e != nil || !retry.Replayed {
		t.Fatal("live stock retry replaced source", retry, e)
	}
	opAccept := mustOp(t, refs)
	if _, e = service.AcceptInvite(c, actors[1], guild.ID(a.GuildID), opAccept); e != nil {
		t.Fatal(e)
	}
	if _, e = reader.ReadMarkerEvidenceTx(c, p, opAccept.ID); e != nil {
		t.Fatal("AcceptInvite marker", e)
	}
	snap, e := reader.ReadInviteSnapshotTx(c, p, opInvite.ID)
	if e != nil {
		t.Fatal(e)
	}
	if live, e := snap.Eligible(time.Now().UTC()); e != nil || live {
		t.Fatal("JOIN did not permanently invalidate", live, e)
	}
	if _, e = service.ApplyOrJoin(c, actors[2], guild.ID(a.GuildID), mustOp(t, refs)); e != nil {
		t.Fatal(e)
	}
	opApplication := mustOp(t, refs)
	if _, e = service.AcceptApplication(c, actors[0], actors[2].PlayerID, opApplication); e != nil {
		t.Fatal(e)
	}
	if _, e = reader.ReadMarkerEvidenceTx(c, p, opApplication.ID); e != nil {
		t.Fatal("AcceptApplication marker", e)
	}
	opCreateB := mustOp(t, refs)
	b, e := service.Create(c, actors[4], guildcore.CreateRequest{Name: "nativeB", Icon: binding.Policy.GuildIcons[0]}, opCreateB)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = service.UpdateSettings(c, actors[4], guildcore.SettingsRequest{Name: "nativeB", Icon: binding.Policy.GuildIcons[0], MinAllowLevel: 32, ApplyType: guild.ApplyImmediate}, mustOp(t, refs)); e != nil {
		t.Fatal(e)
	}
	opImmediate := mustOp(t, refs)
	if _, e = service.ApplyOrJoin(c, actors[3], guild.ID(b.GuildID), opImmediate); e != nil {
		t.Fatal(e)
	}
	if _, e = reader.ReadMarkerEvidenceTx(c, p, opImmediate.ID); e != nil {
		t.Fatal("immediate JOIN marker", e)
	}
	opCreateC := mustOp(t, refs)
	third, e := service.Create(c, actors[5], guildcore.CreateRequest{Name: "nativeC", Icon: binding.Policy.GuildIcons[0]}, opCreateC)
	if e != nil {
		t.Fatal(e)
	}
	opRetiredInvite := mustOp(t, refs)
	if _, e = service.Invite(c, actors[5], actors[6].PlayerID, opRetiredInvite); e != nil {
		t.Fatal(e)
	}
	opRetire := mustOp(t, refs)
	if _, e = service.Dissolve(c, actors[5], opRetire); e != nil {
		t.Fatal(e)
	}
	m, e := reader.ReadMarkerEvidenceTx(c, p, opRetire.ID)
	if e != nil || m.Kind != gi.Retire || m.GuildID != guild.ID(third.GuildID) {
		t.Fatal(m, e)
	}
	retired, e := reader.ReadInviteSnapshotTx(c, p, opRetiredInvite.ID)
	if e != nil {
		t.Fatal(e)
	}
	if live, e := retired.Eligible(time.Now().UTC()); e != nil || live {
		t.Fatal("retired Invite remained eligible", live, e)
	}
	var jobs int64
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'obligation_kind' IN ('guild.invite.notice.v1','guild.invite.cleanup.v1')`).Scan(&jobs); e != nil {
		t.Fatal(e)
	}
	// Source/core/I5 effects plus an already inserted real job must all roll
	// back when the final source enqueue stage fails.
	failingProjection := projection
	failingProjection.Enqueue = failAfterEnqueue{Queue: queue}
	failing := service
	failing.InviteProjection = &failingProjection
	failedOp := mustOp(t, refs)
	if _, e = failing.Create(c, actors[7], guildcore.CreateRequest{Name: "nativeFail", Icon: binding.Policy.GuildIcons[0]}, failedOp); e == nil {
		t.Fatal("injected enqueue failure accepted")
	}
	if _, _, exists, e := store.ReadMarkerTx(c, p, failedOp.ID); e != nil || exists {
		t.Fatal("aborted marker visible", exists, e)
	}
	if _, exists, e := gs.ReadMembership(c, actors[7].PlayerID); e != nil || exists {
		t.Fatal("failed Create left membership", exists, e)
	}
	var balance, afterJobs int64
	if e = p.QueryRow(c, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(actors[7].PlayerID)).Scan(&balance); e != nil || balance != 10000 {
		t.Fatal("failed Create charged currency", balance, e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM river_job WHERE args->>'obligation_kind' IN ('guild.invite.notice.v1','guild.invite.cleanup.v1')`).Scan(&afterJobs); e != nil || afterJobs != jobs {
		t.Fatal("aborted River job visible", jobs, afterJobs, e)
	}
	var issues, markers int64
	if e = p.QueryRow(c, `SELECT count(*) FROM guild_invite_projection_sources`).Scan(&issues); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(c, `SELECT count(*) FROM guild_invite_projection_markers`).Scan(&markers); e != nil {
		t.Fatal(e)
	}
	if issues != 2 || markers != 7 || jobs != 9 {
		t.Fatal("source/marker/job cardinality", issues, markers, jobs)
	}
	t.Log(fmt.Sprintf("WORKING_SOURCE_ONLY: all4JOIN + Invite + Retire;2issues,7markers,9finite real jobs; I5/River rollback; no target consumer or frozen gate credit"))
}
