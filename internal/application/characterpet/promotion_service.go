package characterpet

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/application/characterasset"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrPetPromotionContentInactive = errors.New("CA4-4B Pet promotion restoration content capability inactive")
	ErrPetPromotionUnavailable     = errors.New("character pet: promotion unavailable")
	ErrPetPromotionPrerequisites   = errors.New("character pet: promotion prerequisites not met")
	ErrPetPromotionCorruptState    = errors.New("character pet: corrupt promotion equipment/Fumo state")
	ErrPetPromotionQ1Unsupported   = errors.New("character pet: q1 promotion restoration semantics unavailable")
)

const (
	petPromotionReceiptSchema = "gxb.ca4-4b.pet-advance.v1"
	petPromotionPolicyVersion = "pass551-ca4-4b-contract"
)

type PetPromotionContent interface {
	PetPromotionRestorationRevision(context.Context, string) (bool, error)
	PetPromotionRestorationEligibilityTx(context.Context, tx.Queryer, string, character.EquipmentTemplateID) (character.PetPromotionRestorationEligibility, error)
	PromotionRestorationPolicyTx(context.Context, tx.Queryer, string) (character.PromotionRestorationPolicy, error)
}

type PetRestorationModifier = characterasset.RestorationModifier

type AdvanceResult struct {
	PetID        int64
	FromColor    int64
	ToColor      int64
	Level        int64
	Exp          int64
	Equipment    character.PetEquipmentSlots
	Fumo         character.PetFumoSlots
	RestoreItems []appi5.Award
	StateVersion int64
	Replayed     bool
}

type petPromotionReceipt struct {
	PetID        int64                       `json:"pet_id"`
	FromColor    int64                       `json:"from_color"`
	ToColor      int64                       `json:"to_color"`
	Level        int64                       `json:"result_level"`
	Exp          int64                       `json:"result_exp"`
	Equipment    character.PetEquipmentSlots `json:"result_equips"`
	Fumo         character.PetFumoSlots      `json:"result_fumos"`
	RestoreItems []appi5.Award               `json:"restore_items,omitempty"`
	StateVersion int64                       `json:"state_version"`
}

func (r petPromotionReceipt) result(replayed bool) AdvanceResult {
	return AdvanceResult{
		PetID: r.PetID, FromColor: r.FromColor, ToColor: r.ToColor, Level: r.Level, Exp: r.Exp,
		Equipment: r.Equipment, Fumo: r.Fumo, RestoreItems: append([]appi5.Award(nil), r.RestoreItems...),
		StateVersion: r.StateVersion, Replayed: replayed,
	}
}

func decodePetPromotionReceipt(r receipt.Receipt) (petPromotionReceipt, error) {
	if r.ResultSchema != petPromotionReceiptSchema {
		return petPromotionReceipt{}, fmt.Errorf("character pet: unsupported promotion receipt schema %q", r.ResultSchema)
	}
	var out petPromotionReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.FromColor < 1 || out.FromColor >= 16 || out.ToColor != out.FromColor+1 || out.Level <= 0 || out.Exp < 0 || out.StateVersion <= 0 {
		return out, errors.New("character pet: invalid promotion receipt payload")
	}
	if err := out.Equipment.Validate(); err != nil {
		return out, err
	}
	if err := out.Fumo.Validate(); err != nil {
		return out, err
	}
	for _, x := range out.RestoreItems {
		if x.TableID <= 0 || x.ResourceKey != "" || x.ItemNum <= 0 {
			return out, errors.New("character pet: invalid promotion restoration receipt row")
		}
	}
	return out, nil
}

func putPetPromotionReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, result petPromotionReceipt) error {
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA4_4B_PET_PROMOTION", petPromotionReceiptSchema, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = petPromotionPolicyVersion
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func (s Service) validateAdvance() error {
	if s.Runner.DB == nil || s.Store == nil || s.Fencer == nil || s.Progression == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return errors.New("character pet: incomplete CA4-4B MID785 service")
	}
	if s.Equipment == nil || s.Promotion == nil || s.StrictRestoration == nil || s.RestorationModifier == nil {
		return errors.New("character pet: incomplete CA4-4B MID785 restoration service")
	}
	return nil
}

