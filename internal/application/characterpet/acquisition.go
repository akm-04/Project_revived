package characterpet

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"strconv"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var (
	ErrPetAcquisitionContentInactive = errors.New("CA3-2 Pet acquisition content capability inactive")
	ErrPetNotFound                   = errors.New("character pet: Pet not found")
	ErrPetStillIncubating            = errors.New("character pet: Pet still incubating")
)

type AcquisitionTemplate struct {
	TableID, OriginTableID, InitialStar, EggItemID, EssenceItemID, FragmentCount, HatchSeconds, SummonType int64
}

func (a AcquisitionTemplate) Validate() error {
	if a.TableID <= 0 || a.OriginTableID <= 0 || a.TableID != a.OriginTableID || a.InitialStar < 1 || a.InitialStar > character.MaxPetStar || a.EggItemID <= 0 || a.EssenceItemID <= 0 || a.FragmentCount <= 0 || a.HatchSeconds <= 0 || a.SummonType <= 0 {
		return errors.New("character pet: invalid acquisition template")
	}
	return nil
}

type AcquisitionPolicy struct{ StarterEggItemID, HatchCostParam int64 }

func (p AcquisitionPolicy) Validate() error {
	if p.StarterEggItemID <= 0 || p.HatchCostParam <= 0 {
		return errors.New("character pet: invalid acquisition policy")
	}
	return nil
}

type summonReceipt struct {
	Pet         character.Pet `json:"pet"`
	DebitItemID int64         `json:"debit_item_id,omitempty"`
	DebitCount  int64         `json:"debit_count,omitempty"`
	Recovered   bool          `json:"recovered,omitempty"`
}

func (s Service) bindAcquisitionContent(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return operation.Context{}, "", errors.New("character pet: invalid operation context")
	}
	if rev, ok := op.Policies.Get("content"); ok {
		good, err := s.Content.PetAcquisitionRevision(ctx, rev)
		if err != nil {
			return operation.Context{}, "", err
		}
		if !good {
			return operation.Context{}, "", ErrPetAcquisitionContentInactive
		}
		return op, rev, nil
	}
	rev, good, err := s.Content.PetAcquisitionActive(ctx)
	if err != nil {
		return operation.Context{}, "", err
	}
	if !good {
		return operation.Context{}, "", ErrPetAcquisitionContentInactive
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: "content", Version: rev})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, "", err
	}
	op.Policies = set
	return op, rev, nil
}

func (s Service) bindAcquisitionRevisionTx(ctx context.Context, q tx.Queryer, op operation.Context, revision string) (operation.Context, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() || len(revision) != 64 {
		return operation.Context{}, errors.New("character pet: invalid acquisition revision binding")
	}
	good, err := s.Content.PetAcquisitionRevisionTx(ctx, q, revision)
	if err != nil {
		return operation.Context{}, err
	}
	if !good {
		return operation.Context{}, ErrPetAcquisitionContentInactive
	}
	if cur, ok := op.Policies.Get("content"); ok {
		if cur != revision {
			return operation.Context{}, errors.New("character pet: acquisition content revision conflict")
		}
		return op, nil
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: "content", Version: revision})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, err
	}
	op.Policies = set
	return op, nil
}

func acquisitionReceiptReplay(ctx context.Context, reader receipt.Reader, id receipt.Identity, fp [32]byte) (receipt.Receipt, bool, error) {
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

func petReceiptIdentity(pid identity.PlayerID, operationName string, op operation.Context) receipt.Identity {
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(pid), 10), Domain: "character-pet", Operation: operationName, SemanticKey: op.ID.String()}
}
func decodeSummonReceipt(r receipt.Receipt) (summonReceipt, error) {
	var out summonReceipt
	if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
		return out, err
	}
	if err := out.Pet.ValidatePersistent(); err != nil {
		return out, err
	}
	return out, nil
}

