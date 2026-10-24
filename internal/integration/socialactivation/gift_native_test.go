//go:build postgres && socialintegration

package socialactivation_test

import (
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialgiftstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialinboxstore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func giftFixture(t *testing.T) (*fixture, sg.Service, identity.ActorContext, identity.ActorContext) {
	f := fresh(t)
	f.sql(`TRUNCATE social_gift_epochs CASCADE`)
	f.sql(`TRUNCATE gxb_operation_receipts CASCADE`)
	f.player(100001)
	f.player(200001)
	f.friend(100001, 200001)
	a, _ := f.live(100001)
	b, _ := f.live(200001)
	_, e := registry.Initialize(ctx, registry.Service{Runner: tx.Runner{DB: f.p}, Repo: contentstore.Store{}, Fresh: f.p, Providers: registry.DefaultProviderSet()}, operation.Factory{Clock: clock.System{}})
	if e != nil {
		t.Fatal(e)
	}
	return f, f.gift(), a, b
}
func (f *fixture) gift() sg.Service {
	r := tx.Runner{DB: f.p}
	db := i5store.Store{Queryer: f.p}
	inbox := socialinboxstore.Store{}
	content := contentstore.Store{Queryer: f.p}
	gr := i5.Service{Runner: r, Store: db, Content: content, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: f.p}}
	return sg.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: f.p}}, Runner: r}, Reads: r, Store: socialgiftstore.Store{}, Content: content, Players: i4store.PlayerRootLocker{}, Relations: socialrelationstore.Store{}, Privacy: sr.FriendDMPrivacyProvider{Store: socialrelationstore.Store{}}, Inbox: socialinbox.GiftService{Store: inbox}, NoticeEvidence: inbox, Grants: gr, Admission: f.authority(), Fence: db}
}
func (f *fixture) giftState() string {
	return f.text(`SELECT jsonb_build_object('epochs',(SELECT coalesce(jsonb_agg(to_jsonb(e) ORDER BY player_id,day_token),'[]') FROM social_gift_epochs e),'transfers',(SELECT coalesce(jsonb_agg(to_jsonb(g) ORDER BY transfer_id),'[]') FROM social_gift_transfers g),'claims',(SELECT coalesce(jsonb_agg(to_jsonb(o) ORDER BY operation_id),'[]') FROM social_gift_claim_operations o),'scalar',(SELECT coalesce(jsonb_agg(to_jsonb(s) ORDER BY player_id,resource_key),'[]') FROM player_currency_balances s),'social',$1::jsonb)::text`, f.snapshot())
}
func Test7A_SendClaimCanonicalKnownReplay(t *testing.T) {
	f, s, a, b := giftFixture(t)
	send := f.op()
	r, e := s.Send(ctx, a, b.PlayerID, send)
	if e != nil {
		t.Fatal(e)
	}
	if len(r.NoticeIDs) != 1 || r.Amount != 0 || f.number(`SELECT count(*) FROM social_gift_transfers`) != 1 {
		t.Fatal(r)
	}
	r2, e := s.Send(ctx, a, b.PlayerID, send)
	if e != nil || !reflect.DeepEqual(r, r2) {
		t.Fatal(r2, e)
	}
	if _, e = s.Send(ctx, a, b.PlayerID, f.op()); !errors.Is(e, sg.ErrDuplicate) {
		t.Fatal(e)
	}
	claim := f.op()
	got, e := s.Claim(ctx, b, []socialinbox.NoticeID{r.NoticeIDs[0], r.NoticeIDs[0], 999999}, claim)
	if e != nil {
		t.Fatal(e)
	}
	if got.Amount != 5 || len(got.NoticeIDs) != 1 || got.GrantReceiptID == "" || f.number(`SELECT amount FROM player_currency_balances WHERE player_id=200001 AND resource_key='friendship_coin'`) != 5 {
		t.Fatal(got)
	}
	again, e := s.Claim(ctx, b, []socialinbox.NoticeID{r.NoticeIDs[0], 999999}, claim)
	if e != nil || !reflect.DeepEqual(got, again) {
		t.Fatal(again, e)
	}
	before := f.giftState()
	if _, e = s.Claim(ctx, b, r.NoticeIDs, f.op()); !errors.Is(e, sg.ErrConflict) || f.giftState() != before {
		t.Fatal(e)
	}
	t.Log("REAL_PG natural uniqueness, typed reciprocal notice, dedup order, one named scalar grant, complete known replay, no duplicate credit")
}
func Test7A_UnknownCommitNeverBlindReplay(t *testing.T) {
	for _, send := range []bool{true, false} {
		for _, commit := range []bool{true, false} {
			t.Run(map[bool]string{true: "send", false: "claim"}[send]+map[bool]string{true: "commit", false: "rollback"}[commit], func(t *testing.T) {
				f, s, a, b := giftFixture(t)
				var ids []socialinbox.NoticeID
				if !send {
					r, e := s.Send(ctx, a, b.PlayerID, f.op())
					if e != nil {
						t.Fatal(e)
					}
					ids = r.NoticeIDs
				}
				fault := &ambiguousBeginner{db: f.p, commit: commit}
				s.Timed.Runner.DB = fault
				var e error
				if send {
					_, e = s.Send(ctx, a, b.PlayerID, f.op())
				} else {
					_, e = s.Claim(ctx, b, ids, f.op())
				}
				if commit {
					if e != nil {
						t.Fatal(e)
					}
				} else {
					var unknown *tx.UnknownCommitError
					if !errors.As(e, &unknown) {
						t.Fatal(e)
					}
				}
				if fault.begins != 1 {
					t.Fatal("blind replay", fault.begins)
				}
				t.Log("REAL_PG actual commit/rollback plus ambiguous client result; complete source witness only")
			})
		}
	}
}
func Test7A_PostIssueRelationChangeAndMidnight(t *testing.T) {
	f, s, a, b := giftFixture(t)
	at := time.Date(2026, 10, 8, 15, 59, 59, 0, time.UTC)
	s.Timed.Binder.Time = fixedDMClock{at}
	f.sql(`UPDATE player_social_roots SET created_at=$1,updated_at=$1`, at.Add(-time.Hour))
	f.sql(`UPDATE social_friendships SET activated_at=$1,updated_at=$1`, at.Add(-time.Hour))
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	f.sql(`UPDATE social_friendships SET active=false,ended_at=$1,updated_at=$1`, at)
	f.block(b.PlayerID, a.PlayerID)
	next := at.Add(time.Second)
	s.Timed.Binder.Time = fixedDMClock{next}
	got, e := s.Claim(ctx, b, r.NoticeIDs, f.op())
	if e != nil || got.Amount != 5 {
		t.Fatal(got, e)
	}
	if f.text(`SELECT sender_day FROM social_gift_transfers`) != "2026-10-08" || f.text(`SELECT claim_day FROM social_gift_transfers`) != "2026-10-09" {
		t.Fatal("day boundary")
	}
	t.Log("REAL_PG injected exact database-time port before/at GMT+8 midnight; old gifts survive relation/privacy changes")
}

