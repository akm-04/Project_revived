//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	asset "gxb.local/backend/v2/internal/application/characterasset"
	app "gxb.local/backend/v2/internal/application/course"
	dorm "gxb.local/backend/v2/internal/application/dormhouse"
	gen "gxb.local/backend/v2/internal/application/generation"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

func courseService(p *pg.Pool, db tx.Beginner) app.Service {
	cs := contentstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p, StackUsage: dorm.FurnitureUsage{Owner: dormstore.Store{}, Content: cs}}
	runner := tx.Runner{DB: db}
	iv := i5.Service{Runner: runner, Store: values, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c2e-native-fixture-only-secret-000")}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Reads: tx.Runner{DB: p}, Heroes: characterstore.CourseHeroPort{Store: characterstore.Store{Queryer: p}}, Owner: coursestore.Store{}, Content: cs, Players: i4store.PlayerRootLocker{}, Fence: values, Costs: i5.MaterialCostDebiter{Store: values, Content: cs}, Values: values, Grants: iv, Exchange: iv, Receipts: kernelstore.Store{}, Privileges: i5.BaselinePrivilegeProvider{}}
}

func TestI7C2ECourseCoreQualifiedInputs(t *testing.T) {
	p := pool(t)
	a, rev, s := courseFixture(t, p)
	c, e := s.Content.CourseCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal("catalog", e)
	}
	r := courseRoot(t, p, a)
	if e = r.Facts.Validate(c); e != nil {
		t.Fatal("root", e)
	}
	f := courseFacts(t, p, a, 1)
	if e = f.Facts.Validate(c); e != nil {
		t.Fatal("facet", e)
	}
	if _, e = s.HeroCourseInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 1); e != nil {
		t.Fatal("inputs", e)
	}
}