func (s Service) bindPetPromotionContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
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
	good, err = s.Promotion.PetPromotionRestorationRevision(ctx, revision)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrPetPromotionContentInactive
	}
	return bound, revision, nil
}

func (s Service) loadPetPromotionPositionsTx(ctx context.Context, q tx.Queryer, revision string, p character.Pet) ([character.PetEquipmentSlotCount]character.PetEquipmentPosition, error) {
	var positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition
	if p.Color < 1 || p.Color >= 16 {
		return positions, ErrPetPromotionUnavailable
	}
	if err := p.Equipment.Validate(); err != nil {
		return positions, ErrPetPromotionCorruptState
	}
	if err := p.Fumo.Validate(); err != nil {
		return positions, ErrPetPromotionCorruptState
	}
	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		pos, err := s.Equipment.PetEquipmentPositionTx(ctx, q, revision, p.TableID, p.Color, slot)
		if err != nil {
			return positions, err
		}
		if err := pos.Validate(); err != nil || pos.PetTableID != p.TableID || pos.Color != p.Color || pos.Slot != slot {
			return positions, ErrPetPromotionCorruptState
		}
		positions[slot-1] = pos
	}
	return positions, nil
}

func allPetOrdinaryCollected(p character.Pet, positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition) bool {
	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		if positions[slot-1].Classification == character.PetEquipmentOrdinary && p.Equipment[slot-1] == 0 {
			return false
		}
	}
	return true
}

func (s Service) buildPetPromotionRestorationPlanTx(ctx context.Context, q tx.Queryer, actor identity.ActorContext, revision string, p character.Pet, positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition, op operation.Context) (*grant.Plan, error) {
	inputs := make([]appi5.PromotionRestorationInput, 0, character.PetEquipmentSlotCount)
	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		pos := positions[slot-1]
		raw := p.Fumo[slot-1]
		if pos.Classification != character.PetEquipmentOrdinary || raw == 0 {
			continue
		}
		eligible, err := s.Promotion.PetPromotionRestorationEligibilityTx(ctx, q, revision, pos.ItemID)
		if err != nil {
			return nil, err
		}
		if err := eligible.Validate(); err != nil || eligible.ItemID != pos.ItemID {
			return nil, ErrPetPromotionCorruptState
		}
		if eligible.SourceQuality == 1 {
			return nil, ErrPetPromotionQ1Unsupported
		}
		inputs = append(inputs, appi5.PromotionRestorationInput{RawFumo: raw, Quality: eligible.SourceQuality})
	}
	if len(inputs) == 0 {
		return nil, nil
	}
	contentPolicy, err := s.Promotion.PromotionRestorationPolicyTx(ctx, q, revision)
	if err != nil {
		return nil, err
	}
	base, err := appi5.PlanPromotionRestoration(inputs, contentPolicy)
	if err != nil {
		return nil, err
	}
	if len(base) == 0 {
		return nil, nil
	}
	owner := characterasset.RestorationOwner{Family: "PET", InstanceID: p.PetID, FromColor: p.Color, ToColor: p.Color + 1}
	lines, err := s.RestorationModifier.ModifyRestoration(ctx, q, owner, base, op)
	if err != nil {
		return nil, err
	}
	if len(lines) == 0 {
		return nil, nil
	}
	qualified := make(map[int64]struct{}, len(base))
	for _, line := range base {
		qualified[line.ItemID] = struct{}{}
	}
	seen := make(map[int64]struct{}, len(lines))
	for _, line := range lines {
		if line.Kind != grant.StackItem || line.Validate() != nil {
			return nil, errors.New("character pet: invalid modified restoration line")
		}
		if _, ok := qualified[line.ItemID]; !ok {
			return nil, errors.New("character pet: restoration modifier introduced unqualified material")
		}
		if _, ok := seen[line.ItemID]; ok {
			return nil, errors.New("character pet: duplicate modified restoration material")
		}
		seen[line.ItemID] = struct{}{}
	}
	source, err := characterasset.PetPromotionRestorationSource(p.PetID, p.Color, p.Color+1, appi5.PetPromotionRestorationPolicyVersion)
	if err != nil {
		return nil, err
	}
	plan := grant.Plan{PlayerID: actor.PlayerID, Source: source, Lines: append([]grant.Line(nil), lines...)}
	if err := plan.Validate(); err != nil {
		return nil, err
	}
	return &plan, nil
}

