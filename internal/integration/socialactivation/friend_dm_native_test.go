//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/frienddmstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/socialfriendbase"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sync"
	"testing"
	"time"
)

func (f *fixture) dm() dm.Service {
	c := contentstore.Store{Queryer: f.p}
	return dm.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: f.p}}, Runner: tx.Runner{DB: f.p}}, Queryer: f.p, Store: frienddmstore.Store{}, Players: i4store.PlayerRootLocker{}, Privacy: sr.FriendDMPrivacyProvider{Store: socialrelationstore.Store{}}, Observer: socialpresentation.TransactionReader{}, Content: c, Entitlement: i5.EmoticonEntitlementReader{Store: i5store.Store{Queryer: f.p}, Content: c}, Owner: presencestore.Store{Queryer: f.p}}
}
func (f *fixture) dmBase(s dm.Service) socialfriendbase.Service {
	return socialfriendbase.Service{FriendDM: s, Projection: f.v}
}
func (f *fixture) dmSend(s dm.Service, from, to identity.PlayerID, text string) dm.Occurrence {
	f.t.Helper()
	o, e := s.Accept(ctx, actor(from), to, friendmessage.Message{Kind: 0, Text: text}, f.op())
	if e != nil {
		f.t.Fatal(e)
	}
	return o
}
func (f *fixture) dmSnapshot() string {
	return f.text(`SELECT jsonb_build_object('roots',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY recipient_id),'[]') FROM friend_dm_roots t),'occurrences',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY recipient_id,recipient_sequence),'[]') FROM friend_dm_occurrences t),'delivery',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY occurrence_id),'[]') FROM friend_dm_delivery t),'receipts',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY operation_id),'[]') FROM friend_dm_projection_receipts t))::text`)
}
func dmPair(t *testing.T) (*fixture, dm.Service) {
	f := fresh(t)
	f.player(100001)
	f.player(200001)
	f.friend(100001, 200001)
	return f, f.dm()
}
func Test6A_G06_G07_G25KnownOperationAndLostResponse(t *testing.T) {
	f, s := dmPair(t)
	op := f.op()
	message := friendmessage.Message{Kind: 0, Text: "same text"}
	first, e := s.Accept(ctx, actor(100001), 200001, message, op)
	if e != nil {
		t.Fatal(e)
	}
	before := f.dmSnapshot()
	second, e := s.Accept(ctx, actor(100001), 200001, message, op)
	if e != nil || first != second || f.dmSnapshot() != before {
		t.Fatal("known515 replay", e)
	}
	if _, e = s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 0, Text: "changed"}, op); e == nil || f.dmSnapshot() != before {
		t.Fatal("known operation collision")
	}
	f.dmSend(s, 100001, 200001, "same text")
	if f.number(`SELECT count(*) FROM friend_dm_occurrences`) != 2 {
		t.Fatal("nonce-less request text deduplicated")
	}
	base := f.dmBase(s)
	projectionOp := f.op()
	out, e := base.LoadBase(ctx, actor(200001), projectionOp)
	if e != nil || len(out.PrivateMessages) != 2 || out.PrivateMessages[0].PlayerID != 100001 || out.PrivateMessages[0].Time != first.AcceptedAt.Unix() {
		t.Fatal(out, e)
	}
	replay, e := base.LoadBase(ctx, actor(200001), projectionOp)
	if e != nil || !reflect.DeepEqual(out.PrivateMessages, replay.PrivateMessages) {
		t.Fatal("known176 projection receipt", e)
	}
	newRequest, e := base.LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(newRequest.PrivateMessages) != 0 {
		t.Fatal("lost committed response must not new-request replay", e)
	}
	if f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='OFFLINE_PROJECTED'`) != 2 || f.number(`SELECT count(*) FROM friend_dm_projection_receipts`) != 1 {
		t.Fatal("one-way drain")
	}
	t.Log("REAL_PG known515/known176 positive receipts; new nonce-less occurrence; lost committed176 presentation residual demonstrated")
}
func Test6A_G08_G09UnknownCommitAndRollback(t *testing.T) {
	for _, committed := range []bool{false, true} {
		t.Run(fmt.Sprint(committed), func(t *testing.T) {
			f, s := dmPair(t)
			fault := &ambiguousBeginner{db: f.p, commit: committed}
			s.Timed.Runner.DB = fault
			op := f.op()
			out, e := s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 0, Text: "ambiguous"}, op)
			if committed {
				if e != nil || out.ID != op.ID.String() {
					t.Fatal("positive owner receipt resolution", out, e)
				}
			} else {
				var unknown *tx.UnknownCommitError
				if !errors.As(e, &unknown) || out.ID != "" {
					t.Fatal("unknown published output", out, e)
				}
			}
			if fault.begins != 1 {
				t.Fatal("blind replay", fault.begins)
			}
			if f.number(`SELECT count(*) FROM friend_dm_occurrences`) != map[bool]int64{false: 0, true: 1}[committed] {
				t.Fatal("canonical outcome")
			}
			if !committed && f.number(`SELECT count(*) FROM friend_dm_roots`) != 0 {
				t.Fatal("aborted root creation")
			}
		})
	}
	f, s := dmPair(t)
	f.dmSend(s, 100001, 200001, "private projection")
	base := f.dmBase(s)
	fault := &dmWriteAmbiguous{db: f.p, commit: true}
	base.FriendDM.Timed.Runner.DB = fault
	out, e := base.LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(out.PrivateMessages) != 1 {
		t.Fatal("positive native projection receipt resolution", out, e)
	}
}
func Test6A_G13_G14_G15_G16DirectedPrivacyGeneration(t *testing.T) {
	f, s := dmPair(t)
	f.block(100001, 200001)
	f.dmSend(s, 100001, 200001, "sender block is not recipient denial")
	out, e := f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(out.PrivateMessages) != 1 {
		t.Fatal(out, e)
	}
	f.ok(100001, sr.RemoveBlock, 200001)
	f.dmSend(s, 100001, 200001, "old generation")
	f.ok(200001, sr.DeleteFriend, 100001)
	f.ok(100001, sr.RequestFriend, 200001)
	f.ok(200001, sr.AcceptRequest, 100001)
	out, e = f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(out.PrivateMessages) != 0 || f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='PRIVACY_SUPPRESSED'`) != 1 {
		t.Fatal("refriend leaked", e)
	}
	f.dmSend(s, 100001, 200001, "pre block cycle")
	f.block(200001, 100001)
	before := f.dmSnapshot()
	if _, e = s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 0, Text: "denied"}, f.op()); e == nil || f.dmSnapshot() != before {
		t.Fatal("recipient block accepted")
	}
	f.ok(200001, sr.RemoveBlock, 100001)
	out, e = f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(out.PrivateMessages) != 0 || f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='PRIVACY_SUPPRESSED'`) != 2 {
		t.Fatal("block-unblock revived", e)
	}
}
func Test6A_G18_G20_G21_G22LeaseRetentionAndFences(t *testing.T) {
	f, s := dmPair(t)
	fence, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil {
		t.Fatal(e)
	}
	oldest := f.dmSend(s, 100001, 200001, "oldest")
	claim, ok, e := s.Claim(ctx, 200001, fence, f.op())
	if e != nil || !ok || claim.Delivery.Occurrence.ID != oldest.ID {
		t.Fatal(claim, ok, e)
	}
	out, e := f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(out.PrivateMessages) != 0 {
		t.Fatal("active lease drained", out, e)
	}
	for i := 0; i < 50; i++ {
		f.dmSend(s, 100001, 200001, fmt.Sprint(i))
	}
	if f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='PENDING'`) != 50 || f.number(`SELECT count(*) FROM friend_dm_occurrences`) != 51 || f.text(`SELECT status FROM friend_dm_delivery WHERE occurrence_id=$1::uuid`, oldest.ID) != "RETENTION_SUPPRESSED" {
		t.Fatal("active oldest retention")
	}
	before := f.dmSnapshot()
	if ok, e = s.Complete(ctx, claim, true, f.op()); e != nil || ok || f.dmSnapshot() != before {
		t.Fatal("late worker resurrected", ok, e)
	}
	claim, ok, e = s.Claim(ctx, 200001, fence, f.op())
	if e != nil || !ok {
		t.Fatal(e)
	}
	next, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil || next <= fence {
		t.Fatal(e)
	}
	if _, e = s.Complete(ctx, claim, true, f.op()); e == nil {
		t.Fatal("stale process owner finalized")
	}
	out, e = f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(out.PrivateMessages) != 50 {
		t.Fatal("old-owner lease not recovered", len(out.PrivateMessages), e)
	}
	if f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='OFFLINE_PROJECTED'`) != 50 {
		t.Fatal("restore terminal monotonicity")
	}
}

type fixedDMClock struct{ at time.Time }

func (c fixedDMClock) Now(context.Context) (time.Time, error)              { return c.at, nil }
func (c fixedDMClock) ObserveTx(context.Context, tx.Tx) (time.Time, error) { return c.at, nil }
func Test6A_G19ExpiryEqualityBackwardForward(t *testing.T) {
	f, s := dmPair(t)
	fence, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil {
		t.Fatal(e)
	}
	f.dmSend(s, 100001, 200001, "expiry")
	claim, ok, e := s.Claim(ctx, 200001, fence, f.op())
	if e != nil || !ok {
		t.Fatal(e)
	}
	// These are clock-jump injections over real PostgreSQL owner transitions.
	// Normal production still uses its DB TimeAuthority/TxObserver.
	s.Timed.Binder.Time = fixedDMClock{claim.Delivery.UpdatedAt.Add(-time.Microsecond)}
	s.Observer = fixedDMClock{claim.Delivery.UpdatedAt.Add(-time.Microsecond)}
	before := f.dmSnapshot()
	if _, e = s.Complete(ctx, claim, true, f.op()); e == nil || f.dmSnapshot() != before {
		t.Fatal("backward clock reopened state")
	}
	expiry := *claim.Delivery.ExpiresAt
	s.Timed.Binder.Time = fixedDMClock{expiry}
	s.Observer = fixedDMClock{expiry}
	ok, e = s.Complete(ctx, claim, true, f.op())
	if e != nil || ok || f.text(`SELECT status FROM friend_dm_delivery WHERE occurrence_id=$1::uuid`, claim.Delivery.Occurrence.ID) != "PENDING" {
		t.Fatal("equality must be expired", ok, e)
	}
	forward := expiry.Add(time.Second)
	s.Timed.Binder.Time = fixedDMClock{forward}
	s.Observer = fixedDMClock{forward}
	next, ok, e := s.Claim(ctx, 200001, fence, f.op())
	if e != nil || !ok {
		t.Fatal("fresh forward claim", e)
	}
	jump := forward.Add(31 * time.Second)
	s.Timed.Binder.Time = fixedDMClock{jump}
	s.Observer = fixedDMClock{jump}
	if ok, e = s.Complete(ctx, next, true, f.op()); e != nil || ok {
		t.Fatal("forward jump early expiry", ok, e)
	}
	t.Log("REAL_PG state + injected exact DB-port clock equality/backward observations; not a physical database clock change")
}
func Test6A_G35_G36CatalogAndEntitlementSameTx(t *testing.T) {
	f, s := dmPair(t)
	_, e := registry.Initialize(ctx, registry.Service{Runner: tx.Runner{DB: f.p}, Repo: contentstore.Store{}, Fresh: f.p, Providers: registry.DefaultProviderSet()}, operation.Factory{Clock: clock.System{}})
	if e != nil {
		t.Fatal(e)
	}
	before := f.dmSnapshot()
	if _, e = s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 1, EmoticonID: 26}, f.op()); e == nil || f.dmSnapshot() != before {
		t.Fatal("paid without item accepted")
	}
	var item int64
	revision, e := s.Content.ActiveRevision(ctx, f.p)
	if e != nil {
		t.Fatal(e)
	}
	transaction, e := f.p.Begin(ctx, tx.Options{Isolation: tx.RepeatableRead})
	if e != nil {
		t.Fatal(e)
	}
	definition, e := s.Content.ResolveEmoticonTx(ctx, transaction, revision, 26)
	if e != nil {
		t.Fatal(e)
	}
	item = definition.ItemID
	transaction.Rollback(ctx)
	f.sql(`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES(100001,1,$1)`, f.at)
	f.sql(`INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES(100001,$1,1,3,$2,$2)`, item, f.at)
	stacks := f.text(`SELECT to_jsonb(t)::text FROM player_item_stacks t WHERE player_id=100001 AND item_id=$1`, item)
	catalog, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	seenItems := map[int64]bool{item: true}
	for _, definition := range catalog.Emoticons.Definitions {
		if definition.ItemID > 0 && !seenItems[definition.ItemID] {
			seenItems[definition.ItemID] = true
			f.sql(`INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES(100001,$1,1,3,$2,$2)`, definition.ItemID, f.at)
		}
	}
	for _, definition := range catalog.Emoticons.Definitions {
		out, e := s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 1, EmoticonID: definition.ID}, f.op())
		if e != nil || out.ContentRevision != revision || definition.ItemID > 0 && out.EntitlementVersion != 3 {
			t.Fatal("qualified ordinary emoticon", definition, out, e)
		}
	}
	if len(seenItems) != 47 {
		t.Fatal("paid item qualification count")
	}

	if stacks != f.text(`SELECT to_jsonb(t)::text FROM player_item_stacks t WHERE player_id=100001 AND item_id=$1`, item) {
		t.Fatal("emoticon consumed inventory")
	}
	f.sql(`DELETE FROM player_item_stacks WHERE player_id=100001`)
	out, e := f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(out.PrivateMessages) != 50 {
		t.Fatal("reload re-entitled/revoked", out, e)
	}
	if f.number(`SELECT jsonb_array_length(artifact->'definitions') FROM content_emoticon_catalogs WHERE revision_id=$1`, revision) != 85 {
		t.Fatal("catalog incomplete")
	}
}
func Test6A_G10_G17CrossServerSendDrainConcurrency(t *testing.T) {
	f, s := dmPair(t)
	var wg sync.WaitGroup
	errs := make(chan error, 8)
	rejected := make(chan int, 8)
	for i := 0; i < 8; i++ {
		i := i
		wg.Add(1)
		go func() {
			defer wg.Done()
			from, to := identity.PlayerID(100001), identity.PlayerID(200001)
			if i%2 == 1 {
				from, to = to, from
			}
			op := f.op()
			op.EntropySeed[0] = byte(i)
			_, e := s.Accept(ctx, actor(from), to, friendmessage.Message{Kind: 0, Text: fmt.Sprint(i)}, op)
			if e != nil {
				if !errors.Is(e, dm.ErrStale) && !tx.IsDefiniteAbortError(e) {
					errs <- e
					return
				}
				if _, exists, readErr := s.Store.FindOccurrence(ctx, f.p, op.ID.String()); readErr != nil || exists {
					errs <- fmt.Errorf("definite-abort leaked occurrence: %v", readErr)
					return
				}
				rejected <- i
			}
			errs <- nil
		}()
	}
	wg.Wait()
	close(errs)
	close(rejected)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	// Under the selected backwards-observation rule, a competing committed
	// decision can make a retry-stable earlier instant stale. Verify fail-closed
	// attempts above, then submit separate fresh stock operations serially.
	for i := range rejected {
		from, to := identity.PlayerID(100001), identity.PlayerID(200001)
		if i%2 == 1 {
			from, to = to, from
		}
		op := f.op()
		if _, e := s.Accept(ctx, actor(from), to, friendmessage.Message{Kind: 0, Text: fmt.Sprint(i)}, op); e != nil {
			t.Fatal(e)
		}
	}
	if f.number(`SELECT count(*) FROM friend_dm_occurrences`) != 8 {
		t.Fatal("accepted/aborted occurrence accounting")
	}
	for _, id := range []identity.PlayerID{100001, 200001} {
		out, e := f.dmBase(s).LoadBase(ctx, actor(id), f.op())
		if e != nil || len(out.PrivateMessages) != 4 {
			t.Fatal(out, e)
		}
	}
	t.Log("REAL_PG opposing cross-server operations: committed outcomes or finite definite-abort; absent aborted IDs; fresh stock retries yield exactly8 immutable occurrences")
}

type dmWriteAmbiguous struct {
	db     tx.Beginner
	commit bool
	writes int
}

func (d *dmWriteAmbiguous) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.db.Begin(c, o)
	if e != nil {
		return nil, e
	}
	if o.ReadOnly {
		return t, nil
	}
	d.writes++
	return ambiguousTx{Tx: t, commit: d.commit}, nil
}

type changedPreflight struct {
	dm.Store
	once  sync.Once
	after func()
}

func (s *changedPreflight) Snapshot(c context.Context, q tx.Queryer, id identity.PlayerID, lock bool) (dm.Manifest, error) {
	m, e := s.Store.Snapshot(c, q, id, lock)
	if e == nil && !lock {
		s.once.Do(s.after)
	}
	return m, e
}
func Test6A_G11_G12ChangedManifestReplansWholeDrain(t *testing.T) {
	for _, empty := range []bool{false, true} {
		t.Run(fmt.Sprint(empty), func(t *testing.T) {
			f, s := dmPair(t)
			f.player(300001)
			f.friend(200001, 300001)
			if !empty {
				f.dmSend(s, 100001, 200001, "preflight-old")
			}
			hook := &changedPreflight{Store: s.Store, after: func() { f.dmSend(s, 300001, 200001, "new sender after preflight") }}
			composed := s
			composed.Store = hook
			out, e := f.dmBase(composed).LoadBase(ctx, actor(200001), f.op())
			if e != nil || len(out.PrivateMessages) != map[bool]int{true: 1, false: 2}[empty] {
				t.Fatal("full replan failed", out, e)
			}
			if f.number(`SELECT count(*) FROM friend_dm_delivery WHERE status='PENDING'`) != 0 || f.number(`SELECT count(*) FROM friend_dm_projection_receipts`) != 1 {
				t.Fatal("partial drain during aborted plan")
			}
		})
	}
}
func Test6A_G23CrashAfterWriteBeforeFinalizeDuplicateResidual(t *testing.T) {
	f, s := dmPair(t)
	fence, e := (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil {
		t.Fatal(e)
	}
	o := f.dmSend(s, 100001, 200001, "write-crash")
	claim, ok, e := s.Claim(ctx, 200001, fence, f.op())
	if e != nil || !ok {
		t.Fatal(e)
	}
	allowed, e := s.CheckClaim(ctx, claim, f.op())
	if e != nil || !allowed {
		t.Fatal(e)
	}
	// A socket write is observed in the process fixture. Here stop before calling
	// Complete, then simulate a process restart through the actual epoch owner.
	_, e = (presencestore.Store{Queryer: f.p}).ActivateRealtimeOwnerFence(ctx)
	if e != nil {
		t.Fatal(e)
	}
	out, e := f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(out.PrivateMessages) != 1 || out.PrivateMessages[0].Message != o.Message {
		t.Fatal("crash recovery missing", out, e)
	}
	t.Log("REAL_PG unfinalized claim + native owner restart epoch -> offline re-presentation; duplicate residual, no exactly-once claim")
}
func Test6A_G40UnrelatedReadsDoNotDrain(t *testing.T) {
	f, s := dmPair(t)
	f.dmSend(s, 100001, 200001, "preserve")
	before := f.dmSnapshot()
	for _, kind := range []sp.ListKind{sp.Friend, sp.Blacklist, sp.Request, sp.Notice} {
		if _, e := f.dmBase(s).LoadList(ctx, actor(200001), kind, f.op()); e != nil {
			t.Fatal(e)
		}
	}
	if _, e := f.dmBase(s).Recommend(ctx, actor(200001), f.op()); e != nil {
		t.Fatal(e)
	}
	f.ok(200001, sr.IgnoreRequests, 100001)
	if f.dmSnapshot() != before {
		t.Fatal("179/189/190 drained FriendDM")
	}
}

func dmContent(f *fixture) contentstore.Store { return contentstore.Store{Queryer: f.p} }
func initDMContent(t *testing.T, f *fixture) {
	t.Helper()
	_, e := registry.Initialize(ctx, registry.Service{Runner: tx.Runner{DB: f.p}, Repo: contentstore.Store{}, Fresh: f.p, Providers: registry.DefaultProviderSet()}, operation.Factory{Clock: clock.System{}})
	if e != nil {
		t.Fatal(e)
	}
}
func Test6A_G08ProjectionUnknownRollbackNoOutput(t *testing.T) {
	f, s := dmPair(t)
	f.dmSend(s, 100001, 200001, "keep private")
	before := f.dmSnapshot()
	base := f.dmBase(s)
	fault := &dmWriteAmbiguous{db: f.p, commit: false}
	base.FriendDM.Timed.Runner.DB = fault
	out, e := base.LoadBase(ctx, actor(200001), f.op())
	var unknown *tx.UnknownCommitError
	if !errors.As(e, &unknown) || len(out.PrivateMessages) != 0 || fault.writes != 1 || f.dmSnapshot() != before {
		t.Fatal("unknown projection output/replay/effect", out, e, fault.writes)
	}
}
func Test6A_G36PinnedContentMissingAndProviderFailClosed(t *testing.T) {
	f, s := dmPair(t)
	initDMContent(t, f)
	op := f.op()
	out, e := s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 1, EmoticonID: 1}, op)
	if e != nil {
		t.Fatal(e)
	}
	before := f.dmSnapshot()
	artifact := f.text(`SELECT artifact::text FROM content_emoticon_catalogs WHERE revision_id=$1`, out.ContentRevision)
	f.sql(`DELETE FROM content_emoticon_catalogs WHERE revision_id=$1`, out.ContentRevision)
	value, e := f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e == nil || len(value.PrivateMessages) != 0 || f.dmSnapshot() != before {
		t.Fatal("missing pinned definition published or drained", value, e)
	}
	f.sql(`INSERT INTO content_emoticon_catalogs(revision_id,artifact)VALUES($1,$2::jsonb)`, out.ContentRevision, artifact)
	missing := s
	missing.Content = nil
	if _, e = missing.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 1, EmoticonID: 1}, f.op()); e == nil || f.dmSnapshot() != before {
		t.Fatal("missing content provider accepted")
	}
	missing = s
	missing.Entitlement = nil
	if _, e = missing.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 1, EmoticonID: 1}, f.op()); e == nil || f.dmSnapshot() != before {
		t.Fatal("missing entitlement provider accepted")
	}
	if _, e = s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 1, EmoticonID: 999}, f.op()); e == nil || f.dmSnapshot() != before {
		t.Fatal("undefined content admitted")
	}
	value, e = f.dmBase(s).LoadBase(ctx, actor(200001), f.op())
	if e != nil || len(value.PrivateMessages) != 1 {
		t.Fatal("restored pinned content", value, e)
	}
	t.Log("REAL_PG catalog absence fault -> atomic fail-closed/no private output; restored exact artifact; absent typed providers and undefined content rejected")
}
func Test6A_G19StalePreparationFailsBeforeMutation(t *testing.T) {
	f, s := dmPair(t)
	s.Timed.Binder.Time = fixedDMClock{f.now().Add(-3 * time.Second)}
	before := f.dmSnapshot()
	if _, e := s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 0, Text: "stale"}, f.op()); !errors.Is(e, dm.ErrStale) || f.dmSnapshot() != before {
		t.Fatal("stale-after-lock mutation", e)
	}
}

type everyChangedPreflight struct {
	dm.Store
	after func()
	reads int
}

func (s *everyChangedPreflight) Snapshot(c context.Context, q tx.Queryer, id identity.PlayerID, lock bool) (dm.Manifest, error) {
	m, e := s.Store.Snapshot(c, q, id, lock)
	if e == nil && !lock {
		s.reads++
		s.after()
	}
	return m, e
}
func Test6A_G11ManifestRetryCapNoSubsetDrain(t *testing.T) {
	f, s := dmPair(t)
	hook := &everyChangedPreflight{Store: s.Store, after: func() { f.dmSend(s, 100001, 200001, "manifest perturbation") }}
	composed := s
	composed.Store = hook
	value, e := f.dmBase(composed).LoadBase(ctx, actor(200001), f.op())
	if !errors.Is(e, dm.ErrManifestChanged) || len(value.PrivateMessages) != 0 || hook.reads != 3 || f.number(`SELECT count(*)FROM friend_dm_delivery WHERE status='PENDING'`) != 3 || f.number(`SELECT count(*)FROM friend_dm_projection_receipts`) != 0 {
		t.Fatal("manifest cap/subset drain", value, e, hook.reads)
	}
}
func Test6A_G02Empty176CreatesNoOwnerRows(t *testing.T) {
	f := fresh(t)
	f.player(100001)
	s := f.dm()
	socialBefore := f.snapshot()
	dmBefore := f.dmSnapshot()
	value, e := f.dmBase(s).LoadBase(ctx, actor(100001), f.op())
	if e != nil || value.PrivateMessages == nil || len(value.PrivateMessages) != 0 || f.snapshot() != socialBefore || f.dmSnapshot() != dmBefore {
		t.Fatal("empty176 semantic write/array", value, e)
	}
}
