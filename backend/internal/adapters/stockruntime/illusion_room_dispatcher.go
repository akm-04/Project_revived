package stockruntime

import (
	"context"
	"errors"
	"strconv"
	"strings"

	app "gxb.local/backend/v2/internal/application/illusion"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
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
	GetReport(context.Context, identity.ActorContext, string, operation.Context) (map[string]any, error)
}

// RoomReportFallback reads a report owned by another room family; 1362 is a
// shared report reader, so the composition decides which owner answers an id.
type RoomReportFallback interface {
	GetReport(context.Context, identity.ActorContext, string, operation.Context) (map[string]any, error)
}

type IllusionRoomDispatcher struct {
	Authority      rt.GameplayAuthorityPort
	Service        IllusionRoomPort
	ReportFallback RoomReportFallback
}

func (o IllusionRoomDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: o.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if o.Service == nil {
		return failureReply(defect(nil))
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
		body, err := o.Service.GetReport(ctx, a, reportID, op)
		if err != nil && o.ReportFallback != nil && errors.Is(err, d.ErrRefused) {
			fallback, fallbackErr := o.ReportFallback.GetReport(ctx, a, reportID, op)
			if fallbackErr != nil {
				return failAdventure(fallbackErr)
			}
			return okI5(fallback)
		}
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
	// IllusionSelectHeroWindow.lua:666 sends hero table ids, 0 for an empty slot,
	// and an empty string when the master picks a pet first.
	heroes := []int64{}
	if text == "" {
		return app.PartnerRequest{Heroes: heroes, PetID: pet}, true
	}
	for _, part := range strings.Split(text, "|") {
		id, err := strconv.ParseInt(part, 10, 64)
		if err != nil || id < 0 {
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

// Stock Illusion join refusals: 35022 is the level-band gap, 35023 a room that
// is full, started or gone (message.lua:616-626).
const (
	illusionLevelBandCode       int64 = 35022
	illusionRoomUnavailableCode int64 = 35023
)

var illusionRoomFailureRows = []failureRow{
	{match: d.ErrInvalid, class: failureMalformed, detail: "illusion_invalid_parameter"},
	{match: sharedroom.ErrInvalid, class: failureMalformed, detail: "illusion_invalid_parameter"},
	{match: sr.ErrLevelBand, class: failureRefusal, code: illusionLevelBandCode},
	{match: sr.ErrJoinUnavailable, class: failureRefusal, code: illusionRoomUnavailableCode},
	{match: d.ErrRefused, class: failureRefusal, code: unprovenRefusalCode},
	{match: sr.ErrNotInRoom, class: failureRefusal, code: unprovenRefusalCode},
	{match: sr.ErrAlreadyInRoom, class: failureRefusal, code: unprovenRefusalCode},
	{match: sr.ErrNotFound, class: failureRefusal, code: unprovenRefusalCode},
	{match: sr.ErrConflict, class: failureRefusal, code: staleConflictCode},
	{match: sharedroom.ErrClosed, class: failureRefusal, code: unprovenRefusalCode},
	{match: sharedroom.ErrExpired, class: failureRefusal, code: unprovenRefusalCode},
	{match: sharedroom.ErrFull, class: failureRefusal, code: unprovenRefusalCode},
	{match: sharedroom.ErrKicked, class: failureRefusal, code: unprovenRefusalCode},
	{match: sharedroom.ErrJoinThrottled, class: failureRefusal, code: unprovenRefusalCode},
	{match: sharedroom.ErrNotOwner, class: failureRefusal, code: unprovenRefusalCode},
	{match: sharedroom.ErrNotSeated, class: failureRefusal, code: unprovenRefusalCode},
	{match: sharedroom.ErrNotFound, class: failureRefusal, code: unprovenRefusalCode},
}

func failIllusionRoom(err error) httpedge.Response {
	return failureFromRows(illusionRoomFailureRows, err)
}
