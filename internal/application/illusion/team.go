package illusion

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/publicstats"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	RoomFamily       = "illusion"
	RoomSlot   int64 = 1
	// RoomNoticeRoute wakes the realtime 518 projection for one room.
	RoomNoticeRoute = "illusion.room.notice.v1"
	// TeamTerminalKind names the one terminal of a team fight.
	TeamTerminalKind = "ILLUSION_TEAM_RESULT"

	roomLease = 3000 * time.Second
)

func RoomFamilyRef() sr.Family {
	return sr.Family{Name: RoomFamily, Slot: RoomSlot, Route: RoomNoticeRoute}
}

func (s Mode) roomReady() error {
	if s.Rooms.Store == nil || s.RoomStore == nil || s.Directory == nil || s.Heroes == nil || s.Stats == nil || s.Combat == nil || s.Content == nil || s.Store == nil {
		return d.ErrUnavailable
	}
	return nil
}

// CreateRoom answers 1349 and binds the boss that is open at creation.
func (s Mode) CreateRoom(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	if err = s.eligible(c, s.Fresh, a, at); err != nil {
		return nil, err
	}
	occurrence, catalog, err := s.currentOccurrence(c, s.Fresh, a, at)
	if err != nil {
		return nil, err
	}
	if !occurrence.CanStart(at) {
		return nil, fmt.Errorf("%w: illusion window closed", d.ErrRefused)
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !found || profile.Level < catalog.OpenLevel {
		return nil, fmt.Errorf("%w: illusion opens at level %d", d.ErrRefused, catalog.OpenLevel)
	}
	state := d.RoomState{ParadiseID: occurrence.CampaignID, MasterLevel: profile.Level}
	payload, err := state.Encode()
	if err != nil {
		return nil, err
	}
	if _, err = s.Rooms.Open(c, a, sr.OpenRequest{Family: RoomFamilyRef(), Capacity: d.TeamSeats, Lease: roomLease, Payload: payload}, op); err != nil {
		return nil, err
	}
	var info map[string]any
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		state, err := d.LoadRoomState(room.Payload)
		if err != nil {
			return err
		}
		info, err = s.teamInfo(c, sc.Tx, *room, state, sc.Operation.DecisionAt())
		if err != nil {
			return err
		}
		return s.storeTeamInfo(sc, room, state, info)
	}}, op)
	if err != nil {
		return nil, err
	}
	return info, nil
}

// RoomInfo answers 1350; an absent room is the client's empty reply.
func (s Mode) RoomInfo(c context.Context, a identity.ActorContext, _ operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	room, found, err := s.RoomStore.ReadPlayerRoomTx(c, s.Fresh, a.PlayerID, RoomFamily, RoomSlot)
	if err != nil || !found {
		return map[string]any{}, err
	}
	state, err := d.LoadRoomState(room.Payload)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	return s.teamInfo(c, s.Fresh, room, state, at)
}

// Prepare answers 1351 and Ready answers 1357 with the same per-seat flag.
func (s Mode) Prepare(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.setReady(c, a, true, op)
}

func (s Mode) Ready(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.setReady(c, a, true, op)
}

// CancelPrepare answers 1363.
func (s Mode) CancelPrepare(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	return s.setReady(c, a, false, op)
}

func (s Mode) setReady(c context.Context, a identity.ActorContext, ready bool, op operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	if _, err := s.Rooms.SetReady(c, a, RoomFamilyRef(), ready, op); err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// EnterRoom answers 1352 with the level band and capacity refused server side.
func (s Mode) EnterRoom(c context.Context, a identity.ActorContext, roomID int64, op operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	if roomID <= 0 {
		return nil, d.ErrInvalid
	}
	room, found, err := s.RoomStore.ReadRoomTx(c, s.Fresh, roomID)
	if err != nil {
		return nil, err
	}
	if !found || room.Family != RoomFamily || room.Slot != RoomSlot || room.Status != sharedroom.StatusOpen {
		return nil, fmt.Errorf("%w: room unavailable", d.ErrRefused)
	}
	if !seatedIn(room, a.PlayerID) && len(room.Members()) >= int(room.Capacity) {
		return nil, fmt.Errorf("%w: room full", d.ErrRefused)
	}
	state, err := d.LoadRoomState(room.Payload)
	if err != nil {
		return nil, err
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !found || profile.Level < d.OpenLevel || abs(profile.Level-state.MasterLevel) > d.TeamLevelBand {
		return nil, fmt.Errorf("%w: level band", d.ErrRefused)
	}
	joined, err := s.Rooms.Join(c, a, RoomFamilyRef(), roomID, op)
	if err != nil {
		return nil, err
	}
	state, err = d.LoadRoomState(joined.Payload)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	info, err := s.teamInfo(c, s.Fresh, joined, state, at)
	if err != nil {
		return nil, err
	}
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		state, err := d.LoadRoomState(room.Payload)
		if err != nil {
			return err
		}
		info, err = s.teamInfo(c, sc.Tx, *room, state, sc.Operation.DecisionAt())
		if err != nil {
			return err
		}
		return s.storeTeamInfo(sc, room, state, info)
	}}, op)
	if err != nil {
		return nil, err
	}
	return info, nil
}

