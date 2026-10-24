package characterpet

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
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrPetProgressionContentInactive = errors.New("CA3-3 Pet progression content capability inactive")
	ErrPetNotShown                   = errors.New("character pet: Pet progression unavailable while incubating")
	ErrPetExpMax                     = errors.New("character pet: Pet EXP already at source-qualified maximum")
	ErrPetEvolutionUnavailable       = errors.New("character pet: Pet evolution unavailable")
	ErrPetSkillUnavailable           = errors.New("character pet: Pet skill upgrade unavailable")
)

type EvolveResult struct {
	PetID int64 `json:"pet_id"`
	Star  int64 `json:"star"`
}

type ExpResult struct {
	PetID int64 `json:"pet_id"`
	Level int64 `json:"level"`
	Exp   int64 `json:"exp"`
}

type SkillUpgrade struct {
	Slot  int64 `json:"slot"`
	Count int64 `json:"count"`
}

type SkillResult struct {
	PetID  int64                    `json:"pet_id"`
	Skills character.PetSkillLevels `json:"skills"`
}

func (s Service) bindProgressionContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return operation.Context{}, "", errors.New("character pet: invalid progression operation context")
	}
	if revision, ok := op.Policies.Get("content"); ok {
		good, err := s.Progression.PetProgressionRevision(ctx, revision)
		if err != nil {
			return operation.Context{}, "", err
		}
		if !good {
			return operation.Context{}, "", ErrPetProgressionContentInactive
		}
		return op, revision, nil
	}
	revision, good, err := s.Progression.PetProgressionActive(ctx)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrPetProgressionContentInactive
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: "content", Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, "", err
	}
	op.Policies = set
	return op, revision, nil
}

func progressionReceiptReplay(ctx context.Context, reader receipt.Reader, id receipt.Identity, fp [32]byte) (receipt.Receipt, bool, error) {
	if reader == nil {
		return receipt.Receipt{}, false, errors.New("character pet: missing receipt reader")
	}
	prior, ok, err := reader.Find(ctx, id)
	if err != nil || !ok {
		return prior, ok, err
	}
	if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
		return receipt.Receipt{}, false, &receipt.ConflictError{Identity: id}
	}
	return prior, true, nil
}

func progressionReceiptReplayTx(ctx context.Context, store receipt.Store, q tx.Queryer, id receipt.Identity, fp [32]byte) (receipt.Receipt, bool, error) {
	if store == nil || q == nil {
		return receipt.Receipt{}, false, errors.New("character pet: missing transactional receipt store")
	}
	prior, ok, err := store.FindTx(ctx, q, id)
	if err != nil || !ok {
		return prior, ok, err
	}
	if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
		return receipt.Receipt{}, false, &receipt.ConflictError{Identity: id}
	}
	return prior, true, nil
}

func decodeEvolveReceipt(r receipt.Receipt) (EvolveResult, error) {
	var out EvolveResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.Star < 1 || out.Star > character.MaxPetStar {
		return out, errors.New("character pet: invalid evolution receipt")
	}
	return out, nil
}

func decodeExpReceipt(r receipt.Receipt) (ExpResult, error) {
	var out ExpResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.Level <= 0 || out.Exp < 0 {
		return out, errors.New("character pet: invalid EXP receipt")
	}
	return out, nil
}

func decodeSkillReceipt(r receipt.Receipt) (SkillResult, error) {
	var out SkillResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.Skills.Validate() != nil {
		return out, errors.New("character pet: invalid skill receipt")
	}
	return out, nil
}

