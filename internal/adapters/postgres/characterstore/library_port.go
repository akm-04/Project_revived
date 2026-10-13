package characterstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LibraryHeroPort translates canonical absence without leaking adapter errors.
type LibraryHeroPort struct{ Store }

func (s LibraryHeroPort) LockHeroByPartnerIDTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (character.Hero, error) {
	h, e := s.Store.LockHeroByPartnerIDTx(c, t, p, id)
	if errors.Is(e, kernelstore.ErrNoRows) {
		e = app.ErrRetired
	}
	return h, e
}
