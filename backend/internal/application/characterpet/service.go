package characterpet

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store interface {
	ReadPetRoot(context.Context, identity.PlayerID) (character.PetRoot, error)
	ListPets(context.Context, identity.PlayerID) ([]character.Pet, error)
	LockPetRootTx(context.Context, tx.Tx, identity.PlayerID) (character.PetRoot, error)
	SavePetRootAllocatorTx(context.Context, tx.Tx, character.PetRoot, int64) error
	SavePetRootFreeHatchTx(context.Context, tx.Tx, character.PetRoot, int64) error
	InsertPetTx(context.Context, tx.Tx, character.Pet) error
	FindPetByOriginTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, bool, error)
	LockPetByIDTx(context.Context, tx.Tx, identity.PlayerID, int64) (character.Pet, bool, error)
	SavePetShowStateTx(context.Context, tx.Tx, character.Pet, int64) error
	SavePetStateTx(context.Context, tx.Tx, character.Pet, int64) error
}

type PetAppearanceStore interface {
	ListPetStyleEntitlements(context.Context, identity.PlayerID, int64) ([]character.PetStyleEntitlement, error)
}

type PetRosterView struct {
	Pet        character.Pet
	Appearance characterasset.EffectivePetAppearance
}

type ActorFencer interface {
	FenceActorTx(context.Context, tx.Tx, identity.ActorContext, time.Time) error
}

type AcquisitionContent interface {
	PetAcquisitionActive(context.Context) (string, bool, error)
	PetAcquisitionRevision(context.Context, string) (bool, error)
	PetAcquisitionRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	PetAcquisitionTx(context.Context, tx.Queryer, string, int64) (AcquisitionTemplate, error)
	PetAcquisitionPolicyTx(context.Context, tx.Queryer, string) (AcquisitionPolicy, error)
}

// ProgressionContent is the revision-qualified CA3-3 immutable gameplay seam.
type ProgressionContent interface {
	PetProgressionActive(context.Context) (string, bool, error)
	PetProgressionRevision(context.Context, string) (bool, error)
	PetProgressionTemplateTx(context.Context, tx.Queryer, string, int64) (ProgressionTemplate, error)
	PetSkillSlotsTx(context.Context, tx.Queryer, string, int64) ([]SkillSlotDefinition, error)
	PetExpItemTx(context.Context, tx.Queryer, string, int64) (int64, error)
	PetExpPolicyTx(context.Context, tx.Queryer, string, int64) ([]ExpThreshold, error)
	PetSkillBookCostTx(context.Context, tx.Queryer, string, int64) (int64, error)
	PetSkillSlotPolicyTx(context.Context, tx.Queryer, string, int64) (SkillSlotPolicy, error)
	PetEvolutionCostTx(context.Context, tx.Queryer, string, int64) (int64, error)
	PetProgressionPolicyTx(context.Context, tx.Queryer, string) (ProgressionPolicy, error)
	CharacterMaxLevelTx(context.Context, tx.Queryer, string, int64) (int64, error)
}

type Service struct {
	Runner                  tx.Runner
	Timed                   appgeneration.TimedRunner
	Store                   Store
	Fencer                  ActorFencer
	Content                 AcquisitionContent
	Progression             ProgressionContent
	Receipts                receipt.Store
	ReceiptRead             receipt.Reader
	Acquisition             appi5.TxTimedPetAcquisitionDebiter
	MaterialCosts           appi5.TxMaterialCostDebiter
	Scalar                  appi5.TxScalarDebiter
	PetExp                  appi5.TxPetExpDebiter
	Equipment               EquipmentOperationContent
	EquipmentResources      appi5.TxEquipmentResourceDebiter
	Promotion               PetPromotionContent
	PromotionResources      appi5.TxPromotionResourceSettler
	StrictRestoration       appi5.TxStrictRestorationSettler
	RestorationModifier     characterasset.RestorationModifier
	AppearanceStore         PetAppearanceStore
	Appearance              characterasset.AppearanceContent
	AppearanceMutationStore PetAppearanceMutationStore
}

func profile() tx.Profile {
	return tx.Profile{Name: "CA3_PET_ACQUISITION", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}
func (s Service) validateRead() error {
	if s.Store == nil {
		return errors.New("character pet: missing store")
	}
	return nil
}
func (s Service) validateMutation() error {
	if s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil || s.Store == nil || s.Fencer == nil || s.Content == nil || s.Receipts == nil || s.ReceiptRead == nil || s.Acquisition == nil || s.Scalar == nil {
		return errors.New("character pet: incomplete CA3 acquisition service")
	}
	return nil
}

func (s Service) validateProgression() error {
	if s.Runner.DB == nil || s.Store == nil || s.Fencer == nil || s.Progression == nil || s.Receipts == nil || s.ReceiptRead == nil || s.MaterialCosts == nil || s.PetExp == nil {
		return errors.New("character pet: incomplete CA3-3 progression service")
	}
	return nil
}

func (s Service) RosterView(ctx context.Context, actor identity.ActorContext, observedAt time.Time) (character.PetRoot, []PetRosterView, error) {
	if err := s.validateRead(); err != nil {
		return character.PetRoot{}, nil, err
	}
	if !actor.PlayerID.Valid() || observedAt.IsZero() || s.AppearanceStore == nil || s.Appearance == nil {
		return character.PetRoot{}, nil, errors.New("character pet: invalid appearance roster request")
	}
	revision, active, err := s.Appearance.AppearanceActive(ctx)
	if err != nil {
		return character.PetRoot{}, nil, err
	}
	if !active {
		return character.PetRoot{}, nil, errors.New("character pet: appearance content inactive")
	}
	root, err := s.Store.ReadPetRoot(ctx, actor.PlayerID)
	if err != nil {
		return root, nil, err
	}
	pets, err := s.Store.ListPets(ctx, actor.PlayerID)
	if err != nil {
		return root, nil, err
	}
	out := make([]PetRosterView, 0, len(pets))
	for i := range pets {
		if err := pets[i].ValidatePersistent(); err != nil {
			return root, nil, err
		}
		styles, err := s.AppearanceStore.ListPetStyleEntitlements(ctx, actor.PlayerID, pets[i].PetID)
		if err != nil {
			return root, nil, err
		}
		appearance, err := characterasset.BuildEffectivePetAppearance(ctx, revision, pets[i], styles, observedAt, s.Appearance)
		if err != nil {
			return root, nil, err
		}
		out = append(out, PetRosterView{Pet: pets[i], Appearance: appearance})
	}
	return root, out, nil
}

func (s Service) Roster(ctx context.Context, actor identity.ActorContext) (character.PetRoot, []character.Pet, error) {
	if err := s.validateRead(); err != nil {
		return character.PetRoot{}, nil, err
	}
	if !actor.PlayerID.Valid() {
		return character.PetRoot{}, nil, errors.New("character pet: invalid roster request")
	}
	root, err := s.Store.ReadPetRoot(ctx, actor.PlayerID)
	if err != nil {
		return root, nil, err
	}
	pets, err := s.Store.ListPets(ctx, actor.PlayerID)
	if err != nil {
		return root, nil, err
	}
	for i := range pets {
		if err := pets[i].ValidatePersistent(); err != nil {
			return root, nil, err
		}
	}
	return root, pets, nil
}
