package characterhero

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	ca73PolicyVersion         = "ca7-3.v1"
	skinOnReceiptSchema       = "gxb.ca7-3.skin-on.v1"
	skinCancelReceiptSchema   = "gxb.ca7-3.skin-cancel.v1"
	illusionReceiptSchema     = "gxb.ca7-3.illusion-select.v1"
	appearanceReceiptDomain   = "character-hero-appearance"
	appearanceOperationSkinOn = "skin-on"
	appearanceOperationCancel = "skin-cancel"
	appearanceOperationIllude = "illusion-select"
)

var (
	ErrHeroAppearanceUnavailable      = errors.New("character hero: appearance operation unavailable")
	ErrHeroSkinExperienceAlreadyOwned = errors.New("character hero: permanent skin rejects timed experience card")
)

// HeroAppearanceMutationStore is the exact Hero-owner persistence surface used
// by CA7-3. It exposes no Economy SQL and advances Hero state_version through a
// single cohesive owner CAS for each semantic appearance mutation.
type HeroAppearanceMutationStore interface {
	LockHeroByPartnerIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Hero, error)
	ListHeroSkinEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroSkinEntitlement, error)
	SaveHeroAppearanceMutationTx(context.Context, tx.Tx, character.Hero, *character.HeroSkinEntitlement, int64) error
}

// HeroAppearanceMutationContent combines the immutable CA7 catalog with the
// Hero-kind lookup required to validate a locked Hero through the caller's
// transaction. The active appearance revision is pinned once per new operation.
type HeroAppearanceMutationContent interface {
	characterasset.AppearanceContent
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
}

type SkinResultEntitlement struct {
	ModelID       int64  `json:"model_id"`
	ExpiresAtUnix *int64 `json:"expires_at_unix"`
}

type SkinOnResult struct {
	PartnerID     int64                   `json:"partner_id"`
	CurrentSkinID int64                   `json:"current_skin_id"`
	Skins         []SkinResultEntitlement `json:"skins"`
	StateVersion  int64                   `json:"state_version"`
	Mutated       bool                    `json:"mutated"`
	RemoveItem    bool                    `json:"remove_item"`
	Replayed      bool                    `json:"-"`
}

type SkinCancelResult struct {
	PartnerID     int64 `json:"partner_id"`
	CurrentSkinID int64 `json:"current_skin_id"`
	StateVersion  int64 `json:"state_version"`
	Mutated       bool  `json:"mutated"`
	Replayed      bool  `json:"-"`
}

type IllusionSelectResult struct {
	PartnerID      int64 `json:"partner_id"`
	IllusionSkinID int64 `json:"illusion_skin_id"`
	StateVersion   int64 `json:"state_version"`
	Mutated        bool  `json:"mutated"`
	Replayed       bool  `json:"-"`
}

type appearanceTimedReceiptResolver struct {
	reader receipt.Reader
	id     receipt.Identity
	fp     [32]byte
}

func (r appearanceTimedReceiptResolver) ResolveTimed(ctx context.Context, _ appgeneration.TimedResolutionRequest) (tx.Resolution, error) {
	if r.reader == nil {
		return tx.Resolution{}, errors.New("character hero appearance: nil receipt reader")
	}
	got, ok, err := r.reader.Find(ctx, r.id)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !ok {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if !bytes.Equal(got.RequestFingerprint[:], r.fp[:]) {
		return tx.Resolution{}, &receipt.ConflictError{Identity: r.id}
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: got}, nil
}

func appearanceProfile() tx.Profile {
	return tx.Profile{Name: "CA7_3_HERO_APPEARANCE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s Service) validateAppearanceMutation() error {
	if err := s.validate(); err != nil {
		return err
	}
	if s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil || s.AppearanceMutationStore == nil || s.AppearanceMutationContent == nil {
		return errors.New("character hero: incomplete CA7-3 appearance service")
	}
	return nil
}

func (s Service) bindAppearanceContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return operation.Context{}, "", errors.New("character hero: invalid appearance operation")
	}
	if revision, ok := op.Policies.Get("content"); ok {
		good, err := s.AppearanceMutationContent.AppearanceRevision(ctx, revision)
		if err != nil {
			return operation.Context{}, "", err
		}
		if !good {
			return operation.Context{}, "", ErrAppearanceContentInactive
		}
		return op, revision, nil
	}
	revision, good, err := s.AppearanceMutationContent.AppearanceActive(ctx)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrAppearanceContentInactive
	}
	refs := append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, "", err
	}
	op.Policies = set
	return op, revision, nil
}