func putProgressionReceipt(ctx context.Context, s Service, t tx.Tx, op operation.Context, actor identity.ActorContext, id receipt.Identity, schema string, result any, fp [32]byte) error {
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA3_PET_PROGRESSION", schema, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = "pass528-ca3-3"
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func checkedMul(a, b int64) (int64, error) {
	if a <= 0 || b <= 0 || a > math.MaxInt64/b {
		return 0, errors.New("character pet: EXP multiplication overflow")
	}
	return a * b, nil
}

func petLevelForExp(exp, maxLevel int64, thresholds []ExpThreshold) (int64, error) {
	if exp < 0 || maxLevel < 1 || int64(len(thresholds)) != maxLevel {
		return 0, errors.New("character pet: invalid EXP level calculation")
	}
	level := int64(1)
	for i := int64(1); i <= maxLevel; i++ {
		row := thresholds[i-1]
		if row.Level != i {
			return 0, errors.New("character pet: invalid EXP thresholds")
		}
		if exp >= row.TotalExp {
			if i+1 < maxLevel {
				level = i + 1
			} else {
				level = maxLevel
			}
			continue
		}
		break
	}
	if level > maxLevel {
		level = maxLevel
	}
	return level, nil
}

func (s Service) Evolve(ctx context.Context, actor identity.ActorContext, petID int64, op operation.Context) (EvolveResult, error) {
	if err := s.validateProgression(); err != nil {
		return EvolveResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return EvolveResult{}, errors.New("character pet: invalid evolution request")
	}
	id := petReceiptIdentity(actor.PlayerID, "evolve", op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID})
	if err != nil {
		return EvolveResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return EvolveResult{}, err
	} else if ok {
		return decodeEvolveReceipt(prior)
	}
	bound, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return EvolveResult{}, err
	}
	var out EvolveResult
	res, err := s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out, err = decodeEvolveReceipt(prior)
			return err
		}
		pet, found, err := s.Store.LockPetByIDTx(txctx, scope.Tx, actor.PlayerID, petID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		// A waiter may have missed an uncommitted receipt before blocking on the
		// Pet row. Recheck after the canonical owner lock and before any mutation.
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out, err = decodeEvolveReceipt(prior)
			return err
		}
		if !pet.IsShow {
			return ErrPetNotShown
		}
		target := pet.Star + 1
		if target > character.MaxPetStar {
			return ErrPetEvolutionUnavailable
		}
		tmpl, err := s.Progression.PetProgressionTemplateTx(txctx, scope.Tx, revision, pet.TableID)
		if err != nil {
			return err
		}
		count, err := s.Progression.PetEvolutionCostTx(txctx, scope.Tx, revision, target)
		if err != nil {
			return err
		}
		if _, err := s.MaterialCosts.DebitMaterialCostTx(txctx, scope.Tx, actor.PlayerID, appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: tmpl.StoneItemID, Amount: count}}}, bound); err != nil {
			return err
		}
		old := pet.StateVersion
		pet.Star = target
		pet.StateVersion++
		pet.UpdatedAt = bound.StartedAt.UTC()
		if err := s.Store.SavePetStateTx(txctx, scope.Tx, pet, old); err != nil {
			return err
		}
		out = EvolveResult{PetID: pet.PetID, Star: pet.Star}
		return putProgressionReceipt(txctx, s, scope.Tx, bound, actor, id, "gxb.ca3.pet-evolve.v1", out, fp)
	})
	if err != nil {
		return EvolveResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			out, err = decodeEvolveReceipt(r)
		}
	}
	return out, err
}

func normalizeExpItems(items []appi5.PetExpItemDebit) ([]appi5.PetExpItemDebit, error) {
	if len(items) == 0 || len(items) > 3 {
		return nil, errors.New("character pet: invalid Pet EXP items")
	}
	out := append([]appi5.PetExpItemDebit(nil), items...)
	sort.Slice(out, func(i, j int) bool { return out[i].ItemID < out[j].ItemID })
	for i, x := range out {
		if x.ItemID <= 0 || x.Count <= 0 {
			return nil, errors.New("character pet: invalid Pet EXP item")
		}
		if i > 0 && out[i-1].ItemID == x.ItemID {
			return nil, fmt.Errorf("character pet: duplicate Pet EXP item %d", x.ItemID)
		}
	}
	return out, nil
}

func (s Service) Feed(ctx context.Context, actor identity.ActorContext, petID, itemID, count int64, op operation.Context) (ExpResult, error) {
	return s.useExp(ctx, actor, petID, []appi5.PetExpItemDebit{{ItemID: itemID, Count: count}}, false, "feed", op)
}

func (s Service) UseExpItems(ctx context.Context, actor identity.ActorContext, petID int64, items []appi5.PetExpItemDebit, op operation.Context) (ExpResult, error) {
	return s.useExp(ctx, actor, petID, items, true, "use-exp-items", op)
}

