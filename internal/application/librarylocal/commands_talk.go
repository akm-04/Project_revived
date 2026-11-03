package librarylocal

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// talkAwardTx applies one 843 request. A choice records select_id; a reward
// choice or the dialog-end call claims the dialog's amour_reward once.
func (s Service) talkAwardTx(ctx context.Context, t tx.Tx, d Admission, catalog lib.Catalog, rule lib.TemplateRule, facts lib.HeroFacts) (lib.HeroFacts, bool, lib.DialogFact, error) {
	var dialog lib.DialogFact
	if !rule.DialogEnabled {
		return facts, false, dialog, lib.ErrUnqualified
	}
	config, ok := catalog.DialogConfigs[d.Command.Value]
	if !ok {
		return facts, false, dialog, lib.ErrUnqualified
	}
	existing, found, e := s.Library.ReadDialogTx(ctx, t, identity.PlayerID(d.Actor.Player), d.Command.PartnerID, d.Command.Value)
	if e != nil {
		return facts, false, dialog, e
	}
	if !found && !config.Contextual() && !catalog.DialogOpened(d.Command.Value, facts.Favor, facts.Married) {
		return facts, false, dialog, lib.ErrDialogClosed
	}
	dialog = lib.DialogFact{PlayerID: identity.PlayerID(d.Actor.Player), PartnerID: d.Command.PartnerID, DialogID: d.Command.Value, IsRead: true, UpdatedAt: d.DecisionAt}
	if found {
		dialog = existing
	}
	claim := !d.Command.HasSelect || d.Command.IsReward
	selectID := int64(0)
	if d.Command.HasSelect {
		selectID = d.Command.SelectID
	}
	next, changed, e := dialog.RecordTalk(claim, selectID, d.DecisionAt)
	if e != nil {
		return facts, false, dialog, e
	}
	readChanged := false
	if !next.IsRead {
		next.IsRead, next.UpdatedAt, readChanged = true, d.DecisionAt, true
	}
	hero, favorChanged := facts, false
	if changed && claim {
		hero, favorChanged, e = facts.RaiseFavor(config.AmourReward, d.DecisionAt)
		if e != nil {
			return facts, false, dialog, e
		}
	}
	if changed || readChanged {
		if e = s.Library.SaveDialogTx(ctx, t, next); e != nil {
			return facts, false, dialog, e
		}
	}
	return hero, favorChanged, next, nil
}
