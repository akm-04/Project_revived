package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	i5 "gxb.local/backend/v2/internal/application/i5"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type DormPort interface {
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	Read(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64) (map[string]any, error)
	SocialRead(context.Context, identity.ActorContext, operation.Context, uint16, int64, int64, int64, int64) (map[string]any, error)
}
type DormDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   DormPort
}

func (d DormDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
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
	case 1845:
		c.Family = app.BuyGlue
	case 2512:
		allowed = []string{"host_id"}
	case 2514:
		allowed = []string{"host_id", "house_id"}
	case 2518:
		allowed = []string{"house_id", "house_name"}
		c.Family = app.ChangeName
	case 2519:
	case 2520:
		allowed = []string{"house_id"}
		c.Family = app.HideHouse
	case 2521:
		allowed = []string{"host_id", "house_id"}
		c.Family = app.PraiseHouse
	case 2522:
		allowed = []string{"house_id", "start", "offset", "total_num"}
	case 2523:
		allowed = []string{"host_id", "house_id", "content"}
		c.Family = app.CommentHouse
	case 2524:
		allowed = []string{"host_id", "house_id", "start", "offset", "comment_num", "total_num"}
	case 2525:
		allowed = []string{"host_id", "house_id", "comment_id"}
		c.Family = app.PraiseComment
	case 2526:
		allowed = []string{"house_id", "comment_id"}
		c.Family = app.DeleteComment
	case 2513:
		allowed = []string{"key_item", "floor", "pos"}
		c.Family = app.Open
	case 2515:
		allowed = []string{"house_id", "furniture_record"}
		c.Family = app.Save
	case 2516:
		allowed = []string{"house_id", "index"}
		c.Family = app.Equip
	case 2517:
		allowed = []string{"house_id", "partner_ids"}
		c.Family = app.Enter
	case 2693:
		allowed = []string{"item_id", "item_num"}
		c.Family = app.Exchange
	case 2694:
		allowed = []string{"house_id"}
		c.Family = app.Start
	case 2695:
		allowed = []string{"house_id"}
		c.Family = app.Finish
	default:
		return badHero("unsupported_dorm_mid")
	}
	if !onlyStockGameplayParams(p, allowed...) {
		return badHero("invalid_dorm_params")
	}
	var e error
	get := func(key string) int64 {
		v, err := requiredInt64(p, key)
		if err != nil {
			e = err
		}
		return v
	}
	if mid == 2519 {
		body, err := d.Service.SocialRead(ctx, a, req.Envelope.Operation, mid, 0, 0, 0, 1)
		if err != nil {
			return failSocialDorm(err)
		}
		return httpedge.Response{HTTPStatus: 200, Body: body}
	}
	if mid == 2522 || mid == 2524 {
		c.HouseID = get("house_id")
		host := int64(0)
		if mid == 2524 {
			if _, ok := p["host_id"]; ok {
				host = get("host_id")
				if host <= 0 {
					return badHero("invalid_dorm_social_host")
				}
			}
		}
		start := get("start")
		offset := get("offset")
		if e != nil {
			return badHero("invalid_dorm_social_page")
		}
		body, err := d.Service.SocialRead(ctx, a, req.Envelope.Operation, mid, host, c.HouseID, start, offset)
		if err != nil {
			return failSocialDorm(err)
		}
		return httpedge.Response{HTTPStatus: 200, Body: body}
	}
	if mid != 1845 && mid != 2512 && mid != 2513 && mid != 2693 {
		c.HouseID = get("house_id")
	}
	if mid == 2512 || mid == 2514 {
		host := int64(0)
		if _, ok := p["host_id"]; ok {
			host = get("host_id")
			if host <= 0 {
				return badHero("invalid_dorm_host")
			}
		}
		if e != nil {
			return badHero("invalid_dorm_read")
		}
		body, e := d.Service.Read(ctx, a, req.Envelope.Operation, mid, host, c.HouseID)
		if e != nil {
			return failDorm(e)
		}
		return httpedge.Response{HTTPStatus: 200, Body: body}
	}
	switch mid {
	case 2518:
		value, err := requiredDormString(p, "house_name")
		if err != nil {
			return badHero("invalid_dorm_social_name")
		}
		c.HouseName = value
	case 2521, 2523, 2525:
		c.HostID = get("host_id")
		if mid == 2523 {
			value, err := requiredDormString(p, "content")
			if err != nil {
				return badHero("invalid_dorm_social_content")
			}
			c.Content = value
		}
		if mid == 2525 {
			c.CommentID = get("comment_id")
		}
	case 2526:
		c.CommentID = get("comment_id")
	case 2513:
		c.ItemID = get("key_item")
		c.Floor = get("floor")
		c.Position = get("pos")
	case 2516:
		c.Index = get("index")
	case 2693:
		c.ItemID = get("item_id")
		c.Amount = get("item_num")
	case 2515:
		furniture, err := stockFurnitureRecord(p["furniture_record"])
		if err != nil {
			return badHero("invalid_dorm_layout")
		}
		c.Furniture = furniture
	case 2517:
		raw, err := json.Marshal(p["partner_ids"])
		if err != nil {
			return badHero("invalid_dorm_residents")
		}
		if err = json.Unmarshal(raw, &c.Partners); err != nil || c.Partners == nil {
			return badHero("invalid_dorm_residents")
		}
	}
	if e != nil || c.Validate() != nil {
		return badHero("invalid_dorm_command")
	}
	out, e := d.Service.Command(ctx, a, c, req.Envelope.Operation)
	if e != nil {
		if mid == 1845 {
			return failureFromRows(dormGlueFailureRows, e)
		}
		if mid >= 2518 && mid <= 2526 {
			return failSocialDorm(e)
		}
		response := failDorm(e)
		if key, ok := out.Body["wrong_key"].(string); ok {
			response = failureReply(malformed("dorm_unavailable"))
			response.Body["wrong_key"] = key
		}
		return response
	}
	return httpedge.Response{HTTPStatus: 200, Body: out.Body}
}

