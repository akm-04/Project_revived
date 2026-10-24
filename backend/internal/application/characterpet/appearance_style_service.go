package characterpet

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
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	ca75PolicyVersion        = "ca7-5.v1"
	petStyleReceiptDomain    = "character-pet-appearance"
	petStyleOperationAcquire = "pet-style-acquire"
	petStyleOperationSelect  = "pet-style-select"
	petStyleOperationCancel  = "pet-style-cancel"
	petStyleAcquireSchema    = "gxb.ca7-5.pet-style-acquire.v1"
	petStyleSelectSchema     = "gxb.ca7-5.pet-style-select.v1"
	petStyleCancelSchema     = "gxb.ca7-5.pet-style-cancel.v1"
)

var (
	ErrPetAppearanceContentInactive = errors.New("CA7-5 Pet appearance content capability inactive")
	ErrPetAppearanceUnavailable     = errors.New("character pet: appearance operation unavailable")
	ErrPetStyleSwitchConflict       = errors.New("character pet: cancel active style before selecting another")
)

// PetAppearanceMutationStore is the exact Pet-owner persistence surface used by
// CA7-5. It exposes keyed style rows and a narrow one-owner-CAS composite for
// acquisition/stale-selector normalization; Economy persistence remains in I5.
type PetAppearanceMutationStore interface {
	ListPetStyleEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.PetStyleEntitlement, error)
	SavePetAppearanceMutationTx(context.Context, tx.Tx, character.Pet, *character.PetStyleEntitlement, int64) error
	SavePetActiveStyleTx(context.Context, tx.Tx, character.Pet, int64) error
}

type PetStyleAcquireResult struct {
	PetID        int64   `json:"pet_id"`
	StyleItemID  int64   `json:"style_item_id"`
	ActiveStyle  int64   `json:"active_style"`
	PetStyles    []int64 `json:"pet_styles"`
	StateVersion int64   `json:"state_version"`
	Mutated      bool    `json:"mutated"`
	Consumed     bool    `json:"consumed"`
	Replayed     bool    `json:"-"`
}

type PetStyleSelectResult struct {
	PetID        int64 `json:"pet_id"`
	StyleItemID  int64 `json:"style_item_id"`
	ActiveStyle  int64 `json:"active_style"`
	StateVersion int64 `json:"state_version"`
	Mutated      bool  `json:"mutated"`
	Replayed     bool  `json:"-"`
}

type PetStyleCancelResult struct {
	PetID        int64 `json:"pet_id"`
	ActiveStyle  int64 `json:"active_style"`
	StateVersion int64 `json:"state_version"`
	Mutated      bool  `json:"mutated"`
	Replayed     bool  `json:"-"`
}

func petStyleRetryPolicy() tx.RetryPolicy {
	return tx.RetryPolicy{
		MaxAttempts:              8,
		RetryDefiniteAbort:       true,
		DefiniteAbortBackoffBase: 25 * time.Millisecond,
		DefiniteAbortBackoffMax:  400 * time.Millisecond,
	}
}

func petStyleProfile() tx.Profile {
	return tx.Profile{Name: "CA7_5_PET_HOME_STYLE", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func (s Service) validatePetStyleMutation() error {
	if s.Runner.DB == nil || s.Store == nil || s.Fencer == nil || s.Receipts == nil || s.ReceiptRead == nil || s.Appearance == nil || s.AppearanceMutationStore == nil {
		return errors.New("character pet: incomplete CA7-5 appearance service")
	}
	return nil
}

func (s Service) bindPetAppearanceContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return operation.Context{}, "", errors.New("character pet: invalid appearance operation")
	}
	if revision, ok := op.Policies.Get("content"); ok {
		good, err := s.Appearance.AppearanceRevision(ctx, revision)
		if err != nil {
			return operation.Context{}, "", err
		}
		if !good {
			return operation.Context{}, "", ErrPetAppearanceContentInactive
		}
		return op, revision, nil
	}
	revision, good, err := s.Appearance.AppearanceActive(ctx)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrPetAppearanceContentInactive
	}
	refs := append(op.Policies.Refs(), policy.Ref{Name: "content", Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, "", err
	}
	op.Policies = set
	return op, revision, nil
}

