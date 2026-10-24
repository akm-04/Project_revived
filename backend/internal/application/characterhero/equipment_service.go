package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"sort"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrHeroEquipmentUnavailable = errors.New("character hero: ordinary equipment unavailable")
	ErrHeroAlreadyEquipped      = errors.New("character hero: already equipped")
)

type EquipmentOperationContent interface {
	HeroEquipmentRevision(context.Context, string) (bool, error)
	SuperEquipmentRevision(context.Context, string) (bool, error)
	EquipmentPrimitivesRevision(context.Context, string) (bool, error)
	HeroEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64, int64) (character.HeroEquipmentPosition, error)
	SuperEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64) (character.SuperEquipmentPosition, error)
	SuperEquipmentCapTx(context.Context, tx.Queryer, string, int64) (character.SuperEquipmentEnhancementCap, error)
	SuperEquipmentTierTx(context.Context, tx.Queryer, string, int64) (character.SuperEquipmentEnhancementTier, error)
	EquipmentPrimitiveTx(context.Context, tx.Queryer, string, int64) (character.EquipmentPrimitive, error)
	EquipmentRecipeEdgesTx(context.Context, tx.Queryer, string, int64) ([]character.EquipmentRecipeEdge, error)
}

type EquipItemResult struct {
	PartnerID       int64
	Equipment       character.HeroEquipmentSlots
	AlreadyEquipped bool
}

type OneKeyEquipResult struct {
	PartnerID int64
	Level     int64
	Exp       int64
	Equipment character.HeroEquipmentSlots
	NoWork    bool
}

type EnhanceSuperEquipmentResult struct {
	PartnerID int64
	Equipment character.HeroEquipmentSlots
}

type superEquipmentEnhanceReceipt struct {
	PartnerID int64                        `json:"partner_id"`
	Equipment character.HeroEquipmentSlots `json:"equips"`
}

type heroEquipmentReceipt struct {
	PartnerID       int64                        `json:"partner_id"`
	Level           int64                        `json:"level"`
	Exp             int64                        `json:"exp"`
	Equipment       character.HeroEquipmentSlots `json:"equips"`
	Family          character.HeroKind           `json:"family,omitempty"`
	AlreadyEquipped bool                         `json:"already_equipped,omitempty"`
	NoWork          bool                         `json:"no_work,omitempty"`
}

const (
	heroEquipmentMID54NormalV1 = "gxb.ca4-2.mid54.v1"
	heroEquipmentMID62NormalV1 = "gxb.ca4-2.mid62.v1"
	heroEquipmentMID54SuperV2  = "gxb.ca4-5.mid54.super.v2"
	heroEquipmentMID304SuperV1 = "gxb.ca4-5.mid304.super.v1"
)

func (s Service) validateSuperEquipmentEnhance() error {
	if err := s.validate(); err != nil {
		return err
	}
	if s.ProgressionStore == nil || s.Progression == nil || s.Equipment == nil || s.MaterialCosts == nil {
		return errors.New("character hero: incomplete CA4-5 MID304 service")
	}
	return nil
}

func (s Service) bindSuperEquipmentContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	bound, revision, err := s.bindEquipmentPrimitiveContent(ctx, op)
	if err != nil {
		return operation.Context{}, "", err
	}
	good, err := s.Equipment.SuperEquipmentRevision(ctx, revision)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrHeroEquipmentContentInactive
	}
	return bound, revision, nil
}

func decodeSuperEquipmentEnhanceReceipt(r receipt.Receipt) (superEquipmentEnhanceReceipt, error) {
	if r.ResultSchema != heroEquipmentMID304SuperV1 {
		return superEquipmentEnhanceReceipt{}, errors.New("character hero: unsupported Super equipment enhance receipt schema")
	}
	var out superEquipmentEnhanceReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PartnerID <= 0 {
		return out, errors.New("character hero: invalid Super equipment enhance receipt payload")
	}
	if err := out.Equipment.Validate(); err != nil {
		return out, err
	}
	return out, nil
}

func putSuperEquipmentEnhanceReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, result superEquipmentEnhanceReceipt) error {
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA4_5_SUPER_EQUIPMENT", heroEquipmentMID304SuperV1, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = "pass554-ca4-5"
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func (s Service) validateEquipItem() error {
	if err := s.validateProgression(); err != nil {
		return err
	}
	if s.Equipment == nil || s.MaterialCosts == nil {
		return errors.New("character hero: incomplete CA4-2 MID54 service")
	}
	return nil
}

func (s Service) validateOneKeyEquip() error {
	if err := s.validateProgression(); err != nil {
		return err
	}
	if s.Equipment == nil || s.EquipmentResources == nil {
		return errors.New("character hero: incomplete CA4-2 MID62 service")
	}
	return nil
}

func (s Service) bindEquipmentPrimitiveContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	bound, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return operation.Context{}, "", err
	}
	good, err := s.Equipment.EquipmentPrimitivesRevision(ctx, revision)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrHeroEquipmentContentInactive
	}
	return bound, revision, nil
}

func (s Service) bindEquipmentContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	bound, revision, err := s.bindEquipmentPrimitiveContent(ctx, op)
	if err != nil {
		return operation.Context{}, "", err
	}
	good, err := s.Equipment.HeroEquipmentRevision(ctx, revision)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrHeroEquipmentContentInactive
	}
	return bound, revision, nil
}

func decodeHeroEquipmentReceipt(r receipt.Receipt) (heroEquipmentReceipt, error) {
	var out heroEquipmentReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PartnerID <= 0 || out.Level <= 0 || out.Exp < 0 {
		return out, errors.New("character hero: invalid equipment receipt payload")
	}
	switch r.ResultSchema {
	case heroEquipmentMID54NormalV1, heroEquipmentMID62NormalV1:
		if out.Family != "" && out.Family != character.NormalHero {
			return out, errors.New("character hero: Normal equipment receipt family mismatch")
		}
		if err := out.Equipment.ValidateNormal(); err != nil {
			return out, err
		}
		out.Family = character.NormalHero
	case heroEquipmentMID54SuperV2:
		if out.Family != character.SuperHero {
			return out, errors.New("character hero: Super equipment receipt family mismatch")
		}
		if err := out.Equipment.Validate(); err != nil {
			return out, err
		}
	default:
		return out, errors.New("character hero: unsupported equipment receipt schema")
	}
	return out, nil
}

func putHeroEquipmentReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, result heroEquipmentReceipt, resultType string) error {
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA4_2_HERO_EQUIPMENT", resultType, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = "pass536-ca4-2"
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func validateNormalHeroForEquipment(ctx context.Context, s Service, q tx.Queryer, revision string, h character.Hero) error {
	if err := h.ValidatePersistent(); err != nil {
		return err
	}
	if err := h.Equipment.ValidateNormal(); err != nil {
		return err
	}
	tmpl, err := s.Progression.HeroTemplateProgressionTx(ctx, q, revision, h.TableID)
	if err != nil {
		return err
	}
	if tmpl.Kind != character.NormalHero {
		return ErrHeroEquipmentUnavailable
	}
	return nil
}

func collectNormalEquipmentSlot(h character.Hero, slot int64, now operation.Context) (character.Hero, error) {
	if slot < 1 || slot > character.HeroEquipmentSlotCount || now.StartedAt.IsZero() {
		return character.Hero{}, errors.New("character hero: invalid equipment slot transition")
	}
	if err := h.Equipment.ValidateNormal(); err != nil {
		return character.Hero{}, err
	}
	if h.Equipment[slot-1] != 0 {
		return character.Hero{}, ErrHeroAlreadyEquipped
	}
	h.Equipment[slot-1] = 1
	h.StateVersion++
	h.UpdatedAt = now.StartedAt.UTC()
	if err := h.ValidatePersistent(); err != nil {
		return character.Hero{}, err
	}
	return h, nil
}

func collectSuperEquipmentSlot(h character.Hero, slot int64, now operation.Context) (character.Hero, error) {
	if slot < 1 || slot > character.HeroEquipmentSlotCount || now.StartedAt.IsZero() {
		return character.Hero{}, errors.New("character hero: invalid Super equipment slot transition")
	}
	if err := h.Equipment.Validate(); err != nil {
		return character.Hero{}, err
	}
	if h.Equipment[slot-1] != 0 {
		return character.Hero{}, ErrHeroAlreadyEquipped
	}
	h.Equipment[slot-1] = 1
	h.StateVersion++
	h.UpdatedAt = now.StartedAt.UTC()
	if err := h.ValidatePersistent(); err != nil {
		return character.Hero{}, err
	}
	return h, nil
}

// EquipItem implements the CA4-2 Normal-Hero MID54 semantic operation. It does
// not compose recipes: current src_64 invokes this wire only for a directly
// possessed mapped item. Dispatcher/HTTP shaping remains CA4-2D.
func (s Service) EquipItem(ctx context.Context, actor identity.ActorContext, partnerID, equipIndex int64, op operation.Context) (EquipItemResult, error) {
	if err := s.validateEquipItem(); err != nil {
		return EquipItemResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || equipIndex < 1 || equipIndex > character.HeroEquipmentSlotCount {
		return EquipItemResult{}, errors.New("character hero: invalid equip operation")
	}
	bound, revision, err := s.bindEquipmentPrimitiveContent(ctx, op)
	if err != nil {
		return EquipItemResult{}, err
	}
	id := heroReceiptID(actor, "equip-item", bound)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID, "equip_index": equipIndex})
	if err != nil {
		return EquipItemResult{}, err
	}
	var result EquipItemResult
	_, err = s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			decoded, err := decodeHeroEquipmentReceipt(prior)
			if err != nil {
				return err
			}
			result = EquipItemResult{PartnerID: decoded.PartnerID, Equipment: decoded.Equipment, AlreadyEquipped: decoded.AlreadyEquipped}
			return nil
		}

		hero, err := s.ProgressionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if err := hero.ValidatePersistent(); err != nil {
			return err
		}
		tmpl, err := s.Progression.HeroTemplateProgressionTx(txctx, scope.Tx, revision, hero.TableID)
		if err != nil {
			return err
		}
		var itemID character.EquipmentTemplateID
		var receiptFamily character.HeroKind
		var resultSchema string
		switch tmpl.Kind {
		case character.NormalHero:
			good, err := s.Equipment.HeroEquipmentRevision(txctx, revision)
			if err != nil {
				return err
			}
			if !good {
				return ErrHeroEquipmentContentInactive
			}
			if err := hero.Equipment.ValidateNormal(); err != nil {
				return err
			}
			pos, err := s.Equipment.HeroEquipmentPositionTx(txctx, scope.Tx, revision, hero.TableID, hero.Color, equipIndex)
			if err != nil {
				return err
			}
			if !pos.ItemID.Valid() || !pos.OrdinaryEligible {
				return ErrHeroEquipmentUnavailable
			}
			itemID, receiptFamily, resultSchema = pos.ItemID, character.NormalHero, heroEquipmentMID54NormalV1
		case character.SuperHero:
			good, err := s.Equipment.SuperEquipmentRevision(txctx, revision)
			if err != nil {
				return err
			}
			if !good {
				return ErrHeroEquipmentContentInactive
			}
			if err := hero.Equipment.Validate(); err != nil {
				return err
			}
			pos, err := s.Equipment.SuperEquipmentPositionTx(txctx, scope.Tx, revision, hero.TableID, equipIndex)
			if err != nil {
				return err
			}
			if !pos.ItemID.Valid() {
				return ErrHeroEquipmentUnavailable
			}
			itemID, receiptFamily, resultSchema = pos.ItemID, character.SuperHero, heroEquipmentMID54SuperV2
		default:
			return ErrHeroEquipmentUnavailable
		}
		primitive, err := s.Equipment.EquipmentPrimitiveTx(txctx, scope.Tx, revision, int64(itemID))
		if err != nil {
			return err
		}
		if primitive.ItemID != itemID || primitive.SourceItemType != 1 {
			return ErrHeroEquipmentUnavailable
		}
		if hero.Equipment[equipIndex-1] != 0 {
			result = EquipItemResult{PartnerID: hero.PartnerID, Equipment: hero.Equipment, AlreadyEquipped: true}
			r := heroEquipmentReceipt{PartnerID: hero.PartnerID, Level: hero.Level, Exp: hero.Exp, Equipment: hero.Equipment, AlreadyEquipped: true}
			if receiptFamily == character.SuperHero {
				r.Family = receiptFamily
			}
			return putHeroEquipmentReceipt(txctx, s, scope.Tx, actor, bound, id, fp, r, resultSchema)
		}
		if hero.Level < primitive.RequiredLevel {
			return ErrHeroEquipmentUnavailable
		}
		if _, err := s.MaterialCosts.DebitMaterialCostTx(txctx, scope.Tx, actor.PlayerID, appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: int64(itemID), Amount: 1}}}, bound); err != nil {
			return err
		}
		old := hero.StateVersion
		var next character.Hero
		if receiptFamily == character.SuperHero {
			next, err = collectSuperEquipmentSlot(hero, equipIndex, bound)
		} else {
			next, err = collectNormalEquipmentSlot(hero, equipIndex, bound)
		}
		if err != nil {
			return err
		}
		if err := s.ProgressionStore.SaveHeroStateTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		result = EquipItemResult{PartnerID: next.PartnerID, Equipment: next.Equipment}
		r := heroEquipmentReceipt{PartnerID: next.PartnerID, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment}
		if receiptFamily == character.SuperHero {
			r.Family = receiptFamily
		}
		return putHeroEquipmentReceipt(txctx, s, scope.Tx, actor, bound, id, fp, r, resultSchema)
	})
	return result, err
}

