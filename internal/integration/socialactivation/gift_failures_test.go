//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/application/i5"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"strings"
	"testing"
	"time"
)

var giftInjected = errors.New("gift injected after durable write")

type giftFault struct{ stage string }

func (f giftFault) after(stage string, e error) error {
	if e == nil && f.stage == stage {
		return giftInjected
	}
	return e
}

type giftStoreFault struct {
	sg.Store
	giftFault
}

func (f giftStoreFault) PutEpoch(c context.Context, t tx.Tx, e sg.Epoch, ok bool, at time.Time) error {
	return f.after("epoch", f.Store.PutEpoch(c, t, e, ok, at))
}
func (f giftStoreFault) InsertTransfer(c context.Context, t tx.Tx, v sg.Transfer) error {
	return f.after("transfer", f.Store.InsertTransfer(c, t, v))
}
func (f giftStoreFault) ClaimTransfer(c context.Context, t tx.Tx, v sg.Transfer, old int64) error {
	return f.after("claim-transfer", f.Store.ClaimTransfer(c, t, v, old))
}
func (f giftStoreFault) InsertClaim(c context.Context, t tx.Tx, v sg.ClaimOperation) error {
	return f.after("claim-operation", f.Store.InsertClaim(c, t, v))
}

type giftInboxFault struct {
	socialinbox.GiftNoticeStore
	giftFault
}

func (f giftInboxFault) InsertGiftNoticeTx(c context.Context, t tx.Tx, n socialinbox.Notice) (socialinbox.Notice, error) {
	v, e := f.GiftNoticeStore.InsertGiftNoticeTx(c, t, n)
	return v, f.after("notice", e)
}
func (f giftInboxFault) ConsumeGiftNoticeTx(c context.Context, t tx.Tx, n socialinbox.Notice, at time.Time) error {
	return f.after("consume", f.GiftNoticeStore.ConsumeGiftNoticeTx(c, t, n, at))
}
func (f giftInboxFault) DismissNoticeTx(c context.Context, t tx.Tx, n socialinbox.Notice, at time.Time) error {
	return f.after("relation-dismiss", f.GiftNoticeStore.DismissNoticeTx(c, t, n, at))
}

type giftRelationFault struct {
	sg.RelationOwner
	giftFault
}

func (f giftRelationFault) TouchRootTx(c context.Context, t tx.Tx, r sr.Root, at time.Time) error {
	return f.after("root", f.RelationOwner.TouchRootTx(c, t, r, at))
}

type giftGrantFault struct {
	sg.GrantOwner
	giftFault
}