// RemovePlayer answers 1353; the target's 518 room_id 0 comes from its KICKED
// seat on the room wakeup.
func (s Mode) RemovePlayer(c context.Context, a identity.ActorContext, target identity.PlayerID, op operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	if _, err := s.Rooms.Kick(c, a, RoomFamilyRef(), target, op); err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// ExitRoom answers 1354; an owner exit closes the room and wakes room_id 0.
func (s Mode) ExitRoom(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	if _, err := s.Rooms.Leave(c, a, RoomFamilyRef(), op); err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

type PartnerRequest struct {
	Heroes []int64
	PetID  int64
}

// SetPartner answers 1356 with ownership, duplicate, foreign-pet and mate-pet
// refusals; the checked pick is frozen into the room payload.
func (s Mode) SetPartner(c context.Context, a identity.ActorContext, request PartnerRequest, op operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	var info map[string]any
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		state, err := d.LoadRoomState(room.Payload)
		if err != nil {
			return err
		}
		seats := room.Members()
		index := seatOf(seats, a.PlayerID)
		if index < 0 {
			return d.ErrRefused
		}
		pick, err := s.validatePick(c, sc, state, seats, index, request, sc.Operation.DecisionAt())
		if err != nil {
			return err
		}
		state.SetPick(int64(a.PlayerID), pick)
		info, err = s.teamInfo(c, sc.Tx, *room, state, sc.Operation.DecisionAt())
		if err != nil {
			return err
		}
		return s.storeTeamInfo(sc, room, state, info)
	}}, op)
	if err != nil {
		return nil, err
	}
	return info, nil
}

// Invite answers 1360: the target's level band is checked and the room wakeup
// carries a friend notice type 6 to the appended invitee.
func (s Mode) Invite(c context.Context, a identity.ActorContext, target identity.PlayerID, op operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	if _, err := s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		if room.Owner != a.PlayerID {
			return fmt.Errorf("%w: only the master invites", d.ErrRefused)
		}
		if target == a.PlayerID || !target.Valid() {
			return d.ErrInvalid
		}
		state, err := d.LoadRoomState(room.Payload)
		if err != nil {
			return err
		}
		profile, found, err := s.Directory.ProfileTx(c, sc.Tx, target)
		if err != nil {
			return err
		}
		if !found || profile.Level < d.OpenLevel || abs(profile.Level-state.MasterLevel) > d.TeamLevelBand {
			return fmt.Errorf("%w: level band", d.ErrRefused)
		}
		if state.Invited(int64(target)) {
			return nil
		}
		state.Invites = append(state.Invites, int64(target))
		payload, err := state.Encode()
		if err != nil {
			return err
		}
		return room.SetPayload(payload, sc.Operation.DecisionAt())
	}}, op); err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

func (s Mode) currentOccurrence(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time) (d.Occurrence, d.Catalog, error) {
	revision, err := s.Content.ActiveRevision(c, q)
	if err != nil {
		return d.Occurrence{}, d.Catalog{}, err
	}
	catalog, err := s.Content.IllusionCatalogTx(c, q, revision)
	if err != nil {
		return d.Occurrence{}, d.Catalog{}, err
	}
	occurrence, found, err := s.Store.ReadOccurrenceTx(c, q, int64(a.LogicalServerID))
	if err != nil {
		return d.Occurrence{}, d.Catalog{}, err
	}
	if !found {
		occurrence = d.NewOccurrence(int64(a.LogicalServerID), d.FirstCampaignID, modes.Day(at))
	}
	occurrence.Roll(catalog, at)
	return occurrence, catalog, nil
}

