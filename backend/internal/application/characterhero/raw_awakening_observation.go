package characterhero

import (
	"context"
	"fmt"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type RawAwakeningBirthStore interface {
	FindRawAwakeningTx(context.Context, tx.Queryer, character.HeroRef) (character.RawAwakeningBirth, bool, error)
}
type RawAwakeningObservationReader struct {
	Heroes BaseObservationStore
	Births RawAwakeningBirthStore
}

func (r RawAwakeningObservationReader) RawAwakeningTx(c context.Context, sc ca.CoherentReadScope, ref character.HeroRef) (ca.HeroRawAwakeningObservation, error) {
	var out ca.HeroRawAwakeningObservation
	content, pinned := sc.Operation.Policies.Get("content")
	if !pinned || content != sc.ContentRevision || sc.Validate() != nil || ref.Validate() != nil || r.Heroes == nil || r.Births == nil {
		return out, character.ErrRawAwakeningUnavailable
	}
	h, e := r.Heroes.ReadHeroByPartnerIDTx(c, sc.Queryer(), ref.PlayerID, ref.PartnerID)
	if e != nil {
		return out, e
	}
	if h.Ref() != ref || h.ValidatePersistent() != nil || h.UpdatedAt.Before(h.CreatedAt) {
		return out, character.ErrRawAwakeningUnavailable
	}
	f, found, e := r.Births.FindRawAwakeningTx(c, sc.Queryer(), ref)
	if e != nil {
		return out, e
	}
	if !found {
		return out, character.ErrRawAwakeningUnavailable
	}
	if f.Validate() != nil || f.Ref != ref || f.CreationContentRevision != h.CreationContentRevision || !f.BirthAt.Equal(h.CreatedAt) {
		return out, character.ErrRawAwakeningUnavailable
	}
	producer := fmt.Sprintf("CharacterHero/%s/%d/%d/facet%d/%s", f.BirthPolicy, ref.PlayerID, ref.PartnerID, f.Version, f.BirthAt.UTC().Format(time.RFC3339Nano))
	if f.Version > 1 {
		producer = f.ProducerReference
	}
	observedAt := gen.EffectiveObservation(sc.ObservedAt, h.UpdatedAt, f.UpdatedAt)
	return ca.HeroRawAwakeningObservation{Ref: ref, StateVersion: h.StateVersion, ContentRevision: sc.ContentRevision, ObservedAt: observedAt, Known: true, RawStage: f.RawStage, ProducerReference: producer}, nil
}