func appearanceReceiptID(actor identity.ActorContext, operationName string, op operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: appearanceReceiptDomain, Operation: operationName, SemanticKey: op.ID.String()}
}

func validateSkinReceiptResult(out SkinOnResult) error {
	if out.PartnerID <= 0 || out.CurrentSkinID < 0 || out.StateVersion <= 0 {
		return errors.New("character hero appearance: invalid skin receipt")
	}
	var prior int64
	for i, skin := range out.Skins {
		if skin.ModelID <= 0 || (i > 0 && skin.ModelID <= prior) {
			return errors.New("character hero appearance: non-canonical skin receipt")
		}
		if skin.ExpiresAtUnix != nil && *skin.ExpiresAtUnix <= 0 {
			return errors.New("character hero appearance: invalid skin receipt expiry")
		}
		prior = skin.ModelID
	}
	return nil
}

func decodeSkinOnReceipt(r receipt.Receipt) (SkinOnResult, error) {
	if r.ResultSchema != skinOnReceiptSchema {
		return SkinOnResult{}, fmt.Errorf("character hero appearance: unsupported skin-on receipt schema %q", r.ResultSchema)
	}
	var out SkinOnResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return SkinOnResult{}, err
	}
	if err := validateSkinReceiptResult(out); err != nil {
		return SkinOnResult{}, err
	}
	out.Replayed = true
	return out, nil
}

func decodeSkinCancelReceipt(r receipt.Receipt) (SkinCancelResult, error) {
	if r.ResultSchema != skinCancelReceiptSchema {
		return SkinCancelResult{}, fmt.Errorf("character hero appearance: unsupported skin-cancel receipt schema %q", r.ResultSchema)
	}
	var out SkinCancelResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return SkinCancelResult{}, err
	}
	if out.PartnerID <= 0 || out.CurrentSkinID != 0 || out.StateVersion <= 0 {
		return SkinCancelResult{}, errors.New("character hero appearance: invalid skin-cancel receipt")
	}
	out.Replayed = true
	return out, nil
}

func decodeIllusionReceipt(r receipt.Receipt) (IllusionSelectResult, error) {
	if r.ResultSchema != illusionReceiptSchema {
		return IllusionSelectResult{}, fmt.Errorf("character hero appearance: unsupported illusion receipt schema %q", r.ResultSchema)
	}
	var out IllusionSelectResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return IllusionSelectResult{}, err
	}
	if out.PartnerID <= 0 || out.IllusionSkinID < 0 || out.StateVersion <= 0 {
		return IllusionSelectResult{}, errors.New("character hero appearance: invalid illusion receipt")
	}
	out.Replayed = true
	return out, nil
}

func findAppearanceReceipt(ctx context.Context, reader receipt.Reader, id receipt.Identity, fp [32]byte) (receipt.Receipt, bool, error) {
	if reader == nil {
		return receipt.Receipt{}, false, errors.New("character hero appearance: nil receipt reader")
	}
	got, ok, err := reader.Find(ctx, id)
	if err != nil || !ok {
		return got, ok, err
	}
	if !bytes.Equal(got.RequestFingerprint[:], fp[:]) {
		return receipt.Receipt{}, false, &receipt.ConflictError{Identity: id}
	}
	return got, true, nil
}

func findAppearanceReceiptTx(ctx context.Context, store receipt.Store, q tx.Queryer, id receipt.Identity, fp [32]byte) (receipt.Receipt, bool, error) {
	got, ok, err := store.FindTx(ctx, q, id)
	if err != nil || !ok {
		return got, ok, err
	}
	if !bytes.Equal(got.RequestFingerprint[:], fp[:]) {
		return receipt.Receipt{}, false, &receipt.ConflictError{Identity: id}
	}
	return got, true, nil
}

func putAppearanceReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, schema string, value any) error {
	payload, err := json.Marshal(value)
	if err != nil {
		return err
	}
	rr, err := receipt.New(op, id, "CA7_3_HERO_APPEARANCE", schema, payload, fp)
	if err != nil {
		return err
	}
	rr.ActorAccountUID = string(actor.AccountUID)
	rr.ContextID = actor.ContextID.UUID()
	rr.PolicyVersion = ca73PolicyVersion
	_, err = s.Receipts.PutTx(ctx, t, rr)
	return err
}

func resolveAppearanceHero(ctx context.Context, q tx.Queryer, h character.Hero, content HeroAppearanceMutationContent) (character.Hero, error) {
	kind, err := content.HeroKindTx(ctx, q, h.CreationContentRevision, h.TableID)
	if err != nil {
		return character.Hero{}, err
	}
	h.Kind = kind
	if err := h.Validate(); err != nil {
		return character.Hero{}, err
	}
	return h, nil
}

func skinReceiptProjection(v characterasset.EffectiveHeroAppearance) ([]SkinResultEntitlement, error) {
	if err := v.Validate(); err != nil {
		return nil, err
	}
	out := make([]SkinResultEntitlement, 0, len(v.Skins))
	for _, skin := range v.Skins {
		row := SkinResultEntitlement{ModelID: skin.ModelID}
		if skin.ExpiresAt != nil {
			epoch := skin.ExpiresAt.UTC().Unix()
			if epoch <= 0 {
				return nil, errors.New("character hero appearance: invalid projected skin expiry")
			}
			row.ExpiresAtUnix = &epoch
		}
		out = append(out, row)
	}
	return out, nil
}

func replaceSkinEntitlement(in []character.HeroSkinEntitlement, next character.HeroSkinEntitlement) []character.HeroSkinEntitlement {
	out := make([]character.HeroSkinEntitlement, 0, len(in)+1)
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

func findSkinEntitlement(in []character.HeroSkinEntitlement, modelID int64) (character.HeroSkinEntitlement, bool) {
	for _, ent := range in {
		if ent.ModelID == modelID {
			return ent, true
		}
	}
	return character.HeroSkinEntitlement{}, false
}

func effectiveHasSkin(v characterasset.EffectiveHeroAppearance, modelID int64) bool {
	for _, ent := range v.Skins {
		if ent.ModelID == modelID {
			return true
		}
	}
	return false
}

func timedSkinDeadline(at time.Time, seconds int64) (time.Time, error) {
	if at.IsZero() || seconds <= 0 || seconds > math.MaxInt64/int64(time.Second) {
		return time.Time{}, errors.New("character hero appearance: invalid timed skin duration")
	}
	deadline := at.UTC().Add(time.Duration(seconds) * time.Second)
	if !deadline.After(at.UTC()) {
		return time.Time{}, errors.New("character hero appearance: timed skin deadline overflow")
	}
	return deadline, nil
}

func (s Service) debitSkinCardTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, itemID int64, op operation.Context) error {
	_, err := s.MaterialCosts.DebitMaterialCostTx(ctx, t, actor.PlayerID, appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: itemID, Amount: 1}}}, op)
	if errors.Is(err, economy.ErrInsufficientBalance) || errors.Is(err, economy.ErrUnknownResource) {
		return ErrHeroAppearanceUnavailable
	}
	return err
}

