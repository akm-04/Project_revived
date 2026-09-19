package characterhero

import (
	"bytes"
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
	ErrHeroFumoContentInactive = errors.New("CA4-3A Hero Fumo content capability inactive")
	ErrHeroFumoUnavailable     = errors.New("character hero: Fumo unavailable")
)

type FumoOperationContent interface {
	HeroFumoRevision(context.Context, string) (bool, error)
	HeroFumoTargetTx(context.Context, tx.Queryer, string, character.EquipmentTemplateID) (character.HeroFumoTarget, error)
	HeroFumoMaterialTx(context.Context, tx.Queryer, string, character.EquipmentTemplateID) (character.HeroFumoMaterial, error)
}

type FumoResult struct {
	PartnerID int64
	Slot      int64
	Fumo      int64
	Levels    character.HeroFumoSlots
	Replayed  bool
}

type heroFumoReceipt struct {
	PartnerID int64                   `json:"partner_id"`
	Slot      int64                   `json:"slot"`
	Fumo      int64                   `json:"fumo"`
	Levels    character.HeroFumoSlots `json:"fumo_lev"`
}

func (s Service) validateFumo() error {
	if err := s.validateProgression(); err != nil {
		return err
	}
	if s.Equipment == nil || s.EquipmentResources == nil || s.Fumo == nil {
		return errors.New("character hero: incomplete CA4-3A MID58 service")
	}
	return nil
}

func (s Service) bindFumoContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	bound, revision, err := s.bindProgressionContent(ctx, op)
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
	good, err = s.Fumo.HeroFumoRevision(ctx, revision)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrHeroFumoContentInactive
	}
	return bound, revision, nil
}

func deriveFumoLevel(raw int64, target character.HeroFumoTarget) (int64, error) {
	if err := target.Validate(); err != nil {
		return 0, err
	}
	if raw < 0 || raw > target.TotalCap {
		return 0, errors.New("character hero: raw Fumo outside target cap")
	}
	var cumulative, level int64
	for _, inc := range target.ThresholdIncrements {
		next, err := checkedAdd64(cumulative, inc)
		if err != nil {
			return 0, err
		}
		cumulative = next
		if raw < cumulative {
			break
		}
		level++
	}
	return level, nil
}

type heroFumoPositionTxReader interface {
	HeroEquipmentPositionTx(context.Context, tx.Queryer, string, int64, int64, int64) (character.HeroEquipmentPosition, error)
}

type heroFumoTargetTxReader interface {
	HeroFumoTargetTx(context.Context, tx.Queryer, string, character.EquipmentTemplateID) (character.HeroFumoTarget, error)
}

func deriveFumoLevelsTxWith(ctx context.Context, q tx.Queryer, revision string, h character.Hero, positions heroFumoPositionTxReader, targets heroFumoTargetTxReader) (character.HeroFumoSlots, error) {
	var out character.HeroFumoSlots
	if q == nil || positions == nil || targets == nil || len(revision) != 64 {
		return out, errors.New("character hero: invalid Fumo projection input")
	}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		raw := h.Fumo[slot-1]
		if raw == 0 && h.Equipment[slot-1] == 0 {
			continue
		}
		pos, err := positions.HeroEquipmentPositionTx(ctx, q, revision, h.TableID, h.Color, slot)
		if err != nil {
			return out, err
		}
		if !pos.ItemID.Valid() {
			if raw != 0 {
				return out, errors.New("character hero: raw Fumo without mapped item")
			}
			continue
		}
		if raw == 0 {
			continue
		}
		target, err := targets.HeroFumoTargetTx(ctx, q, revision, pos.ItemID)
		if err != nil {
			return out, err
		}
		level, err := deriveFumoLevel(raw, target)
		if err != nil {
			return out, err
		}
		out[slot-1] = level
	}
	return out, nil
}

func (s Service) deriveFumoLevelsTx(ctx context.Context, q tx.Queryer, revision string, h character.Hero) (character.HeroFumoSlots, error) {
	return deriveFumoLevelsTxWith(ctx, q, revision, h, s.Equipment, s.Fumo)
}

