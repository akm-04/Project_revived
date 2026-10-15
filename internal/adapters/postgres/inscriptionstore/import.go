package inscriptionstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

func (Store) ReadImportProofTx(c context.Context, q tx.Queryer, p identity.PlayerID) (string, bool, error) {
	var digest string
	e := q.QueryRow(c, `SELECT payload_sha256 FROM player_inscription_imports WHERE player_id=$1`, int64(p)).Scan(&digest)
	if errors.Is(e, kernelstore.ErrNoRows) {
		return "", false, nil
	}
	return digest, e == nil, e
}
func (Store) SaveImportProofTx(c context.Context, t tx.Tx, p identity.PlayerID, digest, source, rev string, at time.Time) error {
	_, e := t.Exec(c, `INSERT INTO player_inscription_imports(player_id,payload_sha256,source_sha256,content_revision,seed_policy,imported_at)VALUES($1,$2,$3,$4,'C2F_EMPTY_ZERO_PRESERVATION_SEED_V1',$5)`, int64(p), digest, source, rev, at)
	return e
}
