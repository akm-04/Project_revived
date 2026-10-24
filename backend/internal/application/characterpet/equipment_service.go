package characterpet

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrPetEquipmentContentInactive     = errors.New("CA4-4A Pet equipment content capability inactive")
	ErrPetEquipmentUnavailable         = errors.New("character pet: equipment unavailable")
	ErrPetAwakeningProviderUnavailable = errors.New("character pet: Pet Awakening eligibility authority unavailable")
)

// EquipmentOperationContent is the revision-qualified immutable CA4-4A seam.
// Pet template awakening state is read from the existing CA3 template authority;
// it is not durable CharacterPet mission state.
type EquipmentOperationContent interface {
	PetEquipmentRevision(context.Context, string) (bool, error)
	EquipmentPrimitivesRevision(context.Context, string) (bool, error)
	PetEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64, int64) (character.PetEquipmentPosition, error)
	EquipmentPrimitiveTx(context.Context, tx.Queryer, string, int64) (character.EquipmentPrimitive, error)
	EquipmentRecipeEdgesTx(context.Context, tx.Queryer, string, int64) ([]character.EquipmentRecipeEdge, error)
	EquipmentCompatibilityExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]character.EquipmentCompatibilityExpThreshold, error)
	PetTemplateAwakenedTx(context.Context, tx.Queryer, string, int64) (bool, error)
}

type PetUniqueEquipmentCommittedFact struct {
	PlayerID        identity.PlayerID             `json:"player_id"`
	PetID           int64                         `json:"pet_id"`
	PetTableID      int64                         `json:"pet_table_id"`
	Slot            int64                         `json:"slot"`
	ItemID          character.EquipmentTemplateID `json:"item_id"`
	ContentRevision string                        `json:"content_revision"`
}

func (f PetUniqueEquipmentCommittedFact) Validate() error {
	if !f.PlayerID.Valid() || f.PetID <= 0 || f.PetTableID <= 0 || f.Slot < 1 || f.Slot > character.PetEquipmentSlotCount || !f.ItemID.Valid() || len(f.ContentRevision) != 64 {
		return errors.New("character pet: invalid unique-equipment committed fact")
	}
	return nil
}

type EquipItemResult struct {
	PetID               int64
	Level               int64
	Exp                 int64
	Equipment           character.PetEquipmentSlots
	AlreadyEquipped     bool
	UniqueEquipmentFact *PetUniqueEquipmentCommittedFact
}

type OneKeyEquipResult struct {
	PetID     int64
	Level     int64
	Exp       int64
	Equipment character.PetEquipmentSlots
	NoWork    bool
}

type petEquipmentReceipt struct {
	ResultKind          string                           `json:"result_kind"`
	PetID               int64                            `json:"pet_id"`
	Level               int64                            `json:"level"`
	Exp                 int64                            `json:"exp"`
	Equipment           character.PetEquipmentSlots      `json:"equips"`
	ContentRevision     string                           `json:"content_revision"`
	UniqueEquipmentFact *PetUniqueEquipmentCommittedFact `json:"unique_equipment_fact,omitempty"`
}

func (s Service) validateEquipItem() error {
	if err := s.validateProgression(); err != nil {
		return err
	}
	if s.Equipment == nil || s.MaterialCosts == nil {
		return errors.New("character pet: incomplete CA4-4A MID783 service")
	}
	return nil
}

func (s Service) validateOneKeyEquip() error {
	if err := s.validateProgression(); err != nil {
		return err
	}
	if s.Equipment == nil || s.EquipmentResources == nil {
		return errors.New("character pet: incomplete CA4-4A MID792 service")
	}
	return nil
}

func (s Service) bindEquipmentContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	bound, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return operation.Context{}, "", err
	}
	good, err := s.Equipment.PetEquipmentRevision(ctx, revision)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrPetEquipmentContentInactive
	}
	good, err = s.Equipment.EquipmentPrimitivesRevision(ctx, revision)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrPetEquipmentContentInactive
	}
	return bound, revision, nil
}

