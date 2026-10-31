package stockruntime

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	rt "gxb.local/backend/v2/internal/protocol/realtime"
)

// IllusionInviteNoticeType is the stock friend notice a 1360 invite creates.
const IllusionInviteNoticeType int64 = 6

// IllusionRoomNotice is the canonical room state a 518 push projects.
type IllusionRoomNotice struct {
	RoomID        int64
	Status        int64
	Seated        []identity.PlayerID
	Removed       []identity.PlayerID
	TeamInfo      json.RawMessage
	ReportID      string
	DamageResults map[string]json.RawMessage
	Invites       []identity.PlayerID
	ParadiseID    int64
	Master        playerdirectory.Profile
}

type IllusionRoomNoticeReader struct {
	Store     sharedroomstore.Store
	Directory i4store.PlayerDirectoryReader
	Queryer   tx.Queryer
}

func (r IllusionRoomNoticeReader) ReadRoomNotice(c context.Context, reference string) (IllusionRoomNotice, bool, error) {
	var out IllusionRoomNotice
	roomID, err := strconv.ParseInt(reference, 10, 64)
	if err != nil || roomID <= 0 {
		return out, false, d.ErrInvalid
	}
	if r.Queryer == nil {
		return out, false, d.ErrUnavailable
	}
	room, found, err := r.Store.ReadRoomTx(c, r.Queryer, roomID)
	if err != nil || !found || room.Family != "illusion" || room.Slot != 1 {
		return out, false, err
	}
	state, err := d.LoadRoomState(room.Payload)
	if err != nil {
		return out, false, d.ErrInvalid
	}
	out = IllusionRoomNotice{RoomID: room.ID, Status: illusionStage(room.Members()), TeamInfo: state.TeamInfo, ReportID: state.ReportID,
		DamageResults: state.DamageResults, ParadiseID: state.ParadiseID}
	if room.Status == sharedroom.StatusClosed {
		out.Removed = seatPlayers(room)
	} else {
		out.Seated = room.Members()
		for _, seat := range room.Seats {
			if seat.Stage != sharedroom.SeatSeated {
				out.Removed = append(out.Removed, seat.Player)
			}
		}
	}
	for _, id := range state.Invites {
		out.Invites = append(out.Invites, identity.PlayerID(id))
	}
	profile, found, err := r.Directory.ProfileTx(c, r.Queryer, room.Owner)
	if err != nil {
		return out, false, err
	}
	if found {
		out.Master = profile
	}
	return out, true, nil
}

func illusionStage(members []identity.PlayerID) int64 {
	if len(members) >= int(d.TeamSeats) {
		return 1
	}
	return 0
}

func seatPlayers(room sharedroom.Room) []identity.PlayerID {
	out := make([]identity.PlayerID, 0, len(room.Seats))
	for _, seat := range room.Seats {
		out = append(out, seat.Player)
	}
	return out
}