func (f giftGrantFault) SettleGrantTx(c context.Context, t tx.Tx, a identity.ActorContext, p grant.Plan, op operation.Context, o i5.GrantTxOptions) (i5.GrantResult, error) {
	v, e := f.GrantOwner.SettleGrantTx(c, t, a, p, op, o)
	return v, f.after("grant", e)
}
func Test7A_RollbackAfterEveryOwnerWrite(t *testing.T) {
	for _, send := range []bool{true, false} {
		stages := []string{"epoch", "notice", "transfer", "root"}
		if !send {
			stages = []string{"grant", "epoch", "claim-transfer", "consume", "relation-dismiss", "root", "claim-operation"}
		}
		for _, stage := range stages {
			t.Run(fmt.Sprint(send)+stage, func(t *testing.T) {
				f, s, a, b := giftFixture(t)
				var ids []socialinbox.NoticeID
				if !send {
					r, e := s.Send(ctx, a, b.PlayerID, f.op())
					if e != nil {
						t.Fatal(e)
					}
					ids = r.NoticeIDs
					f.sql(`INSERT INTO social_notices(recipient_player_id,notice_id,notice_type,source_kind,source_key,related_player_id,notice_time,state_version,created_at,updated_at)VALUES(200001,999,2,'social-relation.request.v1','200001:100001:1:DENY',100001,$1,1,$1,$1)`, f.now())
					ids = append(ids, 999)
				}
				fault := giftFault{stage}
				s.Store = giftStoreFault{s.Store, fault}
				s.Inbox.Store = giftInboxFault{s.Inbox.Store, fault}
				s.Relations = giftRelationFault{s.Relations, fault}
				s.Grants = giftGrantFault{s.Grants, fault}
				before := f.giftState()
				var e error
				if send {
					_, e = s.Send(ctx, a, b.PlayerID, f.op())
				} else {
					_, e = s.Claim(ctx, b, ids, f.op())
				}
				if !errors.Is(e, giftInjected) || f.giftState() != before {
					t.Fatal("atomic rollback", e)
				}
				if f.number(`SELECT count(*) FROM gxb_operation_receipts WHERE domain='grant'`) != 0 {
					t.Fatal("receipt leaked")
				}
				t.Log("REAL_PG after-write fault rolled back source, typed notice, scalar and receipt in the same caller Tx")
			})
		}
	}
}
func Test7A_ExactReplayConflictAndPartialRestore(t *testing.T) {
	for _, kind := range []string{"entropy", "started", "ids", "policies", "receipt", "transfer", "claimoperation", "epoch", "balance", "content", "inactive"} {
		t.Run(kind, func(t *testing.T) {
			f, s, a, b := giftFixture(t)
			r, e := s.Send(ctx, a, b.PlayerID, f.op())
			if e != nil {
				t.Fatal(e)
			}
			op := f.op()
			got, e := s.Claim(ctx, b, r.NoticeIDs, op)
			if e != nil {
				t.Fatal(e)
			}
			ids := r.NoticeIDs
			switch kind {
			case "entropy":
				op.EntropySeed[0]++
			case "started":
				op.StartedAt = op.StartedAt.Add(time.Microsecond)
			case "ids":
				ids = []socialinbox.NoticeID{123}
			case "policies":
				p, _ := policy.NewSet(policy.Ref{Name: "content", Version: strings.Repeat("a", 64)})
				op.Policies = p
			case "receipt":
				f.sql(`DELETE FROM gxb_operation_receipts WHERE domain='grant'`)
			case "transfer":
				f.sql(`DELETE FROM social_gift_transfers`)
			case "claimoperation":
				f.sql(`TRUNCATE social_gift_claim_operations CASCADE`)
			case "epoch":
				f.sql(`TRUNCATE social_gift_epochs CASCADE`)
			case "balance":
				f.sql(`DELETE FROM player_currency_balances WHERE resource_key='friendship_coin'`)
			case "content":
				original := f.text(`SELECT payload::text FROM content_social_gift_catalogs`)
				f.sql(`DELETE FROM content_social_gift_catalogs`)
				t.Cleanup(func() {
					f.sql(`INSERT INTO content_social_gift_catalogs(revision_id,payload)VALUES($1,$2::jsonb)`, got.Revision, original)
				})
			case "inactive":
				activation := f.text(`SELECT to_jsonb(a)::text FROM gxb_content_activation a`)
				f.sql(`DELETE FROM gxb_content_activation`)
				t.Cleanup(func() {
					f.sql(`INSERT INTO gxb_content_activation SELECT * FROM jsonb_populate_record(NULL::gxb_content_activation,$1::jsonb)`, activation)
				})
			}
			before := f.giftState()
			again, e := s.Claim(ctx, b, ids, op)
			if kind == "inactive" {
				if e != nil || !reflect.DeepEqual(got, again) {
					t.Fatal("known replay depended on today activation", again, e)
				}
			} else if e == nil || f.giftState() != before {
				t.Fatal("partial restore or conflict recredited", e)
			}
			t.Log("REAL_PG exact operation conflict/full source proof; deliberately incomplete restore cannot manufacture value")
		})
	}
}
func Test7A_DeletedSenderReceiverRestrictionAndPreparedTx(t *testing.T) {
	f, s, a, b := giftFixture(t)
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	deletion, e := f.p.Raw().Begin(ctx)
	if e != nil {
		t.Fatal(e)
	}
	deletion.Exec(ctx, `DELETE FROM gameplay_context_credentials WHERE context_id IN(SELECT context_id FROM gameplay_contexts WHERE player_id=200001)`)
	deletion.Exec(ctx, `DELETE FROM gameplay_contexts WHERE player_id=200001`)
	deletion.Exec(ctx, `DELETE FROM player_directory_profiles WHERE player_id=200001`)
	_, e = deletion.Exec(ctx, `DELETE FROM players WHERE player_id=200001`)
	deletion.Rollback(ctx)
	if e == nil || !strings.Contains(e.Error(), "social_gift") {
		t.Fatal("receiver gift restrict missing", e)
	}
	f.sql(`DELETE FROM gameplay_context_credentials WHERE context_id IN(SELECT context_id FROM gameplay_contexts WHERE player_id=100001)`)
	f.sql(`DELETE FROM gameplay_contexts WHERE player_id=100001`)
	f.sql(`DELETE FROM player_directory_profiles WHERE player_id=100001`)
	f.sql(`DELETE FROM players WHERE player_id=100001`)
	got, e := s.Claim(ctx, b, r.NoticeIDs, f.op())
	if e != nil || got.Amount != 5 {
		t.Fatal(got, e)
	}
	if f.number(`SELECT count(*) FROM players WHERE player_id=100001`) != 0 || f.number(`SELECT count(*) FROM social_notices WHERE notice_type=4 AND related_player_id IS NULL`) != 1 {
		t.Fatal("sender resurrected")
	}
	x, e := f.p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer x.Rollback(ctx)
	y, e := f.p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer y.Rollback(ctx)
	u, _ := ids.NewUUID()
	p, e := s.Inbox.PrepareTx(ctx, x, socialinbox.RecipientFence{PlayerID: b.PlayerID, StateVersion: 1}, socialinbox.GiftDescriptor{TransferID: u, Sender: 300001, Recipient: b.PlayerID, IssuedAt: f.now()})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = s.Inbox.ApplyTx(ctx, y, p); e == nil {
		t.Fatal("prepared plan crossed caller Tx")
	}
	t.Log("REAL_PG retained sender tombstone and claim value, receiver FK restrict, private prepared plan Tx binding")
}