func decodePetEquipmentReceipt(r receipt.Receipt) (petEquipmentReceipt, error) {
	var out petEquipmentReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.Level <= 0 || out.Exp < 0 || len(out.ContentRevision) != 64 {
		return out, errors.New("character pet: invalid equipment receipt payload")
	}
	if err := out.Equipment.Validate(); err != nil {
		return out, err
	}
	switch out.ResultKind {
	case "SUCCESS", "ALREADY_EQUIPPED", "APPLIED", "NO_WORK":
	default:
		return out, errors.New("character pet: invalid equipment receipt result kind")
	}
	if out.UniqueEquipmentFact != nil {
		if err := out.UniqueEquipmentFact.Validate(); err != nil {
			return out, err
		}
	}
	return out, nil
}

func putPetEquipmentReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, result petEquipmentReceipt, resultType string) error {
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA4_4A_PET_EQUIPMENT", resultType, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = "pass549-ca4-4a"
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func equipResultFromReceipt(r receipt.Receipt) (EquipItemResult, error) {
	decoded, err := decodePetEquipmentReceipt(r)
	if err != nil {
		return EquipItemResult{}, err
	}
	if decoded.ResultKind != "SUCCESS" && decoded.ResultKind != "ALREADY_EQUIPPED" {
		return EquipItemResult{}, errors.New("character pet: wrong receipt kind for direct equip")
	}
	return EquipItemResult{PetID: decoded.PetID, Level: decoded.Level, Exp: decoded.Exp, Equipment: decoded.Equipment, AlreadyEquipped: decoded.ResultKind == "ALREADY_EQUIPPED", UniqueEquipmentFact: decoded.UniqueEquipmentFact}, nil
}

func oneKeyResultFromReceipt(r receipt.Receipt) (OneKeyEquipResult, error) {
	decoded, err := decodePetEquipmentReceipt(r)
	if err != nil {
		return OneKeyEquipResult{}, err
	}
	if decoded.ResultKind != "APPLIED" && decoded.ResultKind != "NO_WORK" {
		return OneKeyEquipResult{}, errors.New("character pet: wrong receipt kind for one-key equip")
	}
	return OneKeyEquipResult{PetID: decoded.PetID, Level: decoded.Level, Exp: decoded.Exp, Equipment: decoded.Equipment, NoWork: decoded.ResultKind == "NO_WORK"}, nil
}

func collectPetEquipmentSlots(p character.Pet, slots []int64, level, exp int64, op operation.Context) (character.Pet, error) {
	if op.StartedAt.IsZero() || len(slots) == 0 {
		return character.Pet{}, errors.New("character pet: invalid equipment transition")
	}
	if err := p.Equipment.Validate(); err != nil {
		return character.Pet{}, err
	}
	for _, slot := range slots {
		if slot < 1 || slot > character.PetEquipmentSlotCount || p.Equipment[slot-1] != 0 {
			return character.Pet{}, errors.New("character pet: invalid planned equipment transition")
		}
	}
	p.Level = level
	p.Exp = exp
	for _, slot := range slots {
		p.Equipment[slot-1] = 1
	}
	p.StateVersion++
	p.UpdatedAt = op.StartedAt.UTC()
	if err := p.ValidatePersistent(); err != nil {
		return character.Pet{}, err
	}
	return p, nil
}

// EquipItem implements source-qualified MID783. Direct equip never composes a
// recipe: stock sends this operation only when the mapped finished item exists.
func (s Service) EquipItem(ctx context.Context, actor identity.ActorContext, petID, equipIndex int64, op operation.Context) (EquipItemResult, error) {
	if err := s.validateEquipItem(); err != nil {
		return EquipItemResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || equipIndex < 1 || equipIndex > character.PetEquipmentSlotCount || op.ID.IsZero() || op.StartedAt.IsZero() {
		return EquipItemResult{}, errors.New("character pet: invalid direct equipment request")
	}
	id := petReceiptIdentity(actor.PlayerID, "equip-item", op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID, "equip_index": equipIndex})
	if err != nil {
		return EquipItemResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return EquipItemResult{}, err
	} else if ok {
		return equipResultFromReceipt(prior)
	}
	bound, revision, err := s.bindEquipmentContent(ctx, op)
	if err != nil {
		return EquipItemResult{}, err
	}

	var out EquipItemResult
	res, err := s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out, err = equipResultFromReceipt(prior)
			return err
		}
		pet, found, err := s.Store.LockPetByIDTx(txctx, scope.Tx, actor.PlayerID, petID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out, err = equipResultFromReceipt(prior)
			return err
		}
		if !pet.IsShow {
			return ErrPetNotShown
		}
		pos, err := s.Equipment.PetEquipmentPositionTx(txctx, scope.Tx, revision, pet.TableID, pet.Color, equipIndex)
		if err != nil {
			return err
		}
		if pos.PetTableID != pet.TableID || pos.Color != pet.Color || pos.Slot != equipIndex || !pos.ItemID.Valid() || pos.Classification == character.PetEquipmentEmpty {
			return ErrPetEquipmentUnavailable
		}
		primitive, err := s.Equipment.EquipmentPrimitiveTx(txctx, scope.Tx, revision, int64(pos.ItemID))
		if err != nil {
			return err
		}
		if primitive.SourceItemType != 8 {
			return fmt.Errorf("character pet: mapped equipment item %d is not ItemType-8", pos.ItemID)
		}
		if pet.Equipment[equipIndex-1] != 0 {
			out = EquipItemResult{PetID: pet.PetID, Level: pet.Level, Exp: pet.Exp, Equipment: pet.Equipment, AlreadyEquipped: true}
			return putPetEquipmentReceipt(txctx, s, scope.Tx, actor, bound, id, fp, petEquipmentReceipt{ResultKind: "ALREADY_EQUIPPED", PetID: pet.PetID, Level: pet.Level, Exp: pet.Exp, Equipment: pet.Equipment, ContentRevision: revision}, "gxb.ca4-4a.mid783.v1")
		}
		if pet.Level < primitive.RequiredLevel {
			return ErrPetEquipmentUnavailable
		}
		if pos.Classification == character.PetEquipmentAwakening {
			awakened, err := s.Equipment.PetTemplateAwakenedTx(txctx, scope.Tx, revision, pet.TableID)
			if err != nil {
				return err
			}
			if !awakened {
				// The active-mission path remains activation-gated until the real
				// Awakening owner/provider is qualified. Do not invent mission state.
				return ErrPetAwakeningProviderUnavailable
			}
		}
		if _, err := s.MaterialCosts.DebitMaterialCostTx(txctx, scope.Tx, actor.PlayerID, appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: int64(pos.ItemID), Amount: 1}}}, bound); err != nil {
			return err
		}
		old := pet.StateVersion
		next, err := collectPetEquipmentSlots(pet, []int64{equipIndex}, pet.Level, pet.Exp, bound)
		if err != nil {
			return err
		}
		if err := s.Store.SavePetStateTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		var fact *PetUniqueEquipmentCommittedFact
		if pos.Classification == character.PetEquipmentAwakening {
			f := PetUniqueEquipmentCommittedFact{PlayerID: actor.PlayerID, PetID: next.PetID, PetTableID: next.TableID, Slot: equipIndex, ItemID: pos.ItemID, ContentRevision: revision}
			if err := f.Validate(); err != nil {
				return err
			}
			fact = &f
		}
		out = EquipItemResult{PetID: next.PetID, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment, UniqueEquipmentFact: fact}
		return putPetEquipmentReceipt(txctx, s, scope.Tx, actor, bound, id, fp, petEquipmentReceipt{ResultKind: "SUCCESS", PetID: next.PetID, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment, ContentRevision: revision, UniqueEquipmentFact: fact}, "gxb.ca4-4a.mid783.v1")
	})
	if err != nil {
		return EquipItemResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			out, err = equipResultFromReceipt(r)
		}
	}
	return out, err
}