func (s Service) Summon(ctx context.Context, actor identity.ActorContext, tableID int64, op operation.Context) (character.Pet, error) {
	if err := s.validateMutation(); err != nil {
		return character.Pet{}, err
	}
	if !actor.PlayerID.Valid() || tableID <= 0 || op.ID.IsZero() || op.StartedAt.IsZero() {
		return character.Pet{}, errors.New("character pet: invalid summon")
	}
	id := petReceiptIdentity(actor.PlayerID, "summon", op)
	fp, err := receipt.FingerprintRequest(map[string]any{"table_id": tableID})
	if err != nil {
		return character.Pet{}, err
	}
	if prior, ok, err := acquisitionReceiptReplay(ctx, s.ReceiptRead, id, fp); err != nil {
		return character.Pet{}, err
	} else if ok {
		got, err := decodeSummonReceipt(prior)
		return got.Pet, err
	}
	bound, revision, err := s.bindAcquisitionContent(ctx, op)
	if err != nil {
		return character.Pet{}, err
	}
	var result summonReceipt
	resolver := timedReceiptResolver{reader: s.ReceiptRead, id: id, fp: fp}
	_, res, err := s.Timed.Run(ctx, bound, profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope appgeneration.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := s.Fencer.FenceActorTx(txctx, scope.Tx, actor, at); err != nil {
			return err
		}
		if prior, ok, err := s.Receipts.FindTx(txctx, scope.Tx, id); err != nil {
			return err
		} else if ok {
			if !bytes.Equal(prior.RequestFingerprint[:], fp[:]) {
				return &receipt.ConflictError{Identity: id}
			}
			result, err = decodeSummonReceipt(prior)
			return err
		}
		root, err := s.Store.LockPetRootTx(txctx, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		def, err := s.Content.PetAcquisitionTx(txctx, scope.Tx, revision, tableID)
		if err != nil {
			return err
		}
		if err := def.Validate(); err != nil {
			return err
		}
		if existing, ok, err := s.Store.FindPetByOriginTx(txctx, scope.Tx, actor.PlayerID, def.OriginTableID); err != nil {
			return err
		} else if ok {
			result = summonReceipt{Pet: existing, Recovered: true}
			payload, _ := json.Marshal(result)
			rr, err := receipt.New(bound, id, "CA3_PET_ACQUISITION", "gxb.ca3.pet-summon.v2", payload, fp)
			if err != nil {
				return err
			}
			rr.ActorAccountUID = string(actor.AccountUID)
			rr.ContextID = actor.ContextID.UUID()
			rr.PolicyVersion = "pass528-ca3-3"
			_, err = s.Receipts.PutTx(txctx, scope.Tx, rr)
			return err
		}
		debit, err := s.Acquisition.DebitPetAcquisitionAtTx(txctx, scope.Tx, actor.PlayerID, def.EggItemID, def.EssenceItemID, def.FragmentCount, bound, at)
		if err != nil {
			return err
		}
		old := root.StateVersion
		petID := root.NextPetID
		root.NextPetID++
		root.StateVersion++
		root.UpdatedAt = at
		p := character.Pet{PlayerID: actor.PlayerID, PetID: petID, TableID: def.TableID, OriginTableID: def.OriginTableID, Star: def.InitialStar, Level: 1, Exp: 0, Color: 1, Skills: character.DefaultPetSkillLevels(), Birthday: at.Unix(), IsShow: false, CreationContentRevision: revision, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
		if err := p.ValidatePersistent(); err != nil {
			return err
		}
		if err := s.Store.InsertPetTx(txctx, scope.Tx, p); err != nil {
			return err
		}
		if err := s.Store.SavePetRootAllocatorTx(txctx, scope.Tx, root, old); err != nil {
			return err
		}
		result = summonReceipt{Pet: p, DebitItemID: debit.ItemID, DebitCount: debit.Count}
		payload, _ := json.Marshal(result)
		rr, err := receipt.New(bound, id, "CA3_PET_ACQUISITION", "gxb.ca3.pet-summon.v2", payload, fp)
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
		return character.Pet{}, err
	}
	if res.Reconciled {
		if r, ok := res.Evidence.(receipt.Receipt); ok {
			result, err = decodeSummonReceipt(r)
			if err != nil {
				return character.Pet{}, err
			}
		}
	}
	return result.Pet, nil
}
