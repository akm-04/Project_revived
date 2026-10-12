//go:build postgres && river

package publicshowcase_test

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
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
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

func Test6BGuildCurrentMembershipAndInviteSource(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := profileActor(t, p), profileActor(t, p)
	runner := tx.Runner{DB: p}
	content := contentstore.Store{}
	bundle, e := guildinvitebundle.Prepare(ctx, p, runner, rev)
	if e != nil {
		t.Fatal(e)
	}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		t.Fatal(e)
	}
	store := guildstore.Store{Queryer: p}
	kernel := kernelstore.Store{}
	source := app.SourceService{Reads: runner, Store: guildinvitestore.Store{}, Bindings: store, History: kernel, Reader: bundle.Source, Content: content, Queryer: p, Enqueue: queue}
	artifact, e := guildpolicy.LoadBuiltin()
	if e != nil {
		t.Fatal(e)
	}
	binding, e := guildpolicybridge.FromBuiltin(artifact)
	if e != nil {
		t.Fatal(e)
	}
	cross := i5.CrossOwner{Store: i5store.Store{}}
	core := guildcore.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: fixedTime{at.Add(2 * time.Second)}}, Runner: runner}, Store: store, Fencer: i5store.Store{}, PlayerRoots: i4store.PlayerRootLocker{}, Level: cross, Scalar: cross, LevelAndScalar: cross, Receipts: kernel, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding, InviteProjection: &source}
	for _, a := range []identity.ActorContext{a, b} {
		sqlExec(t, p, `UPDATE player_progression SET level=80 WHERE player_id=$1`, int64(a.PlayerID))
		sqlExec(t, p, `INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,clock_timestamp())`, int64(a.PlayerID))
		sqlExec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',10000,1,clock_timestamp())`, int64(a.PlayerID))
	}
	gop := func() operation.Context {
		o := op()
		o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
		return o
	}
	created, e := core.Create(ctx, a, guildcore.CreateRequest{Name: fmt.Sprintf("B6%d", a.PlayerID), Icon: binding.Policy.GuildIcons[0]}, gop())
	if e != nil {
		t.Fatal(e)
	}
	issue := gop()
	if _, e = core.Invite(ctx, a, b.PlayerID, issue); e != nil {
		t.Fatal(e)
	}
	saved, e := bundle.Source.ReadIssueEvidenceTx(ctx, p, issue.ID)
	if e != nil {
		t.Fatal(e)
	}
	view := guildcore.PublicViewReader{Store: store, Invites: bundle.Source}
	read := func(target identity.PlayerID, at time.Time) (guildcore.PublicView, error) {
		var v guildcore.PublicView
		_, e := runner.Run(ctx, gop(), prof(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
			var e error
			v, e = view.ReadPublicGuildTx(c, sc, a.PlayerID, target, rev, at)
			return e
		})
		return v, e
	}
	v, e := read(b.PlayerID, saved.DecisionAt)
	if e != nil || v.InviteTime != saved.DecisionAt.Unix() || v.GuildID != 0 {
		t.Fatal("validsource", v, e)
	}
	v, e = read(b.PlayerID, saved.ExpiresAt)
	if e != nil || v.InviteTime != 0 {
		t.Fatal("strict expiry", v, e)
	}
	v, e = read(a.PlayerID, saved.DecisionAt)
	if e != nil || v.GuildID != guild.ID(created.GuildID) || v.Role != guild.Leader || v.GuildVersion <= 0 {
		t.Fatal("member view", v, e)
	}
	view.Invites = nil
	if _, e = read(b.PlayerID, saved.DecisionAt); e == nil {
		t.Fatal("missingrequiredsource fabricatedabsence")
	}
	view.Invites = bundle.Source
	core.Timed.Binder.Time = fixedTime{saved.DecisionAt.Add(time.Second)}
	if _, e = core.AcceptInvite(ctx, b, guild.ID(created.GuildID), gop()); e != nil {
		t.Fatal(e)
	}
	v, e = read(b.PlayerID, saved.DecisionAt.Add(2*time.Second))
	if e != nil || v.InviteTime != 0 || v.GuildID != guild.ID(created.GuildID) || v.Role != guild.Member {
		t.Fatal("JOIN notcurrentinvite", v, e)
	}
	core.Timed.Binder.Time = fixedTime{saved.DecisionAt.Add(3 * time.Second)}
	if _, e = core.Leave(ctx, b, gop()); e != nil {
		t.Fatal(e)
	}
	core.Timed.Binder.Time = fixedTime{saved.DecisionAt.Add(4 * time.Second)}
	if _, e = core.Dissolve(ctx, a, gop()); e != nil {
		t.Fatal(e)
	}
	v, e = read(b.PlayerID, saved.DecisionAt.Add(5*time.Second))
	if e != nil || v.GuildID != 0 || v.InviteTime != 0 {
		t.Fatal("retirement view", v, e)
	}
}
