package i4store

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	lockServerName = `SELECT name FROM logical_servers WHERE logical_server_id=$1 FOR UPDATE`
	renameServer   = `UPDATE logical_servers SET name=$2 WHERE logical_server_id=$1`
)

// RenameServerTx is the logicalserver owner's server.rename write: the row is
// locked, read for the old name, then renamed in the bus transaction.
func (ServerDirectoryReader) RenameServerTx(ctx context.Context, transaction tx.Tx, serverID int64, name string) (operator.ServerRename, error) {
	if transaction == nil || serverID <= 0 || name == "" {
		return operator.ServerRename{}, errors.New("invalid server rename")
	}
	var oldName string
	if err := transaction.QueryRow(ctx, lockServerName, serverID).Scan(&oldName); err != nil {
		if errors.Is(err, kernelstore.ErrNoRows) {
			return operator.ServerRename{}, operator.ErrServerNotFound
		}
		return operator.ServerRename{}, err
	}
	if _, err := transaction.Exec(ctx, renameServer, serverID, name); err != nil {
		return operator.ServerRename{}, err
	}
	return operator.ServerRename{ServerID: serverID, OldName: oldName, NewName: name}, nil
}