func (s Service) loadPetOneKeyContentTx(ctx context.Context, q tx.Queryer, revision string, p character.Pet) ([character.PetEquipmentSlotCount]character.PetEquipmentPosition, map[int64]petEquipmentRecipeNode, []int64, map[int64]int64, error) {
	var positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition
	nodes := map[int64]petEquipmentRecipeNode{}
	closure := map[int64]struct{}{}
	visiting := map[int64]bool{}
	var loadNode func(int64) error
	loadNode = func(itemID int64) error {
		if itemID <= 0 {
			return errors.New("character pet: invalid equipment content identity")
		}
		if _, ok := nodes[itemID]; ok {
			closure[itemID] = struct{}{}
			return nil
		}
		if visiting[itemID] {
			return fmt.Errorf("character pet: equipment content cycle at %d", itemID)
		}
		visiting[itemID] = true
		defer delete(visiting, itemID)
		primitive, err := s.Equipment.EquipmentPrimitiveTx(ctx, q, revision, itemID)
		if err != nil {
			return err
		}
		edges, err := s.Equipment.EquipmentRecipeEdgesTx(ctx, q, revision, itemID)
		if err != nil {
			return err
		}
		for i, edge := range edges {
			if edge.ParentItemID != primitive.ItemID || edge.Ordinal != int64(i+1) {
				return errors.New("character pet: invalid equipment recipe content")
			}
			if err := loadNode(int64(edge.ComponentItemID)); err != nil {
				return err
			}
		}
		nodes[itemID] = petEquipmentRecipeNode{Primitive: primitive, Edges: append([]character.EquipmentRecipeEdge(nil), edges...)}
		closure[itemID] = struct{}{}
		return nil
	}

	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		pos, err := s.Equipment.PetEquipmentPositionTx(ctx, q, revision, p.TableID, p.Color, slot)
		if err != nil {
			return positions, nil, nil, nil, err
		}
		positions[slot-1] = pos
		if p.Equipment[slot-1] == 0 && pos.ItemID.Valid() && pos.Classification == character.PetEquipmentOrdinary {
			if err := loadNode(int64(pos.ItemID)); err != nil {
				return positions, nil, nil, nil, err
			}
		}
	}
	potionEXP := make(map[int64]int64, len(petEquipmentPotionOrder))
	for _, itemID := range petEquipmentPotionOrder {
		unit, err := s.Progression.PetExpItemTx(ctx, q, revision, itemID)
		if err != nil {
			return positions, nil, nil, nil, err
		}
		if unit <= 0 {
			return positions, nil, nil, nil, errors.New("character pet: invalid Pet EXP potion content")
		}
		potionEXP[itemID] = unit
		closure[itemID] = struct{}{}
	}
	ids := make([]int64, 0, len(closure))
	for id := range closure {
		ids = append(ids, id)
	}
	if len(ids) > 48 {
		return positions, nil, nil, nil, fmt.Errorf("character pet: equipment closure exceeds source-qualified bound: %d", len(ids))
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	return positions, nodes, ids, potionEXP, nil
}

