package stockruntime

import (
	"context"
	"errors"

	app "gxb.local/backend/v2/internal/application/eventcentre"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type EventCentrePort interface {
	Read(context.Context, identity.ActorContext, uint16, operation.Context) (map[string]any, error)
	Command(context.Context, identity.ActorContext, app.Command, operation.Context) (app.Result, error)
	BoardInfo(context.Context, identity.ActorContext, operation.Context) (map[string]any, error)
	BoardReport(context.Context, identity.ActorContext, int64, operation.Context) (map[string]any, error)
}

type EventCentreDispatcher struct {
	Authority rt.GameplayAuthorityPort
	Service   EventCentrePort
}

func (d EventCentreDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	a, fail := (HeroDispatcher{Authority: d.Authority}).actor(ctx, req)
	if fail != nil {
		return *fail
	}
	if d.Service == nil {
		return failureReply(defect(nil))
	}
	params := req.Envelope.Params
	mid := req.Envelope.MID
	switch mid {
	case 1072, 1074, 1081, 1090:
		if !onlyStockGameplayParams(params) {
			return eventCentreRefusal()
		}
		body, err := d.Service.Read(ctx, a, mid, req.Envelope.Operation)
		if err != nil {
			return failEventCentre(err)
		}
		return okI5(body)
	case 1083:
		if !onlyStockGameplayParams(params) {
			return eventCentreRefusal()
		}
		body, err := d.Service.BoardInfo(ctx, a, req.Envelope.Operation)
		if err != nil {
			return failEventCentre(err)
		}
		return okI5(body)
	case 1087:
		boardID, err := requiredInt64(params, "battle_id")
		if err != nil || !onlyStockGameplayParams(params, "battle_id") {
			return eventCentreRefusal()
		}
		body, err := d.Service.BoardReport(ctx, a, boardID, req.Envelope.Operation)
		if err != nil {
			return failEventCentre(err)
		}
		return okI5(body)
	}
	command, allowed, err := eventCentreCommand(mid, params)
	if err != nil || !onlyStockGameplayParams(params, allowed...) || command.Validate() != nil {
		return eventCentreRefusal()
	}
	result, err := d.Service.Command(ctx, a, command, req.Envelope.Operation)
	if err != nil {
		return failEventCentreCommand(err, command)
	}
	return okI5(result.Body)
}

func eventCentreCommand(mid uint16, params map[string]any) (app.Command, []string, error) {
	command := app.Command{}
	switch mid {
	case 1073:
		itemID, firstErr := requiredInt64(params, "item_id")
		itemNum, secondErr := requiredInt64(params, "item_num")
		if firstErr != nil || secondErr != nil {
			return command, nil, errors.New("invalid recycle request")
		}
		command = app.Command{Family: app.Recycle, ItemID: itemID, ItemNum: itemNum}
		return command, []string{"item_id", "item_num"}, nil
	case 1075:
		itemID, err := requiredInt64(params, "item_id")
		if err != nil {
			return command, nil, err
		}
		command = app.Command{Family: app.Make, ItemID: itemID, BuildingType: app.DeskBuilding}
		return command, []string{"item_id"}, nil
	case 1091:
		itemID, firstErr := requiredInt64(params, "item_id")
		petID, secondErr := requiredInt64(params, "pet_id")
		if firstErr != nil || secondErr != nil {
			return command, nil, errors.New("invalid pet make request")
		}
		command = app.Command{Family: app.Make, ItemID: itemID, BuildingType: app.PetRoomBuilding, PetID: petID}
		return command, []string{"item_id", "pet_id"}, nil
	case 1076:
		buildingType, err := requiredInt64(params, "building_type")
		if err != nil {
			return command, nil, err
		}
		command = app.Command{Family: app.CancelMake, BuildingType: buildingType}
		return command, []string{"building_type"}, nil
	case 1088:
		buildingType, err := requiredInt64(params, "building_type")
		if err != nil {
			return command, nil, err
		}
		command = app.Command{Family: app.ConfirmMake, BuildingType: buildingType}
		return command, []string{"building_type"}, nil
	case 1089:
		speedNum, firstErr := requiredInt64(params, "speed_num")
		buildingType, secondErr := requiredInt64(params, "building_type")
		if firstErr != nil || secondErr != nil {
			return command, nil, errors.New("invalid accelerate request")
		}
		command = app.Command{Family: app.AccelerateMake, SpeedNum: speedNum, BuildingType: buildingType}
		return command, []string{"speed_num", "building_type"}, nil
	case 1084:
		missionID, firstErr := requiredInt64(params, "mission_id")
		leader, secondErr := requiredInt64(params, "leader")
		partners, thirdErr := int64List(params, "partners")
		wish := optionalInt64(params, "wish_crystal")
		if firstErr != nil || secondErr != nil || thirdErr != nil || len(partners) > 5 {
			return command, nil, errors.New("invalid notice board receive request")
		}
		if partners == nil {
			partners = []int64{}
		}
		command = app.Command{Family: app.BoardReceive, MissionID: missionID, Leader: leader, Partners: partners, WishCrystal: wish}
		return command, []string{"mission_id", "leader", "partners", "wish_crystal"}, nil
	case 1085:
		missionID, err := requiredInt64(params, "mission_id")
		if err != nil {
			return command, nil, err
		}
		command = app.Command{Family: app.BoardGiveUp, MissionID: missionID}
		return command, []string{"mission_id"}, nil
	case 1086:
		command = app.Command{Family: app.BoardConfirm}
		return command, nil, nil
	case 1082:
		fromType, firstErr := requiredInt64(params, "from_type")
		toType, secondErr := requiredInt64(params, "to_type")
		if firstErr != nil || secondErr != nil {
			return command, nil, errors.New("invalid administrator conversion request")
		}
		command = app.Command{Family: app.AdminExchange, FromType: fromType, ToType: toType}
		return command, []string{"from_type", "to_type"}, nil
	default:
		return command, nil, errors.New("unsupported event centre mid")
	}
}

// Stock message.lua rows only cover diamond (crystal) and coin (mana) deficits;
// recycle saturation energy and magic materials have no message row.
func failEventCentreCommand(err error, command app.Command) httpedge.Response {
	if errors.Is(err, economy.ErrInsufficientBalance) && command.Family == app.AdminExchange {
		switch command.FromType {
		case 2:
			return failureReply(refusal(20005))
		case 1:
			return failureReply(refusal(20006))
		}
	}
	return failEventCentre(err)
}

// I9_10A C23 keeps Event Centre refusals on 409 so the stock callbacks never
// receive a 200 body; D5 supplies the codes.
var eventCentreFailureRows = []failureRow{
	{match: app.ErrRejected, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrInvalid, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrUnqualified, class: failureRefusal, code: unprovenRefusalCode},
	{match: app.ErrStale, class: failureRefusal, code: staleConflictCode},
	{match: app.ErrStaleTime, class: failureRefusal, code: staleConflictCode},
	{match: bookskill.ErrInvalid, class: failureRefusal, code: unprovenRefusalCode},
	{match: economy.ErrInsufficientBalance, class: failureRefusal, balance: true},
	{match: app.ErrUnavailable, class: failureUnavailable},
}

func eventCentreRefusal() httpedge.Response {
	return failureReply(refusal(unprovenRefusalCode))
}

func failEventCentre(err error) httpedge.Response {
	return failureFromRows(eventCentreFailureRows, err)
}
