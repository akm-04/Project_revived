package stockruntime

import (
	"context"
	"errors"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

type realtimeTestAuthority struct {
	actors map[string]identity.ActorContext
}

func (authority realtimeTestAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	actor, ok := authority.actors[token]
	if !ok {
		return identity.ActorContext{}, errors.New("unknown test bearer")
	}
	return actor, nil
}

func (realtimeTestAuthority) ValidateActor(context.Context, identity.ActorContext, time.Time) error {
	return nil
}

func realtimeTestActor(t *testing.T, suffix string, player int64) identity.ActorContext {
	t.Helper()
	account, err := ids.ParseUUID("11111111-1111-4111-8111-11111111111" + suffix)
	if err != nil {
		t.Fatal(err)
	}
	session, err := ids.ParseUUID("22222222-2222-4222-8222-22222222222" + suffix)
	if err != nil {
		t.Fatal(err)
	}
	contextUUID, err := ids.ParseUUID("33333333-3333-4333-8333-33333333333" + suffix)
	if err != nil {
		t.Fatal(err)
	}
	accountID, _ := identity.AccountIDFrom(account)
	sessionID, _ := identity.SessionIDFrom(session)
	contextID, _ := identity.ContextIDFrom(contextUUID)
	return identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID("2000000" + suffix), SessionID: sessionID,
		ContextID: contextID, LogicalServerID: 1, PlayerID: identity.PlayerID(player), ContextGeneration: 3, SessionLivenessVersion: 4, ContextLivenessVersion: 5}
}

type realtimeChatFanout struct {
	registry  *ConnectionRegistry
	publisher RealtimePublisher
}

func (dispatcher realtimeChatFanout) HandleSessionClientFrame(ctx context.Context, sender SessionHandle, admitted app.Admission, frame wireRT.Frame) ([]wireRT.Frame, error) {
	if frame.MID != mids.MIDSendChatMessage {
		return nil, ErrUnsupportedRealtimeMID
	}
	ingress, err := wireRT.ParseChannelChatIngress(frame.Params)
	if err != nil {
		return nil, err
	}
	handles, ok := dispatcher.registry.ByRoomRoleBounded(admitted.Domain.RoomID, admitted.Domain.Role, 16)
	if !ok {
		return nil, ErrInvalidRealtimeSession
	}
	chat := &amf3.Object{Properties: []amf3.Property{
		{Name: "player_id", Value: float64(admitted.Domain.Actor.PlayerID)},
		{Name: "player_name", Value: "tester"},
		{Name: "message", Value: ingress.Request.Message},
		{Name: "player_type", Value: float64(0)},
		{Name: "type", Value: float64(0)},
		{Name: "avatar_id", Value: float64(0)},
		{Name: "avatar_frame_id", Value: float64(0)},
		{Name: "lev", Value: float64(1)},
		{Name: "np_info", Value: `{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":1}`},
	}}
	for _, target := range handles {
		if err := dispatcher.publisher.PublishDirect(ctx, target, mids.MIDChatMessage, chat); err != nil {
			return nil, err
		}
	}
	push := &amf3.Object{Properties: []amf3.Property{{Name: "friend_id", Value: int64(7)}, {Name: "message", Value: "notice"}}}
	if err := dispatcher.publisher.PublishDirect(ctx, sender, mids.MIDChatFromPlayer, push); err != nil {
		return nil, err
	}
	return nil, nil
}

func newRealtimeTestServer(t *testing.T) RealtimeServer {
	t.Helper()
	actors := map[string]identity.ActorContext{
		"alpha": realtimeTestActor(t, "1", 100001),
		"beta":  realtimeTestActor(t, "2", 100002),
	}
	registry := NewConnectionRegistry()
	events, err := wireRT.NewEventRegistry([]wireRT.DirectRegistration{
		{MID: mids.MIDChatMessage, Roles: []wireRT.Role{wireRT.World, wireRT.Guild, wireRT.Service}, Validate: wireRT.ValidateChannelChat},
		{MID: mids.MIDChatFromPlayer, Roles: []wireRT.Role{wireRT.World}, Validate: func(value any) error {
			if _, ok := value.(*amf3.Object); !ok {
				return wireRT.ErrInvalidS2CPayload
			}
			return nil
		}},
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	dispatcher := realtimeChatFanout{registry: registry, publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}}
	return RealtimeServer{
		Auth:   app.Service{Authority: realtimeTestAuthority{actors: actors}, Endpoints: rtEndpoint{}},
		Limits: limits.Default(), Policy: DefaultRealtimePolicy(), Registry: registry, SessionDispatcher: dispatcher,
	}
}

func realtimeChatRequest(message string) wireRT.Frame {
	return wireRT.Frame{MID: mids.MIDSendChatMessage, Params: &amf3.Object{Properties: []amf3.Property{
		{Name: "message", Value: message}, {Name: "channel", Value: float64(0)}, {Name: "type", Value: float64(0)},
	}}}
}

func realtimeLoginRequest(token string) wireRT.Frame {
	return wireRT.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{
		{Name: "token", Value: token}, {Name: "region", Value: int32(1)}, {Name: "room_id", Value: int32(1)},
	}}}
}
