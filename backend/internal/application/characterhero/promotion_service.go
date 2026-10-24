package characterhero

import (
	"bytes"
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
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrHeroPromotionContentInactive = errors.New("CA4-3B Hero promotion restoration content capability inactive")
	ErrHeroPromotionUnavailable     = errors.New("character hero: promotion unavailable")
	ErrHeroPromotionPrerequisites   = errors.New("character hero: promotion prerequisites not met")
	ErrHeroPromotionCorruptState    = errors.New("character hero: corrupt promotion equipment/Fumo state")
)

const (
	heroPromotionMaxColorPolicyRef = "player.max-color"
	heroPromotionReceiptSchema     = "gxb.ca4-3b.hero-promotion.v1"
	heroPromotionPolicyVersion     = "pass546-ca4-3b-contract"
)

type RestorationModifier = characterasset.RestorationModifier

type MaxHeroColorPolicyProvider interface {
	characterasset.PlayerProgressionMaxHeroColorProvider
	MaxHeroColorPolicyRevision() string
}

type HeroPromotionContent interface {
	HeroPromotionRestorationRevision(context.Context, string) (bool, error)
	HeroPromotionRestorationEligibilityTx(context.Context, tx.Queryer, string, character.EquipmentTemplateID) (character.HeroPromotionRestorationEligibility, error)
	HeroPromotionRestorationPolicyTx(context.Context, tx.Queryer, string) (character.HeroPromotionRestorationPolicy, error)
}

type HeroPromotionBranch string

const (
	HeroPromotionMID51Promote HeroPromotionBranch = "MID51_PROMOTE"
	HeroPromotionMID57Promote HeroPromotionBranch = "MID57_PROMOTE"
	HeroPromotionMID57Collect HeroPromotionBranch = "MID57_COLLECT"
)

type HeroPromotionResult struct {
	PartnerID    int64
	Branch       HeroPromotionBranch
	FromColor    int64
	ToColor      int64
	Level        int64
	Exp          int64
	Equipment    character.HeroEquipmentSlots
	Fumo         character.HeroFumoSlots
	RestoreItems []appi5.Award
	ManaAfter    *int64
	StateVersion int64
	Replayed     bool
}

type heroPromotionReceipt struct {
	PartnerID    int64                        `json:"partner_id"`
	Branch       HeroPromotionBranch          `json:"branch"`
	FromColor    int64                        `json:"from_color"`
	ToColor      int64                        `json:"to_color"`
	Level        int64                        `json:"result_level"`
	Exp          int64                        `json:"result_exp"`
	Equipment    character.HeroEquipmentSlots `json:"result_equips"`
	Fumo         character.HeroFumoSlots      `json:"result_fumos"`
	RestoreItems []appi5.Award                `json:"restore_items,omitempty"`
	ManaAfter    *int64                       `json:"mana_after,omitempty"`
	StateVersion int64                        `json:"state_version"`
}

func (r heroPromotionReceipt) result(replayed bool) HeroPromotionResult {
	return HeroPromotionResult{
		PartnerID: r.PartnerID, Branch: r.Branch, FromColor: r.FromColor, ToColor: r.ToColor,
		Level: r.Level, Exp: r.Exp, Equipment: r.Equipment, Fumo: r.Fumo,
		RestoreItems: append([]appi5.Award(nil), r.RestoreItems...), ManaAfter: cloneInt64Ptr(r.ManaAfter),
		StateVersion: r.StateVersion, Replayed: replayed,
	}
}

func cloneInt64Ptr(in *int64) *int64 {
	if in == nil {
		return nil
	}
	v := *in
	return &v
}

