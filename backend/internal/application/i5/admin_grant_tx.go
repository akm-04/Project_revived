package i5

import (
	"context"
	"errors"
	"strings"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AdminGrantTx is the caller-transaction form of AdminGrant for the operator
// bus: the grant receipt and the command row commit together, so the operator
// edge never acquires a second connection (C1-2). The per-recipient business
// key is the same one AdminGrant derives.
func (s Service) AdminGrantTx(ctx context.Context, transaction tx.Tx, admin AdminOperator, target identity.PlayerID, commandKey, policyVersion string, lines []grant.Line, op operation.Context) (GrantResult, error) {
	if err := admin.Validate(); err != nil {
		return GrantResult{}, err
	}
	if transaction == nil || !target.Valid() || strings.TrimSpace(commandKey) == "" || strings.TrimSpace(policyVersion) == "" {
		return GrantResult{}, errors.New("admin grant transaction command incomplete")
	}
	plan := grant.Plan{PlayerID: target, Source: grant.SourceIdentity{Domain: "admin", Operation: "grant", BusinessKey: admin.ID + ":" + commandKey, PolicyVersion: policyVersion}, Lines: append([]grant.Line(nil), lines...)}
	prepared, err := s.prepareGrantOperationTx(ctx, transaction, plan, op)
	if err != nil {
		return GrantResult{}, err
	}
	return s.SettleGrantTx(ctx, transaction, identity.ActorContext{PlayerID: target}, plan, prepared, GrantTxOptions{AllowOverflowMail: true, SystemSettlement: true})
}