func ValidateIllusionRoomNotice(value any) error {
	object, ok := value.(*amf3.Object)
	if !ok || object == nil {
		return rt.ErrInvalidS2CPayload
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 1 {
		return rt.ErrInvalidS2CPayload
	}
	message, ok := fields["message"].(*amf3.Object)
	if !ok || message == nil {
		return rt.ErrInvalidS2CPayload
	}
	body, err := message.StrictMap()
	if err != nil {
		return rt.ErrInvalidS2CPayload
	}
	roomID, roomOK := body["room_id"].(int64)
	if !roomOK || roomID < 0 {
		return rt.ErrInvalidS2CPayload
	}
	if roomID == 0 {
		return nil
	}
	status, ok := body["status"].(int64)
	if !ok || (status != 0 && status != 1) {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func ValidateIllusionInviteNotice(value any) error {
	object, ok := value.(*amf3.Object)
	if !ok || object == nil {
		return rt.ErrInvalidS2CPayload
	}
	fields, err := object.StrictMap()
	if err != nil || len(fields) != 2 || fields["notice_type"] != IllusionInviteNoticeType {
		return rt.ErrInvalidS2CPayload
	}
	params, ok := fields["params"].(*amf3.Object)
	if !ok || params == nil {
		return rt.ErrInvalidS2CPayload
	}
	body, err := params.StrictMap()
	if err != nil {
		return rt.ErrInvalidS2CPayload
	}
	paradise, paradiseOK := body["paradise_id"].(int64)
	roomID, roomOK := body["room_id"].(int64)
	player, playerOK := body["player_info"].(*amf3.Object)
	if !paradiseOK || paradise <= 0 || !roomOK || roomID <= 0 || !playerOK || player == nil {
		return rt.ErrInvalidS2CPayload
	}
	profile, err := player.StrictMap()
	if err != nil {
		return rt.ErrInvalidS2CPayload
	}
	id, idOK := profile["player_id"].(int64)
	name, nameOK := profile["player_name"].(string)
	level, levelOK := profile["lev"].(int64)
	if !idOK || id <= 0 || !nameOK || name == "" || !levelOK || level <= 0 {
		return rt.ErrInvalidS2CPayload
	}
	return nil
}

func NewIllusionRoomNoticeRegistry() (rt.EventRegistry, error) {
	return rt.NewEventRegistry(
		[]rt.DirectRegistration{{MID: mids.MIDIllusionNotice, Roles: []rt.Role{rt.World}, Validate: ValidateIllusionRoomNotice}},
		[]rt.NoticeRegistration{{ParentMID: mids.MIDPlayerNotice, Namespace: rt.NoticeNamespaceGeneric, NoticeType: IllusionInviteNoticeType, Roles: []rt.Role{rt.World}, Validate: ValidateIllusionInviteNotice}},
	)
}

type IllusionRoomNoticeSource interface {
	ReadRoomNotice(context.Context, string) (IllusionRoomNotice, bool, error)
}

type IllusionRoomNoticeHandler struct {
	Service         IllusionRoomNoticeSource
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	Delivered       *RoomNoticeLedger
	OnDeliveryError func(error)
}

// RoomNoticeLedger remembers each room's one-shot removal and invite notices:
// the wakeup carries only the room, and the room keeps departed seats and invites.
// shortcut: in memory, so a realtime restart repeats them once for a live room;
// persist delivery if that repeat ever reaches a player seated elsewhere.
type RoomNoticeLedger struct {
	mu       sync.Mutex
	rooms    map[int64]map[roomOneShot]bool
	observed map[int64]*roomObservation
}

type roomOneShot struct {
	mid    uint16
	player identity.PlayerID
}

func NewRoomNoticeLedger() *RoomNoticeLedger {
	return &RoomNoticeLedger{rooms: map[int64]map[roomOneShot]bool{}, observed: map[int64]*roomObservation{}}
}

func (l *RoomNoticeLedger) undelivered(room int64, mid uint16, players []identity.PlayerID) []identity.PlayerID {
	l.mu.Lock()
	defer l.mu.Unlock()
	out := make([]identity.PlayerID, 0, len(players))
	for _, player := range players {
		if !l.rooms[room][roomOneShot{mid, player}] {
			out = append(out, player)
		}
	}
	return out
}

func (l *RoomNoticeLedger) markDelivered(room int64, mid uint16, player identity.PlayerID) {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.rooms[room] == nil {
		l.rooms[room] = map[roomOneShot]bool{}
	}
	l.rooms[room][roomOneShot{mid, player}] = true
}

// reseat lets a player who rejoined be told of a later departure again.
func (l *RoomNoticeLedger) reseat(room int64, mid uint16, players []identity.PlayerID) {
	l.mu.Lock()
	defer l.mu.Unlock()
	for _, player := range players {
		delete(l.rooms[room], roomOneShot{mid, player})
	}
}

func (l *RoomNoticeLedger) forget(room int64) {
	l.mu.Lock()
	defer l.mu.Unlock()
	delete(l.rooms, room)
	delete(l.observed, room)
}

func (h IllusionRoomNoticeHandler) ReloadAndDeliver(c context.Context, reference string) error {
	if h.Service == nil || h.Registry == nil || h.Authority == nil || h.Delivered == nil || h.Time == nil || h.MaxHandles < 1 {
		return errors.New("illusion room notice unavailable")
	}
	c, cancel := context.WithTimeout(c, 2*time.Second)
	defer cancel()
	view, found, err := h.Service.ReadRoomNotice(c, reference)
	if err != nil || !found {
		return err
	}
	h.Delivered.reseat(view.RoomID, mids.MIDIllusionNotice, view.Seated)
	if removed := h.Delivered.undelivered(view.RoomID, mids.MIDIllusionNotice, view.Removed); len(removed) > 0 {
		frame, err := illusionFrame(map[string]any{"room_id": int64(0)})
		if err != nil {
			return err
		}
		for _, player := range removed {
			if err := h.deliver(c, player, mids.MIDIllusionNotice, frame); err != nil {
				return err
			}
			h.Delivered.markDelivered(view.RoomID, mids.MIDIllusionNotice, player)
		}
	}
	if len(view.Seated) > 0 {
		base, err := illusionMessage(view)
		if err != nil {
			return err
		}
		for _, player := range view.Seated {
			message := cloneMessage(base)
			message["room_id"] = view.RoomID
			message["status"] = view.Status
			if view.ReportID != "" {
				message["is_report"] = int64(1)
				message["report_id"] = view.ReportID
				if raw, ok := view.DamageResults[strconv.FormatInt(int64(player), 10)]; ok {
					value, err := decodeRawNumber(raw)
					if err != nil {
						return err
					}
					message["damage_result"] = value
				}
			}
			frame, err := illusionFrame(message)
			if err != nil {
				return err
			}
			if err := h.deliver(c, player, mids.MIDIllusionNotice, frame); err != nil {
				return err
			}
		}
	}
	for _, player := range h.Delivered.undelivered(view.RoomID, mids.MIDPlayerNotice, view.Invites) {
		if err := h.deliverInvite(c, view, player); err != nil {
			return err
		}
		h.Delivered.markDelivered(view.RoomID, mids.MIDPlayerNotice, player)
	}
	if len(view.Seated) == 0 {
		h.Delivered.forget(view.RoomID)
	}
	return nil
}

func (h IllusionRoomNoticeHandler) deliverInvite(c context.Context, view IllusionRoomNotice, player identity.PlayerID) error {
	params := map[string]any{"paradise_id": view.ParadiseID, "room_id": view.RoomID,
		"player_info": map[string]any{"player_id": int64(view.Master.PlayerID), "player_name": view.Master.Name, "lev": view.Master.Level,
			"avatar_id": view.Master.AvatarID, "avatar_frame_id": view.Master.AvatarFrameID}}
	converted, err := tournamentAMF(params)
	if err != nil {
		return err
	}
	frame := &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: IllusionInviteNoticeType}, {Name: "params", Value: converted}}}
	return h.deliver(c, player, mids.MIDPlayerNotice, frame)
}

