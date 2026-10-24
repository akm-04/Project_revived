package characterpet

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type CA8EquipmentObservationAdapter struct{ Reader EquipmentStateReader }

func (a CA8EquipmentObservationAdapter) PetEquipmentObservationTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, id int64, rev string) (characterasset.ProviderObservation[characterasset.RawEquipmentState], error) {
	v, err := a.Reader.RawEquipmentStateTx(ctx, q, pid, id, rev)
	if errors.Is(err, ErrPetEquipmentContentInactive) {
		return characterasset.ProviderObservation[characterasset.RawEquipmentState]{Disposition: characterasset.ProviderExplicitlyInactiveOrAbsent}, nil
	}
	if err != nil {
		return characterasset.ProviderObservation[characterasset.RawEquipmentState]{}, err
	}
	return characterasset.ProviderObservation[characterasset.RawEquipmentState]{Disposition: characterasset.ProviderQualifiedActive, Value: v}, nil
}

type CA8PracticeObservationAdapter struct{ Reader PracticeContributionReader }

func (a CA8PracticeObservationAdapter) PetPracticeObservationTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, id int64, rev string) (characterasset.ProviderObservation[characterasset.PracticeContribution], error) {
	v, err := a.Reader.PetPracticeContributionTx(ctx, q, pid, id, rev)
	if errors.Is(err, apppractice.ErrContentInactive) {
		return characterasset.ProviderObservation[characterasset.PracticeContribution]{Disposition: characterasset.ProviderExplicitlyInactiveOrAbsent}, nil
	}
	if err != nil {
		return characterasset.ProviderObservation[characterasset.PracticeContribution]{}, err
	}
	return characterasset.ProviderObservation[characterasset.PracticeContribution]{Disposition: characterasset.ProviderQualifiedActive, Value: v}, nil
}

type CA8AppearanceObservationAdapter struct{ Reader AppearanceContributionReader }

func (a CA8AppearanceObservationAdapter) PetAppearanceObservationTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, id int64, rev string, at time.Time) (characterasset.ProviderObservation[characterasset.PetAppearanceContribution], error) {
	v, err := a.Reader.PetAppearanceContributionTx(ctx, q, pid, id, rev, at)
	if errors.Is(err, ErrPetAppearanceContentInactive) {
		return characterasset.ProviderObservation[characterasset.PetAppearanceContribution]{Disposition: characterasset.ProviderExplicitlyInactiveOrAbsent}, nil
	}
	if err != nil {
		return characterasset.ProviderObservation[characterasset.PetAppearanceContribution]{}, err
	}
	return characterasset.ProviderObservation[characterasset.PetAppearanceContribution]{Disposition: characterasset.ProviderQualifiedActive, Value: v}, nil
}

var _ characterasset.PetEquipmentObservationProvider = CA8EquipmentObservationAdapter{}
var _ characterasset.PetPracticeObservationProvider = CA8PracticeObservationAdapter{}
var _ characterasset.PetAppearanceObservationProvider = CA8AppearanceObservationAdapter{}