func applyPetPromotionState(p character.Pet, positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition, op operation.Context) (character.Pet, error) {
	if op.StartedAt.IsZero() || p.Color < 1 || p.Color >= 16 {
		return character.Pet{}, ErrPetPromotionUnavailable
	}
	oldVersion := p.StateVersion
	p.StateVersion++
	p.UpdatedAt = op.StartedAt.UTC()
	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		if positions[slot-1].Classification == character.PetEquipmentOrdinary {
			p.Equipment[slot-1] = 0
			p.Fumo[slot-1] = 0
		}
	}
	p.Color++
	if p.StateVersion != oldVersion+1 {
		return character.Pet{}, errors.New("character pet: non-cohesive promotion state transition")
	}
	if err := p.ValidatePersistent(); err != nil {
		return character.Pet{}, err
	}
	return p, nil
}

func petAwardsFromRestoration(gr *appi5.GrantResult) ([]appi5.Award, error) {
	if gr == nil {
		return nil, nil
	}
	out := append([]appi5.Award(nil), gr.Awards...)
	for _, x := range out {
		if x.TableID <= 0 || x.ResourceKey != "" || x.ItemNum <= 0 {
			return nil, errors.New("character pet: invalid restoration Grant result")
		}
	}
	return out, nil
}

func promotionReceiptFromAdvance(r AdvanceResult) petPromotionReceipt {
	return petPromotionReceipt{
		PetID: r.PetID, FromColor: r.FromColor, ToColor: r.ToColor, Level: r.Level, Exp: r.Exp,
		Equipment: r.Equipment, Fumo: r.Fumo, RestoreItems: append([]appi5.Award(nil), r.RestoreItems...), StateVersion: r.StateVersion,
	}
}

// Advance implements stock MID785. It is a direct color promotion only: there
// is no recipe, Mana, or Pet-EXP debit. The Pet owner lock is acquired before
// any optional nested restoration lock suffix, and the outer receipt is the
// authoritative same-operation recovery record.
func (s Service) Advance(ctx context.Context, actor identity.ActorContext, petID int64, op operation.Context) (AdvanceResult, error) {
	if err := s.validateAdvance(); err != nil {
		return AdvanceResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return AdvanceResult{}, errors.New("character pet: invalid MID785 request")
	}
	bound, revision, err := s.bindPetPromotionContent(ctx, op)
	if err != nil {
		return AdvanceResult{}, err
	}
	id := petReceiptIdentity(actor.PlayerID, "advance", bound)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID})
	if err != nil {
		return AdvanceResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return AdvanceResult{}, err
	} else if ok {
		decoded, err := decodePetPromotionReceipt(prior)
		if err != nil {
			return AdvanceResult{}, err
		}
		return decoded.result(true), nil
	}

	var out AdvanceResult
	res, err := s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			decoded, err := decodePetPromotionReceipt(prior)
			if err != nil {
				return err
			}
			out = decoded.result(true)
			return nil
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
			decoded, err := decodePetPromotionReceipt(prior)
			if err != nil {
				return err
			}
			out = decoded.result(true)
			return nil
		}
		if !pet.IsShow {
			return ErrPetNotShown
		}
		positions, err := s.loadPetPromotionPositionsTx(txctx, scope.Tx, revision, pet)
		if err != nil {
			return err
		}
		if !allPetOrdinaryCollected(pet, positions) {
			return ErrPetPromotionPrerequisites
		}
		restoration, err := s.buildPetPromotionRestorationPlanTx(txctx, scope.Tx, actor, revision, pet, positions, bound)
		if err != nil {
			return err
		}
		var grantResult *appi5.GrantResult
		if restoration != nil {
			prepared, err := s.StrictRestoration.PrepareStrictRestorationTx(txctx, scope.Tx, actor, appi5.StrictRestorationRequest{Plan: *restoration, AllowOverflowMail: true}, bound)
			if err != nil {
				return err
			}
			gr, err := s.StrictRestoration.ApplyStrictRestorationTx(txctx, scope.Tx, prepared)
			if err != nil {
				return err
			}
			grantResult = &gr
		}
		oldVersion := pet.StateVersion
		next, err := applyPetPromotionState(pet, positions, bound)
		if err != nil {
			return err
		}
		if err := s.Store.SavePetStateTx(txctx, scope.Tx, next, oldVersion); err != nil {
			return err
		}
		awards, err := petAwardsFromRestoration(grantResult)
		if err != nil {
			return err
		}
		out = AdvanceResult{PetID: next.PetID, FromColor: pet.Color, ToColor: next.Color, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment, Fumo: next.Fumo, RestoreItems: awards, StateVersion: next.StateVersion}
		return putPetPromotionReceipt(txctx, s, scope.Tx, actor, bound, id, fp, promotionReceiptFromAdvance(out))
	})
	if err != nil {
		return AdvanceResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			decoded, derr := decodePetPromotionReceipt(r)
			if derr != nil {
				return AdvanceResult{}, derr
			}
			out = decoded.result(true)
		}
	}
	return out, nil
}

