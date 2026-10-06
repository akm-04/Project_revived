// Package socialpresentation composes existing owner readers without owner SQL.
package socialpresentation

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TransactionReader has no pool fallback or transaction opener.
type TransactionReader struct{}

func (TransactionReader) ReadManyTx(ctx context.Context, t tx.Tx, ids []identity.PlayerID) (playerpresentation.Batch, error) {
	out := playerpresentation.Batch{Players: make(map[identity.PlayerID]playerpresentation.Projected)}
	if t == nil {
		return out, errors.New("nil presentation transaction")
	}
	if len(ids) == 0 {
		return out, nil
	}
	ordered, err := playerroot.CanonicalPlayerIDs(ids)
	if err != nil {
		return out, err
	}
	minimal := playerpresentation.Service{Directory: i4store.PlayerDirectoryReader{Queryer: t}, Types: i5store.Store{Queryer: t}}
	for _, pid := range ordered {
		value, ok, err := minimal.Read(ctx, pid)
		if err != nil {
			return out, err
		}
		if !ok || value.PlayerID != pid {
			return out, playerpresentation.ErrMissingPresentation
		}
		out.Players[pid] = playerpresentation.Projected{Minimal: value}
	}
	observed, err := (postgres.AuthoritativeTime{Queryer: t}).Now(ctx)
	if err != nil {
		return out, err
	}
	presence, err := (presencestore.Store{Queryer: t}).ReadManyAt(ctx, ordered, observed)
	if err != nil {
		return out, err
	}
	for _, pid := range ordered {
		value := out.Players[pid]
		obs, ok := presence[pid]
		if !ok {
			return out, playerpresentation.ErrMissingPresentation
		}
		value.Presence = obs
		if err := value.Validate(pid); err != nil {
			return out, err
		}
		out.Players[pid] = value
	}
	out.ObservedAt = observed.UTC()
	return out, nil
}

var _ playerpresentation.TxReader = TransactionReader{}