var dormGlueRefusedBody = map[string]any{"error": "dorm_glue_purchase_refused"}

// MID 1845 business refusals keep the stock refusal body; stale, transient and
// unclassified faults fall through to the shared classes.
var dormGlueFailureRows = []failureRow{
	{match: app.ErrRejected, class: failureRefusal, code: unprovenRefusalCode},
	{match: dorm.ErrGlueDailyLimit, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrStale, class: failureRefusal, code: staleConflictCode},
	{match: dorm.ErrStaleTime, class: failureRefusal, code: staleConflictCode},
	{match: i5.ErrGluePurchaseLimit, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
	{match: dorm.ErrUnqualified, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
	{match: dorm.ErrInvalidFacts, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
	{match: dorm.ErrInvalidLayout, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
	{match: dorm.ErrInUse, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
	{match: dorm.ErrCooldown, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
	{match: dorm.ErrHidden, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true, extra: dormGlueRefusedBody},
	{match: app.ErrRetired, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
	{match: app.ErrActor, class: failureRefusal, code: unprovenRefusalCode, extra: dormGlueRefusedBody},
}

var dormFailureRows = []failureRow{
	{match: dorm.ErrHidden, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrRejected, class: failureRefusal, code: unprovenRefusalCode},
	{match: dorm.ErrInvalidFacts, class: failureMalformed, detail: "dorm_unavailable"},
	{match: dorm.ErrUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: dorm.ErrInvalidLayout, class: failureMalformed, detail: "dorm_unavailable"},
	{match: dorm.ErrStaleTime, class: failureRefusal, code: staleConflictCode},
}

func failDorm(e error) httpedge.Response {
	return failureFromRows(dormFailureRows, e)
}

// Every Dorm social domain refusal is a non-200 refusal: the stock callbacks
// either mutate locally or index a nested table on any 200.
var dormSocialFailureRows = []failureRow{
	{match: app.ErrRejected, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrStale, class: failureRefusal, code: staleConflictCode},
	{match: app.ErrRetired, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrActor, class: failureRefusal, code: unprovenRefusalCode},
	{match: dorm.ErrUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: dorm.ErrInvalidFacts, class: failureMalformed, detail: "dorm_unavailable"},
	{match: dorm.ErrInvalidLayout, class: failureMalformed, detail: "dorm_unavailable"},
	{match: dorm.ErrStaleTime, class: failureRefusal, code: staleConflictCode},
	{match: dorm.ErrHidden, class: failureRefusal, code: unprovenRefusalCode},
}

func failSocialDorm(e error) httpedge.Response {
	return failureFromRows(dormSocialFailureRows, e)
}

func requiredDormString(m map[string]any, key string) (string, error) {
	value, ok := m[key]
	if !ok {
		return "", errors.New("missing " + key)
	}
	text, ok := value.(string)
	if !ok {
		return "", errors.New("invalid " + key)
	}
	return text, nil
}

// stockDormPanelCount is xyd.DormPanelType: the stock client sends
// furniture_record as its three panel tables (Floor, LeftWall, RightWall).
const stockDormPanelCount = 3

// stockFurnitureRecord flattens the stock panel-indexed furniture_record array
// into the placement map the Dorm owner stores. The client builds the array
// from a Lua table keyed 1..3, so cjson emits a JSON array of panel objects.
func stockFurnitureRecord(value any) (map[string]string, error) {
	raw, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	var panels []map[string]string
	if err = json.Unmarshal(raw, &panels); err != nil {
		return nil, err
	}
	if len(panels) != stockDormPanelCount {
		return nil, errors.New("furniture_record is not panel indexed")
	}
	flat := make(map[string]string)
	for _, panel := range panels {
		if panel == nil {
			return nil, errors.New("furniture_record panel is not an object")
		}
		for key, children := range panel {
			if _, repeated := flat[key]; repeated {
				return nil, errors.New("furniture_record repeats a placement")
			}
			flat[key] = children
		}
	}
	return flat, nil
}
