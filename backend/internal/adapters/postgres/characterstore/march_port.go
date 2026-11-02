package characterstore

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type MarchHeroPort struct{ Store }

func (s MarchHeroPort) LockHeroByPartnerIDTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (character.Hero, error) {
	hero, err := s.Store.LockHeroByPartnerIDTx(c, t, p, id)
	if errors.Is(err, kernelstore.ErrNoRows) {
		err = march.ErrRefused
	}
	return hero, err
}
