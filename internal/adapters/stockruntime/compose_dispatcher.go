package stockruntime

import (
	"context"

	appbook "gxb.local/backend/v2/internal/application/bookskill"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// EquipmentComposePort is the Character-owned MID 83 equipment category.
type EquipmentComposePort interface {
	ComposeEquipmentItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
}

// ComposeDispatcher routes MID 83 by the server-qualified recipe owner. Book
// composition keeps the Book owner; hero equipment composition runs through
// the Character owner's CA4-1 recipe graph. Any other category (furniture,
// activity, unknown) is refused by the equipment owner before mutation.
type ComposeDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Book      BookPort
	Equipment EquipmentComposePort
}

func (d ComposeDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Book == nil || d.Equipment == nil {
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
	body, err := d.Equipment.ComposeEquipmentItem(ctx, a, itemID, amount, req.Envelope.Operation)
	if err != nil {
		return failEquipmentCompose(err)
	}
	return okI5(body)
}

var equipmentComposeFailureRows = []failureRow{
	{match: apphero.ErrEquipmentComposeUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

func failEquipmentCompose(err error) httpedge.Response {
	return failureFromRows(equipmentComposeFailureRows, err)
}
