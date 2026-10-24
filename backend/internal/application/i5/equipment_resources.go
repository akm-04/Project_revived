package i5

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// EquipmentResource* are the family-neutral CA4 shared names for the accepted
// I5 equipment Prepare/Apply mechanism. They are aliases, not a second owner:
// Hero callers retain their existing API while Pet/Super callers can depend on
// a neutral seam without importing a Hero gameplay authority.
type EquipmentResourceRequest = HeroEquipmentResourceRequest
type EquipmentStackDebit = HeroEquipmentStackDebit
type EquipmentResourceDebit = HeroEquipmentResourceDebit
type PreparedEquipmentResources = PreparedHeroEquipmentResources
type EquipmentResourceResult = HeroEquipmentResourceResult
type EquipmentResourceDebiter = HeroEquipmentResourceDebiter

// TxEquipmentResourceDebiter is the family-neutral I5-owned Prepare/Apply
// port. Caller family locks must already be held. Prepare acquires the accepted
// I5 suffix; Apply discovers no new identities, reads, content, or locks.
type TxEquipmentResourceDebiter interface {
	PrepareEquipmentResourcesTx(context.Context, tx.Tx, identity.PlayerID, EquipmentResourceRequest, operation.Context) (*PreparedEquipmentResources, error)
	ApplyEquipmentResourceDebitTx(context.Context, tx.Tx, *PreparedEquipmentResources, EquipmentResourceDebit) (EquipmentResourceResult, error)
}

var _ TxEquipmentResourceDebiter = HeroEquipmentResourceDebiter{}

func (d HeroEquipmentResourceDebiter) PrepareEquipmentResourcesTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, req EquipmentResourceRequest, op operation.Context) (*PreparedEquipmentResources, error) {
	return d.PrepareHeroEquipmentResourcesTx(ctx, t, pid, req, op)
}

func (d HeroEquipmentResourceDebiter) ApplyEquipmentResourceDebitTx(ctx context.Context, t tx.Tx, prepared *PreparedEquipmentResources, debit EquipmentResourceDebit) (EquipmentResourceResult, error) {
	return d.ApplyHeroEquipmentResourceDebitTx(ctx, t, prepared, debit)
}
