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
		return s.buy(c, sc, a, catalog, d.EventShop, tableID, func(item d.ShopItem) ([]any, []grant.Line) {
			return nil, []grant.Line{{Kind: grant.StackItem, ItemID: item.Item, Amount: 1}}
		}, &duplicate)
	})
	return Response{Body: body, Duplicate: duplicate}, err
}

// BuyCard answers 2420: the card row's hero is granted as a partner entity
// through I5 and the reply carries the award row.
func (s Mode) BuyCard(c context.Context, a identity.ActorContext, tableID int64, op operation.Context) (Response, error) {
	var duplicate bool
	body, err := s.run(c, a, op, func(c context.Context, sc gen.TimedScope, catalog d.Catalog, _ illusion.Catalog) (map[string]any, error) {
		return s.buy(c, sc, a, catalog, d.EventSummon, tableID, func(item d.ShopItem) ([]any, []grant.Line) {
			return []any{map[string]any{"table_id": item.Item, "item_num": int64(1)}}, []grant.Line{{Kind: grant.PartnerEntity, ItemID: item.Item, Amount: 1}}
		}, &duplicate)
	})
	return Response{Body: body, Duplicate: duplicate}, err
}

func (s Mode) buy(c context.Context, sc gen.TimedScope, a identity.ActorContext, catalog d.Catalog, eventType, tableID int64, build func(d.ShopItem) ([]any, []grant.Line), duplicate *bool) (map[string]any, error) {
	at := sc.Operation.DecisionAt()
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, sc.Tx, a.PlayerID, eventType)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, d.ErrExpired
	}
	if occurrence.Finished() {
		*duplicate = true
		return map[string]any{}, nil
	}
	if !occurrence.Active(at) {
		return nil, d.ErrExpired
	}
	if occurrence.SpecialData != tableID {
		return nil, d.ErrInvalid
	}
	var price int64
	var item d.ShopItem
	if eventType == d.EventShop {
		item, _ = catalog.ShopEntry(tableID)
		price, _ = catalog.ShopPrice(tableID)
	} else {
		card, ok := catalog.CardEntry(tableID)
		if !ok {
			return nil, d.ErrInvalid
		}
		item, price = d.ShopItem{ID: card.ID, Item: card.Item, Price: card.Price, Rate: card.Rate}, card.Price
	}
	if item.Item <= 0 || price <= 0 {
		return nil, d.ErrInvalid
	}
	if err = s.debitCrystal(c, sc, a, price); err != nil {
		return nil, err
	}
	awards, grantLines := build(item)
	if len(grantLines) > 0 {
		if err = s.settleGrant(c, sc, a, "buy_"+eventTypeName(eventType), occurrence, grantLines); err != nil {
			return nil, err
		}
	}
	finished, err := s.finish(c, sc.Tx, a, occurrence, at)
	if err != nil {
		return nil, err
	}
	if !finished {
		*duplicate = true
		return map[string]any{}, nil
	}
	if awards == nil {
		return map[string]any{}, nil
	}
	return map[string]any{"awards": awards}, nil
}

func eventTypeName(eventType int64) string {
	if eventType == d.EventSummon {
		return "card"
	}
	return "shop"
}