func (s Service) SkinOn(ctx context.Context, actor identity.ActorContext, partnerID, itemID int64, op operation.Context) (SkinOnResult, error) {
	if err := s.validateAppearanceMutation(); err != nil {
		return SkinOnResult{}, err
	}
	if s.MaterialCosts == nil {
		return SkinOnResult{}, errors.New("character hero: incomplete CA7-3 skin-on material debit service")
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || itemID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return SkinOnResult{}, errors.New("character hero: invalid skin-on request")
	}
	id := appearanceReceiptID(actor, appearanceOperationSkinOn, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID, "item_id": itemID})
	if err != nil {
		return SkinOnResult{}, err
	}
	if prior, ok, err := findAppearanceReceipt(ctx, s.ReceiptRead, id, fp); err != nil {
		return SkinOnResult{}, err
	} else if ok {
		return decodeSkinOnReceipt(prior)
	}
	bound, revision, err := s.bindAppearanceContent(ctx, op)
	if err != nil {
		return SkinOnResult{}, err
	}
	var result SkinOnResult
	resolver := appearanceTimedReceiptResolver{reader: s.ReceiptRead, id: id, fp: fp}
	_, txres, err := s.Timed.Run(ctx, bound, appearanceProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		boundOp := scope.Operation.Operation()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeSkinOnReceipt(prior)
			return err
		}
		good, err := s.AppearanceMutationContent.AppearanceRevisionTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if !good {
			return ErrAppearanceContentInactive
		}
		h, err := s.AppearanceMutationStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeSkinOnReceipt(prior)
			return err
		}
		h, err = resolveAppearanceHero(txctx, scope.Tx, h, s.AppearanceMutationContent)
		if err != nil {
			return err
		}
		item, ok, err := s.AppearanceMutationContent.AppearanceSkinItemTx(txctx, scope.Tx, revision, itemID)
		if err != nil {
			return err
		}
		if !ok || item.Validate() != nil || item.HeroOriginTableID != h.OriginTableID {
			return ErrHeroAppearanceUnavailable
		}
		skinDef, ok, err := s.AppearanceMutationContent.AppearanceSkinTx(txctx, scope.Tx, revision, item.ModelID)
		if err != nil {
			return err
		}
		if !ok || skinDef.Validate() != nil || skinDef.HeroOriginTableID != h.OriginTableID || skinDef.HeroOriginTableID != item.HeroOriginTableID {
			return ErrHeroAppearanceUnavailable
		}
		ents, err := s.AppearanceMutationStore.ListHeroSkinEntitlementsTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		pre, err := characterasset.BuildEffectiveHeroAppearanceTx(txctx, scope.Tx, revision, h, ents, nil, at, s.AppearanceMutationContent)
		if err != nil {
			return err
		}

		durable, exists := findSkinEntitlement(ents, item.ModelID)
		requestedTimed := item.DurationSeconds > 0
		var entitlement *character.HeroSkinEntitlement
		removeItem := false
		mutated := false

		switch {
		case !exists:
			removeItem = true
			h.CurrentSkinID = pre.CurrentSkinID
			h.IllusionSkinID = pre.IllusionSkinID
			next := character.HeroSkinEntitlement{PlayerID: actor.PlayerID, PartnerID: partnerID, ModelID: item.ModelID}
			if requestedTimed {
				deadline, err := timedSkinDeadline(at, item.DurationSeconds)
				if err != nil {
					return err
				}
				next.ExpiresAt = &deadline
			}
			entitlement = &next
			mutated = true
		case durable.ExpiresAt == nil && requestedTimed:
			return ErrHeroSkinExperienceAlreadyOwned
		case durable.ExpiresAt == nil && !requestedTimed:
			if h.CurrentSkinID != item.ModelID {
				h.CurrentSkinID = item.ModelID
				mutated = true
			}
		case durable.ExpiresAt != nil && !requestedTimed:
			removeItem = true
			h.CurrentSkinID = pre.CurrentSkinID
			h.IllusionSkinID = pre.IllusionSkinID
			next := character.HeroSkinEntitlement{PlayerID: actor.PlayerID, PartnerID: partnerID, ModelID: item.ModelID}
			entitlement = &next
			mutated = true
		case durable.ExpiresAt != nil && requestedTimed && durable.EffectiveAt(at) && effectiveHasSkin(pre, item.ModelID):
			if h.CurrentSkinID != item.ModelID {
				h.CurrentSkinID = item.ModelID
				mutated = true
			}
		case durable.ExpiresAt != nil && requestedTimed:
			removeItem = true
			h.CurrentSkinID = pre.CurrentSkinID
			h.IllusionSkinID = pre.IllusionSkinID
			deadline, err := timedSkinDeadline(at, item.DurationSeconds)
			if err != nil {
				return err
			}
			next := character.HeroSkinEntitlement{PlayerID: actor.PlayerID, PartnerID: partnerID, ModelID: item.ModelID, ExpiresAt: &deadline}
			entitlement = &next
			mutated = true
		default:
			return errors.New("character hero appearance: unreachable skin state")
		}

		if removeItem {
			if err := s.debitSkinCardTx(txctx, scope.Tx, actor, itemID, boundOp); err != nil {
				return err
			}
		}
		if mutated {
			old := h.StateVersion
			h.StateVersion++
			h.UpdatedAt = at
			if err := s.AppearanceMutationStore.SaveHeroAppearanceMutationTx(txctx, scope.Tx, h, entitlement, old); err != nil {
				return err
			}
			if entitlement != nil {
				ents = replaceSkinEntitlement(ents, *entitlement)
			}
		}
		post, err := characterasset.BuildEffectiveHeroAppearanceTx(txctx, scope.Tx, revision, h, ents, nil, at, s.AppearanceMutationContent)
		if err != nil {
			return err
		}
		skins, err := skinReceiptProjection(post)
		if err != nil {
			return err
		}
		result = SkinOnResult{PartnerID: partnerID, CurrentSkinID: post.CurrentSkinID, Skins: skins, StateVersion: h.StateVersion, Mutated: mutated, RemoveItem: removeItem}
		return putAppearanceReceipt(txctx, s, scope.Tx, actor, boundOp, id, fp, skinOnReceiptSchema, result)
	})
	if err != nil {
		return SkinOnResult{}, err
	}
	if txres.Reconciled {
		if r, ok := txres.Evidence.(receipt.Receipt); ok {
			result, err = decodeSkinOnReceipt(r)
			if err != nil {
				return SkinOnResult{}, err
			}
		}
	}
	return result, nil
}

