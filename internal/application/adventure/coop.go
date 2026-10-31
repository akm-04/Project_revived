package adventure

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const coopCampaignType = 61

// CreateCoop answers 2423: the master's 10006 room bound to the occurrence.
func (s Mode) CreateCoop(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	catalog, err := s.adventureCatalog(c, s.Fresh, op)
	if err != nil {
		return nil, err
	}
	if err = s.admit(c, s.Fresh, a, catalog, at); err != nil {
		return nil, err
	}
	if err = s.admitCoop(c, s.Fresh, a, at); err != nil {
		return nil, err
	}
	occurrence, err := s.activeOccurrence(c, s.Fresh, a.PlayerID, d.EventIllusion, at)
	if err != nil {
		return nil, err
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, a.PlayerID)
	if err != nil || !found {
		return nil, d.ErrRefused
	}
	state := d.RoomState{RoomType: d.RoomTypeIllusion, SpecialData: occurrence.SpecialData, MasterLevel: profile.Level, Phase: "SELECTING"}
	payload, err := state.Encode()
	if err != nil {
		return nil, err
	}
	lease := occurrence.EndTime.Sub(at)
	if lease <= 0 {
		return nil, d.ErrExpired
	}
	room, err := s.Rooms.Open(c, a, sr.OpenRequest{Family: IllusionFamily(), Capacity: d.IllusionCoopSeats, Lease: lease, Payload: payload}, op)
	if err != nil {
		return nil, err
	}
	state, err = s.roomState(room)
	if err != nil {
		return nil, err
	}
	info, err := s.coopRoomInfo(c, s.Fresh, room, state)
	if err != nil {
		return nil, err
	}
	return map[string]any{"room_info": info}, nil
}

