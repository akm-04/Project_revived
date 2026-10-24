package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/bookskill"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type BookPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Read(context.Context, identity.ActorContext, uint16, operation.Context) (map[string]any, error)
}
type BookDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   BookPort
}

func (d BookDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failBook(app.ErrUnavailable)
	}
	p := req.Envelope.Params
	mid := req.Envelope.MID
	c := app.Command{}
	var allowed []string
	switch mid {
	case 1056, 1059:
	case 1057, 1058, 1077, 1080:
		allowed = []string{"type"}
		c.Family = map[uint16]string{1057: app.Start, 1058: app.Cancel, 1077: app.Speed, 1080: app.Confirm}[mid]
	case 1060, 1061, 1078:
		allowed = []string{"skill_id"}
		c.Family = map[uint16]string{1060: app.Learn, 1061: app.GiveUp, 1078: app.SpeedSkill}[mid]
	case 1079:
		c.Family = app.ConfirmSkill
	case 83:
		allowed = []string{"item_id", "item_num"}
		c.Family = app.Compose
	default:
		return badHero("unsupported_book_mid")
	}
	if !onlyStockGameplayParams(p, allowed...) {
		return badHero("invalid_book_parameter")
	}
	if mid == 1056 || mid == 1059 {
		body, e := d.Service.Read(ctx, a, mid, req.Envelope.Operation)
		if e != nil {
			return failBook(e)
		}
		return okI5(body)
	}
	var e error
	if c.Family == app.Start || c.Family == app.Cancel || c.Family == app.Speed || c.Family == app.Confirm {
		c.Type, e = requiredInt64(p, "type")
	} else if c.Family == app.Learn || c.Family == app.GiveUp || c.Family == app.SpeedSkill {
		c.SkillID, e = requiredInt64(p, "skill_id")
	} else if c.Family == app.Compose {
		c.ItemID, e = requiredInt64(p, "item_id")
		if e == nil {
			if _, ok := p["item_num"]; ok {
				c.Amount, e = requiredInt64(p, "item_num")
			} else {
				c.Amount = 1
			}
		}
	}
	if e != nil || c.Validate() != nil {
		return badHero("invalid_book_request")
	}
	r, e := d.Service.Command(ctx, a, c, req.Envelope.Operation)
	if e != nil {
		return failBook(e)
	}
	return okI5(r.Body)
}
func failBook(e error) httpedge.Response {
	if errors.Is(e, app.ErrRejected) || errors.Is(e, book.ErrInvalid) || errors.Is(e, economy.ErrInsufficientBalance) {
		return badHero("book_command_rejected")
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: e, Body: map[string]any{"error": "book_unavailable_or_unresolved"}}
}
