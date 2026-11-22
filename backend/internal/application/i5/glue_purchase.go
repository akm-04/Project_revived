package i5

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrInvalidGluePurchase = errors.New("invalid I5 glue purchase")
	ErrGluePurchaseLimit   = errors.New("I5 glue purchase start limit reached")
)

type GluePurchaseRequest struct {
	CrystalCost, GlueAmount, StartLimit int64
	Source                              grant.SourceIdentity
}
type PreparedGluePurchase struct{ exchange *PreparedMaterialExchange }
type GluePurchaseResult struct {
	Crystal, Glue economy.ScalarBalance
}
type TxGluePurchase interface {
	PrepareGluePurchaseTx(context.Context, tx.Tx, identity.ActorContext, GluePurchaseRequest, operation.Context) (*PreparedGluePurchase, error)
	ApplyGluePurchaseTx(context.Context, tx.Tx, *PreparedGluePurchase) (GluePurchaseResult, error)
}

var _ TxGluePurchase = Service{}

// The caller qualifies VIP/day/cost from Dorm source rules and owns the outer
// counter/receipt. I5 closes the two currencies and enforces the balance limit.
func (service Service) PrepareGluePurchaseTx(ctx context.Context, transaction tx.Tx, actor identity.ActorContext, request GluePurchaseRequest, current operation.Context) (*PreparedGluePurchase, error) {
	if request.CrystalCost <= 0 || request.GlueAmount <= 0 || request.StartLimit <= 0 {
		return nil, ErrInvalidGluePurchase
	}
	plan := grant.Plan{PlayerID: actor.PlayerID, Source: request.Source, Lines: []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: GlueResourceKey, Amount: request.GlueAmount}}}
	exchange := MaterialExchangeRequest{Cost: MaterialCost{Scalars: []ScalarMaterialCost{{ResourceKey: "crystal", Amount: request.CrystalCost}}}, Restoration: plan}
	prepared, err := service.prepareMaterialExchangeTx(ctx, transaction, actor, exchange, current, grant.Plan.Validate)
	if err != nil {
		return nil, err
	}
	minimum := prepared.grantPreflight.Lines[0].Policy.DailyFloorMinimum
	if minimum == nil {
		return nil, ErrInvalidGluePurchase
	}
	balance, exists, err := service.Store.LockScalarTx(ctx, transaction, actor.PlayerID, GlueResourceKey, current.StartedAt)
	if err != nil {
		return nil, err
	}
	if !exists {
		balance = economy.ScalarBalance{PlayerID: actor.PlayerID, ResourceKey: GlueResourceKey, StateVersion: 1, UpdatedAt: current.StartedAt}
	}
	effective, err := effectiveDailyFloorTx(ctx, transaction, service.Store, balance, minimum, current.StartedAt)
	if err != nil {
		return nil, err
	}
	if effective.Amount >= request.StartLimit {
		return nil, ErrGluePurchaseLimit
	}
	return &PreparedGluePurchase{exchange: prepared}, nil
}
func (service Service) ApplyGluePurchaseTx(ctx context.Context, transaction tx.Tx, prepared *PreparedGluePurchase) (GluePurchaseResult, error) {
	if prepared == nil || prepared.exchange == nil {
		return GluePurchaseResult{}, ErrInvalidGluePurchase
	}
	applied, err := service.ApplyMaterialExchangeTx(ctx, transaction, prepared.exchange)
	if err != nil {
		return GluePurchaseResult{}, err
	}
	if len(applied.Debit.Scalars) != 1 {
		return GluePurchaseResult{}, ErrInvalidGluePurchase
	}
	crystal := applied.Debit.Scalars[0]
	player := prepared.exchange.playerID
	glue, exists, err := service.Store.LockScalarTx(ctx, transaction, player, GlueResourceKey, prepared.exchange.op.StartedAt)
	if err != nil {
		return GluePurchaseResult{}, err
	}
	if !exists || crystal.Validate() != nil || glue.Validate() != nil || crystal.PlayerID != player || glue.PlayerID != player || crystal.ResourceKey != "crystal" || glue.ResourceKey != GlueResourceKey {
		return GluePurchaseResult{}, ErrInvalidGluePurchase
	}
	return GluePurchaseResult{Crystal: crystal, Glue: glue}, nil
}