func decodeHeroPromotionReceipt(r receipt.Receipt) (heroPromotionReceipt, error) {
	if r.ResultSchema != heroPromotionReceiptSchema {
		return heroPromotionReceipt{}, fmt.Errorf("character hero: unsupported promotion receipt schema %q", r.ResultSchema)
	}
	var out heroPromotionReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PartnerID <= 0 || out.FromColor < 1 || out.FromColor > 16 || out.ToColor < 1 || out.ToColor > 16 || out.Level <= 0 || out.Exp < 0 || out.StateVersion <= 0 {
		return out, errors.New("character hero: invalid promotion receipt payload")
	}
	switch out.Branch {
	case HeroPromotionMID51Promote, HeroPromotionMID57Promote:
		if out.ToColor != out.FromColor+1 {
			return out, errors.New("character hero: invalid promotion receipt color transition")
		}
	case HeroPromotionMID57Collect:
		if out.ToColor != out.FromColor {
			return out, errors.New("character hero: invalid collect receipt color transition")
		}
	default:
		return out, errors.New("character hero: invalid promotion receipt branch")
	}
	if err := out.Equipment.ValidateNormal(); err != nil {
		return out, err
	}
	if err := out.Fumo.Validate(); err != nil {
		return out, err
	}
	for _, x := range out.RestoreItems {
		if x.TableID <= 0 || x.ResourceKey != "" || x.ItemNum <= 0 {
			return out, errors.New("character hero: invalid promotion restoration receipt row")
		}
	}
	if out.ManaAfter != nil && *out.ManaAfter < 0 {
		return out, errors.New("character hero: invalid promotion receipt Mana")
	}
	return out, nil
}

func putHeroPromotionReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, result heroPromotionReceipt) error {
	payload, err := json.Marshal(result)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA4_3B_HERO_PROMOTION", heroPromotionReceiptSchema, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = heroPromotionPolicyVersion
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func (s Service) validatePromotionBase() error {
	if err := s.validateProgression(); err != nil {
		return err
	}
	if s.Equipment == nil || s.Fumo == nil || s.Promotion == nil || s.RestorationModifier == nil {
		return errors.New("character hero: incomplete CA4-3B promotion service")
	}
	return nil
}

func (s Service) validateMID51Promotion() error {
	if err := s.validatePromotionBase(); err != nil {
		return err
	}
	if s.StrictRestoration == nil {
		return errors.New("character hero: incomplete CA4-3B MID51 restoration service")
	}
	return nil
}

func (s Service) validateMID57Promotion() error {
	if err := s.validatePromotionBase(); err != nil {
		return err
	}
	if s.PromotionResources == nil || s.MaxHeroColorPolicy == nil {
		return errors.New("character hero: incomplete CA4-3B MID57 service")
	}
	return nil
}

func bindPolicyRef(op operation.Context, name, version string) (operation.Context, error) {
	if version == "" {
		return operation.Context{}, errors.New("character hero: empty promotion policy revision")
	}
	if got, ok := op.Policies.Get(name); ok {
		if got != version {
			return operation.Context{}, errors.New("character hero: conflicting promotion policy revision")
		}
		return op, nil
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: name, Version: version})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, err
	}
	op.Policies = set
	return op, nil
}

func (s Service) bindPromotionContent(ctx context.Context, op operation.Context, bindMaxColor bool) (operation.Context, string, error) {
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
	good, err = s.Equipment.EquipmentPrimitivesRevision(ctx, revision)
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
	good, err = s.Promotion.HeroPromotionRestorationRevision(ctx, revision)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrHeroPromotionContentInactive
	}
	if bindMaxColor {
		bound, err = bindPolicyRef(bound, heroPromotionMaxColorPolicyRef, s.MaxHeroColorPolicy.MaxHeroColorPolicyRevision())
		if err != nil {
			return operation.Context{}, "", err
		}
	}
	return bound, revision, nil
}

