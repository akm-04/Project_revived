package characterstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/inscription"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type InscriptionHeroPort struct {
	Store
	Content interface {
		HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
	}
}

func (s InscriptionHeroPort) LockHeroByPartnerIDTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (character.Hero, error) {
	h, e := s.Store.LockHeroByPartnerIDTx(c, t, p, id)
	if errors.Is(e, kernelstore.ErrNoRows) {
		e = app.ErrRetired
	}
	return h, e
}

func (s InscriptionHeroPort) InscriptionEligibilityTx(c context.Context, q tx.Queryer, p identity.PlayerID, id int64, revision string, at time.Time) (app.Eligibility, error) {
	if q == nil || s.Content == nil || !p.Valid() || id <= 0 || len(revision) != 64 || at.IsZero() {
		return app.Eligibility{}, app.ErrUnavailable
	}
	h, e := s.ReadHeroByPartnerIDTx(c, q, p, id)
	if e != nil {
		return app.Eligibility{}, e
	}
	r, e := s.ReadRootTx(c, q, p)
	if e != nil {
		return app.Eligibility{}, e
	}
	f, e := (RawAwakeningStore{}).ReadRawAwakeningBirthTx(c, q, h.Ref())
	if errors.Is(e, kernelstore.ErrNoRows) {
		return app.Eligibility{}, app.ErrUnavailable
	}
	if e != nil {
		return app.Eligibility{}, e
	}
	if f.CreationContentRevision != h.CreationContentRevision || !f.BirthAt.Equal(h.CreatedAt) || at.Before(h.UpdatedAt) || at.Before(f.UpdatedAt) {
		return app.Eligibility{}, app.ErrUnavailable
	}
	kind, e := s.Content.HeroKindTx(c, q, revision, h.TableID)
	if e != nil {
		return app.Eligibility{}, e
	}
	return app.Eligibility{Player: p, PartnerID: id, PopulationVersion: r.StateVersion, HeroVersion: h.StateVersion, Level: h.Level, RawStage: f.RawStage, Kind: kind, ContentRevision: revision, ProviderRevision: "I9_AWAKENING_MISSIONS_V1", ObservedAt: at, Qualified: true}, nil
}
