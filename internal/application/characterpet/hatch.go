package characterpet

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"math"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrPetTimeDiscontinuity = errors.New("character pet: authoritative time precedes Pet birthday")

type HatchResult struct {
	PetID       int64 `json:"pet_id"`
	IsShow      bool  `json:"is_show"`
	FirstFree   bool  `json:"first_free,omitempty"`
	Natural     bool  `json:"natural,omitempty"`
	CrystalCost int64 `json:"crystal_cost,omitempty"`
}

func decodeHatchReceipt(r receipt.Receipt) (HatchResult, error) {
	var out HatchResult
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if out.PetID <= 0 {
		return out, errors.New("character pet: invalid hatch receipt")
	}
	return out, nil
}

func hatchCost(hatchSeconds, remaining, coefficient int64) (int64, error) {
	if hatchSeconds <= 0 || remaining <= 0 || remaining > hatchSeconds || coefficient <= 0 {
		return 0, errors.New("character pet: invalid hatch cost input")
	}
	if hatchSeconds > math.MaxInt64/(2*remaining) {
		return 0, errors.New("character pet: hatch cost overflow")
	}
	a := 2 * hatchSeconds * remaining
	if remaining > math.MaxInt64/remaining {
		return 0, errors.New("character pet: hatch cost overflow")
	}
	n := a - remaining*remaining
	if n < 0 {
		return 0, errors.New("character pet: invalid hatch cost")
	}
	return n / coefficient, nil
}

func (s Service) CleanCD(ctx context.Context, actor identity.ActorContext, petID int64, op operation.Context) (HatchResult, error) {
	if err := s.validateMutation(); err != nil {
		return HatchResult{}, err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return HatchResult{}, errors.New("character pet: invalid clean-cd")
	}
	id := petReceiptIdentity(actor.PlayerID, "clean-cd", op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID})
	if err != nil {
		return HatchResult{}, err
	}
	if prior, ok, err := acquisitionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return HatchResult{}, err
	} else if ok {
		return decodeHatchReceipt(prior)
	}
	var result HatchResult
	resolver := timedReceiptResolver{reader: s.ReceiptRead, id: id, fp: fp}
	_, res, err := s.Timed.Run(ctx, op, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		rawOp := scope.Operation.Operation()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			result, err = decodeHatchReceipt(prior)
			return err
		}
		root, err := s.Store.LockPetRootTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		pet, found, err := s.Store.LockPetByIDTx(txctx, scope.Tx, actor.PlayerID, petID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		result = HatchResult{PetID: petID, IsShow: true}
		bound := rawOp
		if !pet.IsShow {
			if at.Unix() < pet.Birthday {
				return ErrPetTimeDiscontinuity
			}
			bound, err = s.bindAcquisitionRevisionTx(txctx, scope.Tx, rawOp, pet.CreationContentRevision)
			if err != nil {
				return err
			}
			def, err := s.Content.PetAcquisitionTx(txctx, scope.Tx, pet.CreationContentRevision, pet.OriginTableID)
			if err != nil {
				return err
			}
			policy, err := s.Content.PetAcquisitionPolicyTx(txctx, scope.Tx, pet.CreationContentRevision)
			if err != nil {
				return err
			}
			deadline := pet.Birthday + def.HatchSeconds
			now := at.Unix()
			if now >= deadline {
				result.Natural = true
			} else if !root.FirstFreeHatchUsed {
				old := root.StateVersion
				root.FirstFreeHatchUsed = true
				root.StateVersion++
				root.UpdatedAt = at
				if err := s.Store.SavePetRootFreeHatchTx(txctx, scope.Tx, root, old); err != nil {
					return err
				}
				result.FirstFree = true
			} else {
				remaining := deadline - now
				cost, err := hatchCost(def.HatchSeconds, remaining, policy.HatchCostParam)
				if err != nil {
					return err
				}
				result.CrystalCost = cost
				if cost > 0 {
					if _, err := s.Scalar.DebitScalarTx(txctx, scope.Tx, actor.PlayerID, "crystal", cost, at); err != nil {
						return err
					}
				}
			}
			old := pet.StateVersion
			pet.IsShow = true
			pet.StateVersion++
			pet.UpdatedAt = at
			if err := s.Store.SavePetShowStateTx(txctx, scope.Tx, pet, old); err != nil {
				return err
			}
		}
		payload, _ := json.Marshal(result)
		rr, err := receipt.New(bound, id, "CA3_PET_ACQUISITION", "gxb.ca3.pet-clean-cd.v2", payload, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = "pass528-ca3-3"
		_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
		return err
	})
	if err != nil {
		return HatchResult{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			result, err = decodeHatchReceipt(r)
		}
	}
	return result, err
}

func (s Service) SetShow(ctx context.Context, actor identity.ActorContext, petID int64, op operation.Context) error {
	if err := s.validateMutation(); err != nil {
		return err
	}
	if !actor.PlayerID.Valid() || petID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return errors.New("character pet: invalid set-show")
	}
	id := petReceiptIdentity(actor.PlayerID, "set-show", op)
	fp, err := receipt.FingerprintRequest(map[string]any{"pet_id": petID})
	if err != nil {
		return err
	}
	if _, ok, err := acquisitionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil || ok {
		return err
	}
	resolver := timedReceiptResolver{reader: s.ReceiptRead, id: id, fp: fp}
	_, _, err = s.Timed.Run(ctx, op, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		rawOp := scope.Operation.Operation()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			return nil
		}
		pet, found, err := s.Store.LockPetByIDTx(txctx, scope.Tx, actor.PlayerID, petID)
		if err != nil {
			return err
		}
		if !found {
			return ErrPetNotFound
		}
		bound := rawOp
		if !pet.IsShow {
			if at.Unix() < pet.Birthday {
				return ErrPetTimeDiscontinuity
			}
			bound, err = s.bindAcquisitionRevisionTx(txctx, scope.Tx, rawOp, pet.CreationContentRevision)
			if err != nil {
				return err
			}
			def, err := s.Content.PetAcquisitionTx(txctx, scope.Tx, pet.CreationContentRevision, pet.OriginTableID)
			if err != nil {
				return err
			}
			if at.Unix() < pet.Birthday+def.HatchSeconds {
				return ErrPetStillIncubating
			}
			old := pet.StateVersion
			pet.IsShow = true
			pet.StateVersion++
			pet.UpdatedAt = at
			if err := s.Store.SavePetShowStateTx(txctx, scope.Tx, pet, old); err != nil {
				return err
			}
		}
		payload, _ := json.Marshal(HatchResult{PetID: petID, IsShow: true, Natural: true})
		rr, err := receipt.New(bound, id, "CA3_PET_ACQUISITION", "gxb.ca3.pet-set-show.v2", payload, fp)
		if err != nil {
			return err
		}
		rr.ActorAccountUID = string(actor.AccountUID)
		rr.ContextID = actor.ContextID.UUID()
		rr.PolicyVersion = "pass528-ca3-3"
		_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
		return err
	})
	return err
}