func (s Service) useExp(ctx context.Context, actor identity.ActorContext, petID int64, requested []appi5.PetExpItemDebit, oneKey bool, operationName string, op operation.Context) (ExpResult, error) {
	if err := s.validateProgression(); err != nil {
		return ExpResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return ExpResult{}, errors.New("character pet: invalid EXP request")
	}
	items, err := normalizeExpItems(requested)
	if err != nil {
		return ExpResult{}, err
	}
	if !oneKey && len(items) != 1 {
		return ExpResult{}, errors.New("character pet: manual feed requires one item")
	}
	id := petReceiptIdentity(actor.PlayerID, operationName, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID, "items": items})
	if err != nil {
		return ExpResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return ExpResult{}, err
	} else if ok {
		return decodeExpReceipt(prior)
	}
	bound, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return ExpResult{}, err
	}
	var out ExpResult
	res, err := s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out, err = decodeExpReceipt(prior)
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
			out, err = decodeExpReceipt(prior)
			return err
		}
		if !pet.IsShow {
			return ErrPetNotShown
		}
		// Ration semantics are content-owned and must be resolved only after the
		// Pet owner lock/receipt fence, before preparing any I5 writes.
		totalAdd := int64(0)
		for _, x := range items {
			unit, err := s.Progression.PetExpItemTx(txctx, scope.Tx, revision, x.ItemID)
			if err != nil {
				return err
			}
			add, err := checkedMul(unit, x.Count)
			if err != nil {
				return err
			}
			if add > math.MaxInt64-totalAdd {
				return errors.New("character pet: total EXP overflow")
			}
			totalAdd += add
		}
		plan, err := s.PetExp.PreparePetExpDebitTx(txctx, scope.Tx, actor.PlayerID, items, bound)
		if err != nil {
			return err
		}
		maxLevel, err := s.Progression.CharacterMaxLevelTx(txctx, scope.Tx, revision, plan.PlayerLevel())
		if err != nil {
			return err
		}
		thresholds, err := s.Progression.PetExpPolicyTx(txctx, scope.Tx, revision, maxLevel)
		if err != nil {
			return err
		}
		if pet.Level > maxLevel {
			return errors.New("character pet: Pet level exceeds current source-qualified maximum")
		}
		if oneKey && pet.Level >= maxLevel {
			return ErrPetExpMax
		}
		capExp := thresholds[len(thresholds)-1].TotalExp
		if pet.Exp >= capExp {
			return ErrPetExpMax
		}
		nextExp := capExp
		if totalAdd <= capExp-pet.Exp {
			nextExp = pet.Exp + totalAdd
		}
		nextLevel, err := petLevelForExp(nextExp, maxLevel, thresholds)
		if err != nil {
			return err
		}
		if _, err := s.PetExp.ApplyPetExpDebitTx(txctx, scope.Tx, plan); err != nil {
			return err
		}
		old := pet.StateVersion
		pet.Exp = nextExp
		pet.Level = nextLevel
		pet.StateVersion++
		pet.UpdatedAt = bound.StartedAt.UTC()
		if err := s.Store.SavePetStateTx(txctx, scope.Tx, pet, old); err != nil {
			return err
		}
		out = ExpResult{PetID: pet.PetID, Level: pet.Level, Exp: pet.Exp}
		return putProgressionReceipt(txctx, s, scope.Tx, bound, actor, id, "gxb.ca3.pet-exp.v1", out, fp)
	})
	if err != nil {
		return ExpResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			out, err = decodeExpReceipt(r)
		}
	}
	return out, err
}

func normalizeSkillUpgrades(in []SkillUpgrade) ([]SkillUpgrade, error) {
	if len(in) == 0 || len(in) > 5 {
		return nil, errors.New("character pet: invalid skill upgrade batch")
	}
	out := append([]SkillUpgrade(nil), in...)
	sort.Slice(out, func(i, j int) bool { return out[i].Slot < out[j].Slot })
	for i, x := range out {
		if x.Slot < 1 || x.Slot > 5 || x.Count <= 0 {
			return nil, errors.New("character pet: invalid skill upgrade")
		}
		if i > 0 && out[i-1].Slot == x.Slot {
			return nil, fmt.Errorf("character pet: duplicate skill slot %d", x.Slot)
		}
	}
	return out, nil
}

