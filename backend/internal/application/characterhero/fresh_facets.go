package characterhero

import (
	"context"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// HeroLocalFacetInitializer is a typed composition seam for a fresh unpublished
// Hero. It may insert that actor's local facet in this transaction, but must not
// discover new existing-owner locks after I5's preflight plan has been acquired.
type HeroLocalFacetInitializer interface {
	InitFreshHeroTx(context.Context, tx.Tx, character.HeroRef, time.Time) error
}

func insertFreshHero(ctx context.Context, t tx.Tx, store AcquisitionStore, facets HeroLocalFacetInitializer, h character.Hero) error {
	if err := store.InsertHeroTx(ctx, t, h); err != nil {
		return err
	}
	// nil is the inherited standalone Character composition before Library activation.
	// The Library-enabled production composition must supply the owning initializer.
	if facets != nil {
		return facets.InitFreshHeroTx(ctx, t, h.Ref(), h.CreatedAt)
	}
	return nil
}
