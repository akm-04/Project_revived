package characterpet

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type BaseObservationStore interface {
	ReadPetByIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Pet, error)
}

// BaseObservationReader exposes only CA3-owned immutable Pet-core state. CA4,
// CA6 and CA7 contributions remain separate owner-qualified providers.
type BaseObservationReader struct{ Store BaseObservationStore }

func (r BaseObservationReader) PetBaseObservationTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, petID int64) (characterasset.PetBaseObservation, error) {
	if r.Store == nil || q == nil || !pid.Valid() || petID <= 0 {
		return characterasset.PetBaseObservation{}, errors.New("character pet: invalid base observation read")
	}
	p, err := r.Store.ReadPetByIDTx(ctx, q, pid, petID)
	if err != nil {
		return characterasset.PetBaseObservation{}, err
	}
	if err := p.ValidatePersistent(); err != nil {
		return characterasset.PetBaseObservation{}, err
	}
	out := characterasset.PetBaseObservation{
		Ref: p.Ref(), TableID: p.TableID, OriginTableID: p.OriginTableID,
		Star: p.Star, Level: p.Level, Exp: p.Exp, Color: p.Color, Skills: p.Skills,
		Birthday: p.Birthday, IsShow: p.IsShow,
		CreationContentRevision: p.CreationContentRevision, StateVersion: p.StateVersion,
	}
	if err := out.Validate(); err != nil {
		return characterasset.PetBaseObservation{}, err
	}
	return out, nil
}

var _ characterasset.PetBaseObservationProvider = BaseObservationReader{}
