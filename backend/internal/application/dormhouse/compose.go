package dormhouse

import (
	"bytes"
	"context"
	"errors"
	"math"
	"strconv"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const FurnitureComposePolicyVersion = "I9_11_FURNITURE_COMPOSE_V1"

var (
	ErrFurnitureComposeUnqualified = errors.New("dorm: item is not a server-qualified furniture composition recipe")
	ErrFurnitureBlueprintNotOwned  = errors.New("dorm: furniture blueprint is not owned")
	ErrFurnitureLevelTooLow        = errors.New("dorm: player level is below the recipe level")
)

// OwnsFurnitureComposeItem answers MID 83 category routing by recipe-set
// membership before any owner command. It writes no admission.
func (s Service) OwnsFurnitureComposeItem(ctx context.Context, itemID int64, op operation.Context) (bool, error) {
	if s.Content == nil || s.Reads.DB == nil || itemID <= 0 {
		return false, ErrUnavailable
	}
	revision, pinned := op.Policies.Get("content")
	if !pinned {
		active, on, err := s.Content.DormInputsActive(ctx)
		if err != nil {
			return false, err
		}
		if !on {
			return false, nil
		}
		revision = active
	}
	var owned bool
	outcome, err := s.Reads.Run(ctx, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		catalog, err := s.Content.DormCatalogTx(ctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		_, furniture := catalog.FurnitureRecipes[itemID]
		_, blueprint := catalog.BlueprintRecipes[itemID]
		owned = furniture || blueprint
		return nil
	})
	if errors.Is(err, dorm.ErrUnqualified) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if outcome.Outcome != tx.DefiniteCommit {
		return false, ErrUnavailable
	}
	return owned, nil
}

// planFurnitureCompose derives the exact I5 cost of one recipe target. A
// furniture target also requires an owned, never debited, blueprint.
func planFurnitureCompose(catalog dorm.Catalog, itemID, amount, playerLevel, blueprintOwned int64) (appi5.MaterialCost, error) {
	if amount <= 0 {
		return appi5.MaterialCost{}, ErrFurnitureComposeUnqualified
	}
	if recipe, ok := catalog.FurnitureRecipes[itemID]; ok {
		blueprint, ok := catalog.BlueprintRecipes[recipe.BlueprintItem]
		if !ok || len(recipe.Materials) == 0 || len(recipe.Materials) != len(recipe.Counts) || recipe.Glue < 0 {
			return appi5.MaterialCost{}, ErrFurnitureComposeUnqualified
		}
		if playerLevel < blueprint.Level {
			return appi5.MaterialCost{}, ErrFurnitureLevelTooLow
		}
		if blueprintOwned < 1 {
			return appi5.MaterialCost{}, ErrFurnitureBlueprintNotOwned
		}
		cost := appi5.MaterialCost{Stacks: make([]appi5.StackMaterialCost, 0, len(recipe.Materials))}
		for i, item := range recipe.Materials {
			scaled, err := scaleFurnitureQuantity(recipe.Counts[i], amount)
			if err != nil {
				return appi5.MaterialCost{}, err
			}
			cost.Stacks = append(cost.Stacks, appi5.StackMaterialCost{ItemID: item, Amount: scaled})
		}
		if recipe.Glue > 0 {
			glue, err := scaleFurnitureQuantity(recipe.Glue, amount)
			if err != nil {
				return appi5.MaterialCost{}, err
			}
			cost.Scalars = []appi5.ScalarMaterialCost{{ResourceKey: appi5.GlueResourceKey, Amount: glue}}
		}
		return cost, nil
	}
	blueprint, ok := catalog.BlueprintRecipes[itemID]
	if !ok {
		return appi5.MaterialCost{}, ErrFurnitureComposeUnqualified
	}
	if playerLevel < blueprint.Level {
		return appi5.MaterialCost{}, ErrFurnitureLevelTooLow
	}
	if len(blueprint.Pieces) == 0 || len(blueprint.Pieces) != len(blueprint.Counts) {
		return appi5.MaterialCost{}, ErrFurnitureComposeUnqualified
	}
	cost := appi5.MaterialCost{Stacks: make([]appi5.StackMaterialCost, 0, len(blueprint.Pieces))}
	for i, item := range blueprint.Pieces {
		scaled, err := scaleFurnitureQuantity(blueprint.Counts[i], amount)
		if err != nil {
			return appi5.MaterialCost{}, err
		}
		cost.Stacks = append(cost.Stacks, appi5.StackMaterialCost{ItemID: item, Amount: scaled})
	}
	return cost, nil
}

func scaleFurnitureQuantity(unit, amount int64) (int64, error) {
	if unit <= 0 || amount <= 0 || unit > math.MaxInt64/amount {
		return 0, ErrFurnitureComposeUnqualified
	}
	return unit * amount, nil
}

// ComposeFurnitureItem implements the furniture and blueprint categories of
// MID 83. One I5 material exchange inside one Serializable transaction debits
// the scaled components and glue and grants the target stack; the grant receipt
// is the operation's once-only evidence.
func (s Service) ComposeFurnitureItem(ctx context.Context, actor identity.ActorContext, itemID, amount int64, op operation.Context) (map[string]any, error) {
	if s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Content == nil || s.Fence == nil || s.Values == nil || s.Exchange == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return nil, ErrUnavailable
	}
	if !actor.PlayerID.Valid() || itemID <= 0 || amount <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return nil, ErrFurnitureComposeUnqualified
	}
	bound, revision, err := s.bindFurnitureComposeContent(ctx, op)
	if err != nil {
		return nil, err
	}
	timed, err := s.Timed.Binder.Bind(ctx, bound)
	if err != nil {
		return nil, err
	}
	decision := timed.Operation()
	decision.StartedAt = timed.DecisionAt()
	plan := grant.Plan{
		PlayerID: actor.PlayerID,
		Source: grant.SourceIdentity{
			Domain:        "dorm-house",
			Operation:     "compose-furniture",
			BusinessKey:   strconv.FormatInt(int64(actor.PlayerID), 10),
			Occurrence:    op.ID.String(),
			PolicyVersion: FurnitureComposePolicyVersion,
		},
		Lines: []grant.Line{{Kind: grant.StackItem, ItemID: itemID, Amount: amount}},
	}
	receiptID, err := plan.ReceiptIdentity()
	if err != nil {
		return nil, err
	}
	fingerprint, err := receipt.FingerprintRequest(plan)
	if err != nil {
		return nil, err
	}
	result := map[string]any{}
	_, err = s.Timed.Runner.Run(ctx, decision, Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: receiptID, Fingerprint: fingerprint}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fence.FenceActorTx(txctx, scope.Tx, actor, decision.StartedAt); err != nil {
			return err
		}
		prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, receiptID)
		if err != nil {
			return err
		}
		if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fingerprint[:]) {
				return &receipt.ConflictError{Identity: receiptID}
			}
			return nil
		}
		catalog, err := s.Content.DormCatalogTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		values, err := s.Values.LockDormPlayerStateTx(txctx, scope.Tx, actor.PlayerID, decision.StartedAt)
		if err != nil {
			return err
		}
		var blueprintOwned int64
		if recipe, exists := catalog.FurnitureRecipes[itemID]; exists {
			stacks, err := s.Values.ListStacksTx(txctx, scope.Tx, actor.PlayerID)
			if err != nil {
				return err
			}
			for _, stack := range stacks {
				if stack.ItemID == recipe.BlueprintItem {
					blueprintOwned = stack.Quantity
				}
			}
		}
		cost, err := planFurnitureCompose(catalog, itemID, amount, values.Level, blueprintOwned)
		if err != nil {
			return err
		}
		request := appi5.MaterialExchangeRequest{Cost: cost, Restoration: plan, AllowOverflowMail: true}
		prepared, err := s.Exchange.PrepareMaterialExchangeTx(txctx, scope.Tx, actor, request, decision)
		if errors.Is(err, appi5.ErrMaterialExchangeGrantAlreadySettled) {
			return nil
		}
		if err != nil {
			return err
		}
		if _, err := s.Exchange.ApplyMaterialExchangeTx(txctx, scope.Tx, prepared); err != nil && !errors.Is(err, appi5.ErrMaterialExchangeGrantAlreadySettled) {
			return err
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return result, nil
}

func (s Service) bindFurnitureComposeContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	revision, active, err := s.Content.DormInputsActive(ctx)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !active {
		return operation.Context{}, "", ErrUnavailable
	}
	if pinned, ok := op.Policies.Get("content"); ok {
		revision = pinned
	}
	if _, ok := op.Policies.Get("content"); ok {
		return op, revision, nil
	}
	refs := append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, "", err
	}
	op.Policies = set
	return op, revision, nil
}