func (s Service) SkinCancel(ctx context.Context, actor identity.ActorContext, partnerID int64, op operation.Context) (SkinCancelResult, error) {
	if err := s.validateAppearanceMutation(); err != nil {
		return SkinCancelResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return SkinCancelResult{}, errors.New("character hero: invalid skin-cancel request")
	}
	id := appearanceReceiptID(actor, appearanceOperationCancel, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID})
	if err != nil {
		return SkinCancelResult{}, err
	}
	if prior, ok, err := findAppearanceReceipt(ctx, s.ReceiptRead, id, fp); err != nil {
		return SkinCancelResult{}, err
	} else if ok {
		return decodeSkinCancelReceipt(prior)
	}
	bound, revision, err := s.bindAppearanceContent(ctx, op)
	if err != nil {
		return SkinCancelResult{}, err
	}
	var result SkinCancelResult
	resolver := appearanceTimedReceiptResolver{reader: s.ReceiptRead, id: id, fp: fp}
	_, txres, err := s.Timed.Run(ctx, bound, appearanceProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		boundOp := scope.Operation.Operation()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeSkinCancelReceipt(prior)
			return err
		}
		good, err := s.AppearanceMutationContent.AppearanceRevisionTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if !good {
			return ErrAppearanceContentInactive
		}
		h, err := s.AppearanceMutationStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeSkinCancelReceipt(prior)
			return err
		}
		mutated := h.CurrentSkinID != 0
		if mutated {
			old := h.StateVersion
			h.CurrentSkinID = 0
			h.StateVersion++
			h.UpdatedAt = at
			if err := s.AppearanceMutationStore.SaveHeroAppearanceMutationTx(txctx, scope.Tx, h, nil, old); err != nil {
				return err
			}
		}
		result = SkinCancelResult{PartnerID: partnerID, CurrentSkinID: 0, StateVersion: h.StateVersion, Mutated: mutated}
		return putAppearanceReceipt(txctx, s, scope.Tx, actor, boundOp, id, fp, skinCancelReceiptSchema, result)
	})
	if err != nil {
		return SkinCancelResult{}, err
	}
	if txres.Reconciled {
		if r, ok := txres.Evidence.(receipt.Receipt); ok {
			result, err = decodeSkinCancelReceipt(r)
			if err != nil {
				return SkinCancelResult{}, err
			}
		}
	}
	return result, nil
}

