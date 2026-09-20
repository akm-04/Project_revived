package characterpet

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type PetAppearanceContributionStore interface {
	ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error)
	ListPetStyleEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.PetStyleEntitlement, error)
}

type PetAppearanceContributionContent interface {
	AppearanceRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	characterasset.AppearanceTxContent
}

type AppearanceContributionReader struct {
	Store   PetAppearanceContributionStore
	Content PetAppearanceContributionContent
}

func (r AppearanceContributionReader) PetAppearanceContributionTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, petID int64, revision string, observedAt time.Time) (characterasset.PetAppearanceContribution, error) {
	if r.Store == nil || r.Content == nil || q == nil || !pid.Valid() || petID <= 0 || observedAt.IsZero() || characterasset.ValidateExactRevisionID(revision) != nil {
		return characterasset.PetAppearanceContribution{}, errors.New("character pet: invalid appearance contribution read")
	}
	good, err := r.Content.AppearanceRevisionTx(ctx, q, revision)
	if err != nil {
		return characterasset.PetAppearanceContribution{}, err
	}
	if !good {
		return characterasset.PetAppearanceContribution{}, ErrPetAppearanceContentInactive
	}
	p, err := r.Store.ReadPetByIDTx(ctx, q, pid, petID)
	if err != nil {
		return characterasset.PetAppearanceContribution{}, err
	}
	if p.PlayerID != pid || p.PetID != petID {
		return characterasset.PetAppearanceContribution{}, errors.New("character pet: appearance contribution owner mismatch")
	}
	if err := p.ValidatePersistent(); err != nil {
		return characterasset.PetAppearanceContribution{}, err
	}
	styles, err := r.Store.ListPetStyleEntitlementsTx(ctx, q, pid, petID)
	if err != nil {
		return characterasset.PetAppearanceContribution{}, err
	}
	appearance, err := characterasset.BuildEffectivePetAppearanceTx(ctx, q, revision, p, styles, observedAt, r.Content)
	if err != nil {
		return characterasset.PetAppearanceContribution{}, err
	}
	out := characterasset.PetAppearanceContribution{
		OwnerID: p.PetID, TableID: p.TableID, OriginTableID: p.OriginTableID,
		ContentRevision: revision, Appearance: appearance,
	}
	if err := out.Validate(); err != nil {
		return characterasset.PetAppearanceContribution{}, err
	}
	return out, nil
}

var _ characterasset.PetAppearanceContributionProvider = AppearanceContributionReader{}