const petOneKeyPromotionReceiptSchema = "gxb.ca4-4b.pet-one-key-up.v1"

const (
	petOneKeyBranchPromote = "PROMOTE"
	petOneKeyBranchCollect = "COLLECT"
)

// OneKeyAdvanceResult is the canonical CharacterPet outcome for stock MID790.
// Branch is retained only for receipt/recovery semantics and is never projected
// onto the stock response wire.
type OneKeyAdvanceResult struct {
	PetID        int64
	Branch       string
	FromColor    int64
	ToColor      int64
	Level        int64
	Exp          int64
	Equipment    character.PetEquipmentSlots
	Fumo         character.PetFumoSlots
	RestoreItems []appi5.Award
	StateVersion int64
	Replayed     bool
}

type petOneKeyPromotionReceipt struct {
	PetID        int64                       `json:"pet_id"`
	Branch       string                      `json:"branch"`
	FromColor    int64                       `json:"from_color"`
	ToColor      int64                       `json:"to_color"`
	Level        int64                       `json:"result_level"`
	Exp          int64                       `json:"result_exp"`
	Equipment    character.PetEquipmentSlots `json:"result_equips"`
	Fumo         character.PetFumoSlots      `json:"result_fumos"`
	RestoreItems []appi5.Award               `json:"restore_items,omitempty"`
	StateVersion int64                       `json:"state_version"`
}

func (r petOneKeyPromotionReceipt) result(replayed bool) OneKeyAdvanceResult {
	return OneKeyAdvanceResult{
		PetID: r.PetID, Branch: r.Branch, FromColor: r.FromColor, ToColor: r.ToColor,
		Level: r.Level, Exp: r.Exp, Equipment: r.Equipment, Fumo: r.Fumo,
		RestoreItems: append([]appi5.Award(nil), r.RestoreItems...), StateVersion: r.StateVersion, Replayed: replayed,
	}
}