// EnterCoop answers 2425 with the function 43 gate and the level band.
func (s Mode) EnterCoop(c context.Context, a identity.ActorContext, roomID int64, op operation.Context) (map[string]any, error) {
	if roomID <= 0 {
		return nil, d.ErrInvalid
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	room, found, err := s.RoomStore.ReadRoomTx(c, s.Fresh, roomID)
	if err != nil {
		return nil, err
	}
	if !found || room.Family != RoomFamily || room.Slot != IllusionSlot || room.Status != sharedroom.StatusOpen {
		return nil, fmt.Errorf("%w: room unavailable", d.ErrRefused)
	}
	state, err := s.roomState(room)
	if err != nil {
		return nil, err
	}
	catalog, err := s.adventureCatalog(c, s.Fresh, op)
	if err != nil {
		return nil, err
	}
	if err = s.admit(c, s.Fresh, a, catalog, at); err != nil {
		return nil, err
	}
	if err = s.admitCoop(c, s.Fresh, a, at); err != nil {
		return nil, err
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, a.PlayerID)
	if err != nil || !found {
		return nil, d.ErrRefused
	}
	if abs64(profile.Level-state.MasterLevel) > d.IllusionLevelBand {
		return nil, fmt.Errorf("%w: level band", d.ErrRefused)
	}
	if len(room.Members()) >= int(room.Capacity) && !seated(room, a.PlayerID) {
		return nil, fmt.Errorf("%w: room full", d.ErrRefused)
	}
	joined, err := s.Rooms.Join(c, a, IllusionFamily(), roomID, op)
	if err != nil {
		return nil, err
	}
	state, err = s.roomState(joined)
	if err != nil {
		return nil, err
	}
	info, err := s.coopRoomInfo(c, s.Fresh, joined, state)
	if err != nil {
		return nil, err
	}
	return map[string]any{"room_info": info}, nil
}

// InviteCoop answers 2427: the target is appended for the room wakeup.
func (s Mode) InviteCoop(c context.Context, a identity.ActorContext, target identity.PlayerID, op operation.Context) (map[string]any, error) {
	if !target.Valid() || target == a.PlayerID {
		return nil, d.ErrInvalid
	}
	_, err := s.Rooms.Update(c, a, sr.UpdateRequest{Family: IllusionFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		if room.Owner != a.PlayerID {
			return fmt.Errorf("%w: only the master invites", d.ErrRefused)
		}
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		profile, found, err := s.Directory.ProfileTx(c, sc.Tx, target)
		if err != nil || !found {
			return d.ErrRefused
		}
		if abs64(profile.Level-state.MasterLevel) > d.IllusionLevelBand {
			return fmt.Errorf("%w: level band", d.ErrRefused)
		}
		if !state.Invited(int64(target)) {
			state.Invites = append(state.Invites, int64(target))
		}
		return s.restoreRoom(sc, room, state)
	}}, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

func (s Mode) RemoveCoop(c context.Context, a identity.ActorContext, target identity.PlayerID, op operation.Context) (map[string]any, error) {
	if !target.Valid() {
		return nil, d.ErrInvalid
	}
	if err := s.requireAdmission(c, a, op); err != nil {
		return nil, err
	}
	if _, err := s.Rooms.Kick(c, a, IllusionFamily(), target, op); err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

func (s Mode) ExitCoop(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if err := s.requireAdmission(c, a, op); err != nil {
		return nil, err
	}
	if _, err := s.Rooms.Leave(c, a, IllusionFamily(), op); err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// EnterTeamFight answers 2428: the master opens selection and every seat gets
// the ENTER_TEAM_FIGHT push.
func (s Mode) EnterTeamFight(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	_, err := s.Rooms.Update(c, a, sr.UpdateRequest{Family: IllusionFamily(), Before: func(c context.Context, t tx.Tx, room sharedroom.Room, at time.Time) error {
		catalog, err := s.adventureCatalog(c, t, op)
		if err != nil {
			return err
		}
		if err = s.admit(c, t, a, catalog, at); err != nil {
			return err
		}
		return s.admitCoop(c, t, a, at)
	}, Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		if room.Owner != a.PlayerID {
			return fmt.Errorf("%w: only the master starts", d.ErrRefused)
		}
		if len(room.Members()) != int(d.IllusionCoopSeats) {
			return fmt.Errorf("%w: three seats", d.ErrRefused)
		}
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		selfInfos := map[string]any{}
		for _, member := range room.Members() {
			info, err := s.pickBody(c, sc.Tx, member, sc.Operation.DecisionAt(), state.Pick(int64(member)), 0)
			if err != nil {
				return err
			}
			selfInfos[strconv.FormatInt(int64(member), 10)] = info
		}
		state.Phase = "SELECTING"
		state.AddPush(2, int64(a.PlayerID), true, map[string]any{"self_infos": selfInfos})
		return s.restoreRoom(sc, room, state)
	}}, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// SelectCoop answers 2429: one hero at a position or the master's pet.
func (s Mode) SelectCoop(c context.Context, a identity.ActorContext, request PickRequest, op operation.Context) (map[string]any, error) {
	hero := request.PartnerID > 0 && request.Position >= 1 && request.Position <= d.IllusionHeroes && request.PetID == 0
	pet := request.PetID > 0 && request.PartnerID == 0 && request.Position == 0
	if !hero && !pet {
		return nil, d.ErrInvalid
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: IllusionFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		if state.Phase != "SELECTING" {
			return fmt.Errorf("%w: selection is closed", d.ErrRefused)
		}
		pick := state.Pick(int64(a.PlayerID))
		if pet {
			if room.Owner != a.PlayerID {
				return fmt.Errorf("%w: only the master has a pet", d.ErrRefused)
			}
			pets, err := s.petRows(c, sc.Tx, a.PlayerID, at)
			if err != nil {
				return err
			}
			if _, owned := pets[strconv.FormatInt(request.PetID, 10)]; !owned {
				return fmt.Errorf("%w: pet %d not owned", d.ErrRefused, request.PetID)
			}
			pick.PetID = request.PetID
		} else {
			roster, err := s.heroRows(c, sc.Tx, a.PlayerID, at)
			if err != nil {
				return err
			}
			if _, owned := roster[strconv.FormatInt(request.PartnerID, 10)]; !owned {
				return fmt.Errorf("%w: hero %d not owned", d.ErrRefused, request.PartnerID)
			}
			tableID := tableIDOf(roster, request.PartnerID)
			for _, member := range room.Members() {
				otherRoster := roster
				if member != a.PlayerID {
					if otherRoster, err = s.heroRows(c, sc.Tx, member, at); err != nil {
						return err
					}
				}
				for index, id := range state.Pick(int64(member)).Heroes {
					if member == a.PlayerID && int64(index+1) == request.Position {
						continue
					}
					if id > 0 && tableIDOf(otherRoster, id) == tableID {
						return fmt.Errorf("%w: duplicate hero", d.ErrRefused)
					}
				}
			}
			heroes := append([]int64(nil), pick.Heroes...)
			for int64(len(heroes)) < request.Position {
				heroes = append(heroes, 0)
			}
			heroes[request.Position-1] = request.PartnerID
			pick.Heroes = heroes
		}
		state.SetPick(int64(a.PlayerID), pick)
		info, err := s.pickBody(c, sc.Tx, a.PlayerID, at, pick, 0)
		if err != nil {
			return err
		}
		state.AddPush(3, int64(a.PlayerID), true, map[string]any{"player_id": int64(a.PlayerID), "self_info": info})
		return s.restoreRoom(sc, room, state)
	}}, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// PrepareCoop answers 2430 as a prepare/cancel toggle.
func (s Mode) PrepareCoop(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if err := s.requireAdmission(c, a, op); err != nil {
		return nil, err
	}
	room, found, err := s.activeRoom(c, s.Fresh, a.PlayerID, IllusionFamily())
	if err != nil || !found {
		return nil, d.ErrRefused
	}
	ready := true
	for _, seat := range room.Seats {
		if seat.Player == a.PlayerID && seat.Stage == sharedroom.SeatSeated {
			ready = !seat.Ready
		}
	}
	if _, err = s.Rooms.SetReady(c, a, IllusionFamily(), ready, op); err != nil {
		return nil, err
	}
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: IllusionFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		pick := state.Pick(int64(a.PlayerID))
		prepare := int64(0)
		if ready {
			prepare = 1
		}
		info, err := s.pickBody(c, sc.Tx, a.PlayerID, sc.Operation.DecisionAt(), pick, prepare)
		if err != nil {
			return err
		}
		state.AddPush(4, int64(a.PlayerID), true, map[string]any{"player_id": int64(a.PlayerID), "self_info": info})
		return s.restoreRoom(sc, room, state)
	}}, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// StartCoop answers 2411. One server report, the same report key to all and one
// mail award per member; a replay returns the stored report and admits nothing.
func (s Mode) StartCoop(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	room, found, err := s.activeRoom(c, s.Fresh, a.PlayerID, IllusionFamily())
	if err != nil || !found {
		return nil, d.ErrRefused
	}
	if room.Owner != a.PlayerID {
		return nil, fmt.Errorf("%w: only the master starts", d.ErrRefused)
	}
	state, err := s.roomState(room)
	if err != nil {
		return nil, err
	}
	if state.ReportID != "" {
		if raw, ok := state.Reports[strconv.FormatInt(int64(a.PlayerID), 10)]; ok {
			return map[string]any{"battle_report": string(raw)}, nil
		}
		return map[string]any{}, nil
	}
	op, err = s.pin(c, op)
	if err != nil {
		return nil, err
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	var started cb.Started
	var fantasy illusion.Catalog
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: IllusionFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		if len(room.Members()) != int(d.IllusionCoopSeats) {
			return fmt.Errorf("%w: three seats", d.ErrRefused)
		}
		for _, seat := range room.Seats {
			if seat.Stage == sharedroom.SeatSeated && !seat.Ready {
				return fmt.Errorf("%w: team is not ready", d.ErrRefused)
			}
		}
		catalog, fantasyCatalog, err := s.readCatalogs(c, sc.Tx, sc.Operation.Operation())
		if err != nil {
			return err
		}
		if err = s.admit(c, sc.Tx, a, catalog, at); err != nil {
			return err
		}
		if err = s.admitCoop(c, sc.Tx, a, at); err != nil {
			return err
		}
		fantasy = fantasyCatalog
		campaign, ok := fantasy.Campaign(state.SpecialData)
		if !ok {
			return d.ErrUnavailable
		}
		battle, _, err := s.coopBattle(c, sc, *room, state, campaign, at)
		if err != nil {
			return err
		}
		scope, err := s.coherentScope(sc, at)
		if err != nil {
			return err
		}
		started, err = s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: coopLocator(*room),
			GenerationRef: coopGeneration(*room), StartFingerprint: coopFingerprint(*room, state),
			ResultDeadline: at.Add(attemptLimit), Battle: battle, TrustProfile: cd.ServerReport, Members: room.Members()})
		return err
	}}, op)
	if err != nil {
		return nil, err
	}
	if _, err = s.Combat.Resolve(c, op, started.Attempt.ID); err != nil {
		return nil, err
	}
	var report []byte
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: IllusionFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		at := sc.Operation.DecisionAt()
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		if state.ReportID != "" {
			report = state.Reports[strconv.FormatInt(int64(a.PlayerID), 10)]
			return nil
		}
		terminal, err := s.Combat.TerminalTx(c, sc.Tx, cb.TerminalRequest{Locator: coopLocator(*room), GenerationRef: coopGeneration(*room),
			TerminalKind: d.IllusionReportKeyKind, SemanticReceiptID: "adventure-illusion-team:" + started.Attempt.ID.String(), At: at})
		if err != nil {
			return err
		}
		report = terminal.Report
		damage, err := reportDamage(report)
		if err != nil {
			return err
		}
		catalog, _, err := s.readCatalogs(c, sc.Tx, sc.Operation.Operation())
		if err != nil {
			return err
		}
		_, lines := giftAwards(catalog, d.IllusionBaseGift)
		for _, member := range room.Members() {
			key := strconv.FormatInt(int64(member), 10)
			state.Reports[key] = append([]byte(nil), report...)
			if _, _, err = s.Mail.DeliverTx(c, sc.Tx, i5.SettlementMailRequest{Recipient: member, SourceKind: "ADVENTURE_ILLUSION",
				SourceKey: started.Attempt.ID.String(), Title: "Adventure", Sender: "Adventure", Body: "Sophia's Adventure reward",
				PolicyVersion: d.PolicyID, Lines: lines, At: at}); err != nil {
				return err
			}
		}
		state.AttemptID, state.ReportID, state.Phase, state.Damage = started.Attempt.ID.String(), started.Attempt.ID.String(), "DONE", damage
		members := make([]int64, 0, len(room.Members()))
		for _, member := range room.Members() {
			members = append(members, int64(member))
		}
		if err = s.Store.InsertReportTx(c, sc.Tx, state.ReportID, int64(room.LogicalServerID), room.ID, members, string(report), at); err != nil {
			return err
		}
		state.AddPush(5, int64(a.PlayerID), true, map[string]any{"total_damage": damage, "report_key": state.ReportID})
		if err = s.restoreRoom(sc, room, state); err != nil {
			return err
		}
		if occurrence, found, readErr := s.Store.ReadOccurrenceTx(c, sc.Tx, a.PlayerID, d.EventIllusion); readErr != nil {
			return readErr
		} else if found && occurrence.Active(at) {
			if _, err = s.finish(c, sc.Tx, a, occurrence, at); err != nil {
				return err
			}
		}
		return nil
	}}, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{"battle_report": string(report)}, nil
}

