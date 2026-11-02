package stockruntime

import (
	"context"
	"errors"
	app "gxb.local/backend/v2/internal/application/arena"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
	"time"
)

func ValidateFriendFightNotice(value any) error {
	object, valid := value.(*amf3.Object)
	if !valid || object == nil {
		return rt.ErrInvalidS2CPayload
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 2 {
		return rt.ErrInvalidS2CPayload
	}
	noticeType, valid := fields["notice_type"].(int64)
	params, paramsValid := fields["params"].(*amf3.Object)
	if !valid || (noticeType != 14 && noticeType != 15) || !paramsValid || params == nil {
		return rt.ErrInvalidS2CPayload
	}
	body, err := params.StrictMap()
	if err != nil {
		return rt.ErrInvalidS2CPayload
	}
	if noticeType == 15 {
		if len(body) != 0 {
			return rt.ErrInvalidS2CPayload
		}
		return nil
	}
	mode, modeValid := body["model"].(int64)
	gameType, typeValid := body["game_type"].(int64)
	player, playerValid := body["player_info"].(*amf3.Object)
	if len(body) != 3 || !modeValid || mode < 1 || mode > 2 || !typeValid || gameType < 1 || gameType > 2 || !playerValid || player == nil {
		return rt.ErrInvalidS2CPayload
	}
	profile, err := player.StrictMap()
	if err != nil || len(profile) != 2 {
		return rt.ErrInvalidS2CPayload
	}
	identifier, valid := profile["player_id"].(int64)
	name, nameValid := profile["player_name"].(string)
	if !valid || identifier < 1 || !nameValid || name == "" {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}
func NewFriendFightNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: 14, Roles: []rt.Role{rt.World}, Validate: ValidateFriendFightNotice},
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: 15, Roles: []rt.Role{rt.World}, Validate: ValidateFriendFightNotice},
	})
}

type FriendFightNoticeSource interface {
	ReadFriendNotice(context.Context, string) (app.FriendFightNotice, bool, error)
}
type FriendFightNoticeHandler struct {
	Service  FriendFightNoticeSource
	Delivery TournamentNoticeHandler
}

func (handler FriendFightNoticeHandler) ReloadAndDeliver(requestContext context.Context, reference string) error {
	if handler.Service == nil || handler.Delivery.Registry == nil || handler.Delivery.Authority == nil || handler.Delivery.Time == nil || handler.Delivery.MaxHandles < 1 {
		return errors.New("friend fight notice unavailable")
	}
	requestContext, cancel := context.WithTimeout(requestContext, 2*time.Second)
	defer cancel()
	view, found, err := handler.Service.ReadFriendNotice(requestContext, reference)
	if err != nil || !found {
		return err
	}
	params := map[string]any{}
	if view.Type == 14 {
		params = map[string]any{"player_info": map[string]any{"player_id": int64(view.Inviter.Player), "player_name": view.Inviter.Name}, "model": int64(view.Mode), "game_type": int64(view.GameType)}
	}
	converted, err := tournamentAMF(params)
	if err != nil {
		return err
	}
	frame := &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: view.Type}, {Name: "params", Value: converted}}}
	return handler.Delivery.deliverPlayer(requestContext, view.Recipient, frame)
}