// EnhanceSuperEquipment implements current src_64 MID304. Super equipment
// raw slots encode enhancement+1: raw=1 is collected level 0. The operation is
// deterministic and consumes only duplicate copies of the already-mapped base
// item; current source does not charge Mana or compose recipe components here.
func (s Service) EnhanceSuperEquipment(ctx context.Context, actor identity.ActorContext, partnerID, equipIndex, enhanceTimes int64, op operation.Context) (EnhanceSuperEquipmentResult, error) {
	if err := s.validateSuperEquipmentEnhance(); err != nil {
		return EnhanceSuperEquipmentResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || equipIndex < 1 || equipIndex > character.HeroEquipmentSlotCount || enhanceTimes <= 0 {
		return EnhanceSuperEquipmentResult{}, errors.New("character hero: invalid Super equipment enhancement operation")
	}
	bound, revision, err := s.bindSuperEquipmentContent(ctx, op)
	if err != nil {
		return EnhanceSuperEquipmentResult{}, err
	}
	id := heroReceiptID(actor, "enhance-super-equipment", bound)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID, "equip_index": equipIndex, "enhance_times": enhanceTimes})
	if err != nil {
		return EnhanceSuperEquipmentResult{}, err
	}
	var result EnhanceSuperEquipmentResult
	_, err = s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			decoded, err := decodeSuperEquipmentEnhanceReceipt(prior)
			if err != nil {
				return err
			}
			result = EnhanceSuperEquipmentResult{PartnerID: decoded.PartnerID, Equipment: decoded.Equipment}
			return nil
		}

		hero, err := s.ProgressionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if err := hero.ValidatePersistent(); err != nil {
			return err
		}
		tmpl, err := s.Progression.HeroTemplateProgressionTx(txctx, scope.Tx, revision, hero.TableID)
		if err != nil {
			return err
		}
		if tmpl.Kind != character.SuperHero || hero.Star < 1 || hero.Star > character.MaxHeroStar {
			return ErrHeroEquipmentUnavailable
		}
		if err := hero.Equipment.Validate(); err != nil {
			return err
		}
		raw := hero.Equipment[equipIndex-1]
		if raw < 1 {
			return ErrHeroEquipmentUnavailable
		}
		current := raw - 1
		if enhanceTimes > math.MaxInt64-current {
			return ErrHeroEquipmentUnavailable
		}
		target := current + enhanceTimes

		capRow, err := s.Equipment.SuperEquipmentCapTx(txctx, scope.Tx, revision, hero.Star)
		if err != nil {
			return err
		}
		if err := capRow.Validate(); err != nil {
			return err
		}
		if capRow.Star != hero.Star || !capRow.EffectiveClientReachable || current > capRow.MaxEnhancement || target > capRow.MaxEnhancement {
			return ErrHeroEquipmentUnavailable
		}

		pos, err := s.Equipment.SuperEquipmentPositionTx(txctx, scope.Tx, revision, hero.TableID, equipIndex)
		if err != nil {
			return err
		}
		if err := pos.Validate(); err != nil {
			return err
		}
		primitive, err := s.Equipment.EquipmentPrimitiveTx(txctx, scope.Tx, revision, int64(pos.ItemID))
		if err != nil {
			return err
		}
		if primitive.ItemID != pos.ItemID || primitive.SourceItemType != 1 {
			return ErrHeroEquipmentUnavailable
		}

		var duplicateCount int64
		for level := current + 1; level <= target; level++ {
			tierID := (level-1)/10 + 1
			tier, err := s.Equipment.SuperEquipmentTierTx(txctx, scope.Tx, revision, tierID)
			if err != nil {
				return err
			}
			if err := tier.Validate(); err != nil {
				return err
			}
			if tier.Tier != tierID || !tier.EffectiveClientReachable || hero.Star < tier.MinStar || tier.DuplicateCount != 1 {
				return ErrHeroEquipmentUnavailable
			}
			if duplicateCount > math.MaxInt64-tier.DuplicateCount {
				return ErrHeroEquipmentUnavailable
			}
			duplicateCount += tier.DuplicateCount
		}
		if duplicateCount != enhanceTimes {
			return ErrHeroEquipmentUnavailable
		}
		if _, err := s.MaterialCosts.DebitMaterialCostTx(txctx, scope.Tx, actor.PlayerID, appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: int64(pos.ItemID), Amount: duplicateCount}}}, bound); err != nil {
			return err
		}

		old := hero.StateVersion
		next := hero
		next.Equipment[equipIndex-1] += enhanceTimes
		next.StateVersion++
		next.UpdatedAt = bound.StartedAt.UTC()
		if err := next.ValidatePersistent(); err != nil {
			return err
		}
		if err := s.ProgressionStore.SaveHeroStateTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		result = EnhanceSuperEquipmentResult{PartnerID: next.PartnerID, Equipment: next.Equipment}
		return putSuperEquipmentEnhanceReceipt(txctx, s, scope.Tx, actor, bound, id, fp, superEquipmentEnhanceReceipt{PartnerID: next.PartnerID, Equipment: next.Equipment})
	})
	return result, err
}

