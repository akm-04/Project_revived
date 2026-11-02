package characterstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type WorkplaceHeroPort struct{ Store }

func (s WorkplaceHeroPort) LockHeroByPartnerIDTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (character.Hero, error) {
	hero, err := s.Store.LockHeroByPartnerIDTx(c, t, p, id)
	if errors.Is(err, kernelstore.ErrNoRows) {
		err = workplace.ErrRefused
	}
	return hero, err
}
