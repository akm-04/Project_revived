package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/course"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

type CoursePort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Read(context.Context, identity.ActorContext, uint16, operation.Context) (map[string]any, error)
}
type CourseDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   CoursePort
}

func (d CourseDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failCourse(app.ErrUnavailable)
	}
	p := req.Envelope.Params
	mid := req.Envelope.MID
	c := app.Command{}
	var allowed []string
	switch mid {
	case 2130, 2137, 2139:
	case 2500:
		allowed = []string{"table_id"}
	case 2129, 2135, 2136, 2138:
		allowed = []string{"partner_id"}
		c.Family = map[uint16]string{2129: app.Collect, 2135: app.Enter, 2136: app.Leave, 2138: app.Cancel}[mid]
	case 2128, 2131, 2132, 2134, 2142:
		allowed = []string{"partner_id", "course_id"}
		c.Family = map[uint16]string{2128: app.Apply, 2131: app.Study, 2132: app.Speed, 2134: app.Forget, 2142: app.Continue}[mid]
	case 2133:
		allowed = []string{"partner_id", "course_id", "skill_index"}
		c.Family = app.Bind
	case 2140:
		allowed = []string{"partner_id", "course_id", "item_id", "item_num", "total_num"}
		c.Family = app.Proficiency
	case 2141:
		allowed = []string{"item_id"}
		c.Family = app.GiftBox
	default:
		return badHero("unsupported_course_mid")
	}
	if !onlyStockGameplayParams(p, allowed...) {
		return badHero("invalid_course_parameter")
	}
	if c.Family == "" {
		if mid == 2500 {
			if tableID, e := requiredInt64(p, "table_id"); e != nil || tableID <= 0 {
				return badHero("invalid_course_parameter")
			}
		}
		body, e := d.Service.Read(ctx, a, mid, req.Envelope.Operation)
		if e != nil {
			return failCourse(e)
		}
		return okI5(body)
	}
	var e error
	if c.Family == app.GiftBox {
		c.ItemID, e = requiredInt64(p, "item_id")
	} else {
		c.PartnerID, e = requiredInt64(p, "partner_id")
		if e == nil {
			if _, ok := p["course_id"]; ok {
				c.CourseID, e = requiredInt64(p, "course_id")
			}
		}
		if e == nil && c.Family == app.Bind {
			c.SkillID, e = requiredInt64(p, "skill_index")
		}
		if e == nil && c.Family == app.Proficiency {
			c.ItemID, e = requiredInt64(p, "item_id")
			if e == nil {
				c.Amount, e = requiredInt64(p, "item_num")
			}
			if e == nil {
				c.Total, e = requiredInt64(p, "total_num")
			}
		}
	}
	if e != nil || c.Validate() != nil {
		return badHero("invalid_course_request")
	}
	r, e := d.Service.Command(ctx, a, c, req.Envelope.Operation)
	if e != nil {
		return failCourse(e)
	}
	return okI5(r.Body)
}
func failCourse(e error) httpedge.Response {
	if errors.Is(e, app.ErrRejected) || errors.Is(e, app.ErrStale) || errors.Is(e, app.ErrRetired) || errors.Is(e, app.ErrActor) || errors.Is(e, course.ErrInvalid) || errors.Is(e, course.ErrUnqualified) || errors.Is(e, course.ErrStaleTime) || errors.Is(e, economy.ErrInsufficientBalance) {
		return conflictRefusal(1)
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: e, Body: map[string]any{"error": "course_unavailable_or_unresolved"}}
}