func Test7A_EligibilityActorAndNaturalFences(t *testing.T) {
	for _, kind := range []string{"self", "missing", "notfriend", "receiverblock", "senderblock", "forgedUID", "forgedPlayer", "revoked", "rotatedContext", "rotatedSession", "expired", "refriend"} {
		t.Run(kind, func(t *testing.T) {
			f, s, a, b := giftFixture(t)
			target := b.PlayerID
			wantSuccess := kind == "senderblock"
			switch kind {
			case "self":
				target = a.PlayerID
			case "missing":
				target = 300001
			case "notfriend":
				f.sql(`UPDATE social_friendships SET active=false,ended_at=$1`, f.now())
			case "receiverblock":
				f.block(b.PlayerID, a.PlayerID)
			case "senderblock":
				f.block(a.PlayerID, b.PlayerID)
			case "forgedUID":
				a.AccountUID = "999"
			case "forgedPlayer":
				a.PlayerID = b.PlayerID
				a.LogicalServerID = b.LogicalServerID
			case "revoked":
				f.sql(`UPDATE account_sessions SET revoked_at=$1,revocation_reason='fixture' WHERE session_id=$2::uuid`, f.now(), a.SessionID.UUID().String())
			case "rotatedContext":
				f.sql(`UPDATE gameplay_contexts SET liveness_version=2 WHERE context_id=$1::uuid`, a.ContextID.UUID().String())
			case "rotatedSession":
				f.sql(`UPDATE account_sessions SET liveness_version=2 WHERE session_id=$1::uuid`, a.SessionID.UUID().String())
			case "expired":
				f.sql(`UPDATE account_sessions SET absolute_expires_at=$1 WHERE session_id=$2::uuid`, f.now(), a.SessionID.UUID().String())
			case "refriend":
				if _, e := s.Send(ctx, a, target, f.op()); e != nil {
					t.Fatal(e)
				}
				f.sql(`UPDATE social_friendships SET generation=2,state_version=2,activated_at=$1,updated_at=$1`, f.now())
			}
			before := f.giftState()
			_, e := s.Send(ctx, a, target, f.op())
			if wantSuccess {
				if e != nil {
					t.Fatal(e)
				}
			} else if e == nil || f.giftState() != before {
				t.Fatal("eligibility/fence failure mutated", e)
			}
			t.Log("REAL_PG owner eligibility/liveness and source conservation")
		})
	}
}
func Test7A_ClockVersionNoticeBoundaryAndScalarFailures(t *testing.T) {
	for _, kind := range []string{"rootversion", "rootfuture", "epochversion", "epochfuture", "epochlaterday", "noticesequence", "scalaroverflow", "scalarversion", "scalarfuture"} {
		t.Run(kind, func(t *testing.T) {
			f, s, a, b := giftFixture(t)
			var ns []socialinbox.NoticeID
			if kind == "epochversion" || kind == "epochfuture" || kind == "epochlaterday" || kind == "scalaroverflow" || kind == "scalarversion" || kind == "scalarfuture" {
				r, e := s.Send(ctx, a, b.PlayerID, f.op())
				if e != nil {
					t.Fatal(e)
				}
				ns = r.NoticeIDs
			}
			claim := false
			switch kind {
			case "rootversion":
				f.sql(`UPDATE player_social_roots SET state_version=9223372036854775807`)
			case "rootfuture":
				f.sql(`UPDATE player_social_roots SET updated_at=$1`, f.now().Add(time.Hour))
			case "epochversion":
				f.sql(`UPDATE social_gift_epochs SET state_version=9223372036854775807`)
			case "epochfuture":
				f.sql(`UPDATE social_gift_epochs SET updated_at=$1`, f.now().Add(time.Hour))
			case "epochlaterday":
				f.sql(`UPDATE social_gift_epochs SET day_token='2099-01-01'`)
			case "noticesequence":
				f.sql(`SELECT setval('social_notice_id_seq',9007199254740992,false)`)
			case "scalaroverflow", "scalarversion", "scalarfuture":
				claim = true
				amount := int64(0)
				version := int64(1)
				at := f.now().Add(-time.Hour)
				if kind == "scalaroverflow" {
					amount = 9223372036854775807
				}
				if kind == "scalarversion" {
					version = 9223372036854775807
				}
				if kind == "scalarfuture" {
					at = f.now().Add(time.Hour)
				}
				f.sql(`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES(200001,'friendship_coin',$1,$2,$3)`, amount, version, at)
			}
			before := f.giftState()
			var e error
			if claim {
				_, e = s.Claim(ctx, b, ns, f.op())
			} else {
				if len(ns) > 0 {
					f.player(300001)
					f.friend(a.PlayerID, 300001)
					before = f.giftState()
					_, e = s.Send(ctx, a, 300001, f.op())
				} else {
					_, e = s.Send(ctx, a, b.PlayerID, f.op())
				}
			}
			if e == nil || f.giftState() != before {
				t.Fatal("clock/overflow/boundary failed atomicity", e)
			}
			t.Log("REAL_PG failure preserved all source and value; sequence gaps are allowed")
		})
	}
}
func Test7A_ClaimMixedPreflightUnknownAndLargeIDs(t *testing.T) {
	for _, kind := range []string{"validmixed", "missingtransfer", "wrongamount", "wrongsource", "claimed", "unsupported", "large"} {
		t.Run(kind, func(t *testing.T) {
			f, s, a, b := giftFixture(t)
			r, e := s.Send(ctx, a, b.PlayerID, f.op())
			if e != nil {
				t.Fatal(e)
			}
			f.sql(`INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,notice_time,state_version,created_at,updated_at)VALUES(200001,999,2,'social-relation.request.v1','200001:100001:1:DENY',100001,$1,1,$1,$1),(200001,998,6,'future.family','opaque',100001,$1,1,$1,$1)`, f.now())
			ids := []socialinbox.NoticeID{999, r.NoticeIDs[0], 999, 998, 123456}
			success := kind == "validmixed" || kind == "large"
			switch kind {
			case "missingtransfer":
				f.sql(`DELETE FROM social_gift_transfers`)
			case "wrongamount":
				f.sql(`UPDATE social_notices SET notice_time=notice_time+interval '1 second' WHERE notice_type=4`)
			case "wrongsource":
				f.sql(`UPDATE social_notices SET source_key=gen_random_uuid()::text WHERE notice_type=4`)
			case "claimed":
				if _, e = s.Claim(ctx, b, r.NoticeIDs, f.op()); e != nil {
					t.Fatal(e)
				}
			case "unsupported":
				original := f.text(`SELECT payload::text FROM content_social_gift_catalogs`)
				t.Cleanup(func() { f.sql(`UPDATE content_social_gift_catalogs SET payload=$1::jsonb`, original) })
				f.sql(`UPDATE content_social_gift_catalogs SET payload=jsonb_set(payload,'{selector}','"GUESS_LEVEL"')`)
			case "large":
				for n := 0; n < 1000; n++ {
					ids = append(ids, socialinbox.NoticeID(100000+n))
				}
			}
			before := f.giftState()
			got, e := s.Claim(ctx, b, ids, f.op())
			if success {
				if e != nil || got.Amount != 5 || !reflect.DeepEqual(got.NoticeIDs, []socialinbox.NoticeID{999, r.NoticeIDs[0]}) || f.number(`SELECT count(*) FROM social_notices WHERE notice_id=998 AND active`) != 1 {
					t.Fatal(got, e)
				}
			} else if e == nil || f.giftState() != before {
				t.Fatal("mixed batch partially consumed", e)
			}

			t.Log("REAL_PG mixed preflight atomicity; finite owner source qualification; first dedup order and no artificial cap50")
		})
	}
}
func Test7A_QuotaCountsAndConcurrentLastSlot(t *testing.T) {
	f, s, a, b := giftFixture(t)
	s.Timed.Binder.Time = fixedDMClock{f.now().Add(time.Hour)}
	for n := 0; n < 9; n++ {
		pid := identity.PlayerID(300001 + n)
		f.player(pid)
		f.friend(a.PlayerID, pid)
		if _, e := s.Send(ctx, a, pid, f.op()); e != nil {
			t.Fatal(e)
		}
	}
	var successes int64
	var wg sync.WaitGroup
	start := make(chan struct{})
	for _, pid := range []identity.PlayerID{b.PlayerID, 400001} {
		if pid == 400001 {
			f.player(pid)
			f.friend(a.PlayerID, pid)
		}
		wg.Add(1)
		go func(pid identity.PlayerID) {
			defer wg.Done()
			<-start
			_, e := s.Send(ctx, a, pid, f.op())
			if e == nil {
				atomic.AddInt64(&successes, 1)
			} else if !errors.Is(e, sg.ErrQuota) {
				t.Errorf("send race: %v", e)
			}
		}(pid)
	}
	close(start)
	wg.Wait()
	if successes != 1 || f.number(`SELECT count(*) FROM social_gift_transfers WHERE sender_player_id=100001`) != 10 {
		t.Fatal(successes)
	}
	// New recipient: ten distinct senders, one old-day gift carried forward.
	for n := 0; n < 11; n++ {
		pid := identity.PlayerID(500001 + n)
		f.player(pid)
		f.friend(pid, b.PlayerID)
		sender, _ := f.live(pid)
		r, e := s.Send(ctx, sender, b.PlayerID, f.op())
		if e != nil {
			t.Fatal(e)
		}
		if n < 9 {
			if _, e = s.Claim(ctx, b, r.NoticeIDs, f.op()); e != nil {
				t.Fatal(e)
			}
		}
	}
	var remaining []byte
	if e := f.p.QueryRow(ctx, `SELECT jsonb_agg(notice_id ORDER BY notice_id) FROM social_gift_transfers WHERE recipient_player_id=200001 AND claim_operation_id IS NULL`).Scan(&remaining); e != nil {
		t.Fatal(e)
	}
	var noticeIDs []socialinbox.NoticeID
	if e := json.Unmarshal(remaining, &noticeIDs); e != nil {
		t.Fatal(e)
	}
	successes = 0
	start = make(chan struct{})
	for _, nid := range noticeIDs {
		wg.Add(1)
		go func(id socialinbox.NoticeID) {
			defer wg.Done()
			<-start
			_, e := s.Claim(ctx, b, []socialinbox.NoticeID{id}, f.op())
			if e == nil {
				atomic.AddInt64(&successes, 1)
			} else if !errors.Is(e, sg.ErrQuota) {
				t.Errorf("claim race: %v", e)
			}
		}(nid)
	}
	close(start)
	wg.Wait()
	if successes != 1 || f.number(`SELECT amount FROM player_currency_balances WHERE player_id=200001 AND resource_key='friendship_coin'`) != 50 || f.number(`SELECT count(*) FROM social_gift_transfers WHERE recipient_player_id=200001 AND claim_operation_id IS NOT NULL`) != 10 {
		t.Fatal(successes)
	}
	t.Log("REAL_PG counts derived exclusively from transfers; last send/receive slot concurrent losers conserve value")
}
func Test7A_TenCompetingSendsAndEleventhQuota(t *testing.T) {
	f, s, a, _ := giftFixture(t)
	s.Timed.Binder.Time = fixedDMClock{f.now().Add(time.Hour)}
	for n := 0; n < 11; n++ {
		pid := identity.PlayerID(600001 + n)
		f.player(pid)
		f.friend(a.PlayerID, pid)
	}
	start := make(chan struct{})
	rejected := make(chan identity.PlayerID, 10)
	var wg sync.WaitGroup
	for n := 0; n < 10; n++ {
		pid := identity.PlayerID(600001 + n)
		wg.Add(1)
		go func(pid identity.PlayerID) {
			defer wg.Done()
			op := f.op()
			<-start
			_, e := s.Send(ctx, a, pid, op)
			if e != nil {
				if !tx.IsDefiniteAbortError(e) {
					t.Errorf("unexpected send race: %v", e)
					return
				}
				if _, ok, err := s.Store.ReadSend(ctx, f.p, op.ID); err != nil || ok {
					t.Errorf("definite abort source leaked: %v", err)
					return
				}
				rejected <- pid
			}
		}(pid)
	}
	close(start)
	wg.Wait()
	close(rejected)
	aborts := 0
	for pid := range rejected {
		aborts++
		if _, e := s.Send(ctx, a, pid, f.op()); e != nil {
			t.Fatal(e)
		}
	}
	if f.number(`SELECT count(*) FROM social_gift_transfers`) != 10 {
		t.Fatal("ten transfer conservation")
	}
	before := f.giftState()
	if _, e := s.Send(ctx, a, 600011, f.op()); !errors.Is(e, sg.ErrQuota) || f.giftState() != before {
		t.Fatal("eleventh quota", e)
	}
	t.Logf("REAL_PG ten competing sends; bounded internal retry preserved, %d authoritative definite-aborts had no source and were resubmitted as separate fresh operations; exactly ten facts, eleventh rejected", aborts)
}
func Test7A_PureSnapshotDoesNotRefreshEpoch(t *testing.T) {
	f, s, a, b := giftFixture(t)
	if _, e := s.Send(ctx, a, b.PlayerID, f.op()); e != nil {
		t.Fatal(e)
	}
	before := f.giftState()
	at := f.now()
	snap, e := s.GiftSnapshotTx(ctx, f.p, a.PlayerID, at)
	if e != nil || snap.Sent != 1 || !reflect.DeepEqual(snap.SentRecipients, []identity.PlayerID{b.PlayerID}) || f.giftState() != before {
		t.Fatal(snap, e)
	}
	sent, claimed, e := s.SnapshotTx(ctx, f.p, a.PlayerID, at)
	if e != nil || sent != 1 || claimed != 0 || f.giftState() != before {
		t.Fatal(sent, claimed, e)
	}
	sent, claimed, e = s.SnapshotTx(ctx, f.p, a.PlayerID, at.Add(24*time.Hour))
	if e != nil || sent != 0 || claimed != 0 || f.giftState() != before {
		t.Fatal("observation refreshed day", sent, claimed, e)
	}
	t.Log("REAL_PG pure fact-derived snapshot at caller observedAt, including next day without epoch writes")
}