func preparedPetPlanningSnapshot(p *appi5.PreparedEquipmentResources) (petEquipmentPlanningSnapshot, error) {
	if p == nil || p.PlayerLevel() <= 0 || p.Mana() < 0 {
		return petEquipmentPlanningSnapshot{}, errors.New("character pet: invalid prepared equipment resources")
	}
	stacks := make(map[int64]int64)
	for _, id := range p.PreparedStackItemIDs() {
		q, ok := p.StackQuantity(id)
		if !ok || q < 0 {
			return petEquipmentPlanningSnapshot{}, errors.New("character pet: incomplete prepared equipment resources")
		}
		stacks[id] = q
	}
	return petEquipmentPlanningSnapshot{PlayerLevel: p.PlayerLevel(), Mana: p.Mana(), Stacks: stacks}, nil
}

func applyPetEquipmentPlan(p character.Pet, plan petEquipmentPlan, maxLevel int64, realThresholds []ExpThreshold, op operation.Context) (character.Pet, error) {
	if plan.noWork() {
		return p, nil
	}
	if maxLevel < 1 || int64(len(realThresholds)) != maxLevel || p.Level > maxLevel {
		return character.Pet{}, errors.New("character pet: invalid real Pet EXP policy for equipment")
	}
	if err := ValidateExpThresholds(realThresholds, maxLevel); err != nil {
		return character.Pet{}, err
	}
	nextExp := p.Exp
	nextLevel := p.Level
	if plan.PotionEXPGranted > 0 {
		capExp := realThresholds[len(realThresholds)-1].TotalExp
		if p.Exp > capExp {
			return character.Pet{}, errors.New("character pet: Pet EXP exceeds source-qualified maximum")
		}
		if plan.PotionEXPGranted <= capExp-p.Exp {
			nextExp = p.Exp + plan.PotionEXPGranted
		} else {
			nextExp = capExp
		}
		var err error
		nextLevel, err = petLevelForExp(nextExp, maxLevel, realThresholds)
		if err != nil {
			return character.Pet{}, err
		}
	}
	return collectPetEquipmentSlots(p, plan.Selected, nextLevel, nextExp, op)
}