func decodePetOneKeyPromotionReceipt(r receipt.Receipt) (petOneKeyPromotionReceipt, error) {
	if r.ResultSchema != petOneKeyPromotionReceiptSchema {
		return petOneKeyPromotionReceipt{}, fmt.Errorf("character pet: unsupported one-key promotion receipt schema %q", r.ResultSchema)
	}
	var out petOneKeyPromotionReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.Level <= 0 || out.Exp < 0 || out.StateVersion <= 0 {
		return out, errors.New("character pet: invalid one-key promotion receipt payload")
	}
	switch out.Branch {
	case petOneKeyBranchPromote:
		if out.FromColor < 1 || out.FromColor >= 16 || out.ToColor != out.FromColor+1 {
			return out, errors.New("character pet: invalid one-key promote receipt transition")
		}
	case petOneKeyBranchCollect:
		if out.FromColor != 16 || out.ToColor != 16 || len(out.RestoreItems) != 0 {
			return out, errors.New("character pet: invalid one-key collect receipt transition")
		}
	default:
		return out, errors.New("character pet: invalid one-key promotion receipt branch")
	}
	if err := out.Equipment.Validate(); err != nil {
		return out, err
	}
	if err := out.Fumo.Validate(); err != nil {
		return out, err
	}
	for _, x := range out.RestoreItems {
		if x.TableID <= 0 || x.ResourceKey != "" || x.ItemNum <= 0 {
			return out, errors.New("character pet: invalid one-key restoration receipt row")
		}
	}
	return out, nil
}

func putPetOneKeyPromotionReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, result petOneKeyPromotionReceipt) error {
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA4_4B_PET_ONE_KEY_UP", petOneKeyPromotionReceiptSchema, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = petPromotionPolicyVersion
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func (s Service) validateOneKeyAdvance() error {
	if s.Runner.DB == nil || s.Store == nil || s.Fencer == nil || s.Progression == nil || s.Receipts == nil || s.ReceiptRead == nil {
		return errors.New("character pet: incomplete CA4-4B MID790 service")
	}
	if s.Equipment == nil || s.Promotion == nil || s.PromotionResources == nil || s.RestorationModifier == nil {
		return errors.New("character pet: incomplete CA4-4B MID790 resource service")
	}
	return nil
}

func missingPetOrdinarySlots(p character.Pet, positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition) []int64 {
	out := make([]int64, 0, character.PetEquipmentSlotCount)
	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		pos := positions[slot-1]
		if pos.Classification == character.PetEquipmentOrdinary && p.Equipment[slot-1] == 0 {
			out = append(out, slot)
		}
	}
	return out
}

func equalPetSlots(a, b []int64) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func validatePetOneKeyPositions(p character.Pet, positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition) error {
	if p.Color < 1 || p.Color > 16 {
		return ErrPetPromotionUnavailable
	}
	if err := p.Equipment.Validate(); err != nil {
		return ErrPetPromotionCorruptState
	}
	if err := p.Fumo.Validate(); err != nil {
		return ErrPetPromotionCorruptState
	}
	for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
		pos := positions[slot-1]
		if err := pos.Validate(); err != nil || pos.PetTableID != p.TableID || pos.Color != p.Color || pos.Slot != slot {
			return ErrPetPromotionCorruptState
		}
	}
	return nil
}

func preparedPetPromotionPlanningSnapshot(p *appi5.PreparedPromotionResources) (petEquipmentPlanningSnapshot, error) {
	if p == nil || p.PlayerLevel() <= 0 || p.Mana() < 0 {
		return petEquipmentPlanningSnapshot{}, errors.New("character pet: invalid prepared promotion resources")
	}
	stacks := make(map[int64]int64)
	for _, id := range p.PreparedStackItemIDs() {
		q, ok := p.StackQuantity(id)
		if !ok || q < 0 {
			return petEquipmentPlanningSnapshot{}, errors.New("character pet: incomplete prepared promotion resources")
		}
		stacks[id] = q
	}
	return petEquipmentPlanningSnapshot{PlayerLevel: p.PlayerLevel(), Mana: p.Mana(), Stacks: stacks}, nil
}

func promotionDebitFromPetPlan(plan petEquipmentPlan) appi5.PromotionResourceDebit {
	ordered := sortedPetEquipmentStackDebits(plan.StackDebits)
	out := appi5.PromotionResourceDebit{Mana: plan.ManaDebit, Stacks: make([]appi5.EquipmentStackDebit, 0, len(ordered))}
	for _, x := range ordered {
		out.Stacks = append(out.Stacks, appi5.EquipmentStackDebit{ItemID: x.ItemID, Count: x.Count})
	}
	return out
}

