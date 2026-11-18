package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"sort"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const HeroSkillLevelPolicyID = "I9_SKILL_LEVEL_PRIVATE_POLICY_V1"
const heroSkillLevelReceiptSchema = "gxb.character-hero.skill-level.v1"

var ErrHeroSkillLevelRequest = errors.New("character hero: invalid skill level request")
var ErrHeroSkillLevelProof = errors.New("character hero: invalid skill level proof")
var ErrHeroSkillLevelStaleTime = errors.New("character hero: stale skill level decision time")
var ErrHeroSkillLevelInactive = errors.New("character hero: skill level content inactive")

type HeroSkillLevelStore interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
	SaveHeroSkillLevelsTx(context.Context, tx.Tx, character.Hero, int64) error
}

type HeroSkillPointReader interface {
	ReadTemporalTx(context.Context, tx.Queryer, identity.PlayerID, string) (economy.TemporalState, bool, error)
}

type HeroSkillLevelBooks interface {
	LockHeroSkillCapTx(context.Context, tx.Tx, identity.PlayerID, string, time.Time, character.HeroRef) (int64, error)
}

type HeroSkillLevelContent interface {
	HeroRawSkillsActive(context.Context) (string, bool, error)
	HeroSkillCatalogTx(context.Context, tx.Queryer, string, int64) (character.HeroSkillCatalog, error)
	HeroKind(context.Context, string, int64) (character.HeroKind, error)
}

type HeroSkillLevelChange struct {
	Slot  int64 `json:"slot"`
	Count int64 `json:"count"`
}

type HeroSkillLevelResult struct {
	Schema          string                 `json:"schema"`
	Family          string                 `json:"family"`
	PlayerID        int64                  `json:"player_id"`
	PartnerID       int64                  `json:"partner_id"`
	SkillLevels     [6]int64               `json:"skill_levels"`
	SkillPoint      int64                  `json:"skill_point"`
	SkillTime       int64                  `json:"skill_time"`
	Success         bool                   `json:"success"`
	Changed         bool                   `json:"changed"`
	ContentRevision string                 `json:"content_revision"`
	StateVersion    int64                  `json:"state_version"`
	Changes         []HeroSkillLevelChange `json:"changes"`
	Account         string                 `json:"account"`
	Context         string                 `json:"context"`
	Server          int32                  `json:"server"`
	EntropySeed     [32]byte               `json:"entropy_seed"`
	DecisionAt      time.Time              `json:"decision_at"`
}

type HeroSkillLevelService struct {
	Timed               gen.TimedRunner
	Reads               tx.Runner
	Store               HeroSkillLevelStore
	Books               HeroSkillLevelBooks
	Content             HeroSkillLevelContent
	Players             playerroot.TxLocker
	Fence               ActorFencer
	Receipts            receipt.Store
	Resources           appi5.TxHeroSkillLevelCost
	Points              HeroSkillPointReader
	Facts               appi5.ObjectiveFacts
	DiscountBasisPoints int64
}

func heroSkillLevelReceiptID(actor identity.ActorContext, op operation.Context, family string) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "character-hero", Operation: family, SemanticKey: op.ID.String()}
}

func heroSkillLevelFingerprint(partner int64, family string, changes []HeroSkillLevelChange) ([32]byte, error) {
	return receipt.FingerprintRequest(map[string]any{"partner_id": partner, "family": family, "changes": changes, "policy": HeroSkillLevelPolicyID})
}

func normalizeHeroSkillLevelChanges(changes []HeroSkillLevelChange) ([]HeroSkillLevelChange, error) {
	if len(changes) == 0 || len(changes) > 6 {
		return nil, ErrHeroSkillLevelRequest
	}
	out := append([]HeroSkillLevelChange(nil), changes...)
	sort.Slice(out, func(i, j int) bool { return out[i].Slot < out[j].Slot })
	for i, change := range out {
		if change.Slot < 1 || change.Slot > 6 || change.Count < 1 || change.Count > maxHeroSkillLevel || (i > 0 && out[i-1].Slot == change.Slot) {
			return nil, ErrHeroSkillLevelRequest
		}
	}
	return out, nil
}