// Canonical51 prerequisite fixture qualifies the Course conditional consumer, not the laterCampaign/Shop origin.
func courseFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, app.Service) {
	t.Helper()
	rev := installed(t, p)
	a := bornActor(t, p)
	for id := int64(1); id <= 3; id++ {
		bornHero(t, p, a, rev, 10001000+id, id)
	}
	s := courseService(p, p)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	lines := []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 10000000}}
	for _, id := range []int64{160600001, 160600002, 160600003, 50001420, 50001421, 50001422, 50001423} {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: id, Amount: 20})
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2e-fixture", Operation: "canonical-inputs", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: "fixture-v1"}, Lines: lines}
	if _, e = s.Grants.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_progression SET level=90,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_function_unlocks(player_id,function_id,source_fact_key,opened_at,state_version)VALUES($1,51,'i7c2e-explicit-qualified-function51',clock_timestamp()-interval '1 hour',1)`, int64(a.PlayerID))
	return a, rev, s
}
func courseCmd(t *testing.T, s app.Service, a identity.ActorContext, c app.Command) app.Result {
	t.Helper()
	r, e := s.Command(ctx, a, c, op())
	if e != nil {
		t.Fatal(c, e)
	}
	return r
}
func courseFacts(t *testing.T, p *pg.Pool, a identity.ActorContext, partner int64) course.HeroRoot {
	t.Helper()
	r, e := (coursestore.Store{}).ReadHeroTx(ctx, p, a.PlayerID, partner)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func courseRoot(t *testing.T, p *pg.Pool, a identity.ActorContext) course.Root {
	t.Helper()
	r, e := (coursestore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func TestI7C2ECourseLearnBindProficiencyForgetWire(t *testing.T) {
	p := pool(t)
	a, rev, s := courseFixture(t, p)
	o := op()
	c := app.Command{Family: app.Study, PartnerID: 1, CourseID: 100101}
	first, e := s.Command(ctx, a, c, o)
	if e != nil {
		t.Fatal(e)
	}
	again, e := s.Command(ctx, a, c, o)
	b1, _ := json.Marshal(first.Body)
	b2, _ := json.Marshal(again.Body)
	if e != nil || string(b1) != string(b2) || first.OperationID != again.OperationID || dormStack(t, p, a, 160600001) != 19 {
		t.Fatal("receipt", e)
	}
	courseCmd(t, s, a, c)
	if dormStack(t, p, a, 160600001) != 19 {
		t.Fatal("active duplicate charged")
	}
	if _, e = s.Command(ctx, a, app.Command{Family: app.Study, PartnerID: 1, CourseID: 100102}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("overwrote active", e)
	}
	if _, e = s.Command(ctx, a, app.Command{Family: app.Leave, PartnerID: 1}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("left running", e)
	}
	for i := 0; i < 5; i++ {
		courseCmd(t, s, a, app.Command{Family: app.Speed, PartnerID: 1, CourseID: 100101})
		if i < 4 {
			family := app.Continue
			if i == 0 {
				family = app.Study
			}
			courseCmd(t, s, a, app.Command{Family: family, PartnerID: 1, CourseID: 100101})
		}
	}
	r := courseFacts(t, p, a, 1)
	if r.Facts.Courses[0].Progress != 100 || dormStack(t, p, a, 160600001) != 19 {
		t.Fatal("progress/resume/ticket", r)
	}
	courseCmd(t, s, a, app.Command{Family: app.Bind, PartnerID: 1, CourseID: 100101, SkillID: 1})
	scope := app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}
	v, e := s.HeroCourseInputsTx(ctx, p, scope, 1)
	if e != nil || len(v.AppliedCourses) != 1 || v.AppliedCourses[0].Skill != 1 || v.Inputs.Catalog.Metadata(100101)["step_up"] != "25.5" {
		t.Fatal("rawboundprovider", e, v)
	}
	for _, pair := range [][2]int64{{50001423, 1}, {50001422, 1}, {50001421, 4}} {
		courseCmd(t, s, a, app.Command{Family: app.Proficiency, PartnerID: 1, CourseID: 100101, ItemID: pair[0], Amount: pair[1], Total: dormStack(t, p, a, pair[0])})
	}
	r = courseFacts(t, p, a, 1)
	if r.Facts.Courses[0].EXP != 1680 || r.Facts.Courses[0].Quality != 6 {
		t.Fatal("wholebookcap", r)
	}
	stock := dormStack(t, p, a, 50001420)
	if _, e = s.Command(ctx, a, app.Command{Family: app.Proficiency, PartnerID: 1, CourseID: 100101, ItemID: 50001420, Amount: 1, Total: stock}, op()); !errors.Is(e, app.ErrRejected) || dormStack(t, p, a, 50001420) != stock {
		t.Fatal("capped consumed", e)
	}
	before := libraryAmount(t, p, a, "crystal")
	b22, b21 := dormStack(t, p, a, 50001422), dormStack(t, p, a, 50001421)
	out := courseCmd(t, s, a, app.Command{Family: app.Forget, PartnerID: 1, CourseID: 100101})
	if libraryAmount(t, p, a, "crystal") != before-200 || dormStack(t, p, a, 50001422) != b22+3 || dormStack(t, p, a, 50001421) != b21+2 || len(courseFacts(t, p, a, 1).Facts.Courses) != 0 || len(out.Body["return_items"].([]any)) != 2 {
		t.Fatal("forget exchange", out)
	}
	wire, e := s.Read(ctx, a, 2130, op())
	if e != nil || wire["log_infos"] == nil {
		t.Fatal("roomlogs", e)
	}
	rows := map[string]any{"heros": map[string]any{"1": map[string]any{}}}
	if e = s.OverlayRosterTx(ctx, p, a, rev, time.Now().UTC(), rows); e != nil {
		t.Fatal(e)
	}
	for _, k := range []string{"courses", "courses_progress", "courses_skill", "courses_quality", "courses_exp"} {
		if len(rows["heros"].(map[string]any)["1"].(map[string]any)[k].([]int64)) != 0 {
			t.Fatal("reload", rows)
		}
	}
}
func TestI7C2ECourseCapacityCancelReferenceAndRollback(t *testing.T) {
	p := pool(t)
	a, _, s := courseFixture(t, p)
	for _, id := range []int64{1, 2} {
		courseCmd(t, s, a, app.Command{Family: app.Enter, PartnerID: id})
	}
	if _, e := s.Command(ctx, a, app.Command{Family: app.Enter, PartnerID: 3}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("capacity", e)
	}
	ref := skillRead(t, p, a, 1).Ref()
	guard := coursestore.Store{}
	plan, e := guard.PreflightHeroRemovalTx(ctx, p, ref)
	if e != nil || len(plan.Locks) != 1 {
		t.Fatal("stableguard", e)
	}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = guard.LockReferenceGuardKeyTx(ctx, tr, plan.Locks[0]); e != nil {
		t.Fatal(e)
	}
	if e = guard.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); !errors.Is(e, asset.ErrReferenceInUse) {
		t.Fatal("idle attendance guard", e)
	}
	tr.Rollback(ctx)
	courseCmd(t, s, a, app.Command{Family: app.Leave, PartnerID: 1})
	courseCmd(t, s, a, app.Command{Family: app.Enter, PartnerID: 3})
	courseCmd(t, s, a, app.Command{Family: app.Study, PartnerID: 2, CourseID: 100101})
	courseCmd(t, s, a, app.Command{Family: app.Cancel, PartnerID: 2})
	if courseFacts(t, p, a, 2).Facts.Courses[0].Progress != 0 || dormStack(t, p, a, 160600001) != 19 {
		t.Fatal("partial/refund")
	}
	stock := dormStack(t, p, a, 160600002)
	exec(t, p, `UPDATE player_item_stacks SET quantity=0 WHERE player_id=$1 AND item_id=160600002`, int64(a.PlayerID))
	if _, e = s.Command(ctx, a, app.Command{Family: app.Study, PartnerID: 1, CourseID: 100201}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("insufficiency", e)
	}
	if len(courseFacts(t, p, a, 1).Facts.Courses) != 0 || len(courseRoot(t, p, a).Facts.Attendance) != 1 {
		t.Fatal("partial ownereffect")
	}
	_ = stock
}
func TestI7C2ECourseUnknownCommitAndActor(t *testing.T) {
	p := pool(t)
	for _, committed := range []bool{true, false} {
		a, _, _ := courseFixture(t, p)
		s := courseService(p, &libraryFaultDB{Beginner: p, commit: committed})
		o := op()
		c := app.Command{Family: app.Apply, PartnerID: 1, CourseID: 100101}
		_, e := s.Command(ctx, a, c, o)
		if committed {
			if e != nil || dormStack(t, p, a, 160600001) != 19 {
				t.Fatal("positiveproof", e)
			}
		} else if e == nil || dormStack(t, p, a, 160600001) != 20 || len(courseFacts(t, p, a, 1).Facts.Courses) != 0 {
			t.Fatal("unknownrollback", e)
		}
		r, e := courseService(p, p).Command(ctx, a, c, o)
		if e != nil || r.OperationID != o.ID || dormStack(t, p, a, 160600001) != 19 {
			t.Fatal("recovery", e)
		}
	}
	a, _, s := courseFixture(t, p)
	exec(t, p, `UPDATE gameplay_contexts SET liveness_version=liveness_version+1 WHERE context_id=$1`, a.ContextID.UUID().String())
	if _, e := s.Command(ctx, a, app.Command{Family: app.Apply, PartnerID: 1, CourseID: 100101}, op()); e == nil || dormStack(t, p, a, 160600001) != 20 {
		t.Fatal("revokedactor", e)
	}
}

type courseInstant struct{ at time.Time }

func (c courseInstant) Now(context.Context) (time.Time, error) { return c.at, nil }
func TestI7C2ECourseDeadlinePureDueAndCancelOnce(t *testing.T) {
	p := pool(t)
	a, rev, s := courseFixture(t, p)
	courseCmd(t, s, a, app.Command{Family: app.Study, PartnerID: 1, CourseID: 100101})
	root := courseRoot(t, p, a)
	end := root.Facts.Attendance[1].Job.StartedAt.Add(8 * time.Hour)
	v, e := s.HeroCourseInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: end.Add(80 * time.Hour)}, 1)
	if e != nil || !v.MaterializationDue || v.Stored.Courses[0].Progress != 0 || v.Applied.Courses[0].Progress != 20 || courseRoot(t, p, a).Version != root.Version {
		t.Fatal("purefinite", e, v)
	}
	s.Timed.Binder.Time = courseInstant{end}
	courseCmd(t, s, a, app.Command{Family: app.Cancel, PartnerID: 1})
	if courseFacts(t, p, a, 1).Facts.Courses[0].Progress != 20 || len(courseRoot(t, p, a).Facts.Attendance) != 0 {
		t.Fatal("duecancel")
	}
	s.Timed.Binder.Time = courseInstant{end.Add(time.Second)}
	courseCmd(t, s, a, app.Command{Family: app.Cancel, PartnerID: 1})
	if courseFacts(t, p, a, 1).Facts.Courses[0].Progress != 20 {
		t.Fatal("double")
	}
}
func TestI7C2ECourseConcurrentAdmissionAndTransitions(t *testing.T) {
	p := pool(t)
	a, _, s := courseFixture(t, p)
	var wg sync.WaitGroup
	errs := make(chan error, 20)
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.Command(context.Background(), a, app.Command{Family: app.Study, PartnerID: 1, CourseID: 100101}, op())
			errs <- e
		}()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil && !errors.Is(e, app.ErrRejected) && !errors.Is(e, app.ErrStale) {
			t.Fatal("admissionrace", e)
		}
	}
	if dormStack(t, p, a, 160600001) != 19 || len(courseRoot(t, p, a).Facts.Attendance) != 1 {
		t.Fatal("concurrentdoublecharge")
	}
	commands := []app.Command{{Family: app.Speed, PartnerID: 1, CourseID: 100101}, {Family: app.Cancel, PartnerID: 1}, {Family: app.Leave, PartnerID: 1}, {Family: app.Collect, PartnerID: 1}}
	errs = make(chan error, len(commands))
	for _, c := range commands {
		wg.Add(1)
		go func(c app.Command) { defer wg.Done(); _, e := s.Command(context.Background(), a, c, op()); errs <- e }(c)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil && !errors.Is(e, app.ErrRejected) && !errors.Is(e, app.ErrStale) {
			t.Fatal("transitionrace", e)
		}
	}
	f := courseFacts(t, p, a, 1).Facts
	if f.Courses[0].Progress != 0 && f.Courses[0].Progress != 20 {
		t.Fatal("raceprogress", f)
	}
	if len(courseRoot(t, p, a).Facts.Attendance) > 1 || dormStack(t, p, a, 160600001) != 19 {
		t.Fatal("raceattendance")
	}
}

var _ operation.Context

func TestI7C2ECourseSuperSlotsAndMissingPrerequisite(t *testing.T) {
	p := pool(t)
	a, rev, svc := courseFixture(t, p)
	h := skillHero(t, p, a, rev, 11001, 4)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (coursestore.Store{}).InitFreshHeroTx(ctx, tr, h.Ref(), time.Now().Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	v, e := svc.HeroCourseInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 4)
	if e != nil || v.Hero.Kind != character.SuperHero || !v.Eligibility[3] || v.Eligibility[4] {
		t.Fatal("Superqualifiedslots", v, e)
	}
	courseCmd(t, svc, a, app.Command{Family: app.Study, PartnerID: 4, CourseID: 100101})
	for i := 0; i < 5; i++ {
		courseCmd(t, svc, a, app.Command{Family: app.Speed, PartnerID: 4, CourseID: 100101})
		if i < 4 {
			courseCmd(t, svc, a, app.Command{Family: app.Continue, PartnerID: 4, CourseID: 100101})
		}
	}
	courseCmd(t, svc, a, app.Command{Family: app.Bind, PartnerID: 4, CourseID: 100101, SkillID: 4})
	if _, e = svc.Command(ctx, a, app.Command{Family: app.Bind, PartnerID: 4, CourseID: 100101, SkillID: 5}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("closedslot", e)
	}
	v, e = svc.HeroCourseInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 4)
	if e != nil || len(v.AppliedCourses) != 1 || v.AppliedCourses[0].Skill != 4 {
		t.Fatal("Super applied", v, e)
	}
	body := map[string]any{"heros": map[string]any{"4": map[string]any{}}}
	if e = svc.OverlayRosterTx(ctx, p, a, rev, time.Now().UTC(), body); e != nil {
		t.Fatal(e)
	}
	row := body["heros"].(map[string]any)["4"].(map[string]any)
	if row["courses_skill"].([]int64)[0] != 4 {
		t.Fatal("Superreload", row)
	}
	exec(t, p, `DELETE FROM player_function_unlocks WHERE player_id=$1 AND function_id=51`, int64(a.PlayerID))
	before := dormStack(t, p, a, 160600002)
	if _, e = svc.Command(ctx, a, app.Command{Family: app.Apply, PartnerID: 4, CourseID: 100201}, op()); !errors.Is(e, app.ErrRejected) || dormStack(t, p, a, 160600002) != before {
		t.Fatal("no inferredunlock", e)
	}
}
func TestI7C2ECourseForgetOverflowUsesI5Policy(t *testing.T) {
	p := pool(t)
	a, rev, s := courseFixture(t, p)
	courseCmd(t, s, a, app.Command{Family: app.Study, PartnerID: 1, CourseID: 100101})
	for i := 0; i < 5; i++ {
		courseCmd(t, s, a, app.Command{Family: app.Speed, PartnerID: 1, CourseID: 100101})
		if i < 4 {
			courseCmd(t, s, a, app.Command{Family: app.Continue, PartnerID: 1, CourseID: 100101})
		}
	}
	courseCmd(t, s, a, app.Command{Family: app.Proficiency, PartnerID: 1, CourseID: 100101, ItemID: 50001421, Amount: 2, Total: 20})
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2e-fixture", Operation: "cap-stock", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: "fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 50001421, Amount: 981}}}
	if _, e = s.Grants.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	before := libraryAmount(t, p, a, "crystal")
	r := courseCmd(t, s, a, app.Command{Family: app.Forget, PartnerID: 1, CourseID: 100101})
	if dormStack(t, p, a, 50001421) != 999 || libraryAmount(t, p, a, "crystal") != before-200 || len(r.Body["return_items"].([]any)) != 0 || len(courseFacts(t, p, a, 1).Facts.Courses) != 0 {
		t.Fatal("inline duplicate orcaploss", r)
	}
	var count int64
	if e = p.QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID)).Scan(&count); e != nil || count != 1 {
		t.Fatal("qualifiedoverflowmail", count, e)
	}
}

// Existing guard seam under real owner prefix locks. DELETE is an explicit
// conditional Character-owner fixture, not a claim of a new retirement route.
func TestI7C2ECourseJoinVersusConditionalRetirement(t *testing.T) {
	p := pool(t)
	for i := 0; i < 8; i++ {
		a, _, s := courseFixture(t, p)
		ref := skillRead(t, p, a, 1).Ref()
		guard := coursestore.Store{}
		plan, e := guard.PreflightHeroRemovalTx(ctx, p, ref)
		if e != nil || len(plan.Locks) != 1 {
			t.Fatal(e)
		}
		errs := make(chan error, 2)
		go func() {
			_, e := s.Command(context.Background(), a, app.Command{Family: app.Enter, PartnerID: 1}, op())
			errs <- e
		}()
		go func() {
			tr, e := p.Begin(context.Background(), tx.Options{Isolation: tx.ReadCommitted})
			if e != nil {
				errs <- e
				return
			}
			defer tr.Rollback(context.Background())
			hs := characterstore.Store{}
			r, e := hs.LockRootTx(context.Background(), tr, a.PlayerID)
			if e != nil {
				errs <- e
				return
			}
			h, e := hs.LockHeroByPartnerIDTx(context.Background(), tr, a.PlayerID, 1)
			if e != nil {
				errs <- e
				return
			}
			if e = guard.LockReferenceGuardKeyTx(context.Background(), tr, plan.Locks[0]); e != nil {
				errs <- e
				return
			}
			if e = guard.ValidateHeroRemovalLockedTx(context.Background(), tr, h.Ref(), plan); e != nil {
				errs <- e
				return
			}
			if _, e = tr.Exec(context.Background(), `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID)); e != nil {
				errs <- e
				return
			}
			old := r.StateVersion
			r.StateVersion++
			r.UpdatedAt = time.Now().UTC()
			if e = hs.SaveRootAllocatorTx(context.Background(), tr, r, old); e != nil {
				errs <- e
				return
			}
			errs <- tr.Commit(context.Background())
		}()
		for n := 0; n < 2; n++ {
			e := <-errs
			if e != nil && !errors.Is(e, app.ErrRetired) && !errors.Is(e, app.ErrRejected) && !errors.Is(e, app.ErrStale) && !errors.Is(e, asset.ErrReferenceInUse) {
				t.Fatal("retire race", e)
			}
		}
		root := courseRoot(t, p, a)
		alive, readErr := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, a.PlayerID, 1)
		_, present := root.Facts.Attendance[1]
		if present && (readErr != nil || alive.PartnerID != 1) {
			t.Fatal("dangling canonicalattendance")
		}
		if readErr != nil {
			if _, e = s.HeroCourseInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: root.Revision, ObservedAt: time.Now().UTC()}, 1); !errors.Is(e, app.ErrRetired) {
				t.Fatal("retiredfacetqualified", e)
			}
		}
	}
}

