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

const LibraryMissionNoticeType int64 = 20

var libraryMissionNoticeInfoKeys = []string{"mission_id", "process", "mission_state"}

func ValidateLibraryMissionNotice(v any) error {
	fields, ok := libraryMissionNoticeFields(v)
	if !ok {
		return rt.ErrInvalidS2CPayload
	}
	if _, ok := fields["partner_id"].(int64); !ok {
		return rt.ErrInvalidS2CPayload
	}
	if _, ok := fields["favor"].(int64); !ok {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func libraryMissionNoticeFields(v any) (map[string]any, bool) {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return nil, false
	}
	m, err := o.StrictMap()
	if err != nil || len(m) != 2 || m["notice_type"] != LibraryMissionNoticeType {
		return nil, false
	}
	params, ok := m["params"].(*amf3.Object)
	if !ok || params == nil {
		return nil, false
	}
	fields, err := params.StrictMap()
	if err != nil || len(fields) != 3 {
		return nil, false
	}
	info, ok := fields["mission_info"].(*amf3.Object)
	if !ok || info == nil {
		return nil, false
	}
	mission, err := info.StrictMap()
	if err != nil || len(mission) != len(libraryMissionNoticeInfoKeys) {
		return nil, false
	}
	for _, key := range libraryMissionNoticeInfoKeys {
		if _, ok := mission[key].(int64); !ok {
			return nil, false
		}
	}
	return fields, true
}

func NewLibraryMissionNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(nil, []rt.NoticeRegistration{
		{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: LibraryMissionNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateLibraryMissionNotice},
	})
}

func libraryMissionNoticeFrame(n app.MissionNotice) *amf3.Object {
	info := &amf3.Object{Properties: []amf3.Property{
		{Name: "mission_id", Value: n.MissionID},
		{Name: "process", Value: n.Process},
		{Name: "mission_state", Value: n.MissionState},
	}}
	params := &amf3.Object{Properties: []amf3.Property{{Name: "mission_info", Value: info}, {Name: "partner_id", Value: n.PartnerID}, {Name: "favor", Value: n.Favor}}}
	return &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: LibraryMissionNoticeType}, {Name: "params", Value: params}}}
}

type LibraryMissionNotices interface {
	ReadMissionNotice(context.Context, identity.PlayerID, int64, int64) (app.MissionNotice, error)
}

// LibraryMissionNoticeHandler is the library.mission.v1 route: it pushes notice
// 20 with the awarded mission and the raised favor to that player's live
// connections. Delivery is D1 optional display: a push failure is reported and
// dropped, and a reconnect or fresh 836 remains the recovery path.
type LibraryMissionNoticeHandler struct {
	Service         LibraryMissionNotices
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	OnDeliveryError func(error)
}

func (h LibraryMissionNoticeHandler) ReloadAndDeliver(ctx context.Context, raw string) error {
	player, partnerID, missionID, err := parseLibraryMissionNoticeRef(raw)
	if err != nil {
		return err
	}
	if h.Service == nil || h.Registry == nil || h.Authority == nil || h.Time == nil || h.MaxHandles < 1 {
		return errors.New("library mission notice route unavailable")
	}
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	handles := h.Registry.ByPlayerRole(player, domainrt.World)
	if len(handles) > h.MaxHandles {
		return errors.New("library mission notice fanout exceeds serving connection bound")
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
	notice, err := h.Service.ReadMissionNotice(ctx, player, partnerID, missionID)
	if err != nil {
		h.deliveryError(err)
		return nil
	}
	frame := libraryMissionNoticeFrame(notice)
	for _, handle := range live {
		if err := h.Publisher.PublishNotice(ctx, handle, mids.MIDPlayerNotice, rt.NoticeNamespaceGeneric, frame); err != nil {
			h.deliveryError(err)
		}
	}
	return nil
}

func (h LibraryMissionNoticeHandler) deliveryError(err error) {
	if h.OnDeliveryError != nil {
		h.OnDeliveryError(err)
	}
}

func parseLibraryMissionNoticeRef(raw string) (identity.PlayerID, int64, int64, error) {
	if strings.Count(raw, ":") != 2 {
		return 0, 0, 0, errors.New("invalid library mission notice reference")
	}
	playerPart, rest, _ := strings.Cut(raw, ":")
	partnerPart, missionPart, _ := strings.Cut(rest, ":")
	playerID, err := strconv.ParseInt(playerPart, 10, 64)
	if err != nil {
		return 0, 0, 0, errors.New("invalid library mission notice reference")
	}
	partnerID, err := strconv.ParseInt(partnerPart, 10, 64)
	if err != nil || partnerID <= 0 {
		return 0, 0, 0, errors.New("invalid library mission notice reference")
	}
	missionID, err := strconv.ParseInt(missionPart, 10, 64)
	if err != nil || missionID <= 0 {
		return 0, 0, 0, errors.New("invalid library mission notice reference")
	}
	player := identity.PlayerID(playerID)
	if !player.Valid() || app.MissionNoticeRef(player, partnerID, missionID) != raw {
		return 0, 0, 0, errors.New("invalid library mission notice reference")
	}
	return player, partnerID, missionID, nil
}

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