func (s Service) loadOneKeyContentTx(ctx context.Context, q tx.Queryer, revision string, h character.Hero) ([character.HeroEquipmentSlotCount]character.HeroEquipmentPosition, map[int64]heroEquipmentRecipeNode, []int64, map[int64]int64, error) {
	var positions [character.HeroEquipmentSlotCount]character.HeroEquipmentPosition
	nodes := map[int64]heroEquipmentRecipeNode{}
	closure := map[int64]struct{}{}
	visiting := map[int64]bool{}
	var loadNode func(int64) error
	loadNode = func(itemID int64) error {
		if itemID <= 0 {
			return errors.New("character hero: invalid equipment content identity")
		}
		if _, ok := nodes[itemID]; ok {
			closure[itemID] = struct{}{}
			return nil
		}
		if visiting[itemID] {
			return fmt.Errorf("character hero: equipment content cycle at %d", itemID)
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
				return errors.New("character hero: invalid equipment recipe content")
			}
			if err := loadNode(int64(edge.ComponentItemID)); err != nil {
				return err
			}
		}
		nodes[itemID] = heroEquipmentRecipeNode{Primitive: primitive, Edges: append([]character.EquipmentRecipeEdge(nil), edges...)}
		closure[itemID] = struct{}{}
		return nil
	}

	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		pos, err := s.Equipment.HeroEquipmentPositionTx(ctx, q, revision, h.TableID, h.Color, slot)
		if err != nil {
			return positions, nil, nil, nil, err
		}
		positions[slot-1] = pos
		if h.Equipment[slot-1] == 0 && pos.ItemID.Valid() && pos.OrdinaryEligible {
			if err := loadNode(int64(pos.ItemID)); err != nil {
				return positions, nil, nil, nil, err
			}
		}
	}

	potionEXP := make(map[int64]int64, len(heroEquipmentPotionOrder))
	for _, itemID := range heroEquipmentPotionOrder {
		unit, err := s.Progression.HeroExpItemTx(ctx, q, revision, itemID)
		if err != nil {
			return positions, nil, nil, nil, err
		}
		if unit <= 0 {
			return positions, nil, nil, nil, errors.New("character hero: invalid Hero EXP potion content")
		}
		potionEXP[itemID] = unit
		closure[itemID] = struct{}{}
	}
	ids := make([]int64, 0, len(closure))
	for id := range closure {
		ids = append(ids, id)
	}
	// I5 re-sorts in its canonical decimal identity order. Numeric ordering here
	// is only for deterministic service tests/artifacts.
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	return positions, nodes, ids, potionEXP, nil
}

