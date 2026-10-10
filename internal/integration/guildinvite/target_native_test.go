//go:build postgres && river

package guildinvite_test

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildinvitestore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/postgres/testfault"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	app "gxb.local/backend/v2/internal/application/guildinvite"
	target "gxb.local/backend/v2/internal/application/guildinvitetarget"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"testing"
	"time"
)

type uncertainDB = testfault.UnknownCommitDB

func savedActor(t *testing.T, c context.Context, p *postgres.Pool, pid identity.PlayerID) identity.ActorContext {
	t.Helper()
	var aid, sid, cid, uid string
	var cg, sl, cl int64
	e := p.QueryRow(c, `SELECT a.account_id::text,a.account_uid,s.session_id::text,g.context_id::text,g.context_generation,s.liveness_version,g.liveness_version FROM gameplay_contexts g JOIN account_sessions s ON s.session_id=g.session_id JOIN accounts a ON a.account_id=g.account_id WHERE g.player_id=$1 AND g.ended_at IS NULL ORDER BY g.created_at DESC LIMIT 1`, int64(pid)).Scan(&aid, &uid, &sid, &cid, &cg, &sl, &cl)
	if e != nil {
		t.Fatal(e)
	}
	a, _ := ids.ParseUUID(aid)
	session, _ := ids.ParseUUID(sid)
	contextID, _ := ids.ParseUUID(cid)
	account, _ := identity.AccountIDFrom(a)
	sess, _ := identity.SessionIDFrom(session)
	ctx, _ := identity.ContextIDFrom(contextID)
	return identity.ActorContext{AccountID: account, AccountUID: identity.AccountUID(uid), SessionID: sess, ContextID: ctx, LogicalServerID: 1, PlayerID: pid, ContextGeneration: cg, SessionLivenessVersion: sl, ContextLivenessVersion: cl}
}

