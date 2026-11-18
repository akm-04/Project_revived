package i5

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrInvalidItemsEnergyExchange = errors.New("invalid I5 items-energy exchange")

// ItemsEnergyExchangeRequest is the I9-11B one-transaction debit/restoration
// pair: a material cost on one side and the item-use or reward restoration on
// the other. Restoration may carry scalar, temporal, stack-item and player-exp
// lines because a loot box mixes them; entity and specialized lines keep their
// own owners and are refused here.
type ItemsEnergyExchangeRequest struct {
	Cost              MaterialCost
	Restoration       grant.Plan
	AllowOverflowMail bool
}

type ItemsEnergyExchangeResult struct {
	Debit       MaterialDebitResult
	Restoration GrantResult
}

type PreparedItemsEnergyExchange struct{ exchange *PreparedMaterialExchange }

type TxItemsEnergyExchange interface {
	PrepareItemsEnergyExchangeTx(context.Context, tx.Tx, identity.ActorContext, ItemsEnergyExchangeRequest, operation.Context) (*PreparedItemsEnergyExchange, error)
	ApplyItemsEnergyExchangeTx(context.Context, tx.Tx, *PreparedItemsEnergyExchange) (ItemsEnergyExchangeResult, error)
}

var _ TxItemsEnergyExchange = Service{}

// A box restoration mixes stack items, scalars, temporal energy and player exp,
// so this pair accepts those four kinds; entity and specialized lines stay with
// their own owners and are refused here.
func validateItemsEnergyRestoration(plan grant.Plan) error {
	if err := plan.Validate(); err != nil {
		return err
	}
	for _, line := range plan.Lines {
		switch line.Kind {
		case grant.ScalarCurrency, grant.Temporal, grant.StackItem, grant.PlayerExp:
		default:
			return ErrInvalidItemsEnergyExchange
		}
	}
	return nil
}

// PrepareItemsEnergyExchangeTx closes the debit and restoration lock union
// before any mutation, exactly like the CA4-1 stack-only pair.
func (s Service) PrepareItemsEnergyExchangeTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, request ItemsEnergyExchangeRequest, op operation.Context) (*PreparedItemsEnergyExchange, error) {
	prepared, err := s.prepareMaterialExchangeTx(ctx, t, actor, MaterialExchangeRequest{Cost: request.Cost, Restoration: request.Restoration, AllowOverflowMail: request.AllowOverflowMail}, op, validateItemsEnergyRestoration)
	if err != nil {
		return nil, err
	}
	return &PreparedItemsEnergyExchange{exchange: prepared}, nil
}

func (s Service) ApplyItemsEnergyExchangeTx(ctx context.Context, t tx.Tx, prepared *PreparedItemsEnergyExchange) (ItemsEnergyExchangeResult, error) {
	if prepared == nil || prepared.exchange == nil {
		return ItemsEnergyExchangeResult{}, ErrInvalidItemsEnergyExchange
	}
	applied, err := s.ApplyMaterialExchangeTx(ctx, t, prepared.exchange)
	if err != nil {
		return ItemsEnergyExchangeResult{}, err
	}
	return ItemsEnergyExchangeResult{Debit: applied.Debit, Restoration: applied.Restoration}, nil
}