func (s Service) loadPromotionPositionsTx(ctx context.Context, q tx.Queryer, revision string, h character.Hero) ([character.HeroEquipmentSlotCount]character.HeroEquipmentPosition, error) {
	var positions [character.HeroEquipmentSlotCount]character.HeroEquipmentPosition
	if err := validateNormalHeroForEquipment(ctx, s, q, revision, h); err != nil {
		return positions, err
	}
	if h.Color >= 16 {
		return positions, ErrHeroPromotionUnavailable
	}
	if err := h.Fumo.Validate(); err != nil {
		return positions, err
	}
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		pos, err := s.Equipment.HeroEquipmentPositionTx(ctx, q, revision, h.TableID, h.Color, slot)
		if err != nil {
			return positions, err
		}
		if err := pos.Validate(); err != nil || pos.HeroTableID != h.TableID || pos.Color != h.Color || pos.Slot != slot {
			return positions, ErrHeroPromotionCorruptState
		}
		positions[slot-1] = pos
		collected := h.Equipment[slot-1] != 0
		raw := h.Fumo[slot-1]
		if collected && !pos.ItemID.Valid() {
			return positions, ErrHeroPromotionCorruptState
		}
		if !collected && raw != 0 {
			return positions, ErrHeroPromotionCorruptState
		}
		if raw > 0 {
			target, err := s.Fumo.HeroFumoTargetTx(ctx, q, revision, pos.ItemID)
			if err != nil {
				return positions, err
			}
			if err := target.Validate(); err != nil || raw > target.TotalCap {
				return positions, ErrHeroPromotionCorruptState
			}
		}
		if pos.ItemID.Valid() && !pos.OrdinaryEligible {
			next, err := s.Equipment.HeroEquipmentPositionTx(ctx, q, revision, h.TableID, h.Color+1, slot)
			if err != nil {
				return positions, err
			}
			if err := next.Validate(); err != nil || next.ItemID != pos.ItemID || next.OrdinaryEligible {
				return positions, ErrHeroPromotionCorruptState
			}
		}
	}
	return positions, nil
}

func missingOrdinarySlots(h character.Hero, positions [character.HeroEquipmentSlotCount]character.HeroEquipmentPosition) []int64 {
	out := make([]int64, 0, character.HeroEquipmentSlotCount)
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		pos := positions[slot-1]
		if pos.ItemID.Valid() && pos.OrdinaryEligible && h.Equipment[slot-1] == 0 {
			out = append(out, slot)
		}
	}
	return out
}

func allOrdinaryCollected(h character.Hero, positions [character.HeroEquipmentSlotCount]character.HeroEquipmentPosition) bool {
	return len(missingOrdinarySlots(h, positions)) == 0
}

func equalSlots(a, b []int64) bool {
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

func (s Service) buildPromotionRestorationPlanTx(ctx context.Context, q tx.Queryer, actor identity.ActorContext, revision string, h character.Hero, positions [character.HeroEquipmentSlotCount]character.HeroEquipmentPosition, op operation.Context) (*grant.Plan, error) {
	inputs := make([]heroPromotionRestorationInput, 0, character.HeroEquipmentSlotCount)
	for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
		pos := positions[slot-1]
		raw := h.Fumo[slot-1]
		if !pos.ItemID.Valid() || !pos.OrdinaryEligible || h.Equipment[slot-1] == 0 || raw == 0 {
			continue
		}
		eligible, err := s.Promotion.HeroPromotionRestorationEligibilityTx(ctx, q, revision, pos.ItemID)
		if err != nil {
			return nil, err
		}
		if err := eligible.Validate(); err != nil || eligible.ItemID != pos.ItemID {
			return nil, ErrHeroPromotionCorruptState
		}
		inputs = append(inputs, heroPromotionRestorationInput{RawFumo: raw, Quality: eligible.SourceQuality})
	}
	if len(inputs) == 0 {
		return nil, nil
	}
	contentPolicy, err := s.Promotion.HeroPromotionRestorationPolicyTx(ctx, q, revision)
	if err != nil {
		return nil, err
	}
	base, err := planBasePromotionRestoration(inputs, contentPolicy)
	if err != nil {
		return nil, err
	}
	if len(base) == 0 {
		return nil, nil
	}
	owner := characterasset.RestorationOwner{Family: "HERO", InstanceID: h.PartnerID, FromColor: h.Color, ToColor: h.Color + 1}
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
	seen := map[int64]struct{}{}
	for _, line := range lines {
		if line.Kind != grant.StackItem || line.Validate() != nil {
			return nil, errors.New("character hero: invalid modified restoration line")
		}
		if _, ok := qualified[line.ItemID]; !ok {
			return nil, errors.New("character hero: restoration modifier introduced unqualified material")
		}
		if _, ok := seen[line.ItemID]; ok {
			return nil, errors.New("character hero: duplicate modified restoration material")
		}
		seen[line.ItemID] = struct{}{}
	}
	source, err := characterasset.HeroPromotionRestorationSource(h.PartnerID, h.Color, h.Color+1, HeroPromotionRestorationPolicyVersion)
	if err != nil {
		return nil, err
	}
	plan := grant.Plan{PlayerID: actor.PlayerID, Source: source, Lines: append([]grant.Line(nil), lines...)}
	if err := plan.Validate(); err != nil {
		return nil, err
	}
	return &plan, nil
}

