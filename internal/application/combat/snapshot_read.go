package combat

import (
	"context"

	d "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SnapshotTx returns verified frozen input to the owning mode; the mode authorizes its viewer.
func (service Service) SnapshotTx(requestContext context.Context, query tx.Queryer, identifier ids.UUID) (d.Snapshot, error) {
	if service.Store == nil || query == nil || identifier.IsZero() {
		return d.Snapshot{}, d.ErrInvalid
	}
	attempt, found, err := service.Store.ReadAttemptTx(requestContext, query, identifier)
	if err != nil {
		return d.Snapshot{}, err
	}
	if !found {
		return d.Snapshot{}, ErrAttemptNotFound
	}
	payload, err := service.Store.ReadSnapshotTx(requestContext, query, attempt.SnapshotHash)
	if err != nil {
		return d.Snapshot{}, err
	}
	snapshot, err := d.DecodeSnapshot(payload, attempt.SnapshotHash)
	if err != nil {
		return d.Snapshot{}, err
	}
	if snapshot.CorpusID != attempt.RulesCorpusID {
		return d.Snapshot{}, d.ErrInvalid
	}
	return snapshot, nil
}
