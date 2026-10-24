//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/guildpolicybridge"
	"gxb.local/backend/v2/internal/adapters/guildviewread"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	fb "gxb.local/backend/v2/internal/application/profilefeedback"
	pp "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/content/guildpolicy"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

func feedback6C(p *pg.Pool) fb.Service {
	content := contentstore.Store{}
	r := tx.Runner{DB: p}
	return fb.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Reads: r, Fresh: p, Roots: fb.RootService{Store: profilefeedbackstore.Store{}}, Basic: pp.BasicReader{Roots: pp.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, PlayerBasis: i5store.Store{}, Relations: socialrelationstore.Store{}, Content: content}, Content: content, Receipts: kernelstore.Store{}, Recipients: i4store.PlayerRootLocker{}, Authors: i5store.Store{}, Display: service(p, p)}
}
func Test6CGuildRosterCanonicalNamesAndRetirement(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	display := service(p, p)
	exec(t, p, `UPDATE player_progression SET level=80 WHERE player_id=$1`, int64(a.PlayerID))
	artifact, e := guildpolicy.LoadBuiltin()
	if e != nil {
		t.Fatal(e)
	}
	binding, e := guildpolicybridge.FromBuiltin(artifact)
	if e != nil {
		t.Fatal(e)
	}
	cross := i5.CrossOwner{Store: i5store.Store{}}
	runner := tx.Runner{DB: p}
	core := guildcore.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Store: guildstore.Store{Queryer: p}, Fencer: i5store.Store{}, PlayerRoots: i4store.PlayerRootLocker{}, Level: cross, Scalar: cross, LevelAndScalar: cross, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Policy: binding}
	gop := func() operation.Context {
		o := op()
		o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
		return o
	}
	created, e := core.Create(ctx, a, guildcore.CreateRequest{Name: fmt.Sprintf("C6%d", a.PlayerID), Icon: binding.Policy.GuildIcons[0]}, gop())
	if e != nil {
		t.Fatal(e)
	}
	name := fmt.Sprintf("Lead%d", a.PlayerID)
	if _, e = display.Execute(ctx, a, app.Command{Kind: "rename", Name: name}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e = display.Execute(ctx, a, app.Command{Kind: "avatar", ID: 110001002, Icon: 10002004, Category: 1}, op()); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_directory_profiles SET name='oldleader',avatar_id=99,lev=1 WHERE player_id=$1`, int64(a.PlayerID))
	reader := guildviewread.Reader{Runner: runner}
	info, rows, e := reader.Members(ctx, a)
	if e != nil || info.GuildLeaderName != name || len(rows) != 1 || rows[0].Name != name || rows[0].Level != 80 || rows[0].AvatarID != 10002004 {
		t.Fatal(info, rows, e)
	}
	if _, e = core.Dissolve(ctx, a, gop()); e != nil {
		t.Fatal(e)
	}
	if _, ok, e := reader.Self(ctx, a); e != nil || ok {
		t.Fatal("retired Guild still visible", ok, e)
	}
	if created.GuildID <= 0 || guild.ID(created.GuildID) == 0 {
		t.Fatal(created)
	}
}

func Test6CFeedbackAuthorsUseCurrentEffectiveDisplay(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := actor(t, p), actor(t, p)
	s := feedback6C(p)
	comments := fb.CommentService{Base: s, Store: profilefeedbackstore.Store{}}
	if _, e := s.Execute(ctx, a, fb.Command{Target: b.PlayerID}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := comments.ExecuteComment(ctx, a, fb.CommentCommand{Kind: "post", Target: b.PlayerID, Content: "6Cauthor"}, op()); e != nil {
		t.Fatal(e)
	}
	display := service(p, p)
	if _, e := display.Execute(ctx, a, app.Command{Kind: "rename", Name: fmt.Sprintf("Author%d", a.PlayerID)}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := display.Execute(ctx, a, app.Command{Kind: "avatar", ID: 110001002, Icon: 10002004, Category: 1}, op()); e != nil {
		t.Fatal(e)
	}
	page, e := s.List(ctx, b, fb.PageRequest{Offset: 20}, op())
	if e != nil || len(page.Rows) != 1 || page.Rows[0].Author.Avatar != 10002004 {
		t.Fatal(page, e)
	}
	runner := tx.Runner{DB: p}
	_, e = runner.Run(ctx, op(), i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		at := time.Now().UTC()
		v, e := comments.ObserveCommentsTx(c, sc, b.PlayerID, a.PlayerID, rev, at, 0, 20, true)
		if e != nil {
			return e
		}
		if len(v.Best) != 1 || v.Best[0].Author.Avatar != 10002004 || v.Best[0].Author.Name != fmt.Sprintf("Author%d", a.PlayerID) {
			t.Fatal(v)
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
}
