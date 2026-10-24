package kernelstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelqueries"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ListIdentitiesTx is an operator inventory port; it reads only KernelReceipt
// ownership. Callers must reconcile each returned receipt with its typed owner.
func (Store) ListIdentitiesTx(c context.Context, q tx.Queryer, domain, operation, after string) ([]receipt.Identity, error) {
	if q == nil || domain == "" || operation == "" {
		return nil, errors.New("invalid receipt inventory")
	}
	var raw string
	if e := q.QueryRow(c, kernelqueries.ListOperationReceiptIdentities, domain, operation, after).Scan(&raw); e != nil {
		return nil, e
	}
	var out []receipt.Identity
	if e := json.Unmarshal([]byte(raw), &out); e != nil {
		return nil, e
	}
	for _, id := range out {
		if id.Validate() != nil || id.Domain != domain || id.Operation != operation || id.SemanticKey <= after {
			return nil, errors.New("invalid receipt inventory identity")
		}
	}
	return out, nil
}