func preparedPlanningSnapshot(p *appi5.PreparedHeroEquipmentResources) (heroEquipmentPlanningSnapshot, error) {
	if p == nil || p.PlayerLevel() <= 0 || p.Mana() < 0 {
		return heroEquipmentPlanningSnapshot{}, errors.New("character hero: invalid prepared equipment resources")
	}
	stacks := make(map[int64]int64)
	for _, id := range p.PreparedStackItemIDs() {
		q, ok := p.StackQuantity(id)
		if !ok || q < 0 {
			return heroEquipmentPlanningSnapshot{}, errors.New("character hero: incomplete prepared equipment resources")
		}
		stacks[id] = q
	}
	return heroEquipmentPlanningSnapshot{PlayerLevel: p.PlayerLevel(), Mana: p.Mana(), Stacks: stacks}, nil
}

func applyEquipmentPlanToHero(h character.Hero, plan heroEquipmentPlan, maxLevel int64, thresholds []character.HeroExpThreshold, op operation.Context) (character.Hero, error) {
	if plan.noWork() {
		return h, nil
	}
	oldVersion := h.StateVersion
	var err error
	if plan.PotionEXPGranted > 0 {
		h, err = h.AddSourceEXP(plan.PotionEXPGranted, maxLevel, thresholds, op.StartedAt)
		if err != nil {
			return character.Hero{}, err
		}
	} else {
		h.StateVersion++
		h.UpdatedAt = op.StartedAt.UTC()
	}
	for _, slot := range plan.Selected {
		if slot < 1 || slot > character.HeroEquipmentSlotCount || h.Equipment[slot-1] != 0 {
			return character.Hero{}, errors.New("character hero: invalid planned equipment transition")
		}
		h.Equipment[slot-1] = 1
	}
	if h.StateVersion != oldVersion+1 {
		return character.Hero{}, errors.New("character hero: non-cohesive equipment state transition")
	}
	if err := h.Equipment.ValidateNormal(); err != nil {
		return character.Hero{}, err
	}
	if err := h.ValidatePersistent(); err != nil {
		return character.Hero{}, err
	}
	return h, nil
}