// OneKeyEquip implements source-compatible MID792. The server ignores any
// client-side prediction because the wire transmits only pet_id; it replans
// under the Pet owner lock plus I5's canonical resource-lock suffix.
func (s Service) OneKeyEquip(ctx context.Context, actor identity.ActorContext, petID int64, op operation.Context) (OneKeyEquipResult, error) {
	if err := s.validateOneKeyEquip(); err != nil {
		return OneKeyEquipResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return OneKeyEquipResult{}, errors.New("character pet: invalid one-key equipment request")
	}
	id := petReceiptIdentity(actor.PlayerID, "one-key-equip", op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID})
	if err != nil {
		return OneKeyEquipResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return OneKeyEquipResult{}, err
	} else if ok {
		return oneKeyResultFromReceipt(prior)
	}
	bound, revision, err := s.bindEquipmentContent(ctx, op)
	if err != nil {
		return OneKeyEquipResult{}, err
	}
	var out OneKeyEquipResult
	res, err := s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out, err = oneKeyResultFromReceipt(prior)
			return err
		}
		pet, found, err := s.Store.LockPetByIDTx(txctx, scope.Tx, actor.PlayerID, petID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out, err = oneKeyResultFromReceipt(prior)
			return err
		}
		if !pet.IsShow {
			return ErrPetNotShown
		}
		positions, nodes, closure, potionEXP, err := s.loadPetOneKeyContentTx(txctx, scope.Tx, revision, pet)
		if err != nil {
			return err
		}
		prepared, err := s.EquipmentResources.PrepareEquipmentResourcesTx(txctx, scope.Tx, actor.PlayerID, appi5.EquipmentResourceRequest{PotentialStackItemIDs: closure}, bound)
		if err != nil {
			return err
		}
		snapshot, err := preparedPetPlanningSnapshot(prepared)
		if err != nil {
			return err
		}
		maxLevel, err := s.Progression.CharacterMaxLevelTx(txctx, scope.Tx, revision, snapshot.PlayerLevel)
		if err != nil {
			return err
		}
		compatibility, err := s.Equipment.EquipmentCompatibilityExpPolicyTx(txctx, scope.Tx, revision, maxLevel)
		if err != nil {
			return err
		}
		plan, err := planPetOneKeyEquipment(pet, positions, nodes, snapshot, maxLevel, compatibility, potionEXP)
		if err != nil {
			return err
		}
		if plan.noWork() {
			out = OneKeyEquipResult{PetID: pet.PetID, Level: pet.Level, Exp: pet.Exp, Equipment: pet.Equipment, NoWork: true}
			return putPetEquipmentReceipt(txctx, s, scope.Tx, actor, bound, id, fp, petEquipmentReceipt{ResultKind: "NO_WORK", PetID: pet.PetID, Level: pet.Level, Exp: pet.Exp, Equipment: pet.Equipment, ContentRevision: revision}, "gxb.ca4-4a.mid792.v1")
		}
		debit := appi5.EquipmentResourceDebit{Mana: plan.ManaDebit}
		for _, x := range sortedPetEquipmentStackDebits(plan.StackDebits) {
			debit.Stacks = append(debit.Stacks, appi5.EquipmentStackDebit{ItemID: x.ItemID, Count: x.Count})
		}
		if _, err := s.EquipmentResources.ApplyEquipmentResourceDebitTx(txctx, scope.Tx, prepared, debit); err != nil {
			return err
		}
		realThresholds, err := s.Progression.PetExpPolicyTx(txctx, scope.Tx, revision, maxLevel)
		if err != nil {
			return err
		}
		old := pet.StateVersion
		next, err := applyPetEquipmentPlan(pet, plan, maxLevel, realThresholds, bound)
		if err != nil {
			return err
		}
		if err := s.Store.SavePetStateTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		out = OneKeyEquipResult{PetID: next.PetID, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment}
		return putPetEquipmentReceipt(txctx, s, scope.Tx, actor, bound, id, fp, petEquipmentReceipt{ResultKind: "APPLIED", PetID: next.PetID, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment, ContentRevision: revision}, "gxb.ca4-4a.mid792.v1")
	})
	if err != nil {
		return OneKeyEquipResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			out, err = oneKeyResultFromReceipt(r)
		}
	}
	return out, err
}