func (h IllusionRoomNoticeHandler) deliver(c context.Context, player identity.PlayerID, mid uint16, frame *amf3.Object) error {
	return RoomDelivery{Registry: h.Registry, Publisher: h.Publisher, Authority: h.Authority, Time: h.Time, MaxHandles: h.MaxHandles, OnDeliveryError: h.OnDeliveryError}.Deliver(c, player, mid, frame)
}

// RoomDelivery publishes one frame to every current world connection of a player.
type RoomDelivery struct {
	Registry        *ConnectionRegistry
	Publisher       RealtimePublisher
	Authority       realtimeauth.GameplayLivenessPort
	Time            SocialDeliveryTime
	MaxHandles      int
	OnDeliveryError func(error)
}

func (delivery RoomDelivery) Deliver(c context.Context, player identity.PlayerID, mid uint16, frame *amf3.Object) error {
	handles := delivery.Registry.ByPlayerRole(player, domainrt.World)
	if len(handles) > delivery.MaxHandles {
		return errors.New("room notice connection bound exceeded")
	}
	for _, handle := range handles {
		metadata, valid := handle.Metadata()
		if !valid || !delivery.Registry.IsCurrent(handle) || metadata.PlayerID != player || metadata.PhysicalRole != domainrt.World || metadata.RoomID != int64(metadata.LogicalServerID) {
			continue
		}
		at, err := delivery.Time.Now(c)
		if err != nil {
			return err
		}
		actor := identity.ActorContext{AccountID: metadata.AccountID, AccountUID: metadata.AccountUID, SessionID: metadata.SessionID, ContextID: metadata.ContextID, LogicalServerID: metadata.LogicalServerID, PlayerID: metadata.PlayerID, ContextGeneration: metadata.ContextGeneration, SessionLivenessVersion: metadata.SessionLivenessVersion, ContextLivenessVersion: metadata.ContextLivenessVersion}
		if delivery.Authority.ValidateActor(c, actor, at) != nil {
			continue
		}
		if mid == mids.MIDIllusionNotice {
			err = delivery.Publisher.PublishDirect(c, handle, mid, frame)
		} else {
			err = delivery.Publisher.PublishNotice(c, handle, mid, rt.NoticeNamespaceGeneric, frame)
		}
		if err != nil && delivery.OnDeliveryError != nil {
			delivery.OnDeliveryError(err)
		}
	}
	return nil
}