func TestI7C2ECourseCallerSnapshotAndDormIndependence(t *testing.T) {
	p := pool(t)
	a, rev, svc := courseFixture(t, p)
	courseCmd(t, svc, a, app.Command{Family: app.Apply, PartnerID: 1, CourseID: 100101})
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	scope := app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}
	before, e := svc.HeroCourseInputsTx(ctx, tr, scope, 1)
	if e != nil {
		t.Fatal(e)
	}
	courseCmd(t, svc, a, app.Command{Family: app.Study, PartnerID: 1, CourseID: 100101})
	courseCmd(t, svc, a, app.Command{Family: app.Speed, PartnerID: 1, CourseID: 100101})
	after, e := svc.HeroCourseInputsTx(ctx, tr, scope, 1)
	if e != nil || before.FacetVersion != after.FacetVersion || before.Inputs.Root.Version != after.Inputs.Root.Version || after.Applied.Courses[0].Progress != 0 {
		t.Fatal("mixedsnapshot", after, e)
	}
	tr.Rollback(ctx)
	current, e := svc.HeroCourseInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, 1)
	if e != nil || current.Applied.Courses[0].Progress != 20 {
		t.Fatal("new snapshot", e)
	}
	h := skillRead(t, p, a, 1)
	exec(t, p, `INSERT INTO player_function_unlocks(player_id,function_id,source_fact_key,opened_at,state_version)VALUES($1,71,'i7c2e-explicit-Dorm-prerequisite',clock_timestamp()-interval '1 hour',1)`, int64(a.PlayerID))
	dormCommand(t, dormService(p, p), a, dorm.Command{Family: dorm.Enter, Partners: []int64{1}, HouseID: 1})
	courseCmd(t, svc, a, app.Command{Family: app.Enter, PartnerID: 1})
	df, e := (dormstore.Store{}).ReadHeroTx(ctx, p, h.Ref())
	if e != nil || df.HouseID != 1 || courseRoot(t, p, a).Facts.Attendance[1].PartnerID != 1 {
		t.Fatal("duplicatedbusyfact", df, e)
	}
}
