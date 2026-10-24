package publicpresentation

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type DiscoveryReader struct{}

func (DiscoveryReader) ProfileTx(c context.Context, t tx.Tx, id identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return (i4store.TransactionDiscoveryReader{}).ProfileTx(c, t, id)
}
func (DiscoveryReader) PlayerIDBoundsTx(c context.Context, t tx.Tx) (identity.PlayerID, identity.PlayerID, bool, error) {
	return (i4store.TransactionDiscoveryReader{}).PlayerIDBoundsTx(c, t)
}
func (DiscoveryReader) ProfilesAfterTx(c context.Context, t tx.Tx, id identity.PlayerID, limit int) ([]playerdirectory.Profile, error) {
	return (i4store.TransactionDiscoveryReader{}).ProfilesAfterTx(c, t, id, limit)
}
func (DiscoveryReader) ProfilesByExactNameTx(c context.Context, t tx.Tx, name string, limit int) ([]playerdirectory.Profile, error) {
	ids, e := (i5store.Store{}).ReadPlayerIDsByExactNameTx(c, t, name, limit)
	if e != nil {
		return nil, e
	}
	out := []playerdirectory.Profile{}
	if len(ids) == 0 {
		return out, nil
	}
	for _, id := range ids {
		p, ok, e := (i4store.TransactionDiscoveryReader{}).ProfileTx(c, t, id)
		if e != nil {
			return nil, e
		}
		if ok {
			// Exact equality was witnessed by the I5 typed candidate selector.
			// Mutable display is enriched once by the consumer at its pinned instant.
			p.Name = name
			out = append(out, p)
		}
	}
	return out, nil
}

var _ playerdirectory.TxDiscoveryReader = DiscoveryReader{}
