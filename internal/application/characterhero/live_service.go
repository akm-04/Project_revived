package characterhero

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	ca74PolicyVersion       = "ca7-4.v1"
	liveUnlockReceiptSchema = "gxb.ca7-4.live-unlock.v1"
	liveShowReceiptSchema   = "gxb.ca7-4.live-show.v1"
	liveOperationUnlock     = "live-unlock"
	liveOperationShow       = "live-show"
)

// HeroLIVEMutationStore is the Character-owned persistence seam for CA7-4.
// It deliberately exposes only the Hero lock, keyed LIVE rows and the existing
// single-owner-CAS LIVE write; Economy persistence remains behind I5.
type HeroLIVEMutationStore interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	ListHeroLIVEEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroLIVEEntitlement, error)
	SaveHeroLIVEEntitlementTx(context.Context, tx.Tx, character.Hero, character.HeroLIVEEntitlement, int64) error
}

type LIVEResultState struct {
	ModelID int64 `json:"model_id"`
	IsShow  bool  `json:"is_show"`
}

type LIVEUnlockResult struct {
	PartnerID    int64             `json:"partner_id"`
	ModelID      int64             `json:"model_id"`
	LIVE         []LIVEResultState `json:"live"`
	StateVersion int64             `json:"state_version"`
	Mutated      bool              `json:"mutated"`
	Replayed     bool              `json:"-"`
}

type LIVEShowResult struct {
	PartnerID    int64 `json:"partner_id"`
	ModelID      int64 `json:"model_id"`
	IsShow       bool  `json:"is_show"`
	StateVersion int64 `json:"state_version"`
	Mutated      bool  `json:"mutated"`
	Replayed     bool  `json:"-"`
}

func liveProfile() tx.Profile {
	return tx.Profile{Name: "CA7_4_HERO_LIVE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s Service) validateLIVEMutation() error {
	if err := s.validate(); err != nil {
		return err
	}
	if s.LIVEMutationStore == nil || s.AppearanceMutationContent == nil {
		return errors.New("character hero: incomplete CA7-4 LIVE service")
	}
	return nil
}

func liveReceiptID(actor identity.ActorContext, operationName string, op operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: appearanceReceiptDomain, Operation: operationName, SemanticKey: op.ID.String()}
}

func validateLIVEStates(in []LIVEResultState) error {
	var prior int64
	for i, x := range in {
		if x.ModelID <= 0 || (i > 0 && x.ModelID <= prior) {
			return errors.New("character hero LIVE: non-canonical LIVE result")
		}
		prior = x.ModelID
	}
	return nil
}

func decodeLIVEUnlockReceipt(r receipt.Receipt) (LIVEUnlockResult, error) {
	if r.ResultSchema != liveUnlockReceiptSchema {
		return LIVEUnlockResult{}, fmt.Errorf("character hero LIVE: unsupported unlock receipt schema %q", r.ResultSchema)
	}
	var out LIVEUnlockResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return LIVEUnlockResult{}, err
	}
	if out.PartnerID <= 0 || out.ModelID <= 0 || out.StateVersion <= 0 || validateLIVEStates(out.LIVE) != nil {
		return LIVEUnlockResult{}, errors.New("character hero LIVE: invalid unlock receipt")
	}
	out.Replayed = true
	return out, nil
}

func decodeLIVEShowReceipt(r receipt.Receipt) (LIVEShowResult, error) {
	if r.ResultSchema != liveShowReceiptSchema {
		return LIVEShowResult{}, fmt.Errorf("character hero LIVE: unsupported show receipt schema %q", r.ResultSchema)
	}
	var out LIVEShowResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return LIVEShowResult{}, err
	}
	if out.PartnerID <= 0 || out.ModelID <= 0 || out.StateVersion <= 0 {
		return LIVEShowResult{}, errors.New("character hero LIVE: invalid show receipt")
	}
	out.Replayed = true
	return out, nil
}

func putLIVEReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, schema string, value any) error {
	payload, err := json.Marshal(value)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA7_4_HERO_LIVE", schema, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = ca74PolicyVersion
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func liveReceiptProjection(v characterasset.EffectiveHeroAppearance) ([]LIVEResultState, error) {
	if err := v.Validate(); err != nil {
		return nil, err
	}
	out := make([]LIVEResultState, 0, len(v.LIVE))
	for _, x := range v.LIVE {
		out = append(out, LIVEResultState{ModelID: x.ModelID, IsShow: x.IsShow})
	}
	return out, validateLIVEStates(out)
}

func replaceLIVEEntitlement(in []character.HeroLIVEEntitlement, next character.HeroLIVEEntitlement) []character.HeroLIVEEntitlement {
	out := make([]character.HeroLIVEEntitlement, 0, len(in)+1)
	replaced := false
	for _, ent := range in {
		if ent.ModelID == next.ModelID {
			out = append(out, next)
			replaced = true
			continue
		}
		out = append(out, ent)
	}
	if !replaced {
		out = append(out, next)
	}
	return out
}

func findQualifiedLIVE(v characterasset.EffectiveHeroAppearance, modelID int64) (characterasset.QualifiedLIVEState, bool) {
	for _, x := range v.LIVE {
		if x.ModelID == modelID {
			return x, true
		}
	}
	return characterasset.QualifiedLIVEState{}, false
}

func qualifyPaidLIVE(ctx context.Context, q tx.Queryer, revision string, h character.Hero, modelID int64, content HeroAppearanceMutationContent) (characterasset.AppearanceLIVEDefinition, error) {
	if h.Kind != character.NormalHero {
		return characterasset.AppearanceLIVEDefinition{}, ErrHeroAppearanceUnavailable
	}
	def, ok, err := content.AppearanceLIVETx(ctx, q, revision, modelID)
	if err != nil {
		return characterasset.AppearanceLIVEDefinition{}, err
	}
	if !ok || def.Validate() != nil || def.HeroOriginTableID != h.OriginTableID {
		return characterasset.AppearanceLIVEDefinition{}, ErrHeroAppearanceUnavailable
	}
	return def, nil
}

func (s Service) debitLIVEUnlockTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, def characterasset.AppearanceLIVEDefinition, op operation.Context) error {
	_, err := s.MaterialCosts.DebitMaterialCostTx(ctx, t, actor.PlayerID, appi5.MaterialCost{
		Scalars: []appi5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: def.CrystalCost}},
		Stacks:  []appi5.StackMaterialCost{{ItemID: def.ActivationItemID, Amount: def.ActivationItemCount}},
	}, op)
	if errors.Is(err, economy.ErrInsufficientBalance) || errors.Is(err, economy.ErrUnknownResource) {
		return ErrHeroAppearanceUnavailable
	}
	return err
}

// UnlockLIVE implements stock MID68 as current-state convergence. Same-operation
// receipt replay proves UNKNOWN-COMMIT, while a fresh identical stock packet is
// re-evaluated against locked durable ownership and therefore never double-debits.
func (s Service) UnlockLIVE(ctx context.Context, actor identity.ActorContext, partnerID, modelID int64, op operation.Context) (LIVEUnlockResult, error) {
	if err := s.validateLIVEMutation(); err != nil {
		return LIVEUnlockResult{}, err
	}
	if s.MaterialCosts == nil {
		return LIVEUnlockResult{}, errors.New("character hero: incomplete CA7-4 LIVE unlock material debit service")
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || modelID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return LIVEUnlockResult{}, errors.New("character hero: invalid LIVE unlock request")
	}
	id := liveReceiptID(actor, liveOperationUnlock, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID, "model_id": modelID})
	if err != nil {
		return LIVEUnlockResult{}, err
	}
	if prior, ok, err := findAppearanceReceipt(ctx, s.ReceiptRead, id, fp); err != nil {
		return LIVEUnlockResult{}, err
	} else if ok {
		return decodeLIVEUnlockReceipt(prior)
	}
	bound, revision, err := s.bindAppearanceContent(ctx, op)
	if err != nil {
		return LIVEUnlockResult{}, err
	}
	var result LIVEUnlockResult
	txres, err := s.Runner.Run(ctx, bound, liveProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeLIVEUnlockReceipt(prior)
			return err
		}
		good, err := s.AppearanceMutationContent.AppearanceRevisionTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if !good {
			return ErrAppearanceContentInactive
		}
		h, err := s.LIVEMutationStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeLIVEUnlockReceipt(prior)
			return err
		}
		h, err = resolveAppearanceHero(txctx, scope.Tx, h, s.AppearanceMutationContent)
		if err != nil {
			return err
		}
		def, err := qualifyPaidLIVE(txctx, scope.Tx, revision, h, modelID, s.AppearanceMutationContent)
		if err != nil {
			return err
		}
		lives, err := s.LIVEMutationStore.ListHeroLIVEEntitlementsTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		pre, err := characterasset.BuildEffectiveHeroAppearanceTx(txctx, scope.Tx, revision, h, nil, lives, bound.StartedAt, s.AppearanceMutationContent)
		if err != nil {
			return err
		}
		_, owned := findQualifiedLIVE(pre, modelID)
		mutated := false
		if !owned {
			if err := s.debitLIVEUnlockTx(txctx, scope.Tx, actor, def, bound); err != nil {
				return err
			}
			ent := character.HeroLIVEEntitlement{PlayerID: actor.PlayerID, PartnerID: partnerID, ModelID: modelID, IsShow: true}
			old := h.StateVersion
			h.StateVersion++
			h.UpdatedAt = bound.StartedAt.UTC()
			if err := s.LIVEMutationStore.SaveHeroLIVEEntitlementTx(txctx, scope.Tx, h, ent, old); err != nil {
				return err
			}
			lives = replaceLIVEEntitlement(lives, ent)
			mutated = true
		}
		post, err := characterasset.BuildEffectiveHeroAppearanceTx(txctx, scope.Tx, revision, h, nil, lives, bound.StartedAt, s.AppearanceMutationContent)
		if err != nil {
			return err
		}
		live, err := liveReceiptProjection(post)
		if err != nil {
			return err
		}
		result = LIVEUnlockResult{PartnerID: partnerID, ModelID: modelID, LIVE: live, StateVersion: h.StateVersion, Mutated: mutated}
		return putLIVEReceipt(txctx, s, scope.Tx, actor, bound, id, fp, liveUnlockReceiptSchema, result)
	})
	if err != nil {
		return LIVEUnlockResult{}, err
	}
	if txres.Reconciled {
		if r, ok := txres.Evidence.(receipt.Receipt); ok {
			result, err = decodeLIVEUnlockReceipt(r)
			if err != nil {
				return LIVEUnlockResult{}, err
			}
		}
	}
	return result, nil
}

