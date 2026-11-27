package i4store

import (
	"context"
	"errors"
	"sort"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	lockServerName = `SELECT name FROM logical_servers WHERE logical_server_id=$1 FOR UPDATE`
	renameServer   = `UPDATE logical_servers SET name=$2 WHERE logical_server_id=$1`
)

// RenameServersTx is the logicalserver owner's server.rename write: every row
// is locked in server id order before any row is updated, so two batches take
// the same order and one transaction commits all names or none.
func (ServerDirectoryReader) RenameServersTx(ctx context.Context, transaction tx.Tx, changes []operator.ServerNameChange) ([]operator.ServerRename, error) {
	if transaction == nil || len(changes) == 0 {
		return nil, errors.New("invalid server rename")
	}
	ordered := append([]operator.ServerNameChange(nil), changes...)
	sort.Slice(ordered, func(left, right int) bool {
		return ordered[left].ServerID < ordered[right].ServerID
	})
	oldNames := make(map[int64]string, len(ordered))
	for _, change := range ordered {
		if change.ServerID <= 0 || change.Name == "" {
			return nil, errors.New("invalid server rename")
		}
		var oldName string
		if err := transaction.QueryRow(ctx, lockServerName, change.ServerID).Scan(&oldName); err != nil {
			if errors.Is(err, kernelstore.ErrNoRows) {
				return nil, &operator.ServerNotFoundError{ServerID: change.ServerID}
			}
			return nil, err
		}
		oldNames[change.ServerID] = oldName
	}
	for _, change := range ordered {
		if _, err := transaction.Exec(ctx, renameServer, change.ServerID, change.Name); err != nil {
			return nil, err
		}
	}
	results := make([]operator.ServerRename, 0, len(changes))
	for _, change := range changes {
		results = append(results, operator.ServerRename{ServerID: change.ServerID, OldName: oldNames[change.ServerID], NewName: change.Name})
	}
	return results, nil
}
