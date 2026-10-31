package adventure

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/operation"
)

// BuyShop answers 2418: the event's shop row is priced from the catalog, the
// crystal debit and item grant go through I5, and the reply carries the
// decorator's economy delta. A repeated terminal is a duplicate.
func (s Mode) BuyShop(c context.Context, a identity.ActorContext, tableID int64, op operation.Context) (Response, error) {
	var duplicate bool
	body, err := s.run(c, a, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog, _ illusion.Catalog) (map[string]any, error) {
		occurrence, err := s.buyableOccurrence(c, sc, a, d.EventShop, tableID, &duplicate)
		if err != nil || duplicate {
			return map[string]any{}, err
		}
		item, ok := catalog.ShopEntry(tableID)
		if !ok || item.Item <= 0 || item.Price <= 0 {
			return nil, d.ErrInvalid
		}
		if err = s.debitCrystal(c, sc, a, item.Price); err != nil {
			return nil, err
		}
		if err = s.settleGrant(c, sc, a, "buy_shop", occurrence, []grant.Line{{Kind: grant.StackItem, ItemID: item.Item, Amount: 1}}); err != nil {
			return nil, err
		}
		return s.finishBuy(c, sc, a, occurrence, &duplicate)
	})
	return Response{Body: body, Duplicate: duplicate}, err
}

// BuyCard answers 2420: the card's hero is acquired through the Character
// owner (or its fragments when already owned), debited through I5 and the
// award row is in the reply.
func (s Mode) BuyCard(c context.Context, a identity.ActorContext, tableID int64, op operation.Context) (Response, error) {
	var duplicate bool
	body, err := s.run(c, a, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog, _ illusion.Catalog) (map[string]any, error) {
		occurrence, err := s.buyableOccurrence(c, sc, a, d.EventSummon, tableID, &duplicate)
		if err != nil || duplicate {
			return map[string]any{}, err
		}
		card, ok := catalog.CardEntry(tableID)
		if !ok || card.Item <= 0 || card.Price <= 0 {
			return nil, d.ErrInvalid
		}
		revision, _ := sc.Operation.Operation().Policies.Get("content")
		hero, proof, err := s.Partners.AwardStoryPartnerTx(c, sc.Tx, a.PlayerID, card.Item, revision, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		awards := []any{}
		if proof != nil {
			row, err := s.HeroWire(hero)
			if err != nil {
				return nil, err
			}
			row["is_partner"] = true
			awards = append(awards, row)
		} else {
			fragments, err := s.cardFragments(c, sc, card.Item, revision)
			if err != nil {
				return nil, err
			}
			awards = append(awards, map[string]any{"table_id": fragments.ItemID, "item_num": fragments.Amount, "to_stone": true})
			if err = s.settleGrant(c, sc, a, "buy_card_fragments", occurrence, []grant.Line{{Kind: grant.StackItem, ItemID: fragments.ItemID, Amount: fragments.Amount}}); err != nil {
				return nil, err
			}
		}
		if err = s.debitCrystal(c, sc, a, card.Price); err != nil {
			return nil, err
		}
		body, err := s.finishBuy(c, sc, a, occurrence, &duplicate)
		if err != nil {
			return nil, err
		}
		body["awards"] = awards
		return body, nil
	})
	return Response{Body: body, Duplicate: duplicate}, err
}

type fragmentAward struct {
	ItemID int64
	Amount int64
}

func (s Mode) cardFragments(c context.Context, sc gen.TimedScope, tableID int64, revision string) (fragmentAward, error) {
	catalog, err := s.Content.SummonCatalogTx(c, sc.Tx, revision)
	if err != nil {
		return fragmentAward{}, err
	}
	fragments, err := catalog.Fragments(tableID)
	if err != nil || fragments[0] <= 0 || fragments[1] <= 0 {
		return fragmentAward{}, d.ErrRefused
	}
	return fragmentAward{ItemID: fragments[0], Amount: fragments[1]}, nil
}

func (s Mode) buyableOccurrence(c context.Context, sc gen.TimedScope, a identity.ActorContext, eventType, tableID int64, duplicate *bool) (d.Occurrence, error) {
	at := sc.Operation.DecisionAt()
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, sc.Tx, a.PlayerID, eventType)
	if err != nil {
		return d.Occurrence{}, err
	}
	if !found {
		return d.Occurrence{}, d.ErrExpired
	}
	if occurrence.Finished() {
		*duplicate = true
		return d.Occurrence{}, nil
	}
	if !occurrence.Active(at) {
		return d.Occurrence{}, d.ErrExpired
	}
	if occurrence.SpecialData != tableID {
		return d.Occurrence{}, d.ErrInvalid
	}
	return occurrence, nil
}

func (s Mode) finishBuy(c context.Context, sc gen.TimedScope, a identity.ActorContext, occurrence d.Occurrence, duplicate *bool) (map[string]any, error) {
	finished, err := s.finish(c, sc.Tx, a, occurrence, sc.Operation.DecisionAt())
	if err != nil {
		return nil, err
	}
	if !finished {
		*duplicate = true
	}
	return map[string]any{}, nil
}
