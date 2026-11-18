package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"net/http"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	app "gxb.local/backend/v2/internal/application/itemsenergy"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/itemsenergy"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// ItemsEnergyMIDs are the exclusive MID 11B commands. MIDs 28 and 29 stay on
// the campaign dispatcher except that 29 consume_id 1 enters through
// ItemsEnergyDispatcher with the campaign port as its fallback.
var ItemsEnergyMIDs = []uint16{27, 82, 86, 87, 96, 97, 241}

var ItemsEnergySharedMIDs = []uint16{28, 29}

type ItemsEnergyPort interface {
	UseEnergyItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	SellItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
	SellItems(context.Context, identity.ActorContext, []app.ItemAmount, operation.Context) (map[string]any, error)
	UseMagicItems(context.Context, identity.ActorContext, []app.ItemAmount, operation.Context) (map[string]any, error)
	EnergyBuy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	GoldenHand(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	TenfoldGoldenHand(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	ExchangeCode(context.Context, identity.ActorContext, int64, int64, int64, operation.Context) (map[string]any, error)
}

// QuickFumoPort is the fumo owner's typed seam for MID 29 consume_id 2.
type QuickFumoPort interface {
	QuickFumo(context.Context, identity.ActorContext, int64, int64, operation.Context) (apphero.QuickFumoResult, error)
}

// ItemsEnergyDispatcher answers I9_11B C1-C15. Campaign serves the shared
// trial MIDs 28 and 29 ids 3..10 unchanged; the fumo owner serves id 2.
type ItemsEnergyDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   ItemsEnergyPort
	Campaign  CampaignPort
	Fumo      QuickFumoPort
}

func (o ItemsEnergyDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failureReply(defect(nil))
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	switch req.Envelope.MID {
	case 27:
		itemID, firstErr := requiredInt64(p, "item_id")
		num, secondErr := requiredInt64(p, "item_num")
		if firstErr != nil || secondErr != nil || itemID <= 0 || num <= 0 || !onlyStockGameplayParams(p, "item_id", "item_num") {
			return itemsEnergyMalformed()
		}
		body, err := o.Service.UseEnergyItem(ctx, a, itemID, num, op)
		return itemsEnergyReply(body, err)
	case 82:
		itemID, firstErr := requiredInt64(p, "item_id")
		num, secondErr := requiredInt64(p, "item_num")
		if firstErr != nil || secondErr != nil || itemID <= 0 || num <= 0 || !onlyStockGameplayParams(p, "item_id", "item_num") {
			return itemsEnergyMalformed()
		}
		body, err := o.Service.SellItem(ctx, a, itemID, num, op)
		return itemsEnergyReply(body, err)
	case 86:
		items, err := itemsEnergyItems(p)
		if err != nil || !onlyStockGameplayParams(p, "items", "itemType") {
			return itemsEnergyMalformed()
		}
		body, commandErr := o.Service.SellItems(ctx, a, items, op)
		return itemsEnergyReply(body, commandErr)
	case 87:
		items, err := itemsEnergyItems(p)
		if err != nil || !onlyStockGameplayParams(p, "items", "itemType") {
			return itemsEnergyMalformed()
		}
		body, commandErr := o.Service.UseMagicItems(ctx, a, items, op)
		return itemsEnergyReply(body, commandErr)
	case 96:
		if !onlyStockGameplayParams(p) {
			return itemsEnergyMalformed()
		}
		body, err := o.Service.GoldenHand(ctx, a, op)
		return itemsEnergyReply(body, err)
	case 97:
		if !onlyStockGameplayParams(p) {
			return itemsEnergyMalformed()
		}
		body, err := o.Service.EnergyBuy(ctx, a, op)
		return itemsEnergyReply(body, err)
	case 241:
		itemID, firstErr := requiredInt64(p, "item_id")
		giftID, secondErr := requiredInt64(p, "gift_id")
		num := int64(1)
		if raw, present := p["num"]; present && raw != nil {
			num, _ = requiredInt64(p, "num")
		}
		if firstErr != nil || secondErr != nil || itemID <= 0 || giftID <= 0 || num <= 0 || !onlyStockGameplayParams(p, "item_id", "gift_id", "num") {
			return itemsEnergyMalformed()
		}
		body, err := o.Service.ExchangeCode(ctx, a, itemID, giftID, num, op)
		return itemsEnergyReply(body, err)
	case 28:
		if o.Campaign == nil {
			return failureReply(defect(nil))
		}
		if !onlyStockGameplayParams(p) {
			return itemsEnergyMalformed()
		}
		body, err := o.Campaign.TrialLoad(ctx, a, 28, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	case 29:
		id, valid := topFloorInteger(p, "consume_id", true)
		if !valid || id < 1 || id > 10 || !onlyStockGameplayParams(p, "consume_id", "partner_id", "equip_index") {
			return itemsEnergyMalformed()
		}
		if id == 1 {
			body, err := o.Service.TenfoldGoldenHand(ctx, a, op)
			return itemsEnergyReply(body, err)
		}
		if id == 2 {
			if o.Fumo == nil {
				return failureReply(defect(nil))
			}
			partnerID, firstErr := requiredInt64(p, "partner_id")
			equipIndex, secondErr := requiredInt64(p, "equip_index")
			if firstErr != nil || secondErr != nil || partnerID <= 0 || equipIndex < 1 || equipIndex > character.HeroEquipmentSlotCount {
				return itemsEnergyMalformed()
			}
			result, err := o.Fumo.QuickFumo(ctx, a, partnerID, equipIndex, op)
			return quickFumoReply(result, err)
		}
		if o.Campaign == nil {
			return failureReply(defect(nil))
		}
		body, err := o.Campaign.BuyTrial(ctx, a, id, op)
		if err != nil {
			return failCampaign(err)
		}
		return okI5(body)
	}
	return failureReply(refusal(unprovenRefusalCode))
}

func itemsEnergyItems(params map[string]any) ([]app.ItemAmount, error) {
	raw, present := params["items"]
	if !present || raw == nil {
		return nil, errors.New("missing items")
	}
	entries, ok := raw.([]any)
	if !ok {
		return nil, errors.New("items is not a list")
	}
	if len(entries) == 0 {
		return nil, errors.New("items is empty")
	}
	out := make([]app.ItemAmount, 0, len(entries))
	for _, entry := range entries {
		row, ok := entry.(map[string]any)
		if !ok || len(row) != 2 {
			return nil, errors.New("invalid item row")
		}
		itemID, firstErr := requiredInt64(row, "item_id")
		num, secondErr := requiredInt64(row, "item_num")
		if firstErr != nil || secondErr != nil || itemID <= 0 || num <= 0 {
			return nil, fmt.Errorf("invalid item row: %v %v", firstErr, secondErr)
		}
		out = append(out, app.ItemAmount{ItemID: itemID, Num: num})
	}
	return out, nil
}

func itemsEnergyMalformed() httpedge.Response {
	return failureReply(malformed("items_energy_invalid_parameter"))
}

// 35031 is the only message-backed refusal of this leaf: B4's stamina cap.
var itemsEnergyFailureRows = []failureRow{
	{match: d.ErrInvalid, class: failureMalformed, detail: "items_energy_invalid_parameter"},
	{match: d.ErrRefused, class: failureRefusal, code: unprovenRefusalCode},
	{match: d.ErrStaleState, class: failureRefusal, code: staleConflictCode},
	{match: app.ErrEnergyCap, class: failureRefusal, code: 35031},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
	{match: d.ErrUnavailable, class: failureUnavailable},
}

func quickFumoReply(result apphero.QuickFumoResult, err error) httpedge.Response {
	if err != nil {
		return failureFromRows(quickFumoFailureRows, err)
	}
	// MID 29's registry paths are shared by every consume_id branch; the fumo
	// client reads only fumo, so the other stock fields carry neutral values.
	return okI5(map[string]any{
		"fumo":       result.Fumo,
		"cost":       result.Cost,
		"crit":       int64(0),
		"mana":       int64(0),
		"trial_info": map[string]any{"left_times": int64(0)},
	})
}

var quickFumoFailureRows = []failureRow{
	{match: apphero.ErrHeroFumoUnavailable, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrHeroFumoContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrHeroEquipmentContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrHeroProgressionContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrHeroContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

func itemsEnergyReply(body map[string]any, err error) httpedge.Response {
	if err == nil {
		return okI5(body)
	}
	response := failureFromRows(itemsEnergyFailureRows, err)
	// C2/C3: the 409 still carries the current energy and buy counter.
	var projected *app.RefusalProjection
	if errors.As(err, &projected) && response.HTTPStatus == http.StatusConflict {
		for key, value := range projected.Body {
			response.Body[key] = value
		}
	}
	return response
}
