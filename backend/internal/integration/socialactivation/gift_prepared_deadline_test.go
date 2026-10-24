//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"errors"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

func Test7A_PreparedConsumptionTxnAndDescriptorBinding(t *testing.T) {
	f, s, a, b := giftFixture(t)
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
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
	n, ok, e := s.Inbox.Store.LockNoticeTx(ctx, x, b.PlayerID, r.NoticeIDs[0])
	if e != nil || !ok {
		t.Fatal(e)
	}
	id, e := ids.ParseUUID(r.TransferIDs[0])
	if e != nil {
		t.Fatal(e)
	}
	v, ok, e := s.Store.ReadTransfer(ctx, x, id)
	if e != nil || !ok {
		t.Fatal(e)
	}
	fence := socialinbox.RecipientFence{PlayerID: b.PlayerID, StateVersion: 1}
	p, e := s.Inbox.PrepareConsumptionTx(ctx, x, fence, n, v.Descriptor(), f.now())
	if e != nil {
		t.Fatal(e)
	}
	if e = s.Inbox.ApplyConsumptionTx(ctx, y, p); e == nil {
		t.Fatal("consumption plan crossed caller Tx")
	}
	bad := v.Descriptor()
	bad.TransferID, _ = ids.NewUUID()
	if _, e = s.Inbox.PrepareConsumptionTx(ctx, x, fence, n, bad, f.now()); e == nil {
		t.Fatal("substituted membership/source descriptor")
	}
	if e = s.Inbox.ApplyConsumptionTx(ctx, x, socialinbox.PreparedGiftConsumption{}); e == nil {
		t.Fatal("unprepared plan accepted")
	}
	if e = s.Inbox.Store.DismissNoticeTx(ctx, x, n, f.now()); e == nil {
		t.Fatal("relation-only dismissal consumed Gift")
	}
	t.Log("REAL_PG private Gift consumption plan rejects wrongTx, changed source/member and unprepared caller; legacy relation dismiss stays finite")
}

type giftDeadlineAdmission struct {
	sg.ActorAdmission
	observed *bool
	block    bool
}

func (a giftDeadlineAdmission) ValidateActor(c context.Context, actor identity.ActorContext, at time.Time) error {
	deadline, ok := c.Deadline()
	if !ok || time.Until(deadline) > sg.Profile().OperationTimeout {
		return errors.New("missing shared command deadline")
	}
	*a.observed = true
	if a.block {
		<-c.Done()
		return c.Err()
	}
	return a.ActorAdmission.ValidateActor(c, actor, at)
}
func Test7A_SharedDeadlineCoversAdmissionAndEntireCommand(t *testing.T) {
	f, s, a, b := giftFixture(t)
	observed := false
	s.Admission = giftDeadlineAdmission{s.Admission, &observed, false}
	if _, e := s.Send(ctx, a, b.PlayerID, f.op()); e != nil || !observed {
		t.Fatal(observed, e)
	}
	before := f.giftState()
	observed = false
	s.Admission = giftDeadlineAdmission{s.Admission, &observed, true}
	op := f.op()
	bounded, cancel := context.WithTimeout(ctx, 50*time.Millisecond)
	defer cancel()
	if _, e := s.Claim(bounded, b, []socialinbox.NoticeID{1}, op); !errors.Is(e, context.DeadlineExceeded) || !observed || f.giftState() != before {
		t.Fatal("deadline allowed effects", observed, e)
	}
	t.Log("REAL_PG owner state with injected blocked admission: one finite parent deadline covers pre-Tx admission, replay/content reads and gameplay; cancellation commits no effects")
}
