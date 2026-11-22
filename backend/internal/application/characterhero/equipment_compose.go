package characterhero

import (
	"bytes"
	"context"
	"errors"
	"sort"
	"strconv"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrEquipmentComposeUnqualified = errors.New("character hero: item is not a server-qualified equipment composition recipe")
	ErrAwakeningComposeUnqualified = errors.New("character hero: item is not a server-qualified awakening material composition recipe")
)

const (
	equipmentComposePolicyVersion   = "PASS534_CA4_1_IMPLEMENTATION_CONTRACT"
	awakeningComposePolicyVersion   = "I9_12_AWAKENING_COMPOSE_V1"
	awakeningMaterialSourceItemType = int64(4)
)

var errComposeRecipeShape = errors.New("character hero: composition recipe is not a scaled cost")

func (s Service) validateEquipmentCompose() error {
	if err := s.validate(); err != nil {
		return err
	}
	if s.Progression == nil || s.Equipment == nil || s.Exchange == nil {
		return errors.New("character hero: incomplete CA4-1 equipment composition service")
	}
	return nil
}

func (s Service) validateAwakeningCompose() error {
	if err := s.validate(); err != nil {
		return err
	}
	if s.Progression == nil || s.Equipment == nil || s.Exchange == nil {
		return errors.New("character hero: incomplete awakening composition service")
	}
	return nil
}

type equipmentComposeCost struct {
	stacks []appi5.StackMaterialCost
	mana   int64
}

// scaledComposeCost sums repeated component identities and scales every source
// quantity and the Mana by the request amount.
func scaledComposeCost(edges []character.EquipmentRecipeEdge, itemID, amount, composeMana int64) (equipmentComposeCost, error) {
	counts := make(map[int64]int64, len(edges))
	for _, edge := range edges {
		if err := edge.Validate(); err != nil {
			return equipmentComposeCost{}, errComposeRecipeShape
		}
		component := int64(edge.ComponentItemID)
		if component == itemID {
			return equipmentComposeCost{}, errComposeRecipeShape
		}
		scaled, err := checkedMul64(edge.ComponentCount, amount)
		if err != nil {
			return equipmentComposeCost{}, errComposeRecipeShape
		}
		if counts[component], err = checkedAdd64(counts[component], scaled); err != nil {
			return equipmentComposeCost{}, errComposeRecipeShape
		}
	}
	ids := make([]int64, 0, len(counts))
	for component := range counts {
		ids = append(ids, component)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	out := equipmentComposeCost{stacks: make([]appi5.StackMaterialCost, 0, len(ids))}
	for _, component := range ids {
		out.stacks = append(out.stacks, appi5.StackMaterialCost{ItemID: component, Amount: counts[component]})
	}
	if composeMana > 0 {
		mana, err := checkedMul64(composeMana, amount)
		if err != nil {
			return equipmentComposeCost{}, errComposeRecipeShape
		}
		out.mana = mana
	}
	return out, nil
}

// equipmentComposeRecipe loads the direct source recipe for one target and
// scales every source quantity by the request amount. A target is qualified
// only as a hero equipment primitive (source item type 1); repeated component
// identities are summed, never deduplicated away.
func (s Service) equipmentComposeRecipe(ctx context.Context, q tx.Queryer, revision string, itemID, amount int64) (equipmentComposeCost, error) {
	edges, err := s.Equipment.EquipmentRecipeEdgesTx(ctx, q, revision, itemID)
	if err != nil {
		return equipmentComposeCost{}, err
	}
	if len(edges) == 0 {
		return equipmentComposeCost{}, ErrEquipmentComposeUnqualified
	}
	primitive, err := s.Equipment.EquipmentPrimitiveTx(ctx, q, revision, itemID)
	if err != nil {
		return equipmentComposeCost{}, err
	}
	if err := primitive.Validate(); err != nil {
		return equipmentComposeCost{}, err
	}
	if int64(primitive.ItemID) != itemID || primitive.SourceItemType != 1 {
		return equipmentComposeCost{}, ErrEquipmentComposeUnqualified
	}
	cost, err := scaledComposeCost(edges, itemID, amount, primitive.ComposeMana)
	if err != nil {
		return equipmentComposeCost{}, ErrEquipmentComposeUnqualified
	}
	return cost, nil
}

// awakeningComposeRecipe qualifies a target as a consumable awakening or
// blood-awakening material (source item type 4) with a compiled recipe.
func (s Service) awakeningComposeRecipe(ctx context.Context, q tx.Queryer, revision string, itemID, amount int64) (equipmentComposeCost, error) {
	edges, err := s.Equipment.EquipmentRecipeEdgesTx(ctx, q, revision, itemID)
	if err != nil {
		return equipmentComposeCost{}, err
	}
	if len(edges) == 0 {
		return equipmentComposeCost{}, ErrAwakeningComposeUnqualified
	}
	primitive, err := s.Equipment.EquipmentPrimitiveTx(ctx, q, revision, itemID)
	if err != nil {
		return equipmentComposeCost{}, err
	}
	if err := primitive.Validate(); err != nil {
		return equipmentComposeCost{}, err
	}
	if int64(primitive.ItemID) != itemID || primitive.SourceItemType != awakeningMaterialSourceItemType {
		return equipmentComposeCost{}, ErrAwakeningComposeUnqualified
	}
	cost, err := scaledComposeCost(edges, itemID, amount, primitive.ComposeMana)
	if err != nil {
		return equipmentComposeCost{}, ErrAwakeningComposeUnqualified
	}
	return cost, nil
}

// OwnsAwakeningComposeItem answers MID 83 category routing before any owner
// command. It reads only the pinned or active equipment recipe graph and
// writes no admission.
func (s Service) OwnsAwakeningComposeItem(ctx context.Context, itemID int64, op operation.Context) (bool, error) {
	if s.Equipment == nil || s.Progression == nil || s.Runner.DB == nil || itemID <= 0 {
		return false, ErrAwakeningComposeUnqualified
	}
	bound, revision, err := s.bindEquipmentPrimitiveContent(ctx, op)
	if err != nil {
		return false, err
	}
	var owned bool
	outcome, err := s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(txctx context.Context, scope tx.Scope) error {
		edges, err := s.Equipment.EquipmentRecipeEdgesTx(txctx, scope.Tx, revision, itemID)
		if err != nil {
			return err
		}
		if len(edges) == 0 {
			return nil
		}
		primitive, err := s.Equipment.EquipmentPrimitiveTx(txctx, scope.Tx, revision, itemID)
		if err != nil {
			return err
		}
		owned = primitive.Validate() == nil && int64(primitive.ItemID) == itemID && primitive.SourceItemType == awakeningMaterialSourceItemType
		return nil
	})
	if err != nil {
		return false, err
	}
	if outcome.Outcome != tx.DefiniteCommit {
		return false, errors.New("character hero: awakening compose routing read did not commit")
	}
	return owned, nil
}

