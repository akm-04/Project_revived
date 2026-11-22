package stockruntime

import (
	"context"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	dormdomain "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// EquipmentComposePort is the Character-owned MID 83 equipment category.
type EquipmentComposePort interface {
	ComposeEquipmentItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
}

// FurnitureComposePort is the Dorm-owned MID 83 furniture and blueprint
// category. Membership in the recipe set, never item type, claims the id.
type FurnitureComposePort interface {
	OwnsFurnitureComposeItem(context.Context, int64, operation.Context) (bool, error)
	ComposeFurnitureItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
}

// AwakeningComposePort is the Character-owned MID 83 awakening material
// category claimed by a compiled recipe on a consumable source item.
type AwakeningComposePort interface {
	OwnsAwakeningComposeItem(context.Context, int64, operation.Context) (bool, error)
	ComposeAwakeningItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
}

// ComposeDispatcher routes MID 83 by the server-qualified recipe owner: Book,
// then Dorm furniture/blueprint, then the Character owner's awakening material
// category, then its CA4-1 equipment recipe graph.
type ComposeDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Book      BookPort
	Furniture FurnitureComposePort
	Awakening AwakeningComposePort
	Equipment EquipmentComposePort
}

func (d ComposeDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Book == nil || d.Furniture == nil || d.Awakening == nil || d.Equipment == nil {
		return failureReply(defect(nil))
	}
	if req.Envelope.MID != 83 {
		return badHero("unsupported_compose_mid")
	}
	p := req.Envelope.Params
	if !onlyStockGameplayParams(p, "item_id", "item_num") {
		return badHero("invalid_compose_parameter")
	}
	itemID, err := requiredInt64(p, "item_id")
	if err != nil || itemID <= 0 {
		return badHero("invalid_compose_request")
	}
	amount := int64(1)
	if _, present := p["item_num"]; present {
		amount, err = requiredInt64(p, "item_num")
	}
	if err != nil || amount <= 0 {
		return badHero("invalid_compose_request")
	}
	owned, err := d.Book.OwnsComposeItem(ctx, itemID, req.Envelope.Operation)
	if err != nil {
		return failBook(err)
	}
	if owned {
		result, err := d.Book.Command(ctx, a, appbook.Command{Family: appbook.Compose, ItemID: itemID, Amount: amount}, req.Envelope.Operation)
		if err != nil {
			return failBook(err)
		}
		return okI5(result.Body)
	}
	owned, err = d.Furniture.OwnsFurnitureComposeItem(ctx, itemID, req.Envelope.Operation)
	if err != nil {
		return failFurnitureCompose(err)
	}
	if owned {
		body, err := d.Furniture.ComposeFurnitureItem(ctx, a, itemID, amount, req.Envelope.Operation)
		if err != nil {
			return failFurnitureCompose(err)
		}
		return okI5(body)
	}
	owned, err = d.Awakening.OwnsAwakeningComposeItem(ctx, itemID, req.Envelope.Operation)
	if err != nil {
		return failAwakeningCompose(err)
	}
	if owned {
		body, err := d.Awakening.ComposeAwakeningItem(ctx, a, itemID, amount, req.Envelope.Operation)
		if err != nil {
			return failAwakeningCompose(err)
		}
		return okI5(body)
	}
	body, err := d.Equipment.ComposeEquipmentItem(ctx, a, itemID, amount, req.Envelope.Operation)
	if err != nil {
		return failEquipmentCompose(err)
	}
	return okI5(body)
}

var furnitureComposeFailureRows = []failureRow{
	{match: appdorm.ErrFurnitureComposeUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: appdorm.ErrFurnitureBlueprintNotOwned, class: failureRefusal, code: unprovenRefusalCode},
	{match: appdorm.ErrFurnitureLevelTooLow, class: failureRefusal, code: unprovenRefusalCode},
	{match: dormdomain.ErrUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

func failFurnitureCompose(err error) httpedge.Response {
	return failureFromRows(furnitureComposeFailureRows, err)
}

var awakeningComposeFailureRows = []failureRow{
	{match: apphero.ErrAwakeningComposeUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

func failAwakeningCompose(err error) httpedge.Response {
	return failureFromRows(awakeningComposeFailureRows, err)
}

var equipmentComposeFailureRows = []failureRow{
	{match: apphero.ErrEquipmentComposeUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

func failEquipmentCompose(err error) httpedge.Response {
	return failureFromRows(equipmentComposeFailureRows, err)
}
