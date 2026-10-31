package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"strconv"
	"strings"

	app "gxb.local/backend/v2/internal/application/illusion"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// IllusionRoomMIDs are the shared team-room MIDs, served by the Illusion owner
// over the family-neutral shared room core.
var IllusionRoomMIDs = []uint16{1349, 1350, 1351, 1352, 1353, 1354, 1356, 1357, 1358, 1360, 1362, 1363}

type IllusionRoomPort interface {
	CreateRoom(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	RoomInfo(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Prepare(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	EnterRoom(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
	RemovePlayer(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	ExitRoom(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	SetPartner(context.Context, identity.ActorContext, app.PartnerRequest, operation.Context) (map[string]any, error)
	Ready(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	CancelPrepare(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	StartTeam(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	Invite(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (map[string]any, error)
	GetReport(context.Context, string, operation.Context) (map[string]any, error)
}

type IllusionRoomDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   IllusionRoomPort
}

func (o IllusionRoomDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failIllusion(d.ErrUnavailable)
	}
	params, op := req.Envelope.Params, req.Envelope.Operation
	bad := badHero("illusion_invalid_parameter")
	switch req.Envelope.MID {
	case 1349:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.CreateRoom(ctx, a, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1350:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.RoomInfo(ctx, a, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1351:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.Prepare(ctx, a, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1352:
		roomID, ok := topFloorInteger(params, "room_id", true)
		if !ok || roomID <= 0 || !onlyStockGameplayParams(params, "room_id") {
			return bad
		}
		body, err := o.Service.EnterRoom(ctx, a, roomID, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1353:
		target, ok := topFloorInteger(params, "p_id", true)
		if !ok || target <= 0 || !onlyStockGameplayParams(params, "p_id") {
			return bad
		}
		body, err := o.Service.RemovePlayer(ctx, a, identity.PlayerID(target), op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1354:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.ExitRoom(ctx, a, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1356:
		request, ok := illusionPartner(params)
		if !ok {
			return bad
		}
		body, err := o.Service.SetPartner(ctx, a, request, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1357:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.Ready(ctx, a, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1358:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.StartTeam(ctx, a, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1360:
		target, ok := topFloorInteger(params, "p_id", true)
		if !ok || target <= 0 || !onlyStockGameplayParams(params, "p_id") {
			return bad
		}
		body, err := o.Service.Invite(ctx, a, identity.PlayerID(target), op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1362:
		reportID, ok := illusionReportID(params)
		if !ok || !onlyStockGameplayParams(params, "report_id") {
			return bad
		}
		body, err := o.Service.GetReport(ctx, reportID, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	case 1363:
		if !onlyStockGameplayParams(params) {
			return bad
		}
		body, err := o.Service.CancelPrepare(ctx, a, op)
		if err != nil {
			return failIllusionRoom(err)
		}
		return okI5(body)
	}
	return bad
}

func illusionPartner(params map[string]any) (app.PartnerRequest, bool) {
	text, textOK := params["partner_str"].(string)
	pet, petOK := topFloorInteger(params, "pet_id", false)
	if !textOK || !petOK || !onlyStockGameplayParams(params, "partner_str", "pet_id") {
		return app.PartnerRequest{}, false
	}
	heroes := []int64{}
	for _, part := range strings.Split(text, "|") {
		id, err := strconv.ParseInt(part, 10, 64)
		if err != nil || id <= 0 {
			return app.PartnerRequest{}, false
		}
		heroes = append(heroes, id)
	}
	return app.PartnerRequest{Heroes: heroes, PetID: pet}, true
}

// illusionReportID accepts the numeric stock field and the string id its own
// push carries.
func illusionReportID(params map[string]any) (string, bool) {
	if text, ok := params["report_id"].(string); ok && text != "" {
		return text, true
	}
	value, ok := topFloorInteger(params, "report_id", true)
	if !ok || value <= 0 {
		return "", false
	}
	return strconv.FormatInt(value, 10), true
}

func failIllusionRoom(err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.Is(err, d.ErrInvalid) || errors.Is(err, sharedroom.ErrInvalid) || errors.As(err, &conflict) {
		return badHero("illusion_invalid_parameter")
	}
	if errors.Is(err, d.ErrRefused) || errors.Is(err, sr.ErrNotInRoom) || errors.Is(err, sr.ErrAlreadyInRoom) || errors.Is(err, sr.ErrNotFound) || errors.Is(err, sr.ErrConflict) ||
		errors.Is(err, sharedroom.ErrClosed) || errors.Is(err, sharedroom.ErrExpired) || errors.Is(err, sharedroom.ErrFull) ||
		errors.Is(err, sharedroom.ErrKicked) || errors.Is(err, sharedroom.ErrNotOwner) || errors.Is(err, sharedroom.ErrNotSeated) ||
		errors.Is(err, sharedroom.ErrNotFound) {
		return okI5(map[string]any{"error_code": int64(1)})
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: err, Body: map[string]any{"error": "illusion_unavailable"}}
}
