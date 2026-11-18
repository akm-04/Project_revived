package librarylocal

import (
	"context"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// PartnerLogNoticeRoute wakes the realtime projection that pushes notice 24
// (LIBRARY_PARTNER_LOG). Its reference is "<player>:<partner_id>".
const PartnerLogNoticeRoute = "library.partner_log.v1"

// PartnerLogRef is the bounded wakeup reference of one changed Girls Log owner.
func PartnerLogRef(player identity.PlayerID, partnerID int64) string {
	return strconv.FormatInt(int64(player), 10) + ":" + strconv.FormatInt(partnerID, 10)
}

// PartnerLogPort is the Library owner's read surface for the log projection.
type PartnerLogPort interface {
	ListHeroLogsTx(context.Context, tx.Queryer, identity.PlayerID) ([]lib.HeroLogFact, error)
	ReadHeroTx(context.Context, tx.Queryer, character.HeroRef) (lib.HeroFacts, error)
}

// PartnerLogReader projects one partner's full Girls Log map with the same
// function 836 uses, so a notice replaces the client cache without divergence.
type PartnerLogReader struct {
	Queryer tx.Queryer
	Library PartnerLogPort
}

func (r PartnerLogReader) ReadPartnerLog(ctx context.Context, player identity.PlayerID, partnerID int64, at time.Time) (map[string]any, error) {
	if r.Queryer == nil || r.Library == nil || !player.Valid() || partnerID <= 0 || at.IsZero() {
		return nil, lib.ErrUnqualified
	}
	rows, err := r.Library.ListHeroLogsTx(ctx, r.Queryer, player)
	if err != nil {
		return nil, err
	}
	facts, err := r.Library.ReadHeroTx(ctx, r.Queryer, character.HeroRef{PlayerID: player, PartnerID: partnerID})
	if err != nil {
		return nil, err
	}
	return partnerLogMap(rows, partnerID, facts.Favor, facts.CreatedAt, at), nil
}