// GetReport serves 1362 the stored co-op report to a seated member of the
// same logical server, in the report[1].content envelope the client decodes.
func (s Mode) GetReport(c context.Context, a identity.ActorContext, reportID string, _ operation.Context) (map[string]any, error) {
	if s.Store == nil || s.Timed.Binder.Time == nil || reportID == "" {
		return nil, d.ErrUnavailable
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	raw, found, err := s.Store.ReadReportTx(c, s.Fresh, reportID, int64(a.LogicalServerID), a.PlayerID, at)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, d.ErrRefused
	}
	return map[string]any{"report": []map[string]any{{"content": raw}}}, nil
}

func (s Mode) coopBattle(c context.Context, sc gen.TimedScope, room sharedroom.Room, state d.RoomState, campaign illusion.Campaign, at time.Time) (cb.BattleRequest, bool, error) {
	waves, err := s.Combat.MonsterWaves(campaign.FightID)
	if err != nil {
		return cb.BattleRequest{}, false, err
	}
	battle := cb.BattleRequest{CampaignType: coopCampaignType, BattleID: campaign.FightID, WavesB: waves}
	for index, member := range room.Members() {
		pick := state.Pick(int64(member))
		if len(pick.Heroes) != d.IllusionHeroes {
			return cb.BattleRequest{}, false, fmt.Errorf("%w: member pick incomplete", d.ErrRefused)
		}
		origin := cd.OwnedSelf
		if index > 0 {
			origin = cd.OwnedMember
		}
		roster, err := s.heroRows(c, sc.Tx, member, at)
		if err != nil {
			return cb.BattleRequest{}, false, err
		}
		for _, id := range pick.Heroes {
			if _, owned := roster[strconv.FormatInt(id, 10)]; !owned {
				return cb.BattleRequest{}, false, fmt.Errorf("%w: hero %d not owned", d.ErrRefused, id)
			}
			battle.TeamA = append(battle.TeamA, cb.Participant{Origin: origin, Kind: cd.HeroActor, Player: member, Identity: id})
		}
		if pick.PetID > 0 {
			battle.PetsA = append(battle.PetsA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: member, Identity: pick.PetID})
		}
	}
	return battle, true, nil
}