func validatePetPromotionResourceBound(closure []int64, restoration *grant.Plan) error {
	count := len(closure)
	if restoration != nil {
		count += len(restoration.Lines)
	}
	if count > 48 {
		return fmt.Errorf("character pet: promotion resource closure exceeds source-qualified bound: %d", count)
	}
	return nil
}

func applyPetOneKeyAdvanceState(p character.Pet, positions [character.PetEquipmentSlotCount]character.PetEquipmentPosition, plan petEquipmentPlan, promote bool, maxLevel int64, realThresholds []ExpThreshold, op operation.Context) (character.Pet, error) {
	if op.StartedAt.IsZero() || plan.noWork() {
		return character.Pet{}, ErrPetPromotionPrerequisites
	}
	if maxLevel < 1 || int64(len(realThresholds)) != maxLevel || p.Level > maxLevel {
		return character.Pet{}, errors.New("character pet: invalid real Pet EXP policy for one-key advance")
	}
	if err := ValidateExpThresholds(realThresholds, maxLevel); err != nil {
		return character.Pet{}, err
	}
	if plan.PotionEXPGranted > 0 {
		capExp := realThresholds[len(realThresholds)-1].TotalExp
		if p.Exp > capExp {
			return character.Pet{}, errors.New("character pet: Pet EXP exceeds source-qualified maximum")
		}
		if plan.PotionEXPGranted <= capExp-p.Exp {
			p.Exp += plan.PotionEXPGranted
		} else {
			p.Exp = capExp
		}
		level, err := petLevelForExp(p.Exp, maxLevel, realThresholds)
		if err != nil {
			return character.Pet{}, err
		}
		p.Level = level
	}
	oldVersion := p.StateVersion
	if promote {
		if p.Color < 1 || p.Color >= 16 {
			return character.Pet{}, ErrPetPromotionUnavailable
		}
		for slot := int64(1); slot <= character.PetEquipmentSlotCount; slot++ {
			if positions[slot-1].Classification == character.PetEquipmentOrdinary {
				p.Equipment[slot-1] = 0
				p.Fumo[slot-1] = 0
			}
		}
		p.Color++
	} else {
		if p.Color != 16 {
			return character.Pet{}, ErrPetPromotionUnavailable
		}
		for _, slot := range plan.Selected {
			if slot < 1 || slot > character.PetEquipmentSlotCount || p.Equipment[slot-1] != 0 || positions[slot-1].Classification != character.PetEquipmentOrdinary || !positions[slot-1].ItemID.Valid() {
				return character.Pet{}, ErrPetPromotionCorruptState
			}
			p.Equipment[slot-1] = 1
		}
	}
	p.StateVersion++
	p.UpdatedAt = op.StartedAt.UTC()
	if p.StateVersion != oldVersion+1 {
		return character.Pet{}, errors.New("character pet: non-cohesive one-key promotion state transition")
	}
	if err := p.ValidatePersistent(); err != nil {
		return character.Pet{}, err
	}
	return p, nil
}

func petOneKeyReceiptFromResult(r OneKeyAdvanceResult) petOneKeyPromotionReceipt {
	return petOneKeyPromotionReceipt{
		PetID: r.PetID, Branch: r.Branch, FromColor: r.FromColor, ToColor: r.ToColor,
		Level: r.Level, Exp: r.Exp, Equipment: r.Equipment, Fumo: r.Fumo,
		RestoreItems: append([]appi5.Award(nil), r.RestoreItems...), StateVersion: r.StateVersion,
	}
}