// illusionMessage decodes the cached teamInfo and patches membership and ready
// flags from the authoritative seats, so a push stays usable after a leave.
func illusionMessage(view IllusionRoomNotice) (map[string]any, error) {
	message := map[string]any{}
	if len(view.TeamInfo) > 0 {
		if err := json.Unmarshal(view.TeamInfo, &message); err != nil {
			return nil, err
		}
	}
	if message["master_partner_detail"] == nil {
		message["master_partner_detail"] = []any{}
	}
	if message["master_pet_detail"] == nil {
		message["master_pet_detail"] = map[string]any{}
	}
	slots := []struct{ idName, infoName, prefix string }{
		{"master_id", "master_id_info", "master"}, {"mate_1", "mate_1_info", "mate_1"}, {"mate_2", "mate_2_info", "mate_2"}}
	for index, slot := range slots {
		id := int64(0)
		status := int64(0)
		if index < len(view.Seated) {
			id = int64(view.Seated[index])
			status = view.Status
		}
		message[slot.idName] = id
		message[slot.prefix+"_status"] = status
		if id == 0 {
			message[slot.infoName] = int64(0)
			message[slot.prefix+"_partner"] = ""
			message[slot.prefix+"_partner_detail"] = []any{}
		}
		if index == 0 && id == 0 {
			message["master_pet"] = int64(0)
			message["master_pet_detail"] = map[string]any{}
		}
	}
	return message, nil
}

func cloneMessage(base map[string]any) map[string]any {
	out := make(map[string]any, len(base))
	for key, value := range base {
		out[key] = value
	}
	return out
}

func illusionFrame(message map[string]any) (*amf3.Object, error) {
	converted, err := amfFromValue(message)
	if err != nil {
		return nil, err
	}
	return &amf3.Object{Properties: []amf3.Property{{Name: "message", Value: converted}}}, nil
}

// amfFromValue round-trips a body through JSON so every number keeps its width.
func amfFromValue(value any) (any, error) {
	payload, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.UseNumber()
	var raw any
	if err := decoder.Decode(&raw); err != nil {
		return nil, err
	}
	return tournamentAMF(raw)
}

func decodeRawNumber(raw json.RawMessage) (any, error) {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	var value any
	if err := decoder.Decode(&value); err != nil {
		return nil, err
	}
	return tournamentAMF(value)
}