func (s Mode) coopRoomInfo(c context.Context, q tx.Queryer, room sharedroom.Room, state d.RoomState) (map[string]any, error) {
	ids, infos, err := s.roomMembers(c, q, room)
	if err != nil {
		return nil, err
	}
	return map[string]any{"room_id": room.ID, "room_type": d.RoomTypeIllusion, "owner": int64(room.Owner),
		"members": ids, "member_infos": infos, "status": state.Phase}, nil
}

type PickRequest struct {
	PartnerID int64
	Position  int64
	PetID     int64
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
	detail := map[string]any{}
	if err := s.Heroes.OverlayMID1(c, q, identity.ActorContext{PlayerID: player}, false, at, detail); err != nil {
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
	if tableID, ok := row["table_id"].(int64); ok && tableID > 0 {
		return tableID
	}
	if tableID, err := strconv.ParseInt(fmt.Sprint(row["table_id"]), 10, 64); err == nil && tableID > 0 {
		return tableID
	}
	return partnerID
}

// pickBody is one member's team-window row: the stock hero rows they froze,
// their pet row when they have one, and the readiness flag.
func (s Mode) pickBody(c context.Context, q tx.Queryer, player identity.PlayerID, at time.Time, pick d.RoomPick, prepare int64) (map[string]any, error) {
	roster, err := s.heroRows(c, q, player, at)
	if err != nil {
		return nil, err
	}
	formation := make([]any, 0, len(pick.Heroes))
	for _, heroID := range pick.Heroes {
		if heroID <= 0 {
			continue
		}
		if row, ok := roster[strconv.FormatInt(heroID, 10)]; ok {
			formation = append(formation, row)
		}
	}
	info := map[string]any{"formation": formation, "is_prepare": prepare}
	if pick.PetID > 0 {
		pets, err := s.petRows(c, q, player, at)
		if err != nil {
			return nil, err
		}
		if row, ok := pets[strconv.FormatInt(pick.PetID, 10)]; ok {
			info["pet"] = row
		}
	}
	return info, nil
}

func coopLocator(room sharedroom.Room) cd.Locator {
	return cd.Locator{DomainKind: "ADVENTURE_ILLUSION", AuthorityScope: fmt.Sprintf("server:%d", room.LogicalServerID), DomainLocator: fmt.Sprintf("room:%d", room.ID)}
}

func coopGeneration(room sharedroom.Room) string {
	return fmt.Sprintf("ADVENTURE_ILLUSION_TEAM/%d", room.ID)
}

func coopFingerprint(room sharedroom.Room, state d.RoomState) string {
	raw, _ := json.Marshal(struct {
		Room  int64
		Picks map[string]d.RoomPick
	}{room.ID, state.Picks})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

func reportDamage(report []byte) (int64, error) {
	var parsed struct {
		Fighter map[string]struct {
			Harms float64 `json:"harms"`
		} `json:"fighter"`
	}
	if err := json.Unmarshal(report, &parsed); err != nil {
		return 0, d.ErrInvalid
	}
	total := 0.0
	for key, fighter := range parsed.Fighter {
		if !strings.HasPrefix(key, "A") {
			continue
		}
		if math.IsNaN(fighter.Harms) || math.IsInf(fighter.Harms, 0) || fighter.Harms < 0 {
			return 0, d.ErrInvalid
		}
		total += fighter.Harms
	}
	if total > float64(d.DefenseDamageCap) {
		total = float64(d.DefenseDamageCap)
	}
	return int64(total), nil
}