func TestWorkingP3MaterializeReplaySuppressionAndUnknownCommit(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8B_TARGET_DSN")
	if dsn == "" {
		t.Skip("fresh disposable working source fixture required")
	}
	c, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	content := contentstore.Store{}
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		t.Fatal(e)
	}
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: rev})
	if e != nil {
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
	gs := guildstore.Store{Queryer: p}
	store := guildinvitestore.Store{}
	kernel := kernelstore.Store{}
	reader := app.SourceReader{Store: store, Bindings: gs, Receipts: kernel, Content: content}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	projection := app.SourceService{Reads: tx.Runner{DB: p}, Store: store, Bindings: gs, History: kernel, Reader: reader, Content: content, Queryer: p, Enqueue: queue}
	i5 := appi5.CrossOwner{Store: i5store.Store{}}
	roots := i4store.PlayerRootLocker{}
	core := guildcore.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: gs, Fencer: i5store.Store{}, PlayerRoots: roots, Level: i5, Scalar: i5, LevelAndScalar: i5, Receipts: kernel, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding, InviteProjection: &projection}
	inbox := socialinboxstore.Store{}
	rootService := socialrelation.RootService{Store: socialrelationstore.Store{}}
	service := target.Service{Timed: core.Timed, Reads: tx.Runner{DB: p}, Sources: reader, Players: roots, Roots: rootService, Store: inbox, Receipts: kernel}
	var leaderA, leaderB, recipient, other int64
	if e = p.QueryRow(c, `SELECT player_id FROM guild_memberships m JOIN guilds g USING(guild_id) WHERE g.name='nativeA' AND role=1`).Scan(&leaderA); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(c, `SELECT player_id FROM guild_memberships m JOIN guilds g USING(guild_id) WHERE g.name='nativeB' AND role=1`).Scan(&leaderB); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(c, `SELECT max(player_id),max(player_id)-1 FROM players`).Scan(&recipient, &other); e != nil {
		t.Fatal(e)
	}
	actorA := savedActor(t, c, p, identity.PlayerID(leaderA))
	actorB := savedActor(t, c, p, identity.PlayerID(leaderB))
	first := mustOp(t, refs)
	if _, e = core.Invite(c, actorA, identity.PlayerID(recipient), first); e != nil {
		t.Fatal(e)
	}
	s, e := reader.ReadIssueEvidenceTx(c, p, first.ID)
	if e != nil {
		t.Fatal(e)
	}
	proof, e := service.Materialize(c, first.ID)
	if e != nil || proof.State != gi.Materialized {
		t.Fatal(proof, e)
	}
	n, ok, e := inbox.ReadNoticeEvidenceTx(c, p, identity.PlayerID(recipient), socialinbox.NoticeID(proof.NoticeID))
	if e != nil || !ok || socialinbox.MatchInvite(n, s) != nil || !n.Active {
		t.Fatal(n, ok, e)
	}
	if n.NoticeTime.UnixMicro() != s.DecisionAt.UnixMicro() {
		t.Fatal("Notice timestamp replaced immutable issue time")
	}
	x, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	root, e := roots.LockBoundRecipientTx(c, x, s.Server, s.Tuple.Recipient)
	if e != nil {
		t.Fatal(e)
	}
	plan, e := rootService.PrepareTx(c, x, root.Root)
	if e != nil {
		t.Fatal(e)
	}
	locked, ok, e := inbox.LockNoticeTx(c, x, s.Tuple.Recipient, n.NoticeID)
	if e != nil || !ok {
		t.Fatal(e)
	}
	at, e := (postgres.AuthoritativeTime{Queryer: x}).Now(c)
	if e != nil {
		t.Fatal(e)
	}
	if e = inbox.ConsumeInviteNoticeTx(c, x, locked, at); e != nil {
		t.Fatal(e)
	}
	if _, e = rootService.ApplyChangeTx(c, x, plan, at); e != nil {
		t.Fatal(e)
	}
	if e = x.Commit(c); e != nil {
		t.Fatal(e)
	}
	replayed, e := service.Materialize(c, first.ID)
	if e != nil || replayed != proof {
		t.Fatal("replay changed immutable target", proof, replayed, e)
	}
	dismissed, ok, e := inbox.ReadNoticeEvidenceTx(c, p, s.Tuple.Recipient, n.NoticeID)
	if e != nil || !ok || dismissed.Active || dismissed.DismissedAt == nil {
		t.Fatal("replay recreated tombstone", dismissed, e)
	}
	second := mustOp(t, refs)
	if _, e = core.Invite(c, actorB, identity.PlayerID(recipient), second); e != nil {
		t.Fatal(e)
	}
	unknownPositive := service
	unknownPositive.Timed.Runner.DB = uncertainDB{Pool: p, Committed: true}
	positive, e := unknownPositive.Materialize(c, second.ID)
	if e != nil || positive.State != gi.Materialized {
		t.Fatal("complete UNKNOWN positive not reconciled", positive, e)
	}
	if again, e := service.Materialize(c, second.ID); e != nil || again != positive {
		t.Fatal("UNKNOWN recovery allocated another Notice", again, e)
	}
	third := mustOp(t, refs)
	if _, e = core.Invite(c, actorA, identity.PlayerID(other), third); e != nil {
		t.Fatal(e)
	}
	unknownAbsent := service
	unknownAbsent.Timed.Runner.DB = uncertainDB{Pool: p, Committed: false}
	_, e = unknownAbsent.Materialize(c, third.ID)
	var unknown *tx.UnknownCommitError
	if !errors.As(e, &unknown) {
		t.Fatal("absent UNKNOWN granted replay", e)
	}
	if _, found, e := inbox.ReadInviteMaterializationTx(c, p, third.ID); e != nil || found {
		t.Fatal("aborted target evidence became terminal", found, e)
	}
	// Intentionally corrupt a transaction snapshot without committing it:
	// retained positive proof beside a missing required Notice must fail.
	corrupt, e := p.Begin(c, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer corrupt.Rollback(c)
	if _, e = corrupt.Exec(c, `DELETE FROM social_notices WHERE recipient_player_id=$1 AND notice_id=$2`, recipient, proof.NoticeID); e != nil {
		t.Fatal(e)
	}
	if _, _, e = service.ReadInviteTargetProofTx(c, corrupt, first.ID); e == nil {
		t.Fatal("missing Notice was healed or treated as absence")
	}
	if e = corrupt.Rollback(c); e != nil {
		t.Fatal(e)
	}
	var joined, retired string
	if e = p.QueryRow(c, `SELECT s.source_id::text FROM guild_invite_projection_sources s JOIN guild_memberships m ON m.player_id=s.recipient_player_id WHERE s.source_id<>$1::uuid ORDER BY s.source_serial LIMIT 1`, first.ID.String()).Scan(&joined); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(c, `SELECT s.source_id::text FROM guild_invite_projection_sources s JOIN guilds g ON g.guild_id=s.guild_id WHERE g.retired_at IS NOT NULL ORDER BY s.source_serial LIMIT 1`).Scan(&retired); e != nil {
		t.Fatal(e)
	}
	for _, raw := range []string{joined, retired} {
		id, e := ids.ParseUUID(raw)
		if e != nil {
			t.Fatal(e)
		}
		p, e := service.Materialize(c, id)
		if e != nil || p.State != gi.Suppressed || p.NoticeID != 0 {
			t.Fatal("canonical suppression invented Notice", p, e)
		}
	}
	// The live canonical Invite and membership remain Guild-owned; first
	// presentation/dismissal commands did not accept or cancel that Invite.
	if inv, ok, e := gs.FindInviteTx(c, p, s.Tuple.GuildID, s.Tuple.Recipient); e != nil || !ok || inv.Generation != s.Tuple.Generation {
		t.Fatal("presentation mutated Guild Invite", inv, ok, e)
	}
	if _, ok, e := gs.ReadMembership(c, s.Tuple.Recipient); e != nil || ok {
		t.Fatal("presentation joined Guild", ok, e)
	}
	t.Log("WORKING_TARGET_ONLY: creation/sameNotice/tombstone, actual positive and absent UNKNOWN, orphan rejection, JOIN/retirement suppression; no full frozen gate credit")
}