// OneKeyAdvance implements stock MID790. It requires at least one missing
// current-color ordinary slot and replans the complete all-or-nothing set under
// the CharacterPet owner lock. Below color 16 the same transaction debits the
// full equipment/EXP plan, settles qualified restoration, advances one color
// and clears ordinary state. At color 16 it collects the full ordinary set only
// and leaves color/Fumo/restoration unchanged.
func (s Service) OneKeyAdvance(ctx context.Context, actor identity.ActorContext, petID int64, op operation.Context) (OneKeyAdvanceResult, error) {
	if err := s.validateOneKeyAdvance(); err != nil {
		return OneKeyAdvanceResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return OneKeyAdvanceResult{}, errors.New("character pet: invalid MID790 request")
	}
	bound, revision, err := s.bindPetPromotionContent(ctx, op)
	if err != nil {
		return OneKeyAdvanceResult{}, err
	}
	id := petReceiptIdentity(actor.PlayerID, "one-key-advance", bound)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID})
	if err != nil {
		return OneKeyAdvanceResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return OneKeyAdvanceResult{}, err
	} else if ok {
		decoded, err := decodePetOneKeyPromotionReceipt(prior)
		if err != nil {
			return OneKeyAdvanceResult{}, err
		}
		return decoded.result(true), nil
	}

	var out OneKeyAdvanceResult
	res, err := s.Runner.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			decoded, err := decodePetOneKeyPromotionReceipt(prior)
			if err != nil {
				return err
			}
			out = decoded.result(true)
			return nil
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
			decoded, err := decodePetOneKeyPromotionReceipt(prior)
			if err != nil {
				return err
			}
			out = decoded.result(true)
			return nil
		}
		if !pet.IsShow {
			return ErrPetNotShown
		}
		positions, nodes, closure, potionEXP, err := s.loadPetOneKeyContentTx(txctx, scope.Tx, revision, pet)
		if err != nil {
			return err
		}
		if err := validatePetOneKeyPositions(pet, positions); err != nil {
			return err
		}
		missing := missingPetOrdinarySlots(pet, positions)
		if len(missing) == 0 {
			return ErrPetPromotionPrerequisites
		}
		promote := pet.Color < 16
		var restoration *grant.Plan
		if promote {
			restoration, err = s.buildPetPromotionRestorationPlanTx(txctx, scope.Tx, actor, revision, pet, positions, bound)
			if err != nil {
				return err
			}
		}
		if err := validatePetPromotionResourceBound(closure, restoration); err != nil {
			return err
		}
		req := appi5.PromotionResourceRequest{PotentialStackItemIDs: closure, AllowOverflowMail: true}
		if restoration != nil {
			copyPlan := *restoration
			req.Restoration = &copyPlan
		}
		prepared, err := s.PromotionResources.PreparePromotionResourcesTx(txctx, scope.Tx, actor, req, bound)
		if err != nil {
			return err
		}
		snapshot, err := preparedPetPromotionPlanningSnapshot(prepared)
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
		if !equalPetSlots(plan.Selected, missing) {
			return ErrPetPromotionPrerequisites
		}
		resources, err := s.PromotionResources.ApplyPromotionResourcesTx(txctx, scope.Tx, prepared, promotionDebitFromPetPlan(plan))
		if err != nil {
			return err
		}
		realThresholds, err := s.Progression.PetExpPolicyTx(txctx, scope.Tx, revision, maxLevel)
		if err != nil {
			return err
		}
		oldVersion := pet.StateVersion
		next, err := applyPetOneKeyAdvanceState(pet, positions, plan, promote, maxLevel, realThresholds, bound)
		if err != nil {
			return err
		}
		if err := s.Store.SavePetStateTx(txctx, scope.Tx, next, oldVersion); err != nil {
			return err
		}
		awards, err := petAwardsFromRestoration(resources.Restoration)
		if err != nil {
			return err
		}
		branch := petOneKeyBranchCollect
		if promote {
			branch = petOneKeyBranchPromote
		}
		out = OneKeyAdvanceResult{PetID: next.PetID, Branch: branch, FromColor: pet.Color, ToColor: next.Color, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment, Fumo: next.Fumo, RestoreItems: awards, StateVersion: next.StateVersion}
		return putPetOneKeyPromotionReceipt(txctx, s, scope.Tx, actor, bound, id, fp, petOneKeyReceiptFromResult(out))
	})
	if err != nil {
		return OneKeyAdvanceResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			decoded, derr := decodePetOneKeyPromotionReceipt(r)
			if derr != nil {
				return OneKeyAdvanceResult{}, derr
			}
			out = decoded.result(true)
		}
	}
	return out, nil
}
