package characterhero

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

func (a CA8EquipmentObservationAdapter) HeroEquipmentObservationTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, id int64, rev string) (characterasset.ProviderObservation[characterasset.RawEquipmentState], error) {
	v, err := a.Reader.RawEquipmentStateTx(ctx, q, pid, id, rev)
	if errors.Is(err, ErrHeroEquipmentContentInactive) || errors.Is(err, ErrSuperEquipmentContentInactive) {
		return characterasset.ProviderObservation[characterasset.RawEquipmentState]{Disposition: characterasset.ProviderExplicitlyInactiveOrAbsent}, nil
	}
	if err != nil {
		return characterasset.ProviderObservation[characterasset.RawEquipmentState]{}, err
	}
	return characterasset.ProviderObservation[characterasset.RawEquipmentState]{Disposition: characterasset.ProviderQualifiedActive, Value: v}, nil
}

type CA8PracticeObservationAdapter struct{ Reader PracticeContributionReader }

func (a CA8PracticeObservationAdapter) HeroPracticeObservationTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, id int64, rev string) (characterasset.ProviderObservation[characterasset.PracticeContribution], error) {
	v, err := a.Reader.HeroPracticeContributionTx(ctx, q, pid, id, rev)
	if errors.Is(err, apppractice.ErrContentInactive) {
		return characterasset.ProviderObservation[characterasset.PracticeContribution]{Disposition: characterasset.ProviderExplicitlyInactiveOrAbsent}, nil
	}
	if err != nil {
		return characterasset.ProviderObservation[characterasset.PracticeContribution]{}, err
	}
	return characterasset.ProviderObservation[characterasset.PracticeContribution]{Disposition: characterasset.ProviderQualifiedActive, Value: v}, nil
}

type CA8AppearanceObservationAdapter struct{ Reader AppearanceContributionReader }

func (a CA8AppearanceObservationAdapter) HeroAppearanceObservationTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, id int64, rev string, at time.Time) (characterasset.ProviderObservation[characterasset.HeroAppearanceContribution], error) {
	v, err := a.Reader.HeroAppearanceContributionTx(ctx, q, pid, id, rev, at)
	if errors.Is(err, ErrAppearanceContentInactive) {
		return characterasset.ProviderObservation[characterasset.HeroAppearanceContribution]{Disposition: characterasset.ProviderExplicitlyInactiveOrAbsent}, nil
	}
	if err != nil {
		return characterasset.ProviderObservation[characterasset.HeroAppearanceContribution]{}, err
	}
	return characterasset.ProviderObservation[characterasset.HeroAppearanceContribution]{Disposition: characterasset.ProviderQualifiedActive, Value: v}, nil
}

var _ characterasset.HeroEquipmentObservationProvider = CA8EquipmentObservationAdapter{}
var _ characterasset.HeroPracticeObservationProvider = CA8PracticeObservationAdapter{}
var _ characterasset.HeroAppearanceObservationProvider = CA8AppearanceObservationAdapter{}
