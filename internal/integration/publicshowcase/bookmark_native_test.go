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
	stockruntime "gxb.local/backend/v2/internal/adapters/stockruntime"
	characterasset "gxb.local/backend/v2/internal/application/characterasset"
	characterhero "gxb.local/backend/v2/internal/application/characterhero"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	builtin "gxb.local/backend/v2/internal/content/builtin"
	character "gxb.local/backend/v2/internal/domain/character"
	identity "gxb.local/backend/v2/internal/domain/identity"
	operation "gxb.local/backend/v2/internal/foundation/operation"
	tx "gxb.local/backend/v2/internal/foundation/tx"
	httpedge "gxb.local/backend/v2/internal/protocol/httpedge"
	"os"
	"os/exec"
	"strings"
	"sync"
	"testing"
	"time"
)

func bookmarkService(p *pg.Pool, db tx.Beginner) characterhero.BookmarkService {
	return characterhero.BookmarkService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: db}}, Reads: tx.Runner{DB: p}, Store: characterstore.Store{}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: kernelstore.Store{}}
}
func heroState(t *testing.T, p *pg.Pool, a identity.ActorContext, id int64) character.Hero {
	t.Helper()
	h, e := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, a.PlayerID, id)
	if e != nil {
		t.Fatal(e)
	}
	return h
}
func mark(t *testing.T, p *pg.Pool, a identity.ActorContext, id, v int64, o operation.Context) characterhero.BookmarkResult {
	t.Helper()
	r, e := bookmarkService(p, p).SetBookmark(ctx, a, id, v, o)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func superAsset(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string) {
	t.Helper()
	b, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	var h character.Hero
	for _, v := range b.HeroCore.Templates {
		if v.HeroKind == "SUPER" {
			h = character.Hero{PlayerID: a.PlayerID, PartnerID: 4, TableID: v.TableID, OriginTableID: v.OriginTableID, Star: v.InitialStar, Level: 1, Color: 1, CreationContentRevision: rev, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
			break
		}
	}
	if h.TableID == 0 {
		t.Fatal("super fixture")
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = (characterstore.Store{}).InsertHeroTx(ctx, tr, h); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}
func TestBookmarkOwnedDesiredNoopNormalSuperAndHistoricalReplay(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	superAsset(t, p, a, rev)
	for _, id := range []int64{1, 4} {
		base := heroState(t, p, a, id)
		zero := mark(t, p, a, id, 0, op())
		if zero.Changed || zero.StateVersion != 1 || heroState(t, p, a, id).UpdatedAt != base.UpdatedAt {
			t.Fatal("zero noop changed")
		}
		o := op()
		one := mark(t, p, a, id, 1, o)
		if !one.Changed || one.IsLike != 1 || one.StateVersion != 2 {
			t.Fatal(one)
		}
		again := mark(t, p, a, id, 1, op())
		if again.Changed || again.StateVersion != 2 {
			t.Fatal(again)
		}
		mark(t, p, a, id, 0, op())
		replay := mark(t, p, a, id, 1, o)
		if replay != one || heroState(t, p, a, id).IsLike != 0 {
			t.Fatal("historical replay reapplied")
		}
		if _, e := bookmarkService(p, p).SetBookmark(ctx, a, id, 0, o); e == nil {
			t.Fatal("sameoperation mismatch")
		}
	}
	b := actor(t, p)
	for _, q := range [][2]int64{{0, 1}, {-1, 1}, {1, 2}, {9007199254740992, 1}, {99999, 1}} {
		if _, e := bookmarkService(p, p).SetBookmark(ctx, a, q[0], q[1], op()); e == nil {
			t.Fatal("invalid", q)
		}
	}
	if _, e := bookmarkService(p, p).SetBookmark(ctx, b, 1, 1, op()); e == nil {
		t.Fatal("foreignowner")
	}
	if _, present := root(t, p, a.PlayerID); present {
		t.Fatal("bookmark created publicroot")
	}
	// DB constraints independently reject corruption; all existing loaders see metadata.
	if _, e := p.Raw().Exec(ctx, `UPDATE player_heroes SET is_like=2 WHERE player_id=$1`, int64(a.PlayerID)); e == nil {
		t.Fatal("persistedbitconstraint")
	}
	rows, e := (characterstore.Store{}).ListHeroesTx(ctx, p, a.PlayerID)
	if e != nil || len(rows) != 4 {
		t.Fatal(rows, e)
	}
	for _, h := range rows {
		if h.IsLike != 0 {
			t.Fatal(h)
		}
	}
}

type bookmarkAuthority struct{ a identity.ActorContext }

func (r bookmarkAuthority) ResolveGameplayBearer(context.Context, string, time.Time) (identity.ActorContext, error) {
	return r.a, nil
}
func selfHeroService(p *pg.Pool) characterhero.Service {
	c := contentstore.Store{Queryer: p}
	return characterhero.Service{Runner: tx.Runner{DB: p}, Store: characterstore.Store{Queryer: p}, Fencer: i5store.Store{}, Content: c, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RosterProjection: c, AppearanceStore: characterstore.Store{Queryer: p}, Appearance: c}
}
func bookmarkRequest(mid uint16, a identity.ActorContext, params map[string]any) httpedge.DispatchRequest {
	var r httpedge.DispatchRequest
	r.Envelope.MID = mid
	r.Envelope.Params = params
	r.Envelope.Operation = op()
	r.Envelope.ReceivedAt = time.Now().UTC()
	r.Envelope.Claims.Token = "native-admitted-actor"
	r.Envelope.Claims.Region = int64(a.LogicalServerID)
	return r
}
func TestBookmarkMID3116Roster49AndMID1CanonicalPropagation(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	superAsset(t, p, a, rev)
	d := stockruntime.HeroDispatcher{Authority: bookmarkAuthority{a}, Service: selfHeroService(p), Bookmark: bookmarkService(p, p)}
	for _, id := range []string{"1", "4"} {
		params := map[string]any{"partner_id": json.Number(id), "is_like": json.Number("1"), "platform": "test"}
		r := d.Dispatch(ctx, bookmarkRequest(3116, a, params))
		if r.HTTPStatus != 200 || len(r.Body) != 0 {
			t.Fatal(r)
		}
	}
	before := heroState(t, p, a, 1)
	for _, v := range []any{nil, true, "0", json.Number("0.0"), json.Number("1e0"), json.Number("2"), json.Number("-1")} {
		r := d.Dispatch(ctx, bookmarkRequest(3116, a, map[string]any{"partner_id": json.Number("1"), "is_like": v}))
		if r.HTTPStatus == 200 {
			t.Fatal("badwire", v)
		}
	}
	r := d.Dispatch(ctx, bookmarkRequest(3116, a, map[string]any{"partner_id": json.Number("1"), "is_like": json.Number("0"), "to_player_id": a.PlayerID}))
	if r.HTTPStatus == 200 {
		t.Fatal("foreignfield")
	}
	if h := heroState(t, p, a, 1); h.StateVersion != before.StateVersion || h.IsLike != 1 {
		t.Fatal("badwire mutated")
	}
	r = d.Dispatch(ctx, bookmarkRequest(49, a, map[string]any{}))
	if r.HTTPStatus != 200 {
		t.Fatal(r)
	}
	rows := r.Body["heros"].(map[string]any)
	for _, id := range []string{"1", "4"} {
		if rows[id].(map[string]any)["is_like"] != int64(1) {
			t.Fatal(rows)
		}
	}
	_, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		detail := map[string]any{}
		if e := (characterstore.HeroBootstrapProjection{Content: contentstore.Store{}}).OverlayMID1(c, sc.Tx, a, false, time.Now().UTC(), detail); e != nil {
			return e
		}
		rr := detail["49"].(map[string]any)["heros"].(map[string]any)
		for _, id := range []string{"1", "4"} {
			if rr[id].(map[string]any)["is_like"] != int64(1) {
				t.Fatal("MID1", rr)
			}
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
}
func TestBookmarkAbortUnknownReplayAndRevocation(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	o := op()
	r, e := bookmarkService(p, faultDB{p, true}).SetBookmark(ctx, a, 1, 1, o)
	if e != nil || r.IsLike != 1 || heroState(t, p, a, 1).StateVersion != 2 {
		t.Fatal("ackloss", r, e)
	}
	o2 := op()
	r, e = bookmarkService(p, faultDB{p, false}).SetBookmark(ctx, a, 1, 0, o2)
	if e == nil || r.Schema != "" || heroState(t, p, a, 1).IsLike != 1 {
		t.Fatal("unknownabort published", r, e)
	}
	retry := &abortOnceDB{Beginner: p}
	stamp, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	stable := bookmarkService(p, retry)
	stable.Timed.Binder.Time = fixedTime{stamp}
	r, e = stable.SetBookmark(ctx, a, 1, 0, op())
	if e != nil || r.StateVersion != 3 || !retry.first.Load() || !r.DecisionAt.Equal(stamp) {
		t.Fatal("definiteabort", r, e)
	}
	stale := bookmarkService(p, p)
	stale.Timed.Binder.Time = fixedTime{stamp.Add(-time.Second)}
	if _, e := stale.SetBookmark(ctx, a, 1, 1, op()); !errors.Is(e, characterhero.ErrBookmarkStaleTime) {
		t.Fatal("staledecision", e)
	}
	// Corrupt a known receipt and ensure replay is not a success or reapplication.
	sqlExec(t, p, `UPDATE gxb_operation_receipts SET result_payload=jsonb_set(result_payload,'{is_like}','0') WHERE owner_key=$1 AND domain='character-hero' AND semantic_key=$2`, strings.TrimSpace(stringInt(int64(a.PlayerID))), o.ID.String())
	if _, e := bookmarkService(p, p).SetBookmark(ctx, a, 1, 1, o); e == nil {
		t.Fatal("corruptproof")
	}
	fresh := op()
	mark(t, p, a, 2, 1, fresh)
	sqlExec(t, p, `UPDATE gameplay_contexts SET context_generation=context_generation+1 WHERE context_id=$1`, a.ContextID.UUID().String())
	if _, e := bookmarkService(p, p).SetBookmark(ctx, a, 2, 1, fresh); e == nil {
		t.Fatal("revokedknownattempt")
	}
}
func stringInt(v int64) string { b, _ := json.Marshal(v); return string(b) }
func TestBookmarkSameHeroConcurrentMetadataPreservation(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	var wg sync.WaitGroup
	errs := make(chan error, 12)
	for i := 0; i < 12; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := bookmarkService(p, p).SetBookmark(ctx, a, 1, 1, op())
			if e != nil && !errors.Is(e, characterhero.ErrBookmarkStaleTime) && !isSerializationAbort(e) {
				errs <- e
			}
		}()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		t.Fatal(e)
	}
	h := heroState(t, p, a, 1)
	if h.IsLike != 1 || h.StateVersion != 2 {
		t.Fatal("samevalue didnotconverge", h)
	}
	// Exercise a real accepted owner CAS concurrently with bookmark assignment.
	errs2 := make(chan error, 2)
	wg.Add(2)
	go func() {
		defer wg.Done()
		_, e := bookmarkService(p, p).SetBookmark(ctx, a, 1, 0, op())
		if e != nil && !errors.Is(e, characterhero.ErrBookmarkStaleTime) && !isSerializationAbort(e) {
			errs2 <- e
		}
	}()
	go func() {
		defer wg.Done()
		_, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc tx.Scope) error {
			h, e := (characterstore.Store{}).LockHeroByPartnerIDTx(c, sc.Tx, a.PlayerID, 1)
			if e != nil {
				return e
			}
			old := h.StateVersion
			h.Level = 2
			h.Exp = 17
			h.UpdatedAt = time.Now().UTC()
			h.StateVersion++
			return (characterstore.Store{}).SaveHeroProgressionTx(c, sc.Tx, h, old)
		})
		if e != nil {
			errs2 <- e
		}
	}()
	wg.Wait()
	close(errs2)
	for e := range errs2 {
		t.Fatal(e)
	}
	h = heroState(t, p, a, 1)
	if h.Level != 2 || h.Exp != 17 {
		t.Fatal("metadata lost progression", h)
	}
	mark(t, p, a, 1, 1, op())
	h = heroState(t, p, a, 1)
	if h.Level != 2 || h.Exp != 17 || h.IsLike != 1 {
		t.Fatal("progression lost metadata", h)
	}
}