func petStyleReceiptID(actor identity.ActorContext, operationName string, op operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: petStyleReceiptDomain, Operation: operationName, SemanticKey: op.ID.String()}
}

func putPetStyleReceipt(ctx context.Context, s Service, t tx.Tx, actor identity.ActorContext, op operation.Context, id receipt.Identity, fp [32]byte, schema string, value any) error {
	payload, err := json.Marshal(value)
	if err != nil {
		return err
	}
	r, err := receipt.New(op, id, "CA7_5_PET_HOME_STYLE", schema, payload, fp)
	if err != nil {
		return err
	}
	r.ActorAccountUID = string(actor.AccountUID)
	r.ContextID = actor.ContextID.UUID()
	r.PolicyVersion = ca75PolicyVersion
	_, err = s.Receipts.PutTx(ctx, t, r)
	return err
}

func validateStyleIDs(ids []int64) error {
	var prior int64
	for i, id := range ids {
		if id <= 0 || (i > 0 && id <= prior) {
			return errors.New("character pet appearance: non-canonical style result")
		}
		prior = id
	}
	return nil
}

func decodePetStyleAcquireReceipt(r receipt.Receipt) (PetStyleAcquireResult, error) {
	if r.ResultSchema != petStyleAcquireSchema {
		return PetStyleAcquireResult{}, fmt.Errorf("character pet appearance: unsupported acquire receipt schema %q", r.ResultSchema)
	}
	var out PetStyleAcquireResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.StyleItemID <= 0 || out.ActiveStyle < 0 || out.StateVersion <= 0 || validateStyleIDs(out.PetStyles) != nil {
		return out, errors.New("character pet appearance: invalid acquire receipt")
	}
	out.Replayed = true
	return out, nil
}

func decodePetStyleSelectReceipt(r receipt.Receipt) (PetStyleSelectResult, error) {
	if r.ResultSchema != petStyleSelectSchema {
		return PetStyleSelectResult{}, fmt.Errorf("character pet appearance: unsupported select receipt schema %q", r.ResultSchema)
	}
	var out PetStyleSelectResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.StyleItemID <= 0 || out.ActiveStyle <= 0 || out.StateVersion <= 0 {
		return out, errors.New("character pet appearance: invalid select receipt")
	}
	out.Replayed = true
	return out, nil
}

func decodePetStyleCancelReceipt(r receipt.Receipt) (PetStyleCancelResult, error) {
	if r.ResultSchema != petStyleCancelSchema {
		return PetStyleCancelResult{}, fmt.Errorf("character pet appearance: unsupported cancel receipt schema %q", r.ResultSchema)
	}
	var out PetStyleCancelResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 || out.ActiveStyle != 0 || out.StateVersion <= 0 {
		return out, errors.New("character pet appearance: invalid cancel receipt")
	}
	out.Replayed = true
	return out, nil
}

func hasStyle(ids []int64, styleID int64) bool {
	for _, id := range ids {
		if id == styleID {
			return true
		}
	}
	return false
}

func appendStyleEntitlement(in []character.PetStyleEntitlement, next character.PetStyleEntitlement) []character.PetStyleEntitlement {
	out := append([]character.PetStyleEntitlement(nil), in...)
	for _, ent := range out {
		if ent.StyleItemID == next.StyleItemID {
			return out
		}
	}
	return append(out, next)
}

func (s Service) debitPetStyleTx(ctx context.Context, t tx.Tx, actor identity.ActorContext, itemID int64, op operation.Context) error {
	_, err := s.MaterialCosts.DebitMaterialCostTx(ctx, t, actor.PlayerID, appi5.MaterialCost{Stacks: []appi5.StackMaterialCost{{ItemID: itemID, Amount: 1}}}, op)
	return err
}