func awardsFromRestoration(gr *appi5.GrantResult) ([]appi5.Award, error) {
	if gr == nil {
		return nil, nil
	}
	out := append([]appi5.Award(nil), gr.Awards...)
	for _, x := range out {
		if x.TableID <= 0 || x.ResourceKey != "" || x.ItemNum <= 0 {
			return nil, errors.New("character hero: invalid restoration Grant result")
		}
	}
	return out, nil
}

func preparedPromotionPlanningSnapshot(p *appi5.PreparedHeroPromotionResources) (heroEquipmentPlanningSnapshot, error) {
	if p == nil || p.PlayerLevel() <= 0 || p.Mana() < 0 {
		return heroEquipmentPlanningSnapshot{}, errors.New("character hero: invalid prepared promotion resources")
	}
	stacks := make(map[int64]int64)
	for _, id := range p.PreparedStackItemIDs() {
		q, ok := p.StackQuantity(id)
		if !ok || q < 0 {
			return heroEquipmentPlanningSnapshot{}, errors.New("character hero: incomplete prepared promotion resources")
		}
		stacks[id] = q
	}
	return heroEquipmentPlanningSnapshot{PlayerLevel: p.PlayerLevel(), Mana: p.Mana(), Stacks: stacks}, nil
}

func equipmentDebitFromPlan(plan heroEquipmentPlan) appi5.HeroEquipmentResourceDebit {
	ordered := sortedEquipmentStackDebits(plan.StackDebits)
	out := appi5.HeroEquipmentResourceDebit{Mana: plan.ManaDebit, Stacks: make([]appi5.HeroEquipmentStackDebit, 0, len(ordered))}
	for _, x := range ordered {
		out.Stacks = append(out.Stacks, appi5.HeroEquipmentStackDebit{ItemID: x.ItemID, Count: x.Count})
	}
	return out
}

func applyPromotionHeroState(h character.Hero, positions [character.HeroEquipmentSlotCount]character.HeroEquipmentPosition, plan *heroEquipmentPlan, promote bool, maxLevel int64, thresholds []character.HeroExpThreshold, op operation.Context) (character.Hero, error) {
	if op.StartedAt.IsZero() {
		return character.Hero{}, errors.New("character hero: promotion operation time required")
	}
	oldVersion := h.StateVersion
	if plan != nil && plan.PotionEXPGranted > 0 {
		var err error
		h, err = h.AddSourceEXP(plan.PotionEXPGranted, maxLevel, thresholds, op.StartedAt)
		if err != nil {
			return character.Hero{}, err
		}
	} else {
		h.StateVersion++
		h.UpdatedAt = op.StartedAt.UTC()
	}
	if promote {
		for slot := int64(1); slot <= character.HeroEquipmentSlotCount; slot++ {
			if positions[slot-1].OrdinaryEligible {
				h.Equipment[slot-1] = 0
				h.Fumo[slot-1] = 0
			}
		}
		h.Color++
	} else {
		if plan == nil || plan.noWork() {
			return character.Hero{}, ErrHeroPromotionPrerequisites
		}
		for _, slot := range plan.Selected {
			if slot < 1 || slot > character.HeroEquipmentSlotCount || h.Equipment[slot-1] != 0 || !positions[slot-1].OrdinaryEligible || !positions[slot-1].ItemID.Valid() {
				return character.Hero{}, ErrHeroPromotionCorruptState
			}
			h.Equipment[slot-1] = 1
		}
	}
	if h.StateVersion != oldVersion+1 {
		return character.Hero{}, errors.New("character hero: non-cohesive promotion state transition")
	}
	if err := h.Equipment.ValidateNormal(); err != nil {
		return character.Hero{}, err
	}
	if err := h.Fumo.Validate(); err != nil {
		return character.Hero{}, err
	}
	if err := h.ValidatePersistent(); err != nil {
		return character.Hero{}, err
	}
	return h, nil
}