func TestWorkingP3LifecycleInvalidationAndUnknownProof(t *testing.T) {
	dsn := os.Getenv("GXB_I7A8B_CLEANUP_DSN")
	if dsn == "" {
		t.Skip("fresh clone of working materialized target fixture required")
	}
	c, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer p.Close()
	content := contentstore.Store{}
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		t.Fatal(e)
	}
	refs, e := policy.NewSet(policy.Ref{Name: "content", Version: rev})
	if e != nil {
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
	gs := guildstore.Store{Queryer: p}
	store := guildinvitestore.Store{}
	kernel := kernelstore.Store{}
	reader := app.SourceReader{Store: store, Bindings: gs, Receipts: kernel, Content: content}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	projection := app.SourceService{Reads: tx.Runner{DB: p}, Store: store, Bindings: gs, History: kernel, Reader: reader, Content: content, Queryer: p, Enqueue: queue}
	i5 := appi5.CrossOwner{Store: i5store.Store{}}
	roots := i4store.PlayerRootLocker{}
	core := guildcore.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: gs, Fencer: i5store.Store{}, PlayerRoots: roots, Level: i5, Scalar: i5, LevelAndScalar: i5, Receipts: kernel, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding, InviteProjection: &projection}
	inbox := socialinboxstore.Store{}
	rootService := socialrelation.RootService{Store: socialrelationstore.Store{}}
	service := target.Service{Timed: core.Timed, Reads: tx.Runner{DB: p}, Sources: reader, Players: roots, Roots: rootService, Store: inbox, Receipts: kernel}

	var recipient, gid int64
	if e = p.QueryRow(c, `SELECT max(player_id) FROM players`).Scan(&recipient); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(c, `SELECT guild_id FROM guilds WHERE name='nativeA'`).Scan(&gid); e != nil {
		t.Fatal(e)
	}
	actor := savedActor(t, c, p, identity.PlayerID(recipient))
	joinOp := mustOp(t, refs)
	if _, e = core.AcceptInvite(c, actor, guild.ID(gid), joinOp); e != nil {
		t.Fatal(e)
	}
	marker, e := reader.ReadMarkerEvidenceTx(c, p, joinOp.ID)
	if e != nil {
		t.Fatal(e)
	}
	var sources string
	if e = p.QueryRow(c, `SELECT COALESCE(jsonb_agg(source_id::text ORDER BY source_serial),'[]'::jsonb)::text FROM guild_invite_projection_sources WHERE recipient_player_id=$1`, recipient).Scan(&sources); e != nil {
		t.Fatal(e)
	}
	var idsRaw []string
	if e = json.Unmarshal([]byte(sources), &idsRaw); e != nil {
		t.Fatal(e)
	}
	consumed, noOp := 0, 0
	for _, raw := range idsRaw {
		sourceID, e := ids.ParseUUID(raw)
		if e != nil {
			t.Fatal(e)
		}
		source, e := reader.ReadIssueEvidenceTx(c, p, sourceID)
		if e != nil {
			t.Fatal(e)
		}
		applies, e := marker.AppliesTo(source)
		if e != nil || !applies {
			t.Fatal(applies, e)
		}
		before, e := service.Materialize(c, sourceID)
		if e != nil {
			t.Fatal(e)
		}
		n, ok, e := inbox.ReadNoticeEvidenceTx(c, p, identity.PlayerID(recipient), socialinbox.NoticeID(before.NoticeID))
		if e != nil || !ok {
			t.Fatal(n, e)
		}
		command := service
		if n.Active {
			command.Timed.Runner.DB = uncertainDB{Pool: p, Committed: true}
		}
		proof, e := command.Invalidate(c, marker.Operation.ID, sourceID)
		if e != nil || proof.Matches(marker, source) != nil {
			t.Fatal(proof, e)
		}
		if proof.Consumed {
			consumed++
		} else {
			noOp++
		}
		if again, e := service.Invalidate(c, marker.Operation.ID, sourceID); e != nil || again != proof {
			t.Fatal("cleanup replay changed proof/root/Notice", again, e)
		}
		closed, ok, e := inbox.ReadNoticeEvidenceTx(c, p, identity.PlayerID(recipient), socialinbox.NoticeID(proof.NoticeID))
		if e != nil || !ok || closed.Active || closed.StateVersion != proof.NoticeStateVersion {
			t.Fatal(closed, ok, e)
		}
		if replay, e := service.Materialize(c, sourceID); e != nil || replay != before {
			t.Fatal("cleanup caused materializer resurrection", replay, e)
		}
	}
	if consumed != 1 || noOp != 1 {
		t.Fatal("active/dismissed lifecycle cleanup counts", consumed, noOp)
	}
	var retiredMarker, retiredSource string
	if e = p.QueryRow(c, `SELECT m.marker_id::text,s.source_id::text FROM guild_invite_projection_markers m JOIN guild_invite_projection_sources s USING(guild_id) WHERE m.marker_kind='RETIRE' ORDER BY s.source_serial LIMIT 1`).Scan(&retiredMarker, &retiredSource); e != nil {
		t.Fatal(e)
	}
	rm, _ := ids.ParseUUID(retiredMarker)
	rs, _ := ids.ParseUUID(retiredSource)
	uncertain := service
	uncertain.Timed.Runner.DB = uncertainDB{Pool: p, Committed: false}
	_, e = uncertain.Invalidate(c, rm, rs)
	var unknown *tx.UnknownCommitError
	if !errors.As(e, &unknown) {
		t.Fatal("absent cleanup UNKNOWN granted replay", e)
	}
	if _, found, e := inbox.ReadInviteInvalidationTx(c, p, rm, rs); e != nil || found {
		t.Fatal("uncommitted cleanup became proof", found, e)
	}
	noNotice, e := service.Invalidate(c, rm, rs)
	if e != nil || noNotice.Consumed || noNotice.NoticeID != 0 {
		t.Fatal("retirement created a Notice", noNotice, e)
	}
	t.Log("WORKING_CLEANUP_ONLY: all-recipient JOIN scope, active consume and existing tombstone/no-op, positive/absent UNKNOWN, retirement/noNotice, replay no resurrection; no marker cursor ACK/frozen gate credit")
}