func (s Service) AcquirePetStyle(ctx context.Context, actor identity.ActorContext, itemID int64, op operation.Context) (PetStyleAcquireResult, error) {
	if err := s.validatePetStyleMutation(); err != nil {
		return PetStyleAcquireResult{}, err
	}
	if s.MaterialCosts == nil {
		return PetStyleAcquireResult{}, errors.New("character pet: incomplete CA7-5 material debit service")
	}
	if !actor.PlayerID.Valid() || itemID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return PetStyleAcquireResult{}, errors.New("character pet: invalid style acquisition request")
	}
	id := petStyleReceiptID(actor, petStyleOperationAcquire, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"item_id": itemID})
	if err != nil {
		return PetStyleAcquireResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return PetStyleAcquireResult{}, err
	} else if ok {
		return decodePetStyleAcquireReceipt(prior)
	}
	bound, revision, err := s.bindPetAppearanceContent(ctx, op)
	if err != nil {
		return PetStyleAcquireResult{}, err
	}
	var result PetStyleAcquireResult
	txres, err := s.Runner.Run(ctx, bound, petStyleProfile(), tx.Options{Isolation: tx.Serializable}, petStyleRetryPolicy(), receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodePetStyleAcquireReceipt(prior)
			return err
		}
		good, err := s.Appearance.AppearanceRevisionTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if !good {
			return ErrPetAppearanceContentInactive
		}
		def, ok, err := s.Appearance.AppearancePetStyleTx(txctx, scope.Tx, revision, itemID)
		if err != nil {
			return err
		}
		if !ok || def.Validate() != nil || def.StyleItemID != itemID {
			return ErrPetAppearanceUnavailable
		}
		candidate, found, err := s.Store.FindPetByOriginTx(txctx, scope.Tx, actor.PlayerID, def.PetOriginTableID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		p, found, err := s.Store.LockPetByIDTx(txctx, scope.Tx, actor.PlayerID, candidate.PetID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		if p.PlayerID != actor.PlayerID || p.OriginTableID != def.PetOriginTableID || p.ValidatePersistent() != nil {
			return ErrPetAppearanceUnavailable
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodePetStyleAcquireReceipt(prior)
			return err
		}
		ents, err := s.AppearanceMutationStore.ListPetStyleEntitlementsTx(txctx, scope.Tx, actor.PlayerID, p.PetID)
		if err != nil {
			return err
		}
		pre, err := characterasset.BuildEffectivePetAppearanceTx(txctx, scope.Tx, revision, p, ents, bound.StartedAt, s.Appearance)
		if err != nil {
			return err
		}
		owned := hasStyle(pre.OwnedStyles, itemID)
		intendedActive := pre.ActiveStyle
		needsNormalization := p.ActiveStyle != intendedActive
		mutated := needsNormalization || !owned
		consumed := false
		var entitlement *character.PetStyleEntitlement
		if !owned {
			if err := s.debitPetStyleTx(txctx, scope.Tx, actor, itemID, bound); err != nil {
				return err
			}
			ent := character.PetStyleEntitlement{PlayerID: actor.PlayerID, PetID: p.PetID, StyleItemID: itemID}
			entitlement = &ent
			consumed = true
		}
		if mutated {
			old := p.StateVersion
			p.ActiveStyle = intendedActive
			p.StateVersion++
			p.UpdatedAt = bound.StartedAt.UTC()
			if err := s.AppearanceMutationStore.SavePetAppearanceMutationTx(txctx, scope.Tx, p, entitlement, old); err != nil {
				return err
			}
			if entitlement != nil {
				ents = appendStyleEntitlement(ents, *entitlement)
			}
		}
		post, err := characterasset.BuildEffectivePetAppearanceTx(txctx, scope.Tx, revision, p, ents, bound.StartedAt, s.Appearance)
		if err != nil {
			return err
		}
		result = PetStyleAcquireResult{PetID: p.PetID, StyleItemID: itemID, ActiveStyle: post.ActiveStyle, PetStyles: append([]int64(nil), post.OwnedStyles...), StateVersion: p.StateVersion, Mutated: mutated, Consumed: consumed}
		return putPetStyleReceipt(txctx, s, scope.Tx, actor, bound, id, fp, petStyleAcquireSchema, result)
	})
	if err != nil {
		return PetStyleAcquireResult{}, err
	}
	if txres.Reconciled {
		if r, ok := txres.Evidence.(receipt.Receipt); ok {
			result, err = decodePetStyleAcquireReceipt(r)
			if err != nil {
				return PetStyleAcquireResult{}, err
			}
		}
	}
	return result, nil
}