func (s Service) UpgradeSkills(ctx context.Context, actor identity.ActorContext, petID int64, requested []SkillUpgrade, op operation.Context) (SkillResult, error) {
	if err := s.validateProgression(); err != nil {
		return SkillResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return SkillResult{}, errors.New("character pet: invalid skill request")
	}
	upgrades, err := normalizeSkillUpgrades(requested)
	if err != nil {
		return SkillResult{}, err
	}
	id := petReceiptIdentity(actor.PlayerID, "upgrade-skills", op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID, "upgrades": upgrades})
	if err != nil {
		return SkillResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return SkillResult{}, err
	} else if ok {
		return decodeSkillReceipt(prior)
	}
	bound, revision, err := s.bindProgressionContent(ctx, op)
	if err != nil {
		return SkillResult{}, err
	}
	var out SkillResult
	res, err := s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			out, err = decodeSkillReceipt(prior)
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
			out, err = decodeSkillReceipt(prior)
			return err
		}
		if !pet.IsShow {
			return ErrPetNotShown
		}
		slots, err := s.Progression.PetSkillSlotsTx(txctx, scope.Tx, revision, pet.TableID)
		if err != nil {
			return err
		}
		progressionPolicy, err := s.Progression.PetProgressionPolicyTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		totalBooks := int64(0)
		nextSkills := pet.Skills
		for _, u := range upgrades {
			def := slots[u.Slot-1]
			pol, err := s.Progression.PetSkillSlotPolicyTx(txctx, scope.Tx, revision, u.Slot)
			if err != nil {
				return err
			}
			if def.SourceSkillID == 0 {
				return ErrPetSkillUnavailable
			}
			if pol.RequiresAwakened {
				if pet.TableID == pet.OriginTableID {
					return ErrPetSkillUnavailable
				}
			} else if pet.Color < pol.MinColor {
				return ErrPetSkillUnavailable
			}
			raw := nextSkills[u.Slot-1]
			if raw > math.MaxInt64-pol.EffectiveOffset {
				return errors.New("character pet: skill level overflow")
			}
			effective := raw + pol.EffectiveOffset
			limit := pet.Level
			if u.Slot <= pet.Star-1 {
				if def.StarBonus > math.MaxInt64-limit {
					return errors.New("character pet: skill ceiling overflow")
				}
				limit += def.StarBonus
			}
			if effective > limit || u.Count > limit-effective {
				return ErrPetSkillUnavailable
			}
			for k := int64(0); k < u.Count; k++ {
				level := effective + k
				cost, err := s.Progression.PetSkillBookCostTx(txctx, scope.Tx, revision, level)
				if err != nil {
					return err
				}
				if cost > math.MaxInt64-totalBooks {
					return errors.New("character pet: Skill Book cost overflow")
				}
				totalBooks += cost
			}
			if raw > math.MaxInt64-u.Count {
				return errors.New("character pet: raw skill overflow")
			}
			nextSkills[u.Slot-1] = raw + u.Count
		}
		if totalBooks <= 0 {
			return ErrPetSkillUnavailable
		}
		if _, err := s.MaterialCosts.DebitMaterialCostTx(txctx, scope.Tx, actor.PlayerID, appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: progressionPolicy.SkillBookItemID, Amount: totalBooks}}}, bound); err != nil {
			return err
		}
		old := pet.StateVersion
		pet.Skills = nextSkills
		pet.StateVersion++
		pet.UpdatedAt = bound.StartedAt.UTC()
		if err := s.Store.SavePetStateTx(txctx, scope.Tx, pet, old); err != nil {
			return err
		}
		out = SkillResult{PetID: pet.PetID, Skills: pet.Skills}
		return putProgressionReceipt(txctx, s, scope.Tx, bound, actor, id, "gxb.ca3.pet-skills.v1", out, fp)
	})
	if err != nil {
		return SkillResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			out, err = decodeSkillReceipt(r)
		}
	}
	return out, err
}