func (s Service) UseIllusionSkinItem(ctx context.Context, actor identity.ActorContext, partnerID, itemID int64, op operation.Context) (IllusionSelectResult, error) {
	if err := s.validateAppearanceMutation(); err != nil {
		return IllusionSelectResult{}, err
	}
	if !actor.PlayerID.Valid() || partnerID <= 0 || itemID < 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return IllusionSelectResult{}, errors.New("character hero: invalid illusion request")
	}
	id := appearanceReceiptID(actor, appearanceOperationIllude, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"partner_id": partnerID, "item_id": itemID})
	if err != nil {
		return IllusionSelectResult{}, err
	}
	if prior, ok, err := findAppearanceReceipt(ctx, s.ReceiptRead, id, fp); err != nil {
		return IllusionSelectResult{}, err
	} else if ok {
		return decodeIllusionReceipt(prior)
	}
	bound, revision, err := s.bindAppearanceContent(ctx, op)
	if err != nil {
		return IllusionSelectResult{}, err
	}
	var result IllusionSelectResult
	resolver := appearanceTimedReceiptResolver{reader: s.ReceiptRead, id: id, fp: fp}
	_, txres, err := s.Timed.Run(ctx, bound, appearanceProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		boundOp := scope.Operation.Operation()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeIllusionReceipt(prior)
			return err
		}
		good, err := s.AppearanceMutationContent.AppearanceRevisionTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if !good {
			return ErrAppearanceContentInactive
		}
		h, err := s.AppearanceMutationStore.LockHeroByPartnerIDTx(txctx, scope.Tx, actor.PlayerID, partnerID)
		if err != nil {
			return err
		}
		if prior, ok, err := findAppearanceReceiptTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodeIllusionReceipt(prior)
			return err
		}
		desired := itemID
		if itemID > 1 {
			h, err = resolveAppearanceHero(txctx, scope.Tx, h, s.AppearanceMutationContent)
			if err != nil {
				return err
			}
			item, ok, err := s.AppearanceMutationContent.AppearanceSkinItemTx(txctx, scope.Tx, revision, itemID)
			if err != nil {
				return err
			}
			if !ok || item.Validate() != nil || item.HeroOriginTableID != h.OriginTableID {
				return ErrHeroAppearanceUnavailable
			}
			ents, err := s.AppearanceMutationStore.ListHeroSkinEntitlementsTx(txctx, scope.Tx, actor.PlayerID, partnerID)
			if err != nil {
				return err
			}
			pre, err := characterasset.BuildEffectiveHeroAppearanceTx(txctx, scope.Tx, revision, h, ents, nil, at, s.AppearanceMutationContent)
			if err != nil {
				return err
			}
			if !effectiveHasSkin(pre, item.ModelID) {
				return ErrHeroAppearanceUnavailable
			}
			desired = item.ModelID
		}
		mutated := h.IllusionSkinID != desired
		if mutated {
			old := h.StateVersion
			h.IllusionSkinID = desired
			h.StateVersion++
			h.UpdatedAt = at
			if err := s.AppearanceMutationStore.SaveHeroAppearanceMutationTx(txctx, scope.Tx, h, nil, old); err != nil {
				return err
			}
		}
		result = IllusionSelectResult{PartnerID: partnerID, IllusionSkinID: desired, StateVersion: h.StateVersion, Mutated: mutated}
		return putAppearanceReceipt(txctx, s, scope.Tx, actor, boundOp, id, fp, illusionReceiptSchema, result)
	})
	if err != nil {
		return IllusionSelectResult{}, err
	}
	if txres.Reconciled {
		if r, ok := txres.Evidence.(receipt.Receipt); ok {
			result, err = decodeIllusionReceipt(r)
			if err != nil {
				return IllusionSelectResult{}, err
			}
		}
	}
	return result, nil
}
