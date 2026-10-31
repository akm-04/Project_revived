package stockruntime

import (
	"context"
	"errors"
	"strconv"
	"sync"
	"time"

	app "gxb.local/backend/v2/internal/application/adventure"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

var adventureOccurFields = []string{"table_id", "special_data", "end_time", "extra_data", "server_time"}

func ValidateAdventureOccurNotice(v any) error {
	fields, ok := adventureNoticeFields(v, app.NoticeOccur)
	if !ok || len(fields) != len(adventureOccurFields) {
		return rt.ErrInvalidS2CPayload
	}
	for _, key := range adventureOccurFields {
		if _, ok := fields[key]; !ok {
			return rt.ErrInvalidS2CPayload
		}
	}
	return nil
}

func ValidateAdventureFinishNotice(v any) error {
	fields, ok := adventureNoticeFields(v, app.NoticeFinish)
	if !ok || len(fields) != 1 {
		return rt.ErrInvalidS2CPayload
	}
	_, ok = fields["table_id"]
	if !ok {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func adventureNoticeFields(v any, noticeType int64) (map[string]any, bool) {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return nil, false
	}
	m, err := o.StrictMap()
	if err != nil || len(m) != 2 || m["notice_type"] != noticeType {
		return nil, false
	}
	params, ok := m["params"].(*amf3.Object)
	if !ok || params == nil {
		return nil, false
	}
	fields, err := params.StrictMap()
	return fields, err == nil
}

func NewAdventureNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: app.NoticeOccur, Roles: []rt.Role{rt.World}, Validate: ValidateAdventureOccurNotice},
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: app.NoticeFinish, Roles: []rt.Role{rt.World}, Validate: ValidateAdventureFinishNotice},
	})
}

func adventureFrame(n app.Notice) *amf3.Object {
	var params *amf3.Object
	if n.Type == app.NoticeOccur {
		params = &amf3.Object{Properties: []amf3.Property{
			{Name: "table_id", Value: n.TableID}, {Name: "special_data", Value: n.SpecialData},
			{Name: "end_time", Value: n.EndTime.Unix()}, {Name: "extra_data", Value: int64(0)},
			{Name: "server_time", Value: n.ServerTime.Unix()},
		}}
	} else {
		params = &amf3.Object{Properties: []amf3.Property{{Name: "table_id", Value: n.TableID}}}
	}
	return &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: n.Type}, {Name: "params", Value: params}}}
}

type AdventureNotices interface {
	ReadNotices(context.Context, identity.PlayerID, operation.Context) ([]app.Notice, error)
}

type adventureNoticeKey struct {
	player     identity.PlayerID
	noticeType int64
	tableID    int64
	occurredAt int64
}

// AdventureNoticeLedger makes occur and finish pushes one-shot per
// occurrence.
// shortcut: in memory, so a realtime restart repeats a live occurrence's push
// once; persist delivery if a repeat ever reaches the client as a new event.
type AdventureNoticeLedger struct {
	mu        sync.Mutex
	delivered map[adventureNoticeKey]struct{}
}

func NewAdventureNoticeLedger() *AdventureNoticeLedger {
	return &AdventureNoticeLedger{delivered: map[adventureNoticeKey]struct{}{}}
}

func (l *AdventureNoticeLedger) mark(n app.Notice, player identity.PlayerID) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	key := adventureNoticeKey{player: player, noticeType: n.Type, tableID: n.TableID, occurredAt: n.OccurredAt.Unix()}
	if _, seen := l.delivered[key]; seen {
		return false
	}
	l.delivered[key] = struct{}{}
	return true
}

// AdventureNoticeHandler is the adventure.notice.v1 route: pushes notice 33
// while an occurrence is live and notice 34 once after its terminal.
type AdventureNoticeHandler struct {
	Service         AdventureNotices
	Operations      operation.Factory
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	Delivered       *AdventureNoticeLedger
	OnDeliveryError func(error)
}

func (h AdventureNoticeHandler) ReloadAndDeliver(ctx context.Context, raw string) error {
	id, err := strconv.ParseInt(raw, 10, 64)
	player := identity.PlayerID(id)
	if err != nil || !player.Valid() || strconv.FormatInt(id, 10) != raw {
		return errors.New("invalid adventure notice reference")
	}
	if h.Service == nil || h.Registry == nil || h.Authority == nil || h.Time == nil || h.Delivered == nil || h.MaxHandles < 1 {
		return errors.New("adventure notice route unavailable")
	}
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	handles := h.Registry.ByPlayerRole(player, domainrt.World)
	if len(handles) > h.MaxHandles {
		return errors.New("adventure notice fanout exceeds serving connection bound")
	}
	live := []SessionHandle{}
	for _, handle := range handles {
		metadata, ok := handle.Metadata()
		if !ok || !h.Registry.IsCurrent(handle) || metadata.PlayerID != player || metadata.PhysicalRole != domainrt.World || metadata.RoomID != int64(metadata.LogicalServerID) {
			continue
		}
		at, err := h.Time.Now(ctx)
		if err != nil {
			return err
		}
		actor := identity.ActorContext{AccountID: metadata.AccountID, AccountUID: metadata.AccountUID, SessionID: metadata.SessionID, ContextID: metadata.ContextID, LogicalServerID: metadata.LogicalServerID, PlayerID: metadata.PlayerID, ContextGeneration: metadata.ContextGeneration, SessionLivenessVersion: metadata.SessionLivenessVersion, ContextLivenessVersion: metadata.ContextLivenessVersion}
		if h.Authority.ValidateActor(ctx, actor, at) == nil {
			live = append(live, handle)
		}
	}
	// shortcut: an offline player's notices wait for the next wakeup; a
	// connect-time reconcile delivers them if the client missed them.
	if len(live) == 0 {
		return nil
	}
	op, err := h.Operations.New(policy.Set{})
	if err != nil {
		return err
	}
	notices, err := h.Service.ReadNotices(ctx, player, op)
	if err != nil {
		return err
	}
	for _, handle := range live {
		for _, notice := range notices {
			if !h.Delivered.mark(notice, player) {
				continue
			}
			if err := h.Publisher.PublishNotice(ctx, handle, mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, adventureFrame(notice)); err != nil && h.OnDeliveryError != nil {
				h.OnDeliveryError(err)
			}
		}
	}
	return nil
}
