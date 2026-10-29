package stockruntime

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/application/realtimeauth"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	projection "gxb.local/backend/v2/internal/projection/arena"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

const TournamentNoticeType int64 = 13

func ValidateTournamentNotice(value any) error {
	object, valid := value.(*amf3.Object)
	if !valid || object == nil {
		return rt.ErrInvalidS2CPayload
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 2 || fields["notice_type"] != TournamentNoticeType {
		return rt.ErrInvalidS2CPayload
	}
	params, valid := fields["params"].(*amf3.Object)
	if !valid || params == nil {
		return rt.ErrInvalidS2CPayload
	}
	body, err := params.StrictMap()
	if err != nil {
		return rt.ErrInvalidS2CPayload
	}
	key, valid := body["room_key"].(string)
	if !valid {
		return rt.ErrInvalidS2CPayload
	}
	if _, _, err := d.ParseSelectionKey(key); err != nil {
		return rt.ErrInvalidS2CPayload
	}
	stage, stageValid := body["stage"].(int64)
	open, openValid := body["is_open"].(int64)
	first, firstValid := body["A_player_id"].(int64)
	second, secondValid := body["B_player_id"].(int64)
	if !stageValid || stage < 0 || stage > d.SelectionDoneTurn || !openValid || (open != 0 && open != 1) || !firstValid || !secondValid || first <= 0 || second <= 0 || first == second {
		return rt.ErrInvalidS2CPayload
	}
	for _, field := range []string{"A_player_info", "B_player_info", "params", "A_partners_info", "B_partners_info"} {
		if _, valid := body[field].(*amf3.Object); !valid {
			return rt.ErrInvalidS2CPayload
		}
	}
	return nil
}

func NewTournamentNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: TournamentNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateTournamentNotice}})
}

func tournamentAMF(value any) (any, error) {
	switch data := value.(type) {
	case map[string]any:
		keys := make([]string, 0, len(data))
		for key := range data {
			keys = append(keys, key)
		}
		sort.Strings(keys)
		result := &amf3.Object{}
		for _, key := range keys {
			converted, err := tournamentAMF(data[key])
			if err != nil {
				return nil, err
			}
			result.Properties = append(result.Properties, amf3.Property{Name: key, Value: converted})
		}
		return result, nil
	case []any:
		result := make([]any, len(data))
		for index, value := range data {
			converted, err := tournamentAMF(value)
			if err != nil {
				return nil, err
			}
			result[index] = converted
		}
		return result, nil
	case json.Number:
		if integer, err := data.Int64(); err == nil {
			return integer, nil
		}
		return data.Float64()
	default:
		return value, nil
	}
}

func tournamentNoticeFrame(view d.TournamentRoomView) (*amf3.Object, error) {
	payload, err := json.Marshal(projection.TournamentRoom(view))
	if err != nil {
		return nil, err
	}
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.UseNumber()
	var raw any
	if err := decoder.Decode(&raw); err != nil {
		return nil, err
	}
	params, err := tournamentAMF(raw)
	if err != nil {
		return nil, err
	}
	return &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: TournamentNoticeType}, {Name: "params", Value: params}}}, nil
}

type TournamentNoticeSource interface {
	ReadNotice(context.Context, string) (d.TournamentRoomView, bool, error)
}

type TournamentNoticeHandler struct {
	Service         TournamentNoticeSource
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	OnDeliveryError func(error)
}

func (handler TournamentNoticeHandler) ReloadAndDeliver(requestContext context.Context, reference string) error {
	if handler.Service == nil || handler.Registry == nil || handler.Authority == nil || handler.Time == nil || handler.MaxHandles < 1 {
		return errors.New("tournament notice unavailable")
	}
	requestContext, cancel := context.WithTimeout(requestContext, 2*time.Second)
	defer cancel()
	view, found, err := handler.Service.ReadNotice(requestContext, reference)
	if err != nil || !found {
		return err
	}
	frame, err := tournamentNoticeFrame(view)
	if err != nil {
		return err
	}
	for side, player := range view.Room.Selection.Players {
		if view.Room.Acknowledged[side] >= view.Room.NoticeVersion {
			continue
		}
		handles := handler.Registry.ByPlayerRole(player, domainrt.World)
		if len(handles) > handler.MaxHandles {
			return errors.New("tournament notice connection bound exceeded")
		}
		for _, handle := range handles {
			metadata, valid := handle.Metadata()
			if !valid || !handler.Registry.IsCurrent(handle) || metadata.PlayerID != player || metadata.PhysicalRole != domainrt.World || metadata.RoomID != int64(metadata.LogicalServerID) {
				continue
			}
			at, err := handler.Time.Now(requestContext)
			if err != nil {
				return err
			}
			actor := identity.ActorContext{AccountID: metadata.AccountID, AccountUID: metadata.AccountUID, SessionID: metadata.SessionID, ContextID: metadata.ContextID, LogicalServerID: metadata.LogicalServerID, PlayerID: metadata.PlayerID, ContextGeneration: metadata.ContextGeneration, SessionLivenessVersion: metadata.SessionLivenessVersion, ContextLivenessVersion: metadata.ContextLivenessVersion}
			if handler.Authority.ValidateActor(requestContext, actor, at) != nil {
				continue
			}
			if err := handler.Publisher.PublishNotice(requestContext, handle, mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, frame); err != nil && handler.OnDeliveryError != nil {
				handler.OnDeliveryError(err)
			}
		}
	}
	return nil
}