func (s HeroSkillLevelService) proof(ctx context.Context, q tx.Queryer, actor identity.ActorContext, partner int64, family string, changes []HeroSkillLevelChange, op operation.Context) (HeroSkillLevelResult, bool, error) {
	id := heroSkillLevelReceiptID(actor, op, family)
	stored, found, err := s.Receipts.FindTx(ctx, q, id)
	if err != nil || !found {
		return HeroSkillLevelResult{}, found, err
	}
	fingerprint, err := heroSkillLevelFingerprint(partner, family, changes)
	if err != nil {
		return HeroSkillLevelResult{}, true, err
	}
	if stored.Validate() != nil || stored.Identity != id || stored.OperationClass != "I9_HERO_SKILL_LEVEL" || stored.ResultSchema != heroSkillLevelReceiptSchema || stored.RequestFingerprint != fingerprint || stored.ActorAccountUID != string(actor.AccountUID) || stored.ContextID != actor.ContextID.UUID() || stored.OperationStartedAt.UnixMicro() != op.StartedAt.UnixMicro() || stored.PolicyVersion != HeroSkillLevelPolicyID {
		return HeroSkillLevelResult{}, true, ErrHeroSkillLevelProof
	}
	if version, ok := stored.OperationPolicyRefs.Get("skillLevel"); !ok || version != HeroSkillLevelPolicyID {
		return HeroSkillLevelResult{}, true, ErrHeroSkillLevelProof
	}
	for _, ref := range op.Policies.Refs() {
		if version, ok := stored.OperationPolicyRefs.Get(ref.Name); !ok || version != ref.Version {
			return HeroSkillLevelResult{}, true, ErrHeroSkillLevelProof
		}
	}
	var result HeroSkillLevelResult
	decoder := json.NewDecoder(bytes.NewReader(stored.ResultPayload))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&result) != nil {
		return result, true, ErrHeroSkillLevelProof
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF {
		return result, true, ErrHeroSkillLevelProof
	}
	if result.Schema != heroSkillLevelReceiptSchema || result.Family != family || result.PlayerID != int64(actor.PlayerID) || result.PartnerID != partner || result.ContentRevision == "" || result.StateVersion < 1 || result.SkillPoint < 0 || result.SkillTime < 0 || result.Account != string(actor.AccountUID) || result.Context != actor.ContextID.UUID().String() || result.Server != int32(actor.LogicalServerID) || result.EntropySeed != op.EntropySeed || result.DecisionAt.IsZero() || result.DecisionAt.After(stored.RecordedAt) {
		return result, true, ErrHeroSkillLevelProof
	}
	if version, ok := stored.OperationPolicyRefs.Get("content"); !ok || version != result.ContentRevision {
		return result, true, ErrHeroSkillLevelProof
	}
	return result, true, nil
}

type heroSkillLevelResolver struct {
	service HeroSkillLevelService
	actor   identity.ActorContext
	partner int64
	family  string
	changes []HeroSkillLevelChange
	op      operation.Context
}

func (r heroSkillLevelResolver) ResolveTimed(ctx context.Context, request gen.TimedResolutionRequest) (tx.Resolution, error) {
	var result HeroSkillLevelResult
	var found bool
	resolution, err := r.service.Reads.Run(ctx, r.op, profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		if err := r.service.Fence.FenceActorTx(ctx, scope.Tx, r.actor, request.Operation.DecisionAt()); err != nil {
			return err
		}
		var err error
		result, found, err = r.service.proof(ctx, scope.Tx, r.actor, r.partner, r.family, r.changes, r.op)
		return err
	})
	if err != nil || resolution.Outcome != tx.DefiniteCommit {
		return tx.Resolution{}, err
	}
	if !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: result}, nil
}

func (s HeroSkillLevelService) factsReady() bool {
	return s.Facts.Open != nil && s.Facts.Owner.Store != nil && s.Facts.Owner.Receipts != nil
}

