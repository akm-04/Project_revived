// Package socialpresentation composes existing owner readers without owner SQL.
package socialpresentation

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/publicpresentation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// TransactionReader has no pool fallback or transaction opener.
type TransactionReader struct {
	Display i5.TxEffectivePlayerDisplayReader
}

func (r TransactionReader) ReadManyTx(c context.Context, t tx.Tx, ids []identity.PlayerID) (playerpresentation.Batch, error) {
	out := playerpresentation.Batch{Players: make(map[identity.PlayerID]playerpresentation.Projected)}
	if t == nil {
		return out, errors.New("nil presentation transaction")
	}
	if len(ids) == 0 {
		return out, nil
	}
	at, e := r.ObserveTx(c, t)
	if e != nil {
		return out, e
	}
	return r.ReadManyAtTx(c, t, ids, at)
}
func (r TransactionReader) ReadManyAtTx(c context.Context, t tx.Tx, ids []identity.PlayerID, at time.Time) (playerpresentation.Batch, error) {
	out := playerpresentation.Batch{ObservedAt: at.UTC(), Players: make(map[identity.PlayerID]playerpresentation.Projected)}
	if t == nil || at.IsZero() {
		return out, errors.New("invalid presentation observation")
	}
	if len(ids) == 0 {
		return out, nil
	}
	ordered, e := playerroot.CanonicalPlayerIDs(ids)
	if e != nil {
		return out, e
	}
	rev, e := (contentstore.Store{}).ActiveRevision(c, t)
	if e != nil {
		return out, e
	}
	reader := publicpresentation.Reader{Queryer: t, Revision: rev, ObservedAt: at, Display: r.Display}
	presence, e := (presencestore.Store{Queryer: t}).ReadManyAt(c, ordered, at)
	if e != nil {
		return out, e
	}
	for _, pid := range ordered {
		m, ok, e := reader.Minimal(c, pid)
		if e != nil {
			return out, e
		}
		if !ok {
			return out, playerpresentation.ErrMissingPresentation
		}
		observation, ok := presence[pid]
		if !ok {
			return out, playerpresentation.ErrMissingPresentation
		}
		v := playerpresentation.Projected{Minimal: m, Presence: observation}
		if e = v.Validate(pid); e != nil {
			return out, e
		}
		out.Players[pid] = v
	}
	return out, nil
}
func (TransactionReader) ObserveTx(c context.Context, t tx.Tx) (time.Time, error) {
	if t == nil {
		return time.Time{}, errors.New("nil observation transaction")
	}
	return (postgres.AuthoritativeTime{Queryer: t}).Now(c)
}

var _ playerpresentation.TxReader = TransactionReader{}
var _ playerpresentation.TxReaderAt = TransactionReader{}
var _ playerpresentation.TxObserver = TransactionReader{}