func promotionReceiptFromResult(r HeroPromotionResult) heroPromotionReceipt {
	return heroPromotionReceipt{
		PartnerID: r.PartnerID, Branch: r.Branch, FromColor: r.FromColor, ToColor: r.ToColor,
		Level: r.Level, Exp: r.Exp, Equipment: r.Equipment, Fumo: r.Fumo,
		RestoreItems: append([]appi5.Award(nil), r.RestoreItems...), ManaAfter: cloneInt64Ptr(r.ManaAfter), StateVersion: r.StateVersion,
	}
}

func (s Service) PowerUpHero(ctx context.Context, actor identity.ActorContext, partnerID int64, op operation.Context) (HeroPromotionResult, error) {
	if err := s.validateMID51Promotion(); err != nil {
		return HeroPromotionResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 {
		return HeroPromotionResult{}, errors.New("character hero: invalid MID51 request")
	}
	bound, revision, err := s.bindPromotionContent(ctx, op, false)
	if err != nil {
		return HeroPromotionResult{}, err
	}
	id := heroReceiptID(actor, "powerup-hero", bound)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID})
	if err != nil {
		return HeroPromotionResult{}, err
	}
	var result HeroPromotionResult
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
			decoded, err := decodeHeroPromotionReceipt(prior)
			if err != nil {
				return err
			}
			if decoded.Branch != HeroPromotionMID51Promote {
				return errors.New("character hero: MID51 receipt branch mismatch")
			}
			result = decoded.result(true)
			return nil
		}
		hero, err := s.ProgressionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		positions, err := s.loadPromotionPositionsTx(txctx, scope.Tx, revision, hero)
		if err != nil {
			return err
		}
		if !allOrdinaryCollected(hero, positions) {
			return ErrHeroPromotionPrerequisites
		}
		restoration, err := s.buildPromotionRestorationPlanTx(txctx, scope.Tx, actor, revision, hero, positions, bound)
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
		oldVersion := hero.StateVersion
		next, err := applyPromotionHeroState(hero, positions, nil, true, 0, nil, bound)
		if err != nil {
			return err
		}
		if err := s.ProgressionStore.SaveHeroStateTx(txctx, scope.Tx, next, oldVersion); err != nil {
			return err
		}
		awards, err := awardsFromRestoration(grantResult)
		if err != nil {
			return err
		}
		result = HeroPromotionResult{PartnerID: next.PartnerID, Branch: HeroPromotionMID51Promote, FromColor: hero.Color, ToColor: next.Color, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment, Fumo: next.Fumo, RestoreItems: awards, StateVersion: next.StateVersion}
		return putHeroPromotionReceipt(txctx, s, scope.Tx, actor, bound, id, fp, promotionReceiptFromResult(result))
	})
	return result, err
}