// ComposeEquipmentItem implements the equipment category of MID 83 as a
// Character-owned port over the CA4-1 recipe graph. The one I5 material
// exchange debits the exact components and Mana and settles the target stack
// grant, whose canonical receipt is the operation's once-only evidence.
func (s Service) ComposeEquipmentItem(ctx context.Context, actor identity.ActorContext, itemID, amount int64, op operation.Context) (map[string]any, error) {
	if err := s.validateEquipmentCompose(); err != nil {
		return nil, err
	}
	if !actor.PlayerID.Valid() || itemID <= 0 || amount <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return nil, ErrEquipmentComposeUnqualified
	}
	return s.composeRecipeItem(ctx, actor, itemID, amount, op, "compose-equipment", equipmentComposePolicyVersion, s.equipmentComposeRecipe)
}

// ComposeAwakeningItem implements the awakening material category of MID 83
// over the same compiled item recipe graph and I5 material exchange.
func (s Service) ComposeAwakeningItem(ctx context.Context, actor identity.ActorContext, itemID, amount int64, op operation.Context) (map[string]any, error) {
	if err := s.validateAwakeningCompose(); err != nil {
		return nil, err
	}
	if !actor.PlayerID.Valid() || itemID <= 0 || amount <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return nil, ErrAwakeningComposeUnqualified
	}
	return s.composeRecipeItem(ctx, actor, itemID, amount, op, "compose-awakening", awakeningComposePolicyVersion, s.awakeningComposeRecipe)
}

func (s Service) composeRecipeItem(ctx context.Context, actor identity.ActorContext, itemID, amount int64, op operation.Context, operationName, policyVersion string, recipe func(context.Context, tx.Queryer, string, int64, int64) (equipmentComposeCost, error)) (map[string]any, error) {
	bound, revision, err := s.bindEquipmentPrimitiveContent(ctx, op)
	if err != nil {
		return nil, err
	}
	plan := grant.Plan{
		PlayerID: actor.PlayerID,
		Source: grant.SourceIdentity{
			Domain:        "character-hero",
			Operation:     operationName,
			BusinessKey:   strconv.FormatInt(int64(actor.PlayerID), 10),
			Occurrence:    bound.ID.String(),
			PolicyVersion: policyVersion,
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
	_, err = s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: receiptID, Fingerprint: fingerprint}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, receiptID); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fingerprint[:]) {
				return &receipt.ConflictError{Identity: receiptID}
			}
			return nil
		}
		cost, err := recipe(txctx, scope.Tx, revision, itemID, amount)
		if err != nil {
			return err
		}
		request := appi5.MaterialExchangeRequest{
			Cost:              appi5.MaterialCost{Stacks: cost.stacks},
			Restoration:       plan,
			AllowOverflowMail: true,
		}
		if cost.mana > 0 {
			request.Cost.Scalars = []appi5.ScalarMaterialCost{{ResourceKey: "mana", Amount: cost.mana}}
		}
		prepared, err := s.Exchange.PrepareMaterialExchangeTx(txctx, scope.Tx, actor, request, bound)
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
