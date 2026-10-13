package characterhero

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// FreshFacetChain composes required unique unpublished facets in the caller Tx.
// Members insert only the new Hero facet; they cannot lock an existing lower
// root after the I5 suffix has been acquired.
type FreshFacetChain []HeroLocalFacetInitializer

func (list FreshFacetChain) InitFreshHeroTx(ctx context.Context, t tx.Tx, ref character.HeroRef, now time.Time) error {
	for _, port := range list {
		if port == nil {
			return errors.New("character: missing required fresh facet")
		}
		if e := port.InitFreshHeroTx(ctx, t, ref, now); e != nil {
			return e
		}
	}
	return nil
}
