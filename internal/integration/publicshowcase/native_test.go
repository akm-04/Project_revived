//go:build postgres

package publicshowcase_test

import (
	"context"
	"encoding/json"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	characterstore "gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	contentstore "gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	i4store "gxb.local/backend/v2/internal/adapters/postgres/i4store"
	i5store "gxb.local/backend/v2/internal/adapters/postgres/i5store"
	kernelstore "gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	publicprofilestore "gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	socialrelationstore "gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	stockruntime "gxb.local/backend/v2/internal/adapters/stockruntime"
	characterasset "gxb.local/backend/v2/internal/application/characterasset"
	characterhero "gxb.local/backend/v2/internal/application/characterhero"
	characterpet "gxb.local/backend/v2/internal/application/characterpet"
	charactersavedpreset "gxb.local/backend/v2/internal/application/charactersavedpreset"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	builtin "gxb.local/backend/v2/internal/content/builtin"
	registry "gxb.local/backend/v2/internal/content/registry"
	character "gxb.local/backend/v2/internal/domain/character"
	identity "gxb.local/backend/v2/internal/domain/identity"
	dom "gxb.local/backend/v2/internal/domain/profile"
	clock "gxb.local/backend/v2/internal/foundation/clock"
	ids "gxb.local/backend/v2/internal/foundation/ids"
	lockkey "gxb.local/backend/v2/internal/foundation/lockkey"
	operation "gxb.local/backend/v2/internal/foundation/operation"
	policy "gxb.local/backend/v2/internal/foundation/policy"
	receipt "gxb.local/backend/v2/internal/foundation/receipt"
	tx "gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

var ctx = context.Background()
var at = time.Now().UTC()

func pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I7B3A_DSN")
	if dsn == "" {
		t.Fatal("required exact native DSN missing")
	}
	p, e := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 16, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(p.Close)
	return p
}
func uuid() ids.UUID {
	u, e := ids.NewUUID()
	if e != nil {
		panic(e)
	}
	return u
}
func op() operation.Context {
	ps, _ := policy.NewSet(policy.Ref{Name: "profile", Version: dom.PolicyVersion})
	o, e := (operation.Factory{Clock: clock.System{}}).New(ps)
	if e != nil {
		panic(e)
	}
	return o
}
func prof() tx.Profile {
	return tx.Profile{Name: "I7B2B_NATIVE", AcquireTimeout: 5 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 15 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 40 * time.Second}
}
func actor(t *testing.T, p *pg.Pool) identity.ActorContext {
	t.Helper()
	a, s, g := uuid(), uuid(), uuid()
	var pid int64
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	e = tr.QueryRow(ctx, `UPDATE logical_servers SET next_player_id=next_player_id+1 WHERE logical_server_id=1 RETURNING next_player_id-1`).Scan(&pid)
	if e != nil {
		t.Fatal(e)
	}
	rows := []struct {
		s string
		a []any
	}{
		{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{a.String(), a.String()}},
		{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'i7b2b-native')`, []any{pid, a.String()}},
		{`INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,'i7b2b-native',$3,$3)`, []any{s.String(), a.String(), at.Add(-time.Hour)}},
		{`INSERT INTO gameplay_contexts(context_id,session_id,account_id,logical_server_id,player_id,context_generation,created_at)VALUES($1,$2,$3,1,$4,1,clock_timestamp())`, []any{g.String(), s.String(), a.String(), pid}},
		{`INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'basis',1,0,0,1,$2::timestamptz-interval '1 day',$2)`, []any{pid, at}},
		{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,1,0,1,$2)`, []any{pid, at}},
	}
	for _, r := range rows {
		if _, e = tr.Exec(ctx, r.s, r.a...); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	aid, _ := identity.AccountIDFrom(a)
	sid, _ := identity.SessionIDFrom(s)
	cid, _ := identity.ContextIDFrom(g)
	return identity.ActorContext{AccountID: aid, AccountUID: identity.AccountUID(a.String()), SessionID: sid, ContextID: cid, LogicalServerID: 1, PlayerID: identity.PlayerID(pid), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func sqlExec(t *testing.T, p *pg.Pool, s string, args ...any) {
	t.Helper()
	if _, e := p.Raw().Exec(ctx, s, args...); e != nil {
		t.Fatal(e)
	}
}
func installed(t *testing.T, p *pg.Pool) string {
	t.Helper()
	b, e := registry.LoadBuiltinBundle()
	if e != nil {
		t.Fatal(e)
	}
	r := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	if os.Getenv("GXB_I7B3A_RESTORED") != "1" && os.Getenv("GXB_I7B3A_CHILD") == "" {
		if _, e = r.EnsureBuiltinInstalled(ctx, op(), b); e != nil {
			t.Fatal(e)
		}
		if _, e = r.BootstrapActivationIfMissing(ctx, op(), b); e != nil {
			t.Fatal(e)
		}
	}
	rev, e := (contentstore.Store{}).ActiveRevision(ctx, p)
	if e != nil || rev != b.RevisionID() {
		t.Fatalf("retainedactive policy missing %s %v", rev, e)
	}
	if _, e = (contentstore.Store{}).ReadPublicProfilePolicy(ctx, p, rev); e != nil {
		t.Fatal(e)
	}
	return rev
}
func service(p *pg.Pool, db tx.Beginner) app.CommandService {
	return app.CommandService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Fresh: p, Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}, Metrics: app.CanonicalCreationMetricProvider{Players: i5store.Store{}}}
}
func assign(t *testing.T, p *pg.Pool, a identity.ActorContext, q app.Command, o operation.Context) app.CommandResult {
	t.Helper()
	r, e := service(p, p).Execute(ctx, a, q, o)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func root(t *testing.T, p *pg.Pool, pid identity.PlayerID) (app.Root, bool) {
	t.Helper()
	r, ok, e := (publicprofilestore.Store{}).ReadRootTx(ctx, p, pid)
	if e != nil {
		t.Fatal(e)
	}
	return r, ok
}

type faultDB struct {
	tx.Beginner
	commit bool
}
type faultTx struct {
	tx.Tx
	commit bool
}

func (d faultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	return faultTx{t, d.commit}, e
}
func (t faultTx) Commit(c context.Context) error {
	if t.commit {
		if e := t.Tx.Commit(c); e != nil {
			return e
		}
	} else {
		_ = t.Tx.Rollback(c)
	}
	return errors.New("injected commit ACK loss")
}

type abortOnceDB struct {
	tx.Beginner
	first atomic.Bool
}
type abortOnceTx struct {
	tx.Tx
	db *abortOnceDB
}

func (d *abortOnceDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	return abortOnceTx{t, d}, e
}
func (t abortOnceTx) Commit(c context.Context) error {
	if !t.db.first.Swap(true) {
		_, e := t.Tx.Exec(c, `DO $$ BEGIN RAISE EXCEPTION 'native definite abort' USING ERRCODE='40001'; END $$`)
		return e
	}
	return t.Tx.Commit(c)
}

type bases struct {
	characterhero.BaseObservationReader
	Pet characterpet.BaseObservationReader
}

func (b bases) PetBaseObservationTx(c context.Context, q tx.Queryer, pid identity.PlayerID, id int64) (characterasset.PetBaseObservation, error) {
	return b.Pet.PetBaseObservationTx(c, q, pid, id)
}
func baseReaders() bases {
	return bases{characterhero.BaseObservationReader{Store: characterstore.Store{}, Content: contentstore.Store{}}, characterpet.BaseObservationReader{Store: characterstore.Store{}}}
}
func showcase(p *pg.Pool, db tx.Beginner) app.ShowcaseAssignmentService {
	return app.ShowcaseAssignmentService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Fresh: p, Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}, Slots: publicprofilestore.Store{}, References: characterstore.Store{}, Bases: baseReaders()}
}
func selection(t *testing.T, p *pg.Pool, pid identity.PlayerID) app.Selection {
	t.Helper()
	s, e := (publicprofilestore.Store{}).ReadSelectionTx(ctx, p, pid)
	if e != nil {
		t.Fatal(e)
	}
	return s
}
func set(t *testing.T, p *pg.Pool, a identity.ActorContext, q app.Selection, o operation.Context) app.ShowcaseResult {
	t.Helper()
	r, e := showcase(p, p).Execute(ctx, a, q, o)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func assets(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string) {
	t.Helper()
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if _, e = tr.Exec(ctx, `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,4,0,1,$2,$2)`, int64(a.PlayerID), at); e != nil {
		t.Fatal(e)
	}
	if _, e = tr.Exec(ctx, `INSERT INTO player_pet_roots(player_id,next_pet_id,first_free_hatch_used,state_version,created_at,updated_at)VALUES($1,2,false,1,$2,$2)`, int64(a.PlayerID), at); e != nil {
		t.Fatal(e)
	}
	c, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	// Native fixture setup only. Source owner adapters insert canonical assets.
	heroIDs := []int64{}
	for _, h := range c.HeroCore.Templates {
		if h.InitialStar == 1 && h.HeroKind == "NORMAL" && len(heroIDs) < 3 {
			heroIDs = append(heroIDs, h.TableID)
		}
	}
	if len(heroIDs) != 3 {
		t.Fatal("hero fixture candidates missing")
	}
	for i, id := range []int64{heroIDs[0], heroIDs[1], heroIDs[0]} {
		h := character.Hero{PlayerID: a.PlayerID, PartnerID: int64(i + 1), TableID: id, OriginTableID: heroIDs[i], Star: 1, Level: 1, Color: 1, CreationContentRevision: rev, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
		if e = (characterstore.Store{}).InsertHeroTx(ctx, tr, h); e != nil {
			t.Fatal(e)
		}
	}
	petID := c.PetCore.Templates[0].TableID
	petStar := c.PetCore.Templates[0].InitialStar
	pet := character.Pet{PlayerID: a.PlayerID, PetID: 1, TableID: petID, OriginTableID: petID, Star: petStar, Level: 1, Color: 1, Skills: character.DefaultPetSkillLevels(), CreationContentRevision: rev, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	if e = (characterstore.Store{}).InsertPetTx(ctx, tr, pet); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}
func guard(a identity.ActorContext) app.PublicProfileReferenceGuard {
	return app.PublicProfileReferenceGuard{Store: publicprofilestore.Store{}, Roots: publicprofilestore.Store{}, Players: i4store.PlayerRootLocker{}, PlayerID: a.PlayerID, Server: a.LogicalServerID}
}
func reader() app.ShowcaseReader {
	b := baseReaders()
	return app.ShowcaseReader{Slots: publicprofilestore.Store{}, Content: contentstore.Store{}, Basic: app.BasicReader{Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, PlayerBasis: i5store.Store{}, Relations: socialrelationstore.Store{}, Content: contentstore.Store{}}, Characters: characterasset.PublicShowcaseCharacterReader{OwnerComposite: &characterasset.OwnedCompositeBuilder{HeroBase: b, PetBase: b}}}
}
func TestSlotsValidationNoopsAndHistoricalReplay(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	if r := set(t, p, a, app.Selection{}, op()); r.RootVersion != 0 || r.Changed {
		t.Fatal("empty materialized")
	}
	if _, ok := root(t, p, a.PlayerID); ok {
		t.Fatal("root created")
	}
	pref := assign(t, p, a, app.Command{Kind: app.IntroCommand, Intro: "preserved"}, op())
	q := app.Selection{1, 0, -1, 0, 0, 2}
	o := op()
	first := set(t, p, a, q, o)
	if first.RootVersion != pref.RootVersion+1 || !first.Changed || selection(t, p, a.PlayerID) != q {
		t.Fatal("slots/version")
	}
	r, _ := root(t, p, a.PlayerID)
	if r.Preferences.Intro != "preserved" {
		t.Fatal("prefs lost")
	}
	if n := set(t, p, a, q, op()); n.Changed || n.RootVersion != first.RootVersion {
		t.Fatal("noop touched")
	}
	var count int
	if e := p.QueryRow(ctx, `SELECT count(*) FROM player_public_profile_showcase_slots WHERE player_id=$1`, int64(a.PlayerID)).Scan(&count); e != nil || count != 3 {
		t.Fatal("not sparse", count, e)
	}
	for _, bad := range []app.Selection{{1, 3}, {1, 1}, {999}, {-999}, {9007199254740992}, {-9007199254740992}} {
		if got, e := showcase(p, p).Execute(ctx, a, bad, op()); e == nil || got.Schema != "" {
			t.Fatal("bad ref admitted", bad, e)
		}
		if selection(t, p, a.PlayerID) != q {
			t.Fatal("partial write")
		}
	}
	b := actor(t, p)
	assets(t, p, b, rev)
	sqlExec(t, p, `UPDATE player_heroes SET partner_id=99 WHERE player_id=$1 AND partner_id=2`, int64(b.PlayerID))
	if _, e := showcase(p, p).Execute(ctx, a, app.Selection{99}, op()); e == nil {
		t.Fatal("foreign instance")
	}
	newer := set(t, p, a, app.Selection{2}, op())
	again := set(t, p, a, q, o)
	if again != first || selection(t, p, a.PlayerID) != newer.Selection {
		t.Fatal("replay reapplied")
	}
	if got, e := showcase(p, p).Execute(ctx, a, app.Selection{2}, o); !errors.Is(e, app.ErrConflict) || got.Schema != "" {
		t.Fatal("proof conflict", e)
	}
	clear := set(t, p, a, app.Selection{}, op())
	if !clear.Changed {
		t.Fatal("clear noop")
	}
	r, ok := root(t, p, a.PlayerID)
	if !ok || r.Preferences.Intro != "preserved" || r.StateVersion != clear.RootVersion {
		t.Fatal("clear removed root")
	}
}
func TestStrictWireAndFailClosedBeforeWrite(t *testing.T) {
	good := []any{json.Number("1e0"), json.Number("-1"), json.Number("0"), json.Number("0"), json.Number("0"), json.Number("2")}
	q, e := stockruntime.DecodeShowcaseAssignment(map[string]any{"ids": good})
	if e != nil || q != (app.Selection{1, -1, 0, 0, 0, 2}) {
		t.Fatal(e)
	}
	for _, x := range []any{nil, "1", float64(1), json.Number("1.5"), json.Number("1e-400"), json.Number("9007199254740992")} {
		bad := append([]any{}, good...)
		bad[0] = x
		if _, e := app.ParseSelection(bad); e == nil {
			t.Fatal("bad signed number", x)
		}
	}
	if _, e = stockruntime.DecodeShowcaseAssignment(map[string]any{"ids": good, "player_id": json.Number("1")}); e == nil {
		t.Fatal("foreign pid")
	}
	if _, _, e = stockruntime.DecodeShowcaseDetail(map[string]any{"to_player_id": json.Number("100001"), "index": json.Number("6")}); e != nil {
		t.Fatal(e)
	}
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	s := showcase(p, p)
	s.BeforeWrite = stockruntime.RequireShowcaseRecords(nil, a.PlayerID)
	if got, e := s.Execute(ctx, a, app.Selection{1}, op()); !errors.Is(e, app.ErrShowcaseUnavailable) || got.Schema != "" {
		t.Fatal("false wire success", e)
	}
	if _, ok := root(t, p, a.PlayerID); ok {
		t.Fatal("failed builder touched")
	}
	var count int
	if e = p.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE owner_key=$1 AND operation='showcase-internal'`, strconv.FormatInt(int64(a.PlayerID), 10)).Scan(&count); e != nil || count != 0 {
		t.Fatal("failed builder receipt", e)
	}
}

type fixedTime struct{ at time.Time }

func (f fixedTime) Now(context.Context) (time.Time, error) { return f.at, nil }

type countingTime struct {
	inner gen.TimeAuthority
	calls atomic.Int32
}

func (c *countingTime) Now(ctx context.Context) (time.Time, error) {
	c.calls.Add(1)
	return c.inner.Now(ctx)
}
func TestRetryUnknownProofAndStaleActor(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	q := app.Selection{1, 0, -1}
	o := op()
	s := showcase(p, &abortOnceDB{Beginner: p})
	ct := &countingTime{inner: pg.AuthoritativeTime{Queryer: p}}
	s.Timed.Binder.Time = ct
	r, e := s.Execute(ctx, a, q, o)
	if e != nil || ct.calls.Load() != 1 {
		t.Fatal("retry time", e, ct.calls.Load())
	}
	rootRow, _ := root(t, p, a.PlayerID)
	if !rootRow.CreatedAt.Equal(r.DecisionAt) {
		t.Fatal("time drift")
	}
	stale := showcase(p, p)
	stale.Timed.Binder.Time = fixedTime{r.DecisionAt.Add(-time.Microsecond)}
	if got, e := stale.Execute(ctx, a, app.Selection{2}, op()); !errors.Is(e, app.ErrInvalidState) || got.Schema != "" {
		t.Fatal("old decision", e)
	}
	s = showcase(p, faultDB{p, true})
	known := op()
	committed, e := s.Execute(ctx, a, app.Selection{2}, known)
	if e != nil || committed.Selection != (app.Selection{2}) {
		t.Fatal("unknown committed", e)
	}
	s = showcase(p, faultDB{p, false})
	if got, e := s.Execute(ctx, a, q, op()); e == nil || got.Schema != "" {
		t.Fatal("unknown absent success")
	}
	if selection(t, p, a.PlayerID) != (app.Selection{2}) {
		t.Fatal("unknown reapply")
	}
	bad := known
	bad.EntropySeed[0] ^= 1
	if _, e := showcase(p, p).Execute(ctx, a, app.Selection{2}, bad); !errors.Is(e, app.ErrConflict) {
		t.Fatal("entropy mismatch", e)
	}
	sqlExec(t, p, `UPDATE gameplay_contexts SET ended_at=clock_timestamp(),end_reason='native',liveness_version=liveness_version+1 WHERE context_id=$1`, a.ContextID.UUID().String())
	if got, e := showcase(p, p).Execute(ctx, a, app.Selection{2}, known); e == nil || got.Schema != "" {
		t.Fatal("replay bypassed revoke")
	}
}
func readSelected(t *testing.T, p *pg.Pool, a identity.ActorContext, target identity.PlayerID, index int, rev string, iso tx.Isolation) (app.SelectedShowcase, error) {
	t.Helper()
	var out app.SelectedShowcase
	_, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: iso}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out, e = reader().ReadSelectedTx(c, sc, a, target, index, rev, at)
		return e
	})
	return out, e
}
func TestCurrentIndexPrivacyAndCoherentFacets(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := actor(t, p), actor(t, p)
	sqlExec(t, p, `INSERT INTO player_social_roots(player_id,created_at,updated_at)VALUES($1,clock_timestamp(),clock_timestamp()),($2,clock_timestamp(),clock_timestamp())`, int64(a.PlayerID), int64(b.PlayerID))
	assets(t, p, b, rev)
	set(t, p, b, app.Selection{1, 0, -1, 0, 0, 2}, op())
	assign(t, p, b, app.Command{Kind: app.HideCommand, Hide: []int16{2, 4}}, op())
	for _, iso := range []tx.Isolation{tx.RepeatableRead, tx.Serializable} {
		x, e := readSelected(t, p, a, b.PlayerID, 6, rev, iso)
		if e != nil || x.Hero == nil || x.Hero.Base.Ref.PartnerID != 2 || x.Hero.HeroSkillsDisposition != characterasset.ProviderUnavailableUnqualified {
			t.Fatal("index6 main/skills", e)
		}
		x, e = readSelected(t, p, b, b.PlayerID, 3, rev, iso)
		if e != nil || x.Pet == nil || x.Pet.Base.Ref.PetID != 1 || x.Pet.Base.Skills != character.DefaultPetSkillLevels() {
			t.Fatal("pet", e)
		}
	}
	if _, e := readSelected(t, p, a, b.PlayerID, 2, rev, tx.RepeatableRead); !errors.Is(e, app.ErrEmptyShowcase) {
		t.Fatal("empty fabricated", e)
	}
	if _, e := readSelected(t, p, a, b.PlayerID, 1, rev, tx.ReadCommitted); e == nil {
		t.Fatal("unwitnessed read")
	}
	set(t, p, b, app.Selection{2}, op())
	x, e := readSelected(t, p, a, b.PlayerID, 1, rev, tx.RepeatableRead)
	if e != nil || x.Hero.Base.Ref.PartnerID != 2 {
		t.Fatal("old card index reused", e)
	}
	for _, pair := range [][2]identity.PlayerID{{a.PlayerID, b.PlayerID}, {b.PlayerID, a.PlayerID}} {
		sqlExec(t, p, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp()) ON CONFLICT(blocker_player_id,blocked_player_id)DO UPDATE SET active=true,removed_at=NULL,state_version=social_blocks.state_version+1,updated_at=clock_timestamp()`, int64(pair[0]), int64(pair[1]))
		if _, e := readSelected(t, p, a, b.PlayerID, 1, rev, tx.RepeatableRead); !errors.Is(e, app.ErrShowcasePrivate) {
			t.Fatal("directed block leaked", e)
		}
		sqlExec(t, p, `UPDATE social_blocks SET active=false,removed_at=clock_timestamp(),updated_at=clock_timestamp() WHERE blocker_player_id=$1 AND blocked_player_id=$2`, int64(pair[0]), int64(pair[1]))
	}
}
func TestSharedRootAssignmentConcurrency(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	when, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	var wg sync.WaitGroup
	errs := make(chan error, 3)
	versions := make(chan int64, 3)
	for _, q := range []app.Selection{{1, 0, -1, 0, 0, 2}, {2, 0, 0, 0, -1, 1}} {
		wg.Add(1)
		go func(q app.Selection) {
			defer wg.Done()
			s := showcase(p, p)
			s.Timed.Binder.Time = fixedTime{when}
			r, e := s.Execute(ctx, a, q, op())
			errs <- e
			versions <- r.RootVersion
		}(q)
	}
	wg.Add(1)
	go func() {
		defer wg.Done()
		s := service(p, p)
		s.Timed.Binder.Time = fixedTime{when}
		r, e := s.Execute(ctx, a, app.Command{Kind: app.IntroCommand, Intro: "race preserved"}, op())
		errs <- e
		versions <- r.RootVersion
	}()
	wg.Wait()
	close(errs)
	close(versions)
	seen := map[int64]bool{}
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	for v := range versions {
		if v < 1 || v > 3 || seen[v] {
			t.Fatal("lost version", v)
		}
		seen[v] = true
	}
	r, ok := root(t, p, a.PlayerID)
	if !ok || r.StateVersion != 3 || r.Preferences.Intro != "race preserved" {
		t.Fatal("shared root lost", r)
	}
	q := selection(t, p, a.PlayerID)
	if q != (app.Selection{1, 0, -1, 0, 0, 2}) && q != (app.Selection{2, 0, 0, 0, -1, 1}) {
		t.Fatal("torn slots", q)
	}
}
func lockGuard(t *testing.T, tr tx.Tx, g app.PublicProfileReferenceGuard, plan characterasset.ReferenceGuardPlan) {
	t.Helper()
	for _, k := range plan.Locks {
		if e := g.LockReferenceGuardKeyTx(ctx, tr, k); e != nil {
			t.Fatal(e)
		}
	}
}
func TestGuardStablePlanRemovalAndSavedPresetComposition(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	g := guard(a)
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	plan, e := g.PreflightHeroRemovalTx(ctx, p, ref)
	if e != nil || len(plan.Locks) != 2 || plan.Locks[0].DomainRank != 315 || plan.Locks[1].DomainRank != 391 {
		t.Fatal("unstable absent", e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	lockGuard(t, tr, g, plan)
	if e = g.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); e != nil {
		t.Fatal(e)
	}
	tr.Rollback(ctx)
	if _, ok := root(t, p, a.PlayerID); ok {
		t.Fatal("guard materialized")
	}
	set(t, p, a, app.Selection{1, 0, -1}, op())
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	lockGuard(t, tr, g, plan)
	if e = g.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); !errors.Is(e, characterasset.ErrReferenceInUse) {
		t.Fatal("referenced allowed", e)
	}
	pet := character.PetRef{PlayerID: a.PlayerID, PetID: 1}
	pp, e := g.PreflightPetRemovalTx(ctx, tr, pet)
	if e != nil {
		t.Fatal(e)
	}
	if e = g.ValidatePetRemovalLockedTx(ctx, tr, pet, pp); !errors.Is(e, characterasset.ErrReferenceInUse) {
		t.Fatal("pet referenced", e)
	}
	bad := plan
	bad.Locks = bad.Locks[:1]
	if e = g.ValidateHeroRemovalLockedTx(ctx, tr, ref, bad); !errors.Is(e, characterasset.ErrInvalidReferenceGuard) {
		t.Fatal("bad plan", e)
	}
	tr.Rollback(ctx)
	sqlExec(t, p, `INSERT INTO player_saved_preset_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,$2,$2)`, int64(a.PlayerID), at)
	saved := charactersavedpreset.SavedPresetReferenceGuard{Store: characterstore.Store{}, PlayerID: a.PlayerID}
	sp, e := saved.PreflightHeroRemovalTx(ctx, p, ref)
	if e != nil {
		t.Fatal(e)
	}
	combined, e := characterasset.CanonicalizeReferenceGuardPlans([]characterasset.ReferenceGuardPlan{sp, plan})
	if e != nil {
		t.Fatal(e)
	}
	assetKey, _ := characterasset.HeroReferenceLockKey(ref)
	parent, _ := i4RootKey(a.PlayerID)
	keys, e := lockkey.CanonicalDedup(append(append([]lockkey.Key{}, combined.Locks...), assetKey, parent))
	if e != nil || len(keys) != 4 || keys[0].DomainRank != 315 || keys[1].DomainRank != 391 || keys[2].DomainRank != 410 || keys[3].DomainRank != 440 {
		t.Fatal("global order", e, keys)
	}
	tr, e = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	for _, k := range keys {
		switch k.DomainRank {
		case 315, 391:
			if e = g.LockReferenceGuardKeyTx(ctx, tr, k); e != nil {
				t.Fatal(e)
			}
		case 410:
			if e = (characterstore.Store{}).LockHeroReferenceKeyTx(ctx, tr, k, ref); e != nil {
				t.Fatal(e)
			}
		case 440:
			if e = saved.LockReferenceGuardKeyTx(ctx, tr, k); e != nil {
				t.Fatal(e)
			}
		}
	}
	if e = saved.ValidateHeroRemovalLockedTx(ctx, tr, ref, sp); e != nil {
		t.Fatal(e)
	}
	if e = g.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); !errors.Is(e, characterasset.ErrReferenceInUse) {
		t.Fatal("provider omitted", e)
	}
}
func i4RootKey(pid identity.PlayerID) (lockkey.Key, error) {
	return lockkey.New(315, "i4.player-root", lockkey.Int64(int64(pid)))
}
func TestGuardAbsenceVersusFirstSelection(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	g := guard(a)
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	plan, e := g.PreflightHeroRemovalTx(ctx, p, ref)
	if e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	lockGuard(t, tr, g, plan)
	k, _ := characterasset.HeroReferenceLockKey(ref)
	if e = (characterstore.Store{}).LockHeroReferenceKeyTx(ctx, tr, k, ref); e != nil {
		t.Fatal(e)
	}
	if e = g.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); e != nil {
		t.Fatal(e)
	}
	started := make(chan struct{}, 1)
	done := make(chan error, 1)
	s := showcase(p, p)
	s.Fence = signalledFence{inner: i5store.Store{}, signal: started}
	go func() { _, e := s.Execute(ctx, a, app.Selection{1}, op()); done <- e }()
	<-started
	// Owner-side destructive callback is native test setup, never a gameplay route.
	if _, e = tr.Exec(ctx, `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	if e = <-done; e == nil {
		t.Fatal("dangling first selection")
	}
	if selection(t, p, a.PlayerID) != (app.Selection{}) {
		t.Fatal("dangling ref committed")
	}
}

type signalledFence struct {
	inner  app.ActorFencer
	signal chan struct{}
}

func (s signalledFence) FenceActorTx(c context.Context, t tx.Tx, a identity.ActorContext, at time.Time) error {
	if e := s.inner.FenceActorTx(c, t, a, at); e != nil {
		return e
	}
	select {
	case s.signal <- struct{}{}:
	default:
	}
	return nil
}

type recordFake struct {
	record map[string]any
	fail   bool
}

func (r recordFake) RecordTx(_ context.Context, s characterasset.CoherentReadScope, _ identity.PlayerID, _ int64) (map[string]any, error) {
	if s.Validate() != nil {
		return nil, app.ErrSelection
	}
	if r.fail {
		return nil, app.ErrShowcaseUnavailable
	}
	return r.record, nil
}
func TestSixRecordHolesAndDeepCopyComponent(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	var records [6]map[string]any
	original := map[string]any{"partner_id": int64(1), "nested": []any{map[string]any{"v": 1}}}
	_, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, s tx.Scope) error {
		var e error
		records, e = app.SlotRecordsTx(c, s, app.ShowcaseSnapshot{PlayerID: a.PlayerID, Selection: app.Selection{1, 0, -1, 0, 0, 2}, ContentRevision: rev, ObservedAt: at}, recordFake{record: original})
		return e
	})
	if e != nil {
		t.Fatal(e)
	}
	original["nested"].([]any)[0].(map[string]any)["v"] = 99
	raw, e := json.Marshal(records)
	if e != nil || strings.Contains(string(raw), "null") || !strings.Contains(string(raw), ",{},") || strings.Contains(string(raw), "99") {
		t.Fatal("record isolation/holes", string(raw), e)
	}
}

type actorTransport struct {
	Account, Session, Context, UID string
	PlayerID                       int64
	Server                         int32
}

func encodeActor(a identity.ActorContext) actorTransport {
	return actorTransport{a.AccountID.UUID().String(), a.SessionID.UUID().String(), a.ContextID.UUID().String(), string(a.AccountUID), int64(a.PlayerID), int32(a.LogicalServerID)}
}
func decodeActor(t *testing.T, v actorTransport) identity.ActorContext {
	t.Helper()
	u, e := ids.ParseUUID(v.Account)
	if e != nil {
		t.Fatal(e)
	}
	a, _ := identity.AccountIDFrom(u)
	u, e = ids.ParseUUID(v.Session)
	if e != nil {
		t.Fatal(e)
	}
	s, _ := identity.SessionIDFrom(u)
	u, e = ids.ParseUUID(v.Context)
	if e != nil {
		t.Fatal(e)
	}
	c, _ := identity.ContextIDFrom(u)
	return identity.ActorContext{AccountID: a, AccountUID: identity.AccountUID(v.UID), SessionID: s, ContextID: c, LogicalServerID: identity.LogicalServerID(v.Server), PlayerID: identity.PlayerID(v.PlayerID), ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1}
}
func TestProcessHelper(t *testing.T) {
	mode := os.Getenv("GXB_I7B3A_CHILD")
	if mode == "" {
		t.Skip("subprocess helper")
	}
	p := pool(t)
	installed(t, p)
	var v actorTransport
	if e := json.Unmarshal([]byte(os.Getenv("GXB_I7B3A_ACTOR")), &v); e != nil {
		t.Fatal(e)
	}
	a := decodeActor(t, v)
	if mode == "assign" {
		var q app.Selection
		if e := json.Unmarshal([]byte(os.Getenv("GXB_I7B3A_SELECTION")), &q); e != nil {
			t.Fatal(e)
		}
		when, e := time.Parse(time.RFC3339Nano, os.Getenv("GXB_I7B3A_AT"))
		if e != nil {
			t.Fatal(e)
		}
		s := showcase(p, p)
		s.Timed.Binder.Time = fixedTime{when}
		if r, e := s.Execute(ctx, a, q, op()); e != nil || r.RootVersion < 1 {
			t.Fatal("child assignment", e)
		}
	} else {
		if selection(t, p, a.PlayerID) == (app.Selection{}) {
			t.Fatal("child reload")
		}
		r, ok := root(t, p, a.PlayerID)
		if !ok || r.StateVersion != 2 {
			t.Fatal("child rootversion", r.StateVersion)
		}
	}
}
func process(t *testing.T, a identity.ActorContext, mode string, q app.Selection, at time.Time) *exec.Cmd {
	raw, _ := json.Marshal(encodeActor(a))
	v, _ := json.Marshal(q)
	cmd := exec.Command(os.Args[0], "-test.run=^TestProcessHelper$", "-test.v")
	cmd.Env = append(os.Environ(), "GXB_I7B3A_CHILD="+mode, "GXB_I7B3A_ACTOR="+string(raw), "GXB_I7B3A_SELECTION="+string(v), "GXB_I7B3A_AT="+at.Format(time.RFC3339Nano))
	return cmd
}
func TestIndependentProcessAssignmentsAndReload(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	when, e := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if e != nil {
		t.Fatal(e)
	}
	cmds := []*exec.Cmd{process(t, a, "assign", app.Selection{1, 0, -1, 0, 0, 2}, when), process(t, a, "assign", app.Selection{2, 0, 0, 0, -1, 1}, when)}
	var wg sync.WaitGroup
	errs := make(chan string, 2)
	for _, c := range cmds {
		wg.Add(1)
		go func(c *exec.Cmd) {
			defer wg.Done()
			out, e := c.CombinedOutput()
			if e != nil {
				errs <- string(out)
			}
		}(c)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		t.Fatal(e)
	}
	if out, e := process(t, a, "reload", app.Selection{}, when).CombinedOutput(); e != nil {
		t.Fatal(string(out), e)
	}
}
func TestRestoredSelectionPolicyReceiptReload(t *testing.T) {
	if os.Getenv("GXB_I7B3A_RESTORED") != "1" {
		t.Skip("restore/restart gate")
	}
	p := pool(t)
	installed(t, p)
	var raw string
	if e := p.QueryRow(ctx, `SELECT result_payload::text FROM gxb_operation_receipts WHERE domain='public-profile' AND operation='showcase-internal' AND result_payload->>'changed'='true' ORDER BY recorded_at LIMIT 1`).Scan(&raw); e != nil {
		t.Fatal(e)
	}
	var r app.ShowcaseResult
	if e := json.Unmarshal([]byte(raw), &r); e != nil {
		t.Fatal(e)
	}
	row, ok := root(t, p, identity.PlayerID(r.PlayerID))
	if !ok || row.StateVersion < r.RootVersion {
		t.Fatal("restored root receipt")
	}
	if _, e := (contentstore.Store{}).ReadPublicShowcasePolicy(ctx, p, r.Revision); e != nil {
		t.Fatal("retained content", e)
	}
	if _, e := (publicprofilestore.Store{}).ReadSelectionTx(ctx, p, identity.PlayerID(r.PlayerID)); e != nil {
		t.Fatal("restored selection", e)
	}
}

func TestRetainedShowcasePolicyAndCorruptProof(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	q := app.Selection{1, 0, -1, 0, 0, 2}
	o := op()
	first := set(t, p, a, q, o)
	id := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(a.PlayerID), 10), Domain: "public-profile", Operation: "showcase-internal", SemanticKey: o.ID.String()}
	rr, yes, e := (kernelstore.Store{}).FindTx(ctx, p, id)
	if e != nil || !yes {
		t.Fatal(e)
	}
	var oldPayload string
	if e = p.QueryRow(ctx, `SELECT payload::text FROM content_public_showcase_policies WHERE revision_id=$1`, rev).Scan(&oldPayload); e != nil {
		t.Fatal(e)
	}
	// Unavailable current activation is a controlled administrative-fault case.
	// It does not claim a full qualified alternate content deployment. Receipt
	// recovery must use retained exact policy, never the activation pointer.
	sqlExec(t, p, `DELETE FROM gxb_content_activation WHERE slot='content'`)
	again, e := showcase(p, p).Execute(ctx, a, q, o)
	if e != nil || again != first {
		t.Fatal("retained replay consulted current pointer", e)
	}
	if _, e = showcase(p, p).Execute(ctx, a, q, op()); e == nil {
		t.Fatal("missing current activation allowed newoperation")
	}
	sqlExec(t, p, `INSERT INTO gxb_content_activation(slot,revision_id,activation_version,activated_at,activated_by)VALUES('content',$1,99,clock_timestamp(),'i7b2b-native-fault-restore')`, rev)
	altered := o
	altered.EntropySeed[0] ^= 1
	if _, e = showcase(p, p).Execute(ctx, a, q, altered); !errors.Is(e, app.ErrConflict) {
		t.Fatal("changed semanticcontext accepted", e)
	}
	sqlExec(t, p, `UPDATE gxb_operation_receipts SET result_payload=jsonb_set(result_payload,'{server}','2'::jsonb) WHERE receipt_id=$1`, rr.ID.String())
	if _, e = showcase(p, p).Execute(ctx, a, q, o); !errors.Is(e, app.ErrConflict) {
		t.Fatal("corrupt result binding accepted", e)
	}
	sqlExec(t, p, `UPDATE gxb_operation_receipts SET result_payload=$2::jsonb WHERE receipt_id=$1`, rr.ID.String(), string(rr.ResultPayload))
	sqlExec(t, p, `UPDATE content_public_showcase_policies SET payload=jsonb_set(payload,'{slots}','5'::jsonb) WHERE revision_id=$1`, rev)
	if _, e = showcase(p, p).Execute(ctx, a, q, o); e == nil {
		t.Fatal("corrupt retained policy accepted")
	}
	sqlExec(t, p, `UPDATE content_public_showcase_policies SET payload=$2::jsonb WHERE revision_id=$1`, rev, oldPayload)
	var oldManifest string
	if e = p.QueryRow(ctx, `SELECT manifest::text FROM gxb_content_revisions WHERE revision_id=$1`, rev).Scan(&oldManifest); e != nil {
		t.Fatal(e)
	}
	sqlExec(t, p, `UPDATE gxb_content_revisions SET manifest=jsonb_set(manifest,'{source_archive_sha256}','"0000000000000000000000000000000000000000000000000000000000000000"'::jsonb) WHERE revision_id=$1`, rev)
	if _, e = showcase(p, p).Execute(ctx, a, q, o); e == nil {
		t.Fatal("mismatched retained manifest identity accepted")
	}
	sqlExec(t, p, `UPDATE gxb_content_revisions SET manifest=$2::jsonb WHERE revision_id=$1`, rev, oldManifest)
}
