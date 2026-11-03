package librarylocal

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// awardActTx records the once-per-hero/act claim before raising favor, as
// every claim family does. The client computes act progress locally; only the
// unlock gate and the once-only row are server facts.
func (s Service) awardActTx(ctx context.Context, t tx.Tx, d Admission, catalog lib.Catalog, rule lib.TemplateRule, facts lib.HeroFacts) (lib.HeroFacts, bool, error) {
	if !rule.DialogEnabled {
		return facts, false, lib.ErrUnqualified
	}
	act, ok := catalog.Acts[d.Command.Value]
	if !ok {
		return facts, false, lib.ErrUnqualified
	}
	if !catalog.ActUnlocked(d.Command.Value, facts.Favor) {
		return facts, false, lib.ErrActLocked
	}
	inserted, e := s.Library.InsertActAwardTx(ctx, t, lib.ActAwardFact{PlayerID: identity.PlayerID(d.Actor.Player), PartnerID: d.Command.PartnerID, ActID: d.Command.Value, AwardedAt: d.DecisionAt})
	if e != nil {
		return facts, false, e
	}
	if !inserted {
		return facts, false, lib.ErrActAwarded
	}
	return facts.AwardAct(act, d.DecisionAt)
}