func (s Service) SelectPetStyle(ctx context.Context, actor identity.ActorContext, petID, styleID int64, op operation.Context) (PetStyleSelectResult, error) {
	if err := s.validatePetStyleMutation(); err != nil {
		return PetStyleSelectResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || styleID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return PetStyleSelectResult{}, errors.New("character pet: invalid style selection request")
	}
	id := petStyleReceiptID(actor, petStyleOperationSelect, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID, "style_id": styleID})
	if err != nil {
		return PetStyleSelectResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return PetStyleSelectResult{}, err
	} else if ok {
		return decodePetStyleSelectReceipt(prior)
	}
	bound, revision, err := s.bindPetAppearanceContent(ctx, op)
	if err != nil {
		return PetStyleSelectResult{}, err
	}
	var result PetStyleSelectResult
	txres, err := s.Runner.Run(ctx, bound, petStyleProfile(), tx.Options{Isolation: tx.Serializable}, petStyleRetryPolicy(), receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodePetStyleSelectReceipt(prior)
			return err
		}
		good, err := s.Appearance.AppearanceRevisionTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if !good {
			return ErrPetAppearanceContentInactive
		}
		p, found, err := s.Store.LockPetByIDTx(txctx, scope.Tx, actor.PlayerID, petID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodePetStyleSelectReceipt(prior)
			return err
		}
		def, ok, err := s.Appearance.AppearancePetStyleTx(txctx, scope.Tx, revision, styleID)
		if err != nil {
			return err
		}
		if !ok || def.Validate() != nil || def.StyleItemID != styleID || def.PetOriginTableID != p.OriginTableID {
			return ErrPetAppearanceUnavailable
		}
		ents, err := s.AppearanceMutationStore.ListPetStyleEntitlementsTx(txctx, scope.Tx, actor.PlayerID, p.PetID)
		if err != nil {
			return err
		}
		pre, err := characterasset.BuildEffectivePetAppearanceTx(txctx, scope.Tx, revision, p, ents, bound.StartedAt, s.Appearance)
		if err != nil {
			return err
		}
		if !hasStyle(pre.OwnedStyles, styleID) {
			return ErrPetAppearanceUnavailable
		}
		if pre.ActiveStyle > 0 && pre.ActiveStyle != styleID {
			return ErrPetStyleSwitchConflict
		}
		mutated := p.ActiveStyle != styleID
		if mutated {
			old := p.StateVersion
			p.ActiveStyle = styleID
			p.StateVersion++
			p.UpdatedAt = bound.StartedAt.UTC()
			if err := s.AppearanceMutationStore.SavePetActiveStyleTx(txctx, scope.Tx, p, old); err != nil {
				return err
			}
		}
		post, err := characterasset.BuildEffectivePetAppearanceTx(txctx, scope.Tx, revision, p, ents, bound.StartedAt, s.Appearance)
		if err != nil {
			return err
		}
		if post.ActiveStyle != styleID {
			return ErrPetAppearanceUnavailable
		}
		result = PetStyleSelectResult{PetID: petID, StyleItemID: styleID, ActiveStyle: post.ActiveStyle, StateVersion: p.StateVersion, Mutated: mutated}
		return putPetStyleReceipt(txctx, s, scope.Tx, actor, bound, id, fp, petStyleSelectSchema, result)
	})
	if err != nil {
		return PetStyleSelectResult{}, err
	}
	if txres.Reconciled {
		if r, ok := txres.Evidence.(receipt.Receipt); ok {
			result, err = decodePetStyleSelectReceipt(r)
			if err != nil {
				return PetStyleSelectResult{}, err
			}
		}
	}
	return result, nil
}

