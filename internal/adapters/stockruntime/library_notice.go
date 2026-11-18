package stockruntime

import (
	"context"
	"errors"
	"strconv"
	"strings"
	"time"

	app "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

const LibraryPartnerLogNoticeType int64 = 24

func ValidateLibraryPartnerLogNotice(v any) error {
	fields, ok := libraryPartnerLogFields(v)
	if !ok {
		return rt.ErrInvalidS2CPayload
	}
	if _, ok := fields["partner_id"].(int64); !ok {
		return rt.ErrInvalidS2CPayload
	}
	logInfo, ok := fields["log_info"].(map[string]any)
	if !ok || logInfo == nil {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func libraryPartnerLogFields(v any) (map[string]any, bool) {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return nil, false
	}
	m, err := o.StrictMap()
	if err != nil || len(m) != 2 || m["notice_type"] != LibraryPartnerLogNoticeType {
		return nil, false
	}
	params, ok := m["params"].(*amf3.Object)
	if !ok || params == nil {
		return nil, false
	}
	fields, err := params.StrictMap()
	if err != nil || len(fields) != 2 {
		return nil, false
	}
	return fields, true
}

func NewLibraryPartnerLogNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: LibraryPartnerLogNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateLibraryPartnerLogNotice},
	})
}

func libraryPartnerLogFrame(partnerID int64, logInfo map[string]any) *amf3.Object {
	params := &amf3.Object{Properties: []amf3.Property{{Name: "partner_id", Value: partnerID}, {Name: "log_info", Value: logInfo}}}
	return &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: LibraryPartnerLogNoticeType}, {Name: "params", Value: params}}}
}

type LibraryPartnerLogs interface {
	ReadPartnerLog(context.Context, identity.PlayerID, int64, time.Time) (map[string]any, error)
}

// LibraryPartnerLogNoticeHandler is the library.partner_log.v1 route: it pushes
// notice 24 with the partner's full log map to that player's live connections.
// Delivery is D1 optional display: a reload or push failure is reported and
// dropped, and a reconnect or fresh 836 remains the recovery path.
type LibraryPartnerLogNoticeHandler struct {
	Service         LibraryPartnerLogs
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	OnDeliveryError func(error)
}

func (h LibraryPartnerLogNoticeHandler) ReloadAndDeliver(ctx context.Context, raw string) error {
	player, partnerID, err := parseLibraryPartnerLogRef(raw)
	if err != nil {
		return err
	}
	if h.Service == nil || h.Registry == nil || h.Authority == nil || h.Time == nil || h.MaxHandles < 1 {
		return errors.New("library partner log route unavailable")
	}
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	handles := h.Registry.ByPlayerRole(player, domainrt.World)
	if len(handles) > h.MaxHandles {
		return errors.New("library partner log fanout exceeds serving connection bound")
	}
	at, err := h.Time.Now(ctx)
	if err != nil {
		h.deliveryError(err)
		return nil
	}
	live := []SessionHandle{}
	for _, handle := range handles {
		m, ok := handle.Metadata()
		if !ok || !h.Registry.IsCurrent(handle) || m.PlayerID != player || m.PhysicalRole != domainrt.World || m.RoomID != int64(m.LogicalServerID) {
			continue
		}
		actor := identity.ActorContext{AccountID: m.AccountID, AccountUID: m.AccountUID, SessionID: m.SessionID, ContextID: m.ContextID, LogicalServerID: m.LogicalServerID, PlayerID: m.PlayerID, ContextGeneration: m.ContextGeneration, SessionLivenessVersion: m.SessionLivenessVersion, ContextLivenessVersion: m.ContextLivenessVersion}
		if h.Authority.ValidateActor(ctx, actor, at) == nil {
			live = append(live, handle)
		}
	}
	// An offline player's notice waits for the next 836 or login (D1).
	if len(live) == 0 {
		return nil
	}
	logInfo, err := h.Service.ReadPartnerLog(ctx, player, partnerID, at)
	if err != nil {
		h.deliveryError(err)
		return nil
	}
	frame := libraryPartnerLogFrame(partnerID, logInfo)
	for _, handle := range live {
		if err := h.Publisher.PublishNotice(ctx, handle, mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, frame); err != nil {
			h.deliveryError(err)
		}
	}
	return nil
}

func (h LibraryPartnerLogNoticeHandler) deliveryError(err error) {
	if h.OnDeliveryError != nil {
		h.OnDeliveryError(err)
	}
}

func parseLibraryPartnerLogRef(raw string) (identity.PlayerID, int64, error) {
	if strings.Count(raw, ":") != 1 {
		return 0, 0, errors.New("invalid library partner log reference")
	}
	playerPart, partnerPart, _ := strings.Cut(raw, ":")
	player, err := strconv.ParseInt(playerPart, 10, 64)
	if err != nil {
		return 0, 0, errors.New("invalid library partner log reference")
	}
	partnerID, err := strconv.ParseInt(partnerPart, 10, 64)
	if err != nil || partnerID <= 0 {
		return 0, 0, errors.New("invalid library partner log reference")
	}
	value := identity.PlayerID(player)
	if !value.Valid() || app.PartnerLogRef(value, partnerID) != raw {
		return 0, 0, errors.New("invalid library partner log reference")
	}
	return value, partnerID, nil
}
