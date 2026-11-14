package stockruntime

import (
	"context"
	"errors"

	guildwire "gxb.local/backend/v2/internal/adapters/guildwire"
	"gxb.local/backend/v2/internal/application/guildtea"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// GuildTeaMIDs are the stock Tea Party callbacks (I9_GUILD_ACTIVITY_V1 C13).
var GuildTeaMIDs = []uint16{1808, 1809, 1810, 1811}

type GuildTeaPort interface {
	Info(context.Context, identity.ActorContext, operation.Context, bool) (guildtea.State, error)
	Request(context.Context, identity.ActorContext, int64, operation.Context) (guildtea.State, error)
	Present(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (guildtea.State, error)
	Confirm(context.Context, identity.ActorContext, operation.Context) (guildtea.State, error)
}

type GuildTeaDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   GuildTeaPort
}

func (d GuildTeaDispatcher) Dispatch(c context.Context, r httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(c, r)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failureReply(defect(nil))
	}
	p, op := r.Envelope.Params, r.Envelope.Operation
	var state guildtea.State
	var err error
	switch r.Envelope.MID {
	case 1808:
		if !onlyStockGameplayParams(p, "is_self") {
			return teaBad()
		}
		selfOnly := false
		if raw, ok := p["is_self"]; ok && raw != nil {
			value, e := requiredInt64(p, "is_self")
			if e != nil {
				return teaBad()
			}
			selfOnly = value == 1
		}
		state, err = d.Service.Info(c, a, op, selfOnly)
	case 1809:
		if !onlyStockGameplayParams(p, "item_id") {
			return teaBad()
		}
		itemID, e := requiredInt64(p, "item_id")
		if e != nil || itemID <= 0 {
			return teaBad()
		}
		state, err = d.Service.Request(c, a, itemID, op)
	case 1810:
		if !onlyStockGameplayParams(p, "player_id") {
			return teaBad()
		}
		playerID, e := requiredInt64(p, "player_id")
		if e != nil || playerID <= 0 {
			return teaBad()
		}
		state, err = d.Service.Present(c, a, identity.PlayerID(playerID), op)
	case 1811:
		if !onlyStockGameplayParams(p) {
			return teaBad()
		}
		state, err = d.Service.Confirm(c, a, op)
	default:
		return failureReply(refusal(unprovenRefusalCode))
	}
	if err != nil {
		return teaFailure(err)
	}
	return okI5(guildwire.Tea(state))
}

func teaBad() httpedge.Response {
	return failureReply(malformed("guild_tea_invalid_parameter"))
}

var teaFailureRows = []failureRow{
	{match: guildtea.ErrNotInGuild, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildtea.ErrAlreadyWished, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildtea.ErrNoWish, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildtea.ErrWishFull, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildtea.ErrAlreadyDonated, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildtea.ErrSelfDonation, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildtea.ErrNotOwner, class: failureRefusal, code: unprovenRefusalCode},
	{match: guildtea.ErrUnknownScroll, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

// teaFailure refuses with 409: Backend.lua hands any 200 body to the success
// callback, which indexes self_wish_info/gift_list/wish_list (F4/D370).
func teaFailure(err error) httpedge.Response {
	if errors.Is(err, guildtea.ErrInvalid) {
		return teaBad()
	}
	if classified := classifyFailure(teaFailureRows, err); classified != nil {
		return failureReply(classified)
	}
	return failureFromRows(nil, err)
}