// SetLIVEShow implements stock MID69 as an explicit desired-state assignment.
// It never toggles server state implicitly and never depends on the I5 debit port.
func (s Service) SetLIVEShow(ctx context.Context, actor identity.ActorContext, partnerID, modelID int64, isShow bool, op operation.Context) (LIVEShowResult, error) {
	if err := s.validateLIVEMutation(); err != nil {
		return LIVEShowResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || modelID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return LIVEShowResult{}, errors.New("character hero: invalid LIVE show request")
	}
	wireShow := int64(0)
	if isShow {
		wireShow = 1
	}
	id := liveReceiptID(actor, liveOperationShow, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID, "model_id": modelID, "is_show": wireShow})
	if err != nil {
		return LIVEShowResult{}, err
	}
	if prior, ok, err := findAppearanceReceipt(ctx, s.ReceiptRead, id, fp); err != nil {
		return LIVEShowResult{}, err
	} else if ok {
		return decodeLIVEShowReceipt(prior)
	}
	bound, revision, err := s.bindAppearanceContent(ctx, op)
	if err != nil {
		return LIVEShowResult{}, err
	}
	var result LIVEShowResult
	txres, err := s.Runner.Run(ctx, bound, liveProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeLIVEShowReceipt(prior)
			return err
		}
		good, err := s.AppearanceMutationContent.AppearanceRevisionTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if !good {
			return ErrAppearanceContentInactive
		}
		h, err := s.LIVEMutationStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeLIVEShowReceipt(prior)
			return err
		}
		h, err = resolveAppearanceHero(txctx, scope.Tx, h, s.AppearanceMutationContent)
		if err != nil {
			return err
		}
		if _, err := qualifyPaidLIVE(txctx, scope.Tx, revision, h, modelID, s.AppearanceMutationContent); err != nil {
			return err
		}
		lives, err := s.LIVEMutationStore.ListHeroLIVEEntitlementsTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		pre, err := characterasset.BuildEffectiveHeroAppearanceTx(txctx, scope.Tx, revision, h, nil, lives, bound.StartedAt, s.AppearanceMutationContent)
		if err != nil {
			return err
		}
		current, owned := findQualifiedLIVE(pre, modelID)
		if !owned {
			return ErrHeroAppearanceUnavailable
		}
		mutated := current.IsShow != isShow
		if mutated {
			ent := character.HeroLIVEEntitlement{PlayerID: actor.PlayerID, PartnerID: partnerID, ModelID: modelID, IsShow: isShow}
			old := h.StateVersion
			h.StateVersion++
			h.UpdatedAt = bound.StartedAt.UTC()
			if err := s.LIVEMutationStore.SaveHeroLIVEEntitlementTx(txctx, scope.Tx, h, ent, old); err != nil {
				return err
			}
			lives = replaceLIVEEntitlement(lives, ent)
		}
		// Rebuild after mutation as a qualification/invariant check. The MID69
		// stock callback needs no semantic body, but receipt state must reflect
		// the committed desired assignment.
		if _, err := characterasset.BuildEffectiveHeroAppearanceTx(txctx, scope.Tx, revision, h, nil, lives, bound.StartedAt, s.AppearanceMutationContent); err != nil {
			return err
		}
		result = LIVEShowResult{PartnerID: partnerID, ModelID: modelID, IsShow: isShow, StateVersion: h.StateVersion, Mutated: mutated}
		return putLIVEReceipt(txctx, s, scope.Tx, actor, bound, id, fp, liveShowReceiptSchema, result)
	})
	if err != nil {
		return LIVEShowResult{}, err
	}
	if txres.Reconciled {
		if r, ok := txres.Evidence.(receipt.Receipt); ok {
			result, err = decodeLIVEShowReceipt(r)
			if err != nil {
				return LIVEShowResult{}, err
			}
		}
	}
	return result, nil
}
