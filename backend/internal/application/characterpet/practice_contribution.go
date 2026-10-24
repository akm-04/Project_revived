package characterpet

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type PetPracticeContributionStore interface {
	ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error)
}

type PetPracticeContributionContent interface {
	PracticeRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	PetPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]apppractice.Threshold, error)
}

type PracticeContributionReader struct {
	Store   PetPracticeContributionStore
	Content PetPracticeContributionContent
}

func (r PracticeContributionReader) PetPracticeContributionTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, petID int64, revision string) (characterasset.PracticeContribution, error) {
	if r.Store == nil || r.Content == nil || q == nil || !pid.Valid() || petID <= 0 || len(revision) != 64 {
		return characterasset.PracticeContribution{}, errors.New("character pet: invalid Practice contribution read")
	}
	good, err := r.Content.PracticeRevisionTx(ctx, q, revision)
	if err != nil {
		return characterasset.PracticeContribution{}, err
	}
	if !good {
		return characterasset.PracticeContribution{}, apppractice.ErrContentInactive
	}
	p, err := r.Store.ReadPetByIDTx(ctx, q, pid, petID)
	if err != nil {
		return characterasset.PracticeContribution{}, err
	}
	if err := p.ValidatePersistent(); err != nil {
		return characterasset.PracticeContribution{}, err
	}
	thresholds, err := r.Content.PetPracticeThresholdsTx(ctx, q, revision, p.TableID)
	if err != nil {
		return characterasset.PracticeContribution{}, err
	}
	reducer, rows, err := apppractice.ReduceAppliedPracticeContribution(characterasset.PracticeFamilyPet, p.Practice, thresholds)
	if err != nil {
		return characterasset.PracticeContribution{}, err
	}
	out := characterasset.PracticeContribution{
		Family: characterasset.PracticeFamilyPet, OwnerID: p.PetID, TableID: p.TableID, StateVersion: p.StateVersion,
		ContentRevision: revision, Applied: p.Practice, Reducer: reducer, Contributions: rows,
	}
	if err := out.Validate(); err != nil {
		return characterasset.PracticeContribution{}, err
	}
	return out, nil
}

var _ characterasset.PetPracticeContributionProvider = PracticeContributionReader{}