// OneKeyEquip implements the CA4-2 Normal-Hero MID62 semantic operation. It
// deterministically reconstructs the stock-client planner under canonical Hero
// and prepared I5 locks. HTTP/economy projection remains CA4-2D.
func (s Service) OneKeyEquip(ctx context.Context, actor identity.ActorContext, partnerID int64, op operation.Context) (OneKeyEquipResult, error) {
	if err := s.validateOneKeyEquip(); err != nil {
		return OneKeyEquipResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 {
		return OneKeyEquipResult{}, errors.New("character hero: invalid one-key equipment operation")
	}
	bound, revision, err := s.bindEquipmentContent(ctx, op)
	if err != nil {
		return OneKeyEquipResult{}, err
	}
	id := heroReceiptID(actor, "one-key-equip", bound)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID})
	if err != nil {
		return OneKeyEquipResult{}, err
	}
	var result OneKeyEquipResult
	_, err = s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			decoded, err := decodeHeroEquipmentReceipt(prior)
			if err != nil {
				return err
			}
			result = OneKeyEquipResult{PartnerID: decoded.PartnerID, Level: decoded.Level, Exp: decoded.Exp, Equipment: decoded.Equipment, NoWork: decoded.NoWork}
			return nil
		}

		hero, err := s.ProgressionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if err := validateNormalHeroForEquipment(txctx, s, scope.Tx, revision, hero); err != nil {
			return err
		}
		positions, nodes, closure, potionEXP, err := s.loadOneKeyContentTx(txctx, scope.Tx, revision, hero)
		if err != nil {
			return err
		}
		prepared, err := s.EquipmentResources.PrepareHeroEquipmentResourcesTx(txctx, scope.Tx, actor.PlayerID, appi5.HeroEquipmentResourceRequest{PotentialStackItemIDs: closure}, bound)
		if err != nil {
			return err
		}
		snapshot, err := preparedPlanningSnapshot(prepared)
		if err != nil {
			return err
		}
		maxLevel, err := s.Progression.HeroMaxLevelTx(txctx, scope.Tx, revision, snapshot.PlayerLevel)
		if err != nil {
			return err
		}
		thresholds, err := s.Progression.HeroExpPolicyTx(txctx, scope.Tx, revision, maxLevel)
		if err != nil {
			return err
		}
		plan, err := planOneKeyEquipment(hero, positions, nodes, snapshot, maxLevel, thresholds, potionEXP)
		if err != nil {
			return err
		}
		if plan.noWork() {
			result = OneKeyEquipResult{PartnerID: hero.PartnerID, Level: hero.Level, Exp: hero.Exp, Equipment: hero.Equipment, NoWork: true}
			return putHeroEquipmentReceipt(txctx, s, scope.Tx, actor, bound, id, fp, heroEquipmentReceipt{PartnerID: hero.PartnerID, Level: hero.Level, Exp: hero.Exp, Equipment: hero.Equipment, NoWork: true}, heroEquipmentMID62NormalV1)
		}

		debit := appi5.HeroEquipmentResourceDebit{Mana: plan.ManaDebit}
		for _, x := range sortedEquipmentStackDebits(plan.StackDebits) {
			debit.Stacks = append(debit.Stacks, appi5.HeroEquipmentStackDebit{ItemID: x.ItemID, Count: x.Count})
		}
		if _, err := s.EquipmentResources.ApplyHeroEquipmentResourceDebitTx(txctx, scope.Tx, prepared, debit); err != nil {
			return err
		}
		old := hero.StateVersion
		next, err := applyEquipmentPlanToHero(hero, plan, maxLevel, thresholds, bound)
		if err != nil {
			return err
		}
		if err := s.ProgressionStore.SaveHeroStateTx(txctx, scope.Tx, next, old); err != nil {
			return err
		}
		result = OneKeyEquipResult{PartnerID: next.PartnerID, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment}
		return putHeroEquipmentReceipt(txctx, s, scope.Tx, actor, bound, id, fp, heroEquipmentReceipt{PartnerID: next.PartnerID, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment}, heroEquipmentMID62NormalV1)
	})
	return result, err
}
