package stockruntime

import (
	"context"
	"net/http"

	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	d "gxb.local/backend/v2/internal/domain/heroassets"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// HeroAssetsMIDs are the I9-11A skill-point commands. MIDs 39, 53 and 88 keep
// their existing hero dispatcher cases.
var HeroAssetsMIDs = []uint16{90, 99}

type HeroAssetsPort interface {
	SkillPointBuy(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	UseSkillPointItem(context.Context, identity.ActorContext, int64, int64, operation.Context) (map[string]any, error)
}

// HeroAssetsDispatcher answers I9_11A C5 (MID 99) and C6 (MID 90).
type HeroAssetsDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   HeroAssetsPort
}

func (o HeroAssetsDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failureReply(defect(nil))
	}
	p, op := req.Envelope.Params, req.Envelope.Operation
	switch req.Envelope.MID {
	case 99:
		if !onlyStockGameplayParams(p) {
			return heroAssetsMalformed()
		}
		body, err := o.Service.SkillPointBuy(ctx, a, op)
		return heroAssetsReply(body, err)
	case 90:
		itemID, firstErr := requiredInt64(p, "item_id")
		num, secondErr := requiredInt64(p, "item_num")
		if firstErr != nil || secondErr != nil || itemID <= 0 || num <= 0 || !onlyStockGameplayParams(p, "item_id", "item_num") {
			return heroAssetsMalformed()
		}
		body, err := o.Service.UseSkillPointItem(ctx, a, itemID, num, op)
		return heroAssetsReply(body, err)
	}
	return failureReply(refusal(unprovenRefusalCode))
}

func heroAssetsMalformed() httpedge.Response {
	return failureReply(malformed("hero_assets_invalid_parameter"))
}

var heroAssetsFailureRows = []failureRow{
	{match: d.ErrInvalid, class: failureMalformed, detail: "hero_assets_invalid_parameter"},
	{match: d.ErrRefused, class: failureRefusal, code: unprovenRefusalCode},
	{match: d.ErrVipRequired, class: failureRefusal, code: unprovenRefusalCode},
	{match: d.ErrUnsupportedItem, class: failureRefusal, code: unprovenRefusalCode},
	{match: d.ErrStaleState, class: failureRefusal, code: staleConflictCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
	{match: d.ErrUnavailable, class: failureUnavailable},
}

func heroAssetsReply(body map[string]any, err error) httpedge.Response {
	if err == nil {
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: body}
	}
	return failureFromRows(heroAssetsFailureRows, err)
}