// SkillLevelView reads the committed hero skills and skill-point state without
// writing. C2 uses it to fill the four fields the stock MID 39 callback indexes
// even on a refusal.
func (s HeroSkillLevelService) SkillLevelView(ctx context.Context, actor identity.ActorContext, partner int64, op operation.Context) (HeroSkillLevelResult, error) {
	if partner <= 0 || !actor.PlayerID.Valid() || s.Reads.DB == nil || s.Store == nil || s.Points == nil {
		return HeroSkillLevelResult{}, ErrHeroSkillLevelRequest
	}
	var view HeroSkillLevelResult
	_, err := s.Reads.Run(ctx, op, profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		hero, err := s.Store.ReadHeroByPartnerIDTx(ctx, scope.Tx, actor.PlayerID, partner)
		if err != nil {
			return err
		}
		if hero.ValidatePersistent() != nil || hero.PartnerID != partner {
			return ErrHeroSkillLevelRequest
		}
		points, exists, err := s.Points.ReadTemporalTx(ctx, scope.Tx, actor.PlayerID, "skill_point")
		if err != nil {
			return err
		}
		if !exists {
			return economy.ErrUnknownResource
		}
		view.SkillLevels = hero.RawSkills.Levels
		view.SkillPoint = points.StoredAmount
		if points.RegenAnchorAt != nil {
			view.SkillTime = points.RegenAnchorAt.UTC().Unix()
		}
		return nil
	})
	if err != nil {
		return HeroSkillLevelResult{}, err
	}
	return view, nil
}

func (s HeroSkillLevelService) SetSkillLevel(ctx context.Context, actor identity.ActorContext, partner, slot int64, op operation.Context) (HeroSkillLevelResult, error) {
	return s.change(ctx, actor, partner, "set_skill_level", []HeroSkillLevelChange{{Slot: slot, Count: 1}}, op)
}

func (s HeroSkillLevelService) SetAllSkillLevels(ctx context.Context, actor identity.ActorContext, partner int64, changes []HeroSkillLevelChange, op operation.Context) (HeroSkillLevelResult, error) {
	return s.change(ctx, actor, partner, "set_all_skill_level", changes, op)
}

