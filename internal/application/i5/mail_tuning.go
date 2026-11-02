package i5

import (
	"context"

	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MailTuningReader is the optional overlay read implemented by the I5 store.
type MailTuningReader interface {
	MailTuningTx(context.Context, tx.Queryer) (mail.Tuning, bool, error)
}

// The stock client's own overflow-mail strings (translation.lua:14908-14918);
// MailNewDetail.lua crashes on an empty content, so they are mandatory.
const (
	overflowMailTitle  = "Items exceed capacity"
	overflowMailSender = "Academy"
	overflowMailBody   = "Dear master, since your items in bag exceed capacity, we have sent them through mail. Please make room in bag and collect them soon!"
)

// mailTuning applies an operator overlay, keeping the built-in durations when
// the row is absent, unreadable or invalid.
func mailTuning(ctx context.Context, q tx.Queryer, store any) mail.Tuning {
	reader, ok := store.(MailTuningReader)
	if !ok || q == nil {
		return mail.Tuning{}
	}
	tuning, found, err := reader.MailTuningTx(ctx, q)
	if err != nil || !found || tuning.Validate() != nil {
		return mail.Tuning{}
	}
	return tuning
}
