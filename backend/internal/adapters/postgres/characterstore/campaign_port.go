package characterstore

import (
	"context"
	"errors"
	"fmt"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// CampaignHeroPort locks a campaign formation hero; a hero the player does not own refuses the fight.
type CampaignHeroPort struct{ Store }

func (s CampaignHeroPort) LockHeroByPartnerIDTx(c context.Context, t tx.Tx, p identity.PlayerID, id int64) (character.Hero, error) {
	h, e := s.Store.LockHeroByPartnerIDTx(c, t, p, id)
	if errors.Is(e, kernelstore.ErrNoRows) {
		e = fmt.Errorf("%w: partner %d not owned", campaign.ErrRefused, id)
	}
	return h, e
}