func (s Service) OneClickJinjie(ctx context.Context, actor identity.ActorContext, partnerID int64, op operation.Context) (HeroPromotionResult, error) {
	if err := s.validateMID57Promotion(); err != nil {
		return HeroPromotionResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 {
		return HeroPromotionResult{}, errors.New("character hero: invalid MID57 request")
	}
	bound, revision, err := s.bindPromotionContent(ctx, op, true)
	if err != nil {
		return HeroPromotionResult{}, err
	}
	id := heroReceiptID(actor, "one-click-jinjie", bound)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID})
	if err != nil {
		return HeroPromotionResult{}, err
	}
	var result HeroPromotionResult
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
			decoded, err := decodeHeroPromotionReceipt(prior)
			if err != nil {
				return err
			}
			if decoded.Branch != HeroPromotionMID57Promote && decoded.Branch != HeroPromotionMID57Collect {
				return errors.New("character hero: MID57 receipt branch mismatch")
			}
			result = decoded.result(true)
			return nil
		}
		hero, err := s.ProgressionStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		positions, err := s.loadPromotionPositionsTx(txctx, scope.Tx, revision, hero)
		if err != nil {
			return err
		}
		missing := missingOrdinarySlots(hero, positions)
		if len(missing) == 0 {
			return ErrHeroPromotionPrerequisites
		}
		maxColor, err := s.MaxHeroColorPolicy.MaxHeroColorTx(txctx, scope.Tx, actor.PlayerID, bound)
		if err != nil {
			return err
		}
		if maxColor < 1 || maxColor > 16 {
			return errors.New("character hero: invalid max_color policy value")
		}
		promote := hero.Color < maxColor
		var restoration *grant.Plan
		if promote {
			restoration, err = s.buildPromotionRestorationPlanTx(txctx, scope.Tx, actor, revision, hero, positions, bound)
			if err != nil {
				return err
			}
		}
		loadedPositions, nodes, potentialIDs, potionEXP, err := s.loadOneKeyContentTx(txctx, scope.Tx, revision, hero)
		if err != nil {
			return err
		}
		if loadedPositions != positions {
			return ErrHeroPromotionCorruptState
		}
		req := appi5.HeroPromotionResourceRequest{PotentialStackItemIDs: potentialIDs, AllowOverflowMail: true}
		if restoration != nil {
			copyPlan := *restoration
			req.Restoration = &copyPlan
		}
		prepared, err := s.PromotionResources.PrepareHeroPromotionResourcesTx(txctx, scope.Tx, actor, req, bound)
		if err != nil {
			return err
		}
		snap, err := preparedPromotionPlanningSnapshot(prepared)
		if err != nil {
			return err
		}
		maxLevel, err := s.Progression.HeroMaxLevelTx(txctx, scope.Tx, revision, snap.PlayerLevel)
		if err != nil {
			return err
		}
		thresholds, err := s.Progression.HeroExpPolicyTx(txctx, scope.Tx, revision, maxLevel)
		if err != nil {
			return err
		}
		plan, err := planOneKeyEquipment(hero, positions, nodes, snap, maxLevel, thresholds, potionEXP)
		if err != nil {
			return err
		}
		if !equalSlots(plan.Selected, missing) {
			return ErrHeroPromotionPrerequisites
		}
		resources, err := s.PromotionResources.ApplyHeroPromotionResourcesTx(txctx, scope.Tx, prepared, equipmentDebitFromPlan(plan))
		if err != nil {
			return err
		}
		oldVersion := hero.StateVersion
		next, err := applyPromotionHeroState(hero, positions, &plan, promote, maxLevel, thresholds, bound)
		if err != nil {
			return err
		}
		if err := s.ProgressionStore.SaveHeroStateTx(txctx, scope.Tx, next, oldVersion); err != nil {
			return err
		}
		awards, err := awardsFromRestoration(resources.Restoration)
		if err != nil {
			return err
		}
		branch := HeroPromotionMID57Collect
		if promote {
			branch = HeroPromotionMID57Promote
		}
		var manaAfter *int64
		if plan.ManaDebit > 0 {
			v := resources.Debit.Mana.Amount
			manaAfter = &v
		}
		result = HeroPromotionResult{PartnerID: next.PartnerID, Branch: branch, FromColor: hero.Color, ToColor: next.Color, Level: next.Level, Exp: next.Exp, Equipment: next.Equipment, Fumo: next.Fumo, RestoreItems: awards, ManaAfter: manaAfter, StateVersion: next.StateVersion}
		return putHeroPromotionReceipt(txctx, s, scope.Tx, actor, bound, id, fp, promotionReceiptFromResult(result))
	})
	return result, err
}