func (s Mode) validatePick(c context.Context, sc gen.TimedScope, state d.RoomState, seats []identity.PlayerID, index int, request PartnerRequest, at time.Time) (d.TeamPick, error) {
	heroes := d.MasterHeroes
	if index > 0 {
		heroes = d.MateHeroes
		if request.PetID != 0 {
			return d.TeamPick{}, fmt.Errorf("%w: mate pet", d.ErrRefused)
		}
	}
	if len(request.Heroes) != heroes || request.PetID < 0 {
		return d.TeamPick{}, d.ErrInvalid
	}
	roster, err := s.heroRows(c, sc.Tx, seats[index], at)
	if err != nil {
		return d.TeamPick{}, err
	}
	revision, err := s.Content.ActiveRevision(c, sc.Tx)
	if err != nil {
		return d.TeamPick{}, err
	}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, revision, at)
	if err != nil {
		return d.TeamPick{}, err
	}
	used := map[int64]bool{}
	for otherIndex, member := range seats {
		if otherIndex == index {
			continue
		}
		otherRoster, err := s.heroRows(c, sc.Tx, member, at)
		if err != nil {
			return d.TeamPick{}, err
		}
		for _, id := range state.Pick(int64(member)).Heroes {
			used[tableIDOf(otherRoster, id)] = true
		}
	}
	force := int64(0)
	powers := make([]int64, 0, len(request.Heroes))
	for _, id := range request.Heroes {
		if _, owned := roster[strconv.FormatInt(id, 10)]; !owned {
			return d.TeamPick{}, fmt.Errorf("%w: hero %d not owned", d.ErrRefused, id)
		}
		tableID := tableIDOf(roster, id)
		if used[tableID] {
			return d.TeamPick{}, fmt.Errorf("%w: duplicate hero", d.ErrRefused)
		}
		used[tableID] = true
		result, err := s.Stats.HeroTx(c, scope, character.HeroRef{PlayerID: seats[index], PartnerID: id}, publicstats.View{Kind: publicstats.Self, Viewer: seats[index]})
		if err != nil {
			return d.TeamPick{}, err
		}
		power := int64(result.Stats.Force)
		powers = append(powers, power)
		force += power
	}
	for _, power := range powers {
		if power < force/d.TeamPowerLimit {
			return d.TeamPick{}, fmt.Errorf("%w: hero power", d.ErrRefused)
		}
	}
	if request.PetID > 0 {
		pets, err := s.petRows(c, sc.Tx, seats[index], at)
		if err != nil {
			return d.TeamPick{}, err
		}
		if _, owned := pets[strconv.FormatInt(request.PetID, 10)]; !owned {
			return d.TeamPick{}, fmt.Errorf("%w: pet %d not owned", d.ErrRefused, request.PetID)
		}
	}
	return d.TeamPick{Heroes: append([]int64(nil), request.Heroes...), PetID: request.PetID, Force: force}, nil
}

