package i5

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MailExpiryLoginReconciler stamps the overflow mails a grant made for someone
// else (or a system settlement) left without an expiry. It runs in MID1's
// transaction, so it never advances shared time-driven state on a read path.
type MailExpiryLoginReconciler struct {
	Store interface {
		MailTuningReader
		StampOverflowMailExpiryTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (int64, error)
	}
}

func (MailExpiryLoginReconciler) Name() string { return "i5.mail-expiry" }

func (r MailExpiryLoginReconciler) ReconcileCharacterLogin(ctx context.Context, t tx.Tx, actor identity.ActorContext, op operation.Context, at time.Time) error {
	if r.Store == nil || t == nil || !actor.PlayerID.Valid() || at.IsZero() {
		return errors.New("i5 mail expiry reconcile unavailable")
	}
	expires := at.Add(mailTuning(ctx, t, r.Store).OverflowAfterLogin())
	_, err := r.Store.StampOverflowMailExpiryTx(ctx, t, actor.PlayerID, expires)
	return err
}
