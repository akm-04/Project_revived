package i4store

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type TransactionDiscoveryReader struct{}

func (TransactionDiscoveryReader) ProfileTx(c context.Context, t tx.Tx, p identity.PlayerID) (playerdirectory.Profile, bool, error) {
	if t == nil {
		return playerdirectory.Profile{}, false, errors.New("nil directory transaction")
	}
	return (PlayerDirectoryReader{Queryer: t}).Profile(c, p)
}
func (TransactionDiscoveryReader) ProfilesByExactNameTx(c context.Context, t tx.Tx, n string, l int) ([]playerdirectory.Profile, error) {
	if t == nil {
		return nil, errors.New("nil directory transaction")
	}
	return (PlayerDirectoryReader{Queryer: t}).ProfilesByExactName(c, n, l)
}
func (TransactionDiscoveryReader) PlayerIDBoundsTx(c context.Context, t tx.Tx) (identity.PlayerID, identity.PlayerID, bool, error) {
	if t == nil {
		return 0, 0, false, errors.New("nil directory transaction")
	}
	return (PlayerDirectoryReader{Queryer: t}).PlayerIDBounds(c)
}
func (TransactionDiscoveryReader) ProfilesAfterTx(c context.Context, t tx.Tx, p identity.PlayerID, l int) ([]playerdirectory.Profile, error) {
	if t == nil {
		return nil, errors.New("nil directory transaction")
	}
	return (PlayerDirectoryReader{Queryer: t}).ProfilesAfter(c, p, l)
}

var _ playerdirectory.TxDiscoveryReader = TransactionDiscoveryReader{}