type badBookmark struct {
	characterhero.BookmarkObservationReader
}

func (b badBookmark) BookmarkTx(c context.Context, sc characterasset.CoherentReadScope, ref character.HeroRef) (characterhero.BookmarkObservation, error) {
	v, e := b.BookmarkObservationReader.BookmarkTx(c, sc, ref)
	v.StateVersion++
	return v, e
}
func TestBookmarkParentComposedSelectionPrivacyAndCoherence(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	b := actor(t, p)
	assets(t, p, a, rev)
	mark(t, p, a, 1, 1, op())
	set(t, p, a, app.Selection{1, 0, -1, 0, 0, 2}, op())
	br := characterhero.BookmarkObservationReader{Store: characterstore.Store{}}

	// Explicit caller scope binds selection, Hero base and bookmark to one snapshot.
	_, e := (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		stamp := time.Now().UTC()
		v, e := reader().ReadSelectedWithBookmarkTx(c, sc, b, a.PlayerID, 1, rev, stamp, br)
		if e != nil {
			return e
		}
		if v.HeroBookmark == nil || v.HeroBookmark.IsLike != 1 || v.HeroBookmark.StateVersion != v.Selected.Hero.Base.StateVersion {
			t.Fatal(v)
		}
		if _, e = reader().ReadSelectedWithBookmarkTx(c, sc, b, a.PlayerID, 1, rev, stamp, badBookmark{br}); e == nil {
			t.Fatal("coherence mismatch")
		}
		if _, e = reader().ReadSelectedWithBookmarkTx(c, sc, b, a.PlayerID, 1, rev, stamp, nil); e == nil {
			t.Fatal("missingprovider")
		}
		pet, e := reader().ReadSelectedWithBookmarkTx(c, sc, b, a.PlayerID, 3, rev, stamp, nil)
		if e != nil || pet.Selected.Pet == nil || pet.HeroBookmark != nil {
			t.Fatal(pet, e)
		}
		if _, e = reader().ReadSelectedWithBookmarkTx(c, sc, b, a.PlayerID, 2, rev, stamp, br); !errors.Is(e, app.ErrEmptyShowcase) {
			t.Fatal(e)
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	sqlExec(t, p, `INSERT INTO player_social_roots(player_id,state_version,created_at,updated_at)VALUES($1,1,clock_timestamp(),clock_timestamp()),($2,1,clock_timestamp(),clock_timestamp()) ON CONFLICT DO NOTHING`, int64(a.PlayerID), int64(b.PlayerID))
	sqlExec(t, p, `INSERT INTO social_blocks(blocker_player_id,blocked_player_id,generation,active,activated_at,state_version,updated_at)VALUES($1,$2,1,true,clock_timestamp(),1,clock_timestamp())`, int64(b.PlayerID), int64(a.PlayerID))
	_, e = (tx.Runner{DB: p}).Run(ctx, op(), prof(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		_, e := reader().ReadSelectedWithBookmarkTx(c, sc, b, a.PlayerID, 1, rev, time.Now().UTC(), br)
		return e
	})
	if !errors.Is(e, app.ErrShowcasePrivate) {
		t.Fatal("blockprivacy", e)
	}
}
func TestBookmarkProcessHelper(t *testing.T) {
	if os.Getenv("GXB_BOOKMARK_CHILD") == "" {
		t.Skip("only actual subprocess helper")
	}
	p := pool(t)
	var transported actorTransport
	if e := json.Unmarshal([]byte(os.Getenv("GXB_BOOKMARK_ACTOR")), &transported); e != nil {
		t.Fatal(e)
	}
	a := decodeActor(t, transported)
	mark(t, p, a, 1, 1, op())
	if heroState(t, p, a, 1).IsLike != 1 {
		t.Fatal("processreload")
	}
}
func TestBookmarkIndependentProcessReload(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	assets(t, p, a, rev)
	raw, _ := json.Marshal(encodeActor(a))
	cmd := exec.Command(os.Args[0], "-test.run=^TestBookmarkProcessHelper$", "-test.v")
	cmd.Env = append(os.Environ(), "GXB_BOOKMARK_CHILD=1", "GXB_BOOKMARK_ACTOR="+string(raw), "GXB_I7B3A_CHILD=bookmark")
	if out, e := cmd.CombinedOutput(); e != nil {
		t.Fatalf("%s %v", out, e)
	}
	if heroState(t, p, a, 1).IsLike != 1 {
		t.Fatal("parentreload")
	}
}
func TestBookmarkRestoredReload(t *testing.T) {
	if os.Getenv("GXB_BOOKMARK_RESTORED") != "1" {
		t.Skip("restore/restart helper")
	}
	p := pool(t)
	var n int
	if e := p.QueryRow(ctx, `SELECT count(*) FROM player_heroes WHERE is_like=1`).Scan(&n); e != nil || n == 0 {
		t.Fatal(n, e)
	}
	var pid, id int64
	if e := p.QueryRow(ctx, `SELECT player_id,partner_id FROM player_heroes WHERE is_like=1 ORDER BY player_id LIMIT 1`).Scan(&pid, &id); e != nil {
		t.Fatal(e)
	}
	h, e := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, identity.PlayerID(pid), id)
	if e != nil || h.IsLike != 1 {
		t.Fatal(h, e)
	}
	var r int
	if e = p.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE domain='character-hero' AND operation='bookmark'`).Scan(&r); e != nil || r == 0 {
		t.Fatal(r, e)
	}
}

func isSerializationAbort(e error) bool {
	var state interface{ SQLState() string }
	return errors.As(e, &state) && state.SQLState() == "40001"
}