func (s Service) CancelPetStyle(ctx context.Context, actor identity.ActorContext, petID int64, op operation.Context) (PetStyleCancelResult, error) {
	if err := s.validatePetStyleMutation(); err != nil {
		return PetStyleCancelResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return PetStyleCancelResult{}, errors.New("character pet: invalid style cancel request")
	}
	id := petStyleReceiptID(actor, petStyleOperationCancel, op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID})
	if err != nil {
		return PetStyleCancelResult{}, err
	}
	if prior, ok, err := progressionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return PetStyleCancelResult{}, err
	} else if ok {
		return decodePetStyleCancelReceipt(prior)
	}
	bound, revision, err := s.bindPetAppearanceContent(ctx, op)
	if err != nil {
		return PetStyleCancelResult{}, err
	}
	var result PetStyleCancelResult
	txres, err := s.Runner.Run(ctx, bound, petStyleProfile(), tx.Options{Isolation: tx.Serializable}, petStyleRetryPolicy(), receipt.Resolver{Reader: s.ReceiptRead, Identity: id, Fingerprint: fp}, func(txctx context.Context, scope tx.Scope) error {
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, bound.StartedAt); err != nil {
			return err
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodePetStyleCancelReceipt(prior)
			return err
		}
		good, err := s.Appearance.AppearanceRevisionTx(txctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		if !good {
			return ErrPetAppearanceContentInactive
		}
		p, found, err := s.Store.LockPetByIDTx(txctx, scope.Tx, actor.PlayerID, petID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		if prior, ok, err := progressionReceiptReplayTx(txctx, s.Receipts, scope.Tx, id, fp); err != nil {
			return err
		} else if ok {
			result, err = decodePetStyleCancelReceipt(prior)
			return err
		}
		ents, err := s.AppearanceMutationStore.ListPetStyleEntitlementsTx(txctx, scope.Tx, actor.PlayerID, p.PetID)
		if err != nil {
			return err
		}
		if _, err := characterasset.BuildEffectivePetAppearanceTx(txctx, scope.Tx, revision, p, ents, bound.StartedAt, s.Appearance); err != nil {
			return err
		}
		mutated := p.ActiveStyle > 0
		if mutated {
			old := p.StateVersion
			p.ActiveStyle = 0
			p.StateVersion++
			p.UpdatedAt = bound.StartedAt.UTC()
			if err := s.AppearanceMutationStore.SavePetActiveStyleTx(txctx, scope.Tx, p, old); err != nil {
				return err
			}
		}
		post, err := characterasset.BuildEffectivePetAppearanceTx(txctx, scope.Tx, revision, p, ents, bound.StartedAt, s.Appearance)
		if err != nil {
			return err
		}
		if post.ActiveStyle != 0 {
			return ErrPetAppearanceUnavailable
		}
		result = PetStyleCancelResult{PetID: petID, ActiveStyle: 0, StateVersion: p.StateVersion, Mutated: mutated}
		return putPetStyleReceipt(txctx, s, scope.Tx, actor, bound, id, fp, petStyleCancelSchema, result)
	})
	if err != nil {
		return PetStyleCancelResult{}, err
	}
	if txres.Reconciled {
		if r, ok := txres.Evidence.(receipt.Receipt); ok {
			result, err = decodePetStyleCancelReceipt(r)
			if err != nil {
				return PetStyleCancelResult{}, err
			}
		}
	}
	return result, nil
}
