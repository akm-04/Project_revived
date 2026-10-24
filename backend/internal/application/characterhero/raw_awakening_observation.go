package characterhero

import (
	"context"
	"fmt"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type RawAwakeningBirthStore interface {
	ReadRawAwakeningBirthTx(context.Context, tx.Queryer, character.HeroRef) (character.RawAwakeningBirth, error)
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
	if h.Ref() != ref || h.ValidatePersistent() != nil || h.UpdatedAt.Before(h.CreatedAt) || sc.ObservedAt.Before(h.UpdatedAt) {
		return out, character.ErrRawAwakeningUnavailable
	}
	f, e := r.Births.ReadRawAwakeningBirthTx(c, sc.Queryer(), ref)
	if e != nil {
		return out, e
	}
	if f.Validate() != nil || f.Ref != ref || f.CreationContentRevision != h.CreationContentRevision || !f.BirthAt.Equal(h.CreatedAt) || sc.ObservedAt.Before(f.UpdatedAt) {
		return out, character.ErrRawAwakeningUnavailable
	}
	return ca.HeroRawAwakeningObservation{Ref: ref, StateVersion: h.StateVersion, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt, Known: true, RawStage: f.RawStage, ProducerReference: fmt.Sprintf("CharacterHero/%s/%d/%d/facet%d/%s", f.BirthPolicy, ref.PlayerID, ref.PartnerID, f.Version, f.BirthAt.UTC().Format(time.RFC3339Nano))}, nil
}