func (s HeroSkillLevelService) change(ctx context.Context, actor identity.ActorContext, partner int64, family string, changes []HeroSkillLevelChange, op operation.Context) (HeroSkillLevelResult, error) {
	changes, err := normalizeHeroSkillLevelChanges(changes)
	if err != nil || partner <= 0 || partner > 9007199254740991 || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || !actor.AccountUID.Valid() || actor.ContextID.UUID().IsZero() || op.ID.IsZero() || op.StartedAt.IsZero() || s.Timed.Binder.Time == nil || s.Timed.Runner.DB == nil || s.Reads.DB == nil || s.Store == nil || s.Books == nil || s.Content == nil || s.Players == nil || s.Fence == nil || s.Receipts == nil || s.Resources == nil || s.Points == nil || !s.factsReady() || s.DiscountBasisPoints < 1 || s.DiscountBasisPoints > 10000 {
		return HeroSkillLevelResult{}, ErrHeroSkillLevelRequest
	}
	var known HeroSkillLevelResult
	var found bool
	readResult, err := s.Reads.Run(ctx, op, profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		var err error
		known, found, err = s.proof(ctx, scope.Tx, actor, partner, family, changes, op)
		if err != nil || !found {
			return err
		}
		at, err := s.Timed.Binder.Time.Now(ctx)
		if err != nil {
			return err
		}
		return s.Fence.FenceActorTx(ctx, scope.Tx, actor, at)
	})
	if err != nil {
		return HeroSkillLevelResult{}, err
	}
	if found {
		if readResult.Outcome != tx.DefiniteCommit {
			return HeroSkillLevelResult{}, ErrHeroSkillLevelProof
		}
		return known, nil
	}
	revision, active, err := s.Content.HeroRawSkillsActive(ctx)
	if err != nil {
		return HeroSkillLevelResult{}, err
	}
	if !active {
		return HeroSkillLevelResult{}, ErrHeroSkillLevelInactive
	}
	if pinned, ok := op.Policies.Get("content"); ok {
		revision = pinned
	}
	refs := op.Policies.Refs()
	if _, ok := op.Policies.Get("content"); !ok {
		refs = append(refs, policy.Ref{Name: "content", Version: revision})
	}
	if version, ok := op.Policies.Get("skillLevel"); ok {
		if version != HeroSkillLevelPolicyID {
			return HeroSkillLevelResult{}, ErrHeroSkillLevelProof
		}
	} else {
		refs = append(refs, policy.Ref{Name: "skillLevel", Version: HeroSkillLevelPolicyID})
	}
	policies, err := policy.NewSet(refs...)
	if err != nil {
		return HeroSkillLevelResult{}, err
	}
	op.Policies = policies
	ref := character.HeroRef{PlayerID: actor.PlayerID, PartnerID: partner}
	if _, err := characterasset.HeroReferenceLockKey(ref); err != nil {
		return HeroSkillLevelResult{}, err
	}
	var result HeroSkillLevelResult
	_, timedResult, err := s.Timed.Run(ctx, op, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 5 * time.Millisecond, DefiniteAbortBackoffMax: 30 * time.Millisecond}, heroSkillLevelResolver{s, actor, partner, family, changes, op}, func(ctx context.Context, scope gen.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fence.FenceActorTx(ctx, scope.Tx, actor, at); err != nil {
			return err
		}
		prior, exists, err := s.proof(ctx, scope.Tx, actor, partner, family, changes, op)
		if err != nil {
			return err
		}
		if exists {
			result = prior
			return nil
		}
		roots, err := s.Players.LockPlayerRootsTx(ctx, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID})
		if err != nil {
			return err
		}
		if len(roots) != 1 {
			return ErrHeroSkillLevelRequest
		}
		hero, err := s.Store.LockHeroByPartnerIDTx(ctx, scope.Tx, actor.PlayerID, partner)
		if err != nil {
			return err
		}
		if hero.ValidatePersistent() != nil || hero.Ref() != ref {
			return ErrHeroSkillLevelRequest
		}
		if at.Before(hero.UpdatedAt) {
			return ErrHeroSkillLevelStaleTime
		}
		kind, err := s.Content.HeroKind(ctx, hero.CreationContentRevision, hero.TableID)
		if err != nil {
			return err
		}
		if kind != character.NormalHero && kind != character.SuperHero {
			return ErrHeroSkillLevelRequest
		}
		bookCap, err := s.Books.LockHeroSkillCapTx(ctx, scope.Tx, actor.PlayerID, revision, at, ref)
		if err != nil {
			return err
		}
		catalog, err := s.Content.HeroSkillCatalogTx(ctx, scope.Tx, revision, hero.TableID)
		if err != nil {
			return err
		}
		resolvedSkillIDs, err := catalog.ResolveRawIDs(hero)
		if err != nil {
			return err
		}
		maximumLevel := hero.Level + bookCap
		if maximumLevel > maxHeroSkillLevel {
			maximumLevel = maxHeroSkillLevel
		}
		manaCost, pointCost, planValid := heroSkillLevelCost(hero, kind, resolvedSkillIDs, changes, maximumLevel, s.DiscountBasisPoints)
		if !planValid {
			manaCost = 1
			pointCost = math.MaxInt64
		}
		if manaCost < 1 {
			manaCost = 1
		}
		if pointCost < 1 {
			pointCost = 1
		}
		factContext, err := s.Facts.PrepareTx(ctx, scope.Tx, actor.PlayerID, scope.Operation)
		if err != nil {
			return err
		}
		prepared, err := s.Resources.PrepareHeroSkillLevelCostTx(ctx, scope.Tx, actor.PlayerID, manaCost, pointCost, op)
		if err != nil {
			return err
		}
		result = HeroSkillLevelResult{
			Schema: heroSkillLevelReceiptSchema, Family: family, PlayerID: int64(actor.PlayerID), PartnerID: partner,
			SkillLevels: hero.RawSkills.Levels, SkillPoint: prepared.SkillPoint, SkillTime: prepared.SkillTime,
			ContentRevision: revision, StateVersion: hero.StateVersion, Changes: changes,
			Account: string(actor.AccountUID), Context: actor.ContextID.UUID().String(), Server: int32(actor.LogicalServerID),
			EntropySeed: op.EntropySeed, DecisionAt: at,
		}
		if planValid && prepared.Affordable {
			oldVersion := hero.StateVersion
			for _, change := range changes {
				index := change.Slot - 1
				hero.RawSkills.Levels[index] += change.Count
			}
			hero.StateVersion++
			hero.UpdatedAt = at
			if err := s.Store.SaveHeroSkillLevelsTx(ctx, scope.Tx, hero, oldVersion); err != nil {
				return err
			}
			resources, err := s.Resources.ApplyHeroSkillLevelCostTx(ctx, scope.Tx, prepared)
			if err != nil {
				return err
			}
			result.SkillLevels = hero.RawSkills.Levels
			result.SkillPoint = resources.SkillPoint
			result.SkillTime = resources.SkillTime
			result.StateVersion = hero.StateVersion
			result.Success = true
			result.Changed = true
			// C3: exactly one fact per accepted request; the receipt replay path
			// returns above and never reaches this code.
			changedLevels := int64(0)
			for _, change := range changes {
				changedLevels += change.Count
			}
			if changedLevels > 0 {
				fact := objective.Fact{PlayerID: actor.PlayerID, SourceDomain: "character-hero", SourceBusinessKey: op.ID.String(), Kind: "HERO_SKILL_UPGRADED", Delta: changedLevels}
				if err := s.Facts.RecordTx(factContext, scope.Tx, scope.Operation.Operation(), fact); err != nil {
					return err
				}
			}
		}
		payload, err := json.Marshal(result)
		if err != nil {
			return err
		}
		fingerprint, err := heroSkillLevelFingerprint(partner, family, changes)
		if err != nil {
			return err
		}
		record, err := receipt.New(op, heroSkillLevelReceiptID(actor, op, family), "I9_HERO_SKILL_LEVEL", heroSkillLevelReceiptSchema, payload, fingerprint)
		if err != nil {
			return err
		}
		record.ActorAccountUID = string(actor.AccountUID)
		record.ContextID = actor.ContextID.UUID()
		record.PolicyVersion = HeroSkillLevelPolicyID
		record.RecordedAt = at
		put, err := s.Receipts.PutTx(ctx, scope.Tx, record)
		if err != nil {
			return err
		}
		if !put.Inserted {
			return ErrHeroSkillLevelProof
		}
		return nil
	})
	if err != nil {
		return HeroSkillLevelResult{}, err
	}
	if timedResult.Reconciled && timedResult.Outcome == tx.DefiniteCommit {
		known, ok := timedResult.Evidence.(HeroSkillLevelResult)
		if !ok {
			return HeroSkillLevelResult{}, ErrHeroSkillLevelProof
		}
		return known, nil
	}
	if timedResult.Outcome != tx.DefiniteCommit {
		return HeroSkillLevelResult{}, ErrHeroSkillLevelProof
	}
	return result, nil
}

