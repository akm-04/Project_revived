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

type InscriptionHeroPort struct{ Store }

func (s InscriptionHeroPort) LockHeroByPartnerIDTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (character.Hero, error) {
	h, e := s.Store.LockHeroByPartnerIDTx(c, t, p, id)
	if errors.Is(e, kernelstore.ErrNoRows) {
		e = app.ErrRetired
	}
	return h, e
}

// No durable raw blood-stage producer exists in accepted116. Unavailability is
// explicit; neither zero, allocated evolution nor skill levels supply this fact.
func (s InscriptionHeroPort) InscriptionEligibilityTx(context.Context, tx.Queryer, identity.PlayerID, int64, string, time.Time) (app.Eligibility, error) {
	return app.Eligibility{}, app.ErrUnavailable
}
