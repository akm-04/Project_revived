package characterhero

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type BaseObservationStore interface {
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
}

type BaseObservationContent interface {
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
}

// BaseObservationReader exposes the narrow CA2-owned immutable state needed by
// CA8 without reusing the stock roster DTO as an internal authority contract.
type BaseObservationReader struct {
	Store   BaseObservationStore
	Content BaseObservationContent
}

func (r BaseObservationReader) HeroBaseObservationTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64) (characterasset.HeroBaseObservation, error) {
	if r.Store == nil || r.Content == nil || q == nil || !pid.Valid() || partnerID <= 0 {
		return characterasset.HeroBaseObservation{}, errors.New("character hero: invalid base observation read")
	}
	h, err := r.Store.ReadHeroByPartnerIDTx(ctx, q, pid, partnerID)
	if err != nil {
		return characterasset.HeroBaseObservation{}, err
	}
	if err := h.ValidatePersistent(); err != nil {
		return characterasset.HeroBaseObservation{}, err
	}
	kind, err := r.Content.HeroKindTx(ctx, q, h.CreationContentRevision, h.TableID)
	if err != nil {
		return characterasset.HeroBaseObservation{}, err
	}
	out := characterasset.HeroBaseObservation{
		Ref: h.Ref(), TableID: h.TableID, OriginTableID: h.OriginTableID, Kind: kind,
		Star: h.Star, Level: h.Level, Exp: h.Exp, Color: h.Color,
		CreationContentRevision: h.CreationContentRevision, StateVersion: h.StateVersion,
	}
	if err := out.Validate(); err != nil {
		return characterasset.HeroBaseObservation{}, err
	}
	return out, nil
}

var _ characterasset.HeroBaseObservationProvider = BaseObservationReader{}