func (s Service) deriveFumoLevelsRead(ctx context.Context, revision string, h character.Hero) (character.HeroFumoSlots, error) {
	var out character.HeroFumoSlots
	if s.RosterProjection == nil {
		return out, errors.New("character hero: roster projection unavailable")
	}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		raw := h.Fumo[slot-1]
		if raw == 0 && h.Equipment[slot-1] == 0 {
			continue
		}
		pos, err := s.RosterProjection.HeroEquipmentPosition(ctx, revision, h.TableID, h.Color, slot)
		if err != nil {
			return out, err
		}
		if !pos.ItemID.Valid() {
			if raw != 0 {
				return out, errors.New("character hero: raw Fumo without mapped item")
			}
			continue
		}
		if raw == 0 {
			continue
		}
		target, err := s.RosterProjection.HeroFumoTarget(ctx, revision, pos.ItemID)
		if err != nil {
			return out, err
		}
		level, err := deriveFumoLevel(raw, target)
		if err != nil {
			return out, err
		}
		out[slot-1] = level
	}
	return out, nil
}

func decodeHeroFumoReceipt(r receipt.Receipt) (heroFumoReceipt, error) {
	var out heroFumoReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PartnerID <= 0 || out.Slot < 1 || out.Slot > character.HeroEquipmentSlotCount || out.Fumo <= 0 {
		return out, errors.New("character hero: invalid Fumo receipt payload")
	}
	if err := out.Levels.Validate(); err != nil {
		return out, err
	}
	return out, nil
}

func putHeroFumoReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, result heroFumoReceipt) error {
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA4_3A_HERO_FUMO", "gxb.ca4-3a.mid58.v1", payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = "pass542-ca4-3a"
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func aggregateFumoMaterials(materials []int64) ([]int64, map[int64]int64, error) {
	if len(materials) == 0 {
		return nil, nil, errors.New("character hero: empty Fumo materials")
	}
	counts := make(map[int64]int64, len(materials))
	for _, itemID := range materials {
		if itemID <= 0 {
			return nil, nil, errors.New("character hero: invalid Fumo material identity")
		}
		next, err := checkedAdd64(counts[itemID], 1)
		if err != nil {
			return nil, nil, err
		}
		counts[itemID] = next
	}
	ids := make([]int64, 0, len(counts))
	for itemID := range counts {
		ids = append(ids, itemID)
	}
	sort.Slice(ids, func(i, j int) bool { return fmt.Sprintf("%d", ids[i]) < fmt.Sprintf("%d", ids[j]) })
	return ids, counts, nil
}

// FeedFumo implements the CA4-3A MID58 semantic operation. Same-operation
// receipt replay is exactly-once. A later HTTP retry has a new stock operation
// identity and is intentionally not deduplicated by payload/time heuristics.
func (s Service) FeedFumo(ctx context.Context, actor identity.ActorContext, partnerID, equipIndex int64, materials []int64, op operation.Context) (FumoResult, error) {
	if err := s.validateFumo(); err != nil {
		return FumoResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || equipIndex < 1 || equipIndex > character.HeroEquipmentSlotCount {
		return FumoResult{}, errors.New("character hero: invalid Fumo operation")
	}
	ids, counts, err := aggregateFumoMaterials(materials)
	if err != nil {
		return FumoResult{}, err
	}
	bound, revision, err := s.bindFumoContent(ctx, op)
	if err != nil {
		return FumoResult{}, err
	}
	id := heroReceiptID(actor, "feed-fumo", bound)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID, "equip_index": equipIndex, "materials": materials})
	if err != nil {
		return FumoResult{}, err
	}

	var result FumoResult
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
			decoded, err := decodeHeroFumoReceipt(prior)
			if err != nil {
				return err
			}
			result = FumoResult{PartnerID: decoded.PartnerID, Slot: decoded.Slot, Fumo: decoded.Fumo, Levels: decoded.Levels, Replayed: true}
			return nil
		}

		hero, err := s.ProgressionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if err := validateNormalHeroForEquipment(txctx, s, scope.Tx, revision, hero); err != nil {
			return err
		}
		if hero.Equipment[equipIndex-1] == 0 {
			return ErrHeroFumoUnavailable
		}
		pos, err := s.Equipment.HeroEquipmentPositionTx(txctx, scope.Tx, revision, hero.TableID, hero.Color, equipIndex)
		if err != nil {
			return err
		}
		if !pos.ItemID.Valid() {
			return ErrHeroFumoUnavailable
		}
		target, err := s.Fumo.HeroFumoTargetTx(txctx, scope.Tx, revision, pos.ItemID)
		if err != nil {
			return ErrHeroFumoUnavailable
		}
		current := hero.Fumo[equipIndex-1]
		if current < 0 || current >= target.TotalCap {
			return ErrHeroFumoUnavailable
		}

		var rawSupply int64
		for _, itemID := range ids {
			material, err := s.Fumo.HeroFumoMaterialTx(txctx, scope.Tx, revision, character.EquipmentTemplateID(itemID))
			if err != nil {
				return ErrHeroFumoUnavailable
			}
			value, err := checkedMul64(material.Moneng, counts[itemID])
			if err != nil {
				return err
			}
			rawSupply, err = checkedAdd64(rawSupply, value)
			if err != nil {
				return err
			}
		}
		if rawSupply <= 0 {
			return ErrHeroFumoUnavailable
		}
		remaining := target.TotalCap - current
		credited := rawSupply
		if credited > remaining {
			credited = remaining
		}
		manaDebit, err := checkedMul64(credited, target.ManaPerFumo)
		if err != nil {
			return err
		}

		prepared, err := s.EquipmentResources.PrepareHeroEquipmentResourcesTx(txctx, scope.Tx, actor.PlayerID, appi5.HeroEquipmentResourceRequest{PotentialStackItemIDs: ids}, bound)
		if err != nil {
			return err
		}
		stackDebits := make([]appi5.HeroEquipmentStackDebit, 0, len(ids))
		for _, itemID := range ids {
			have, ok := prepared.StackQuantity(itemID)
			if !ok || have < counts[itemID] {
				return errors.New("character hero: insufficient Fumo material quantity")
			}
			stackDebits = append(stackDebits, appi5.HeroEquipmentStackDebit{ItemID: itemID, Count: counts[itemID]})
		}
		if prepared.Mana() < manaDebit {
			return errors.New("character hero: insufficient Mana for Fumo")
		}
		if _, err := s.EquipmentResources.ApplyHeroEquipmentResourceDebitTx(txctx, scope.Tx, prepared, appi5.HeroEquipmentResourceDebit{Mana: manaDebit, Stacks: stackDebits}); err != nil {
			return err
		}

		oldVersion := hero.StateVersion
		hero.Fumo[equipIndex-1], err = checkedAdd64(current, credited)
		if err != nil {
			return err
		}
		hero.StateVersion++
		hero.UpdatedAt = bound.StartedAt.UTC()
		if err := hero.ValidatePersistent(); err != nil {
			return err
		}
		if err := s.ProgressionStore.SaveHeroStateTx(txctx, scope.Tx, hero, oldVersion); err != nil {
			return err
		}
		levels, err := s.deriveFumoLevelsTx(txctx, scope.Tx, revision, hero)
		if err != nil {
			return err
		}
		result = FumoResult{PartnerID: hero.PartnerID, Slot: equipIndex, Fumo: hero.Fumo[equipIndex-1], Levels: levels}
		return putHeroFumoReceipt(txctx, s, scope.Tx, actor, bound, id, fp, heroFumoReceipt{PartnerID: hero.PartnerID, Slot: equipIndex, Fumo: result.Fumo, Levels: levels})
	})
	return result, err
}
