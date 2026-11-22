package stockruntime

import (
	"context"
	app "gxb.local/backend/v2/internal/application/bookskill"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	book "gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/economy"
	ec "gxb.local/backend/v2/internal/domain/eventcentre"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type BookPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Read(context.Context, identity.ActorContext, uint16, operation.Context) (map[string]any, error)
	OwnsComposeItem(context.Context, int64, operation.Context) (bool, error)
}
type BookDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   BookPort
	Tracker   *lobby.BootTracker
}

func (d BookDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failureReply(defect(nil))
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
		if mid == 1056 && d.Tracker != nil {
			_ = d.Tracker.Record(d.Tracker.Correlate(lobby.BootEvent{MID: 1056, Kind: lobby.BootLegitTimer, Phase: lobby.PhaseClientRequestObserved, At: req.Envelope.ReceivedAt}, a.SessionID.UUID().String(), a.ContextID.UUID().String(), ""))
		}
		return okI5(body)
	}
	var e error
	if c.Family == app.Start || c.Family == app.Cancel || c.Family == app.Speed || c.Family == app.Confirm {
		c.Type, e = requiredInt64(p, "type")
	} else if c.Family == app.Learn || c.Family == app.GiveUp || c.Family == app.SpeedSkill {
		c.SkillID, e = requiredInt64(p, "skill_id")
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

// The EventCentre rows below carry the same class and code as
// eventcentre_dispatcher.go:182,184 so MID 1056/1059 agree with MID 1074.
var bookFailureRows = []failureRow{
	{match: app.ErrRejected, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrStale, class: failureRefusal, code: staleConflictCode},
	{match: book.ErrInvalid, class: failureRefusal, code: unprovenRefusalCode},
	{match: book.ErrUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: book.ErrStaleTime, class: failureRefusal, code: staleConflictCode},
	{match: ec.ErrUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: ec.ErrStaleTime, class: failureRefusal, code: staleConflictCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
}

func failBook(e error) httpedge.Response {
	return failureFromRows(bookFailureRows, e)
}