func (s Mode) heroRows(c context.Context, q tx.Queryer, player identity.PlayerID, at time.Time) (map[string]map[string]any, error) {
	detail := map[string]any{}
	if err := s.Heroes.OverlayMID1(c, q, identity.ActorContext{PlayerID: player}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["49"].(map[string]any)
	rows, _ := body["heros"].(map[string]any)
	out := make(map[string]map[string]any, len(rows))
	for key, raw := range rows {
		if row, ok := raw.(map[string]any); ok {
			out[key] = row
		}
	}
	return out, nil
}

func (s Mode) petRows(c context.Context, q tx.Queryer, player identity.PlayerID, at time.Time) (map[string]map[string]any, error) {
	if s.Pets == nil {
		return nil, d.ErrUnavailable
	}
	detail := map[string]any{}
	if err := s.Pets.OverlayMID1(c, q, identity.ActorContext{PlayerID: player}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail["780"].(map[string]any)
	rows, _ := body["pets"].([]any)
	out := make(map[string]map[string]any, len(rows))
	for _, raw := range rows {
		row, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		out[fmt.Sprint(row["pet_id"])] = row
	}
	return out, nil
}

func tableIDOf(roster map[string]map[string]any, partnerID int64) int64 {
	row, found := roster[strconv.FormatInt(partnerID, 10)]
	if !found {
		return partnerID
	}
	if id, ok := numeric(row["table_id"]); ok && id > 0 {
		return id
	}
	return partnerID
}

func (s Mode) storeTeamInfo(sc gen.TimedScope, room *sharedroom.Room, state d.RoomState, info map[string]any) error {
	raw, err := json.Marshal(info)
	if err != nil {
		return err
	}
	state.TeamInfo = raw
	payload, err := state.Encode()
	if err != nil {
		return err
	}
	return room.SetPayload(payload, sc.Operation.DecisionAt())
}

// teamInfo projects the full 1349/1350/1352/518 table. Seats are the master and
// up to two mates in seat order.
func (s Mode) teamInfo(c context.Context, q tx.Queryer, room sharedroom.Room, state d.RoomState, at time.Time) (map[string]any, error) {
	seats := room.Members()
	out := map[string]any{"room_id": room.ID, "status": stageOf(seats)}
	slots := []struct{ idName, infoName, prefix string }{
		{"master_id", "master_id_info", "master"}, {"mate_1", "mate_1_info", "mate_1"}, {"mate_2", "mate_2_info", "mate_2"}}
	for index, slot := range slots {
		if index >= len(seats) {
			out[slot.idName] = int64(0)
			out[slot.infoName] = int64(0)
			out[slot.prefix+"_status"] = int64(0)
			out[slot.prefix+"_partner"] = ""
			out[slot.prefix+"_partner_detail"] = []map[string]any{}
			if index == 0 {
				out["master_pet"] = int64(0)
				out["master_pet_detail"] = map[string]any{}
			}
			continue
		}
		player := seats[index]
		profile, found, err := s.Directory.ProfileTx(c, q, player)
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, d.ErrRefused
		}
		pick := state.Pick(int64(player))
		roster, err := s.heroRows(c, q, player, at)
		if err != nil {
			return nil, err
		}
		details := make([]map[string]any, 0, len(pick.Heroes))
		ids := make([]string, 0, len(pick.Heroes))
		for _, id := range pick.Heroes {
			ids = append(ids, strconv.FormatInt(id, 10))
			if row, owned := roster[strconv.FormatInt(id, 10)]; owned {
				details = append(details, row)
			}
		}
		out[slot.idName] = int64(player)
		out[slot.infoName] = playerInfo(profile, pick.Force)
		out[slot.prefix+"_status"] = readyOf(room, player)
		out[slot.prefix+"_partner"] = strings.Join(ids, "|")
		out[slot.prefix+"_partner_detail"] = details
		if index == 0 {
			out["master_pet"] = pick.PetID
			pets, err := s.petRows(c, q, player, at)
			if err != nil {
				return nil, err
			}
			out["master_pet_detail"] = map[string]any{}
			if row, owned := pets[strconv.FormatInt(pick.PetID, 10)]; owned {
				out["master_pet_detail"] = row
			}
		}
	}
	return out, nil
}

func playerInfo(profile playerdirectory.Profile, force int64) map[string]any {
	return map[string]any{"player_id": int64(profile.PlayerID), "player_name": profile.Name, "avatar_id": profile.AvatarID,
		"avatar_frame_id": profile.AvatarFrameID, "lev": profile.Level, "force": force,
		"conquer_lev": profile.ConquerLevel, "conquer_loop_id": profile.ConquerLoopID}
}

func stageOf(seats []identity.PlayerID) int64 {
	if len(seats) >= int(d.TeamSeats) {
		return 1
	}
	return 0
}

func readyOf(room sharedroom.Room, player identity.PlayerID) int64 {
	for _, seat := range room.Seats {
		if seat.Player == player && seat.Stage == sharedroom.SeatSeated && seat.Ready {
			return 1
		}
	}
	return 0
}

func seatedIn(room sharedroom.Room, player identity.PlayerID) bool {
	for _, seat := range room.Seats {
		if seat.Player == player && seat.Stage == sharedroom.SeatSeated {
			return true
		}
	}
	return false
}

func seatOf(seats []identity.PlayerID, player identity.PlayerID) int {
	for index, member := range seats {
		if member == player {
			return index
		}
	}
	return -1
}

func abs(value int64) int64 {
	if value < 0 {
		return -value
	}
	return value
}
