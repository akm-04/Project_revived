//go:build postgres && river

package guildinvite_test

import (
	"context"
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
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/obligation"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

// world is one test's own Guild Invite source history on a shared deployed database (D65, I8.5-6): eight level-80 actors,
// Guild A (leader 0, member 1 by Invite, member 2 by application), Guild B (leader 4, member 3 by immediate JOIN) and a
// dissolved Guild C whose Invite to actor 6 was retired. Names and players are unique per world, so worlds never collide.
type world struct {
	actors                 []identity.ActorContext
	guildA, guildB, guildC guild.ID
	invite, accept         operation.Context
	retiredInvite, retire  operation.Context
	refs                   policy.Set
	core                   guildcore.Service
	projection             app.SourceService
	queue                  obligation.Queue
}

func seedWorld(t *testing.T, c context.Context, p *postgres.Pool) world {
	t.Helper()
	if e := riveradapter.ValidateDeployment(c, p.Raw()); e != nil {
		t.Fatal(e)
	}
	content := contentstore.Store{}
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		t.Fatal(e)
	}
	if _, has, e := content.ReadInvitePolicy(c, p, rev); e != nil || !has {
		t.Fatal("active catalog lacks the Invite capability", has, e)
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
	w := world{queue: queue}
	w.projection = app.SourceService{Reads: tx.Runner{DB: p}, Store: store, Bindings: gs, History: kernel, Reader: reader, Content: content, Queryer: p, Enqueue: queue}
	i5 := appi5.CrossOwner{Store: i5store.Store{}}
	w.core = guildcore.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: gs, Fencer: i5store.Store{}, PlayerRoots: i4store.PlayerRootLocker{}, Level: i5, Scalar: i5, LevelAndScalar: i5, Receipts: kernel, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding, InviteProjection: &w.projection}
	w.actors = seedActors(t, c, p)
	if w.refs, e = policy.NewSet(policy.Ref{Name: "content", Version: rev}); e != nil {
		t.Fatal(e)
	}
	suffix := int64(w.actors[0].PlayerID)
	icon := binding.Policy.GuildIcons[0]
	service := w.core
	// The named operations below are retained so their full immutable source
	// evidence can be read through the actual owner/content ports after commit.
	opCreateA := mustOp(t, w.refs)
	a, e := service.Create(c, w.actors[0], guildcore.CreateRequest{Name: fmt.Sprintf("A%d", suffix), Icon: icon}, opCreateA)
	if e != nil {
		t.Fatal(e)
	}
	w.guildA = guild.ID(a.GuildID)
	if _, e = reader.ReadMarkerEvidenceTx(c, p, opCreateA.ID); e != nil {
		t.Fatal("Create marker", e)
	}
	w.invite = mustOp(t, w.refs)
	if _, e = service.Invite(c, w.actors[0], w.actors[1].PlayerID, w.invite); e != nil {
		t.Fatal(e)
	}
	source, e := reader.ReadIssueEvidenceTx(c, p, w.invite.ID)
	if e != nil {
		t.Fatal(e)
	}
	if source.Tuple.Generation != 1 {
		t.Fatal("unexpected initial retained generation", source.Tuple.Generation)
	}
	if retry, e := service.Invite(c, w.actors[0], w.actors[1].PlayerID, mustOp(t, w.refs)); e != nil || !retry.Replayed {
		t.Fatal("live stock retry replaced source", retry, e)
	}
	w.accept = mustOp(t, w.refs)
	if _, e = service.AcceptInvite(c, w.actors[1], w.guildA, w.accept); e != nil {
		t.Fatal(e)
	}
	if _, e = reader.ReadMarkerEvidenceTx(c, p, w.accept.ID); e != nil {
		t.Fatal("AcceptInvite marker", e)
	}
	snap, e := reader.ReadInviteSnapshotTx(c, p, w.invite.ID)
	if e != nil {
		t.Fatal(e)
	}
	if live, e := snap.Eligible(time.Now().UTC()); e != nil || live {
		t.Fatal("JOIN did not permanently invalidate", live, e)
	}
	if _, e = service.ApplyOrJoin(c, w.actors[2], w.guildA, mustOp(t, w.refs)); e != nil {
		t.Fatal(e)
	}
	opApplication := mustOp(t, w.refs)
	if _, e = service.AcceptApplication(c, w.actors[0], w.actors[2].PlayerID, opApplication); e != nil {
		t.Fatal(e)
	}
	if _, e = reader.ReadMarkerEvidenceTx(c, p, opApplication.ID); e != nil {
		t.Fatal("AcceptApplication marker", e)
	}
	nameB := fmt.Sprintf("B%d", suffix)
	b, e := service.Create(c, w.actors[4], guildcore.CreateRequest{Name: nameB, Icon: icon}, mustOp(t, w.refs))
	if e != nil {
		t.Fatal(e)
	}
	w.guildB = guild.ID(b.GuildID)
	if _, e = service.UpdateSettings(c, w.actors[4], guildcore.SettingsRequest{Name: nameB, Icon: icon, MinAllowLevel: 32, ApplyType: guild.ApplyImmediate}, mustOp(t, w.refs)); e != nil {
		t.Fatal(e)
	}
	opImmediate := mustOp(t, w.refs)
	if _, e = service.ApplyOrJoin(c, w.actors[3], w.guildB, opImmediate); e != nil {
		t.Fatal(e)
	}
	if _, e = reader.ReadMarkerEvidenceTx(c, p, opImmediate.ID); e != nil {
		t.Fatal("immediate JOIN marker", e)
	}
	third, e := service.Create(c, w.actors[5], guildcore.CreateRequest{Name: fmt.Sprintf("C%d", suffix), Icon: icon}, mustOp(t, w.refs))
	if e != nil {
		t.Fatal(e)
	}
	w.guildC = guild.ID(third.GuildID)
	w.retiredInvite = mustOp(t, w.refs)
	if _, e = service.Invite(c, w.actors[5], w.actors[6].PlayerID, w.retiredInvite); e != nil {
		t.Fatal(e)
	}
	w.retire = mustOp(t, w.refs)
	if _, e = service.Dissolve(c, w.actors[5], w.retire); e != nil {
		t.Fatal(e)
	}
	m, e := reader.ReadMarkerEvidenceTx(c, p, w.retire.ID)
	if e != nil || m.Kind != gi.Retire || m.GuildID != w.guildC {
		t.Fatal(m, e)
	}
	retired, e := reader.ReadInviteSnapshotTx(c, p, w.retiredInvite.ID)
	if e != nil {
		t.Fatal(e)
	}
	if live, e := retired.Eligible(time.Now().UTC()); e != nil || live {
		t.Fatal("retired Invite remained eligible", live, e)
	}
	return w
}

func seedActors(t *testing.T, c context.Context, p *postgres.Pool) []identity.ActorContext {
	t.Helper()
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
	return actors
}

// joinedTargets is the lifecycle fixture: after materializeTargets, actor 7 joins Guild A, and that JOIN marker covers both of
// actor 7's materialized Invites (one dismissed, one active).
func joinedTargets(t *testing.T, c context.Context, p *postgres.Pool) (world, operation.Context) {
	t.Helper()
	w := seedWorld(t, c, p)
	materializeTargets(t, c, p, w)
	join := mustOp(t, w.refs)
	if _, e := w.core.AcceptInvite(c, w.actors[7], w.guildA, join); e != nil {
		t.Fatal(e)
	}
	return w, join
}
