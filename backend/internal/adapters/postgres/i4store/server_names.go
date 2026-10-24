package i4store

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ServerNames is the identity owner's read-only display seam for logical
// server names (cross-server modes show the opponent's server).
type ServerNames struct{}

func (ServerNames) ServerNameTx(ctx context.Context, q tx.Queryer, id identity.LogicalServerID) (string, error) {
	server, err := loadServer(ctx, q, id)
	if err != nil {
		return "", err
	}
	return server.Name, nil
}
