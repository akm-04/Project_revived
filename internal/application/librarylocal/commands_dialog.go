package librarylocal

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// readDialogTx marks one statically opened dialog read. Contextual dialog rows
// (event/choice/gift) are accepted once their own row exists.
func (s Service) readDialogTx(ctx context.Context, t tx.Tx, d Admission, catalog lib.Catalog, rule lib.TemplateRule, facts lib.HeroFacts) (lib.DialogFact, error) {
	if !rule.DialogEnabled {
		return lib.DialogFact{}, lib.ErrDialogClosed
	}
	existing, found, e := s.Library.ReadDialogTx(ctx, t, identity.PlayerID(d.Actor.Player), d.Command.PartnerID, d.Command.Value)
	if e != nil {
		return lib.DialogFact{}, e
	}
	if !found && !catalog.DialogOpened(d.Command.Value, facts.Favor, facts.Married) {
		return lib.DialogFact{}, lib.ErrDialogClosed
	}
	dialog := lib.DialogFact{PlayerID: identity.PlayerID(d.Actor.Player), PartnerID: d.Command.PartnerID, DialogID: d.Command.Value, IsRead: true, UpdatedAt: d.DecisionAt}
	if !found {
		return dialog, s.Library.SaveDialogTx(ctx, t, dialog)
	}
	dialog = existing
	if dialog.IsRead {
		return dialog, nil
	}
	dialog.IsRead = true
	dialog.UpdatedAt = d.DecisionAt
	return dialog, s.Library.SaveDialogTx(ctx, t, dialog)
}