func heroSkillLevelCost(hero character.Hero, kind character.HeroKind, skillIDs [6]int64, changes []HeroSkillLevelChange, maximumLevel, discountBasisPoints int64) (int64, int64, bool) {
	manaTotal := int64(0)
	pointTotal := int64(0)
	valid := true
	multiplier := int64(1)
	if kind == character.SuperHero {
		multiplier = 10
	}
	for _, change := range changes {
		index := change.Slot - 1
		if skillIDs[index] <= 0 {
			valid = false
			continue
		}
		level := hero.RawSkills.Levels[index] + heroSkillLevelExtra[index]
		if level < 1 || level+change.Count > maximumLevel || level+change.Count > maxHeroSkillLevel {
			valid = false
			continue
		}
		for step := int64(0); step < change.Count; step++ {
			price, found := heroSkillLevelManaCost(level + step)
			if !found || price > math.MaxInt64/multiplier {
				valid = false
				continue
			}
			price *= multiplier
			if price > math.MaxInt64/discountBasisPoints {
				valid = false
				continue
			}
			price = price * discountBasisPoints / 10000
			if price > math.MaxInt64-manaTotal {
				valid = false
				continue
			}
			manaTotal += price
		}
		if pointTotal > math.MaxInt64-change.Count {
			valid = false
			continue
		}
		pointTotal += change.Count
	}
	return manaTotal, pointTotal, valid
}

func (r HeroSkillLevelResult) SkillString() string {
	parts := make([]string, len(r.SkillLevels))
	for index, level := range r.SkillLevels {
		parts[index] = strconv.FormatInt(level, 10)
	}
	return strings.Join(parts, "|")
}

func (r HeroSkillLevelResult) SuccessValue() int64 {
	if r.Success {
		return 1
	}
	return 0
}

func (r HeroSkillLevelResult) Validate() error {
	if r.Schema != heroSkillLevelReceiptSchema || r.PartnerID <= 0 || r.SkillPoint < 0 || r.SkillTime < 0 || r.StateVersion < 1 || r.DecisionAt.IsZero() {
		return fmt.Errorf("invalid Hero skill level result")
	}
	return nil
}

var _ = appi5.TxHeroSkillLevelCost(nil)
