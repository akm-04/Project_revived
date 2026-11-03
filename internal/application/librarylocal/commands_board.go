package librarylocal

import (
	"context"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// boardTx validates the selected card and model against the actor's Hero and
// skin ownership, then stores the board selection on the player root.
func (s Service) boardTx(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, hero character.Hero, root lib.PlayerFacts) (lib.PlayerFacts, error) {
	card, model := d.Command.Value, d.Command.SelectID
	if hero.PlayerID != a.PlayerID || hero.PartnerID != d.Command.PartnerID {
		return root, lib.ErrUnqualified
	}
	if card == lib.CardAwake && hero.TableID == hero.OriginTableID {
		return root, lib.ErrUnqualified
	}
	if card == lib.CardSkin {
		if s.Skins == nil {
			return root, ErrUnavailable
		}
		entitlements, e := s.Skins.ListHeroSkinEntitlementsTx(ctx, t, a.PlayerID, hero.PartnerID)
		if e != nil {
			return root, e
		}
		owned := false
		for _, entitlement := range entitlements {
			if entitlement.ModelID == model && entitlement.EffectiveAt(d.DecisionAt) {
				owned = true
				break
			}
		}
		if !owned {
			return root, lib.ErrUnqualified
		}
	}
	next, changed, e := root.SetBoard(hero.PartnerID, card, model, d.DecisionAt)
	if e != nil {
		return root, e
	}
	if !changed {
		return next, nil
	}
	if e = s.Library.SavePlayerTx(ctx, t, next, root.StateVersion); e != nil {
		return root, e
	}
	return next, nil
}
