package stockruntime

import (
	"context"
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/achievement"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

const AchievementNoticeType int64 = 17

var achievementNoticeFields = []string{"achieve_id", "complete_time", "progress", "point_level", "total_points", "rank"}

func ValidateAchievementNotice(v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return rt.ErrInvalidS2CPayload
	}
	m, e := o.StrictMap()
	if e != nil || len(m) != 2 || m["notice_type"] != AchievementNoticeType {
		return rt.ErrInvalidS2CPayload
	}
	params, ok := m["params"].(*amf3.Object)
	if !ok || params == nil {
		return rt.ErrInvalidS2CPayload
	}
	p, e := params.StrictMap()
	if e != nil || len(p) != len(achievementNoticeFields) {
		return rt.ErrInvalidS2CPayload
	}
	for _, k := range achievementNoticeFields {
		if _, ok := p[k]; !ok {
			return rt.ErrInvalidS2CPayload
		}
	}
	times, ok := p["complete_time"].([]any)
	if !ok || len(times) != 3 {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func NewAchievementNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: AchievementNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateAchievementNotice}})
}

func achievementNoticeFrame(n achievement.NoticeParams) *amf3.Object {
	times := []any{n.CompleteTimes[0], n.CompleteTimes[1], n.CompleteTimes[2]}
	params := &amf3.Object{Properties: []amf3.Property{{Name: "achieve_id", Value: n.AchievementID}, {Name: "complete_time", Value: times}, {Name: "progress", Value: n.Progress}, {Name: "point_level", Value: n.PointLevel}, {Name: "total_points", Value: n.TotalPoints}, {Name: "rank", Value: n.Rank}}}
	return &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: AchievementNoticeType}, {Name: "params", Value: params}}}
}

type AchievementNotices interface {
	TakeNotices(context.Context, identity.PlayerID, operation.Context) ([]achievement.NoticeParams, error)
}

// AchievementNoticeHandler is the C4F_ACHIEVEMENT_NOTICE_V1 route: best-effort
// notice 17 pushes to the player's live World connections.
type AchievementNoticeHandler struct {
	Service         AchievementNotices
	Operations      operation.Factory
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	OnDeliveryError func(error)
}

func (h AchievementNoticeHandler) ReloadAndDeliver(ctx context.Context, raw string) error {
	id, e := strconv.ParseInt(raw, 10, 64)
	player := identity.PlayerID(id)
	if e != nil || !player.Valid() || strconv.FormatInt(id, 10) != raw {
		return errors.New("invalid achievement notice reference")
	}
	if h.Service == nil || h.Registry == nil || h.Authority == nil || h.Time == nil || h.MaxHandles < 1 {
		return errors.New("achievement notice route unavailable")
	}
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	handles := h.Registry.ByPlayerRole(player, domainrt.World)
	if len(handles) > h.MaxHandles {
		return errors.New("achievement notice fanout exceeds serving connection bound")
	}
	live := []SessionHandle{}
	for _, handle := range handles {
		m, ok := handle.Metadata()
		if !ok || !h.Registry.IsCurrent(handle) || m.PlayerID != player || m.PhysicalRole != domainrt.World || m.RoomID != int64(m.LogicalServerID) {
			continue
		}
		at, e := h.Time.Now(ctx)
		if e != nil {
			return e
		}
		actor := identity.ActorContext{AccountID: m.AccountID, AccountUID: m.AccountUID, SessionID: m.SessionID, ContextID: m.ContextID, LogicalServerID: m.LogicalServerID, PlayerID: m.PlayerID, ContextGeneration: m.ContextGeneration, SessionLivenessVersion: m.SessionLivenessVersion, ContextLivenessVersion: m.ContextLivenessVersion}
		if h.Authority.ValidateActor(ctx, actor, at) == nil {
			live = append(live, handle)
		}
	}
	// shortcut: an offline player's notices wait for the next tier wakeup; add a connect-time reconcile if players miss them.
	if len(live) == 0 {
		return nil
	}
	op, e := h.Operations.New(policy.Set{})
	if e != nil {
		return e
	}
	notices, e := h.Service.TakeNotices(ctx, player, op)
	if e != nil {
		return e
	}
	for _, handle := range live {
		for _, n := range notices {
			if e := h.Publisher.PublishNotice(ctx, handle, mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, achievementNoticeFrame(n)); e != nil && h.OnDeliveryError != nil {
				h.OnDeliveryError(e)
			}
		}
	}
	return nil
}
