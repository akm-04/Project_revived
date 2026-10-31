package adventure

import (
	"context"
	"fmt"
	"strconv"
	"time"

	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const defenseCampaignType = 62

var defenseSummaryPolicy = cd.SummaryPolicy{ID: "I9_ADVENTURE_DEFENSE_SUMMARY_V1", Version: 1, MaxStar: d.DefenseMaxStar, WinFromStar: true, MaxDamage: d.DefenseDamageCap}

// DefenseInfo answers 2417 for 10001: the occurrence owner's room is created on
// the first read (C5).
func (s Mode) DefenseInfo(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
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
	occurrence, err := s.activeOccurrence(c, s.Fresh, a.PlayerID, d.EventDefense, at)
	if err != nil {
		return nil, err
	}
	room, err := s.ensureDefenseRoom(c, a, catalog, occurrence, at, op)
	if err != nil {
		return nil, err
	}
	state, err := s.roomState(room)
	if err != nil {
		return nil, err
	}
	detail, err := s.defenseDetail(c, s.Fresh, room, state, a.PlayerID)
	if err != nil {
		return nil, err
	}
	return map[string]any{"detail": detail}, nil
}

func (s Mode) adventureCatalog(c context.Context, q tx.Queryer, op operation.Context) (d.Catalog, error) {
	revision, _ := op.Policies.Get("content")
	return s.Content.AdventureCatalogTx(c, q, revision)
}

func (s Mode) ensureDefenseRoom(c context.Context, a identity.ActorContext, catalog d.Catalog, occurrence d.Occurrence, at time.Time, op operation.Context) (sharedroom.Room, error) {
	if room, found, err := s.activeRoom(c, s.Fresh, a.PlayerID, DefenseFamily()); err != nil || found {
		return room, err
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, a.PlayerID)
	if err != nil {
		return sharedroom.Room{}, err
	}
	if !found {
		return sharedroom.Room{}, d.ErrRefused
	}
	campaign, ok := catalog.CampaignForLevel(profile.Level)
	if !ok {
		return sharedroom.Room{}, d.ErrRefused
	}
	state := d.RoomState{RoomType: d.RoomTypeDefense, SpecialData: d.EventDefense, CampaignID: campaign.ID, MasterLevel: profile.Level, Phase: "OPEN"}
	payload, err := state.Encode()
	if err != nil {
		return sharedroom.Room{}, err
	}
	lease := occurrence.EndTime.Sub(at)
	if lease <= 0 {
		return sharedroom.Room{}, d.ErrExpired
	}
	room, err := s.Rooms.Open(c, a, sr.OpenRequest{Family: DefenseFamily(), Capacity: d.DefenseRoomCapacity, Lease: lease, Payload: payload}, op)
	if err == nil || err != sr.ErrAlreadyInRoom {
		return room, err
	}
	room, found, err = s.activeRoom(c, s.Fresh, a.PlayerID, DefenseFamily())
	if err != nil || !found {
		return sharedroom.Room{}, d.ErrRefused
	}
	return room, nil
}

// defenseDetail is the 2417/2425 defense object and the ROOM_CHANGE room_info:
// room_info is the member list, the position and kill arrays are siblings, and
// challenge_times is the viewer's tries array indexed by position.
func (s Mode) defenseDetail(c context.Context, q tx.Queryer, room sharedroom.Room, state d.RoomState, viewer identity.PlayerID) (map[string]any, error) {
	ids, infos, err := s.roomMembers(c, q, room)
	if err != nil {
		return nil, err
	}
	positions := make([]any, d.DefenseMonsterCount)
	monsters := make([]any, d.DefenseMonsterCount)
	for position := 1; position <= d.DefenseMonsterCount; position++ {
		busy := state.Busy[position-1]
		positions[position-1] = map[string]any{"player_id": busy.Player, "busy_type": busy.Type}
		monsters[position-1] = state.Monsters[position-1].Killer
	}
	tries := state.TriesOf(int64(viewer))
	challenges := make([]any, len(tries))
	for index, value := range tries {
		challenges[index] = value
	}
	return map[string]any{
		"room_info": map[string]any{
			"room_id": room.ID, "table_id": d.EventDefense, "owner": int64(room.Owner),
			"members": ids, "member_infos": infos, "campaign_id": state.CampaignID,
		},
		"pos_statuses": positions, "monster_statuses": monsters, "challenge_times": challenges,
	}, nil
}

// EnterDefense answers 2425 with the server-side band and capacity.
func (s Mode) EnterDefense(c context.Context, a identity.ActorContext, roomID int64, op operation.Context) (map[string]any, error) {
	if roomID <= 0 {
		return nil, d.ErrInvalid
	}
	room, found, err := s.RoomStore.ReadRoomTx(c, s.Fresh, roomID)
	if err != nil {
		return nil, err
	}
	if !found || room.Family != RoomFamily || room.Slot != DefenseSlot || room.Status != sharedroom.StatusOpen {
		return nil, fmt.Errorf("%w: room unavailable", d.ErrRefused)
	}
	state, err := s.roomState(room)
	if err != nil {
		return nil, err
	}
	profile, found, err := s.Directory.ProfileTx(c, s.Fresh, a.PlayerID)
	if err != nil || !found {
		return nil, d.ErrRefused
	}
	if abs64(profile.Level-state.MasterLevel) > d.LevelBand {
		return nil, fmt.Errorf("%w: level band", d.ErrRefused)
	}
	if len(room.Members()) >= int(room.Capacity) && !seated(room, a.PlayerID) {
		return nil, fmt.Errorf("%w: room full", d.ErrRefused)
	}
	joined, err := s.Rooms.Join(c, a, DefenseFamily(), roomID, op)
	if err != nil {
		return nil, err
	}
	state, err = s.roomState(joined)
	if err != nil {
		return nil, err
	}
	return s.defenseDetail(c, s.Fresh, joined, state, a.PlayerID)
}

// PrepareDefense answers 2412: one try of a monster position is consumed and the
// position is marked busy for this player.
func (s Mode) PrepareDefense(c context.Context, a identity.ActorContext, position int64, op operation.Context) (map[string]any, error) {
	if position < 1 || position > d.DefenseMonsterCount {
		return nil, d.ErrInvalid
	}
	_, err := s.Rooms.Update(c, a, sr.UpdateRequest{Family: DefenseFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		return s.mutateRoom(sc, room, func(state *d.RoomState) error {
			if state.Monsters[position-1].Solved {
				return fmt.Errorf("%w: monster already killed", d.ErrRefused)
			}
			if state.Busy[position-1].Type != 0 {
				return fmt.Errorf("%w: position is busy", d.ErrRefused)
			}
			progress := d.DefenseProgress{}
			copy(progress.Tries[:], state.TriesOf(int64(a.PlayerID)))
			next, err := progress.Admit(position)
			if err != nil {
				return err
			}
			state.SetTries(int64(a.PlayerID), next.Tries[:])
			state.Busy[position-1] = d.BusyState{Player: int64(a.PlayerID), Type: 1}
			state.AddPush(6, int64(a.PlayerID), false, map[string]any{"room_id": room.ID, "monster_pos": position,
				"pos_status": map[string]any{"player_id": int64(a.PlayerID), "busy_type": int64(1)}})
			return nil
		})
	}}, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// StartDefense answers 2431: a client-summary attempt is frozen for one monster.
func (s Mode) StartDefense(c context.Context, a identity.ActorContext, request FightRequest, position int64, op operation.Context) (map[string]any, error) {
	if err := validateFormation(request.Formation); err != nil || position < 1 || position > d.DefenseMonsterCount {
		return nil, d.ErrInvalid
	}
	_, err := s.Rooms.Update(c, a, sr.UpdateRequest{Family: DefenseFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		at := sc.Operation.DecisionAt()
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		if state.Busy[position-1] != (d.BusyState{Player: int64(a.PlayerID), Type: 1}) {
			return fmt.Errorf("%w: position is not prepared", d.ErrRefused)
		}
		catalog, _, err := s.readCatalogs(c, sc.Tx, sc.Operation.Operation())
		if err != nil {
			return err
		}
		campaign, ok := catalog.CampaignByID(state.CampaignID)
		if !ok || position > int64(len(campaign.BattleIDs)) {
			return d.ErrUnavailable
		}
		waves, err := s.Combat.MonsterWaves(campaign.BattleIDs[position-1])
		if err != nil {
			return err
		}
		if err = s.ownedHeroes(c, sc.Tx, a, at, request.Formation); err != nil {
			return err
		}
		scope, err := s.coherentScope(sc, at)
		if err != nil {
			return err
		}
		started, err := s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: defenseLocator(*room, position),
			GenerationRef: defenseGeneration(*room, position), StartFingerprint: startFingerprint(a, sc.Operation.Operation().ID.String(), request.Formation),
			ResultDeadline: at.Add(attemptLimit), TrustProfile: cd.ClientSummaryAttested, Replay: cd.ReplaySpec{Response: cd.ReplayOK},
			Battle: cb.BattleRequest{CampaignType: defenseCampaignType, BattleID: campaign.BattleIDs[position-1], TeamA: ownedTeam(a.PlayerID, request.Formation), Formation: request.Formation, WavesB: waves}})
		if err != nil {
			return err
		}
		if state.Attempts == nil {
			state.Attempts = map[string]string{}
		}
		state.Attempts[strconv.Itoa(int(position))] = started.Attempt.ID.String()
		state.Busy[position-1] = d.BusyState{Player: int64(a.PlayerID), Type: 2}
		state.AddPush(6, int64(a.PlayerID), false, map[string]any{"room_id": room.ID, "monster_pos": position,
			"pos_status": map[string]any{"player_id": int64(a.PlayerID), "busy_type": int64(2)}})
		return s.restoreRoom(sc, room, state)
	}}, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

// DefenseResult answers 2410: the attested summary is clamped, the try is
// consumed once and the monster position records its killer.
func (s Mode) DefenseResult(c context.Context, a identity.ActorContext, request ResultRequest, position int64, op operation.Context) (Response, error) {
	if request.Star < 0 || request.Star > d.DefenseMaxStar || request.Damage < 0 || position < 1 || position > d.DefenseMonsterCount {
		return Response{}, d.ErrInvalid
	}
	if err := validateFormation(request.Formation); err != nil {
		return Response{}, d.ErrInvalid
	}
	var response Response
	room, err := s.Rooms.Update(c, a, sr.UpdateRequest{Family: DefenseFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		at := sc.Operation.DecisionAt()
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		attemptID := state.Attempts[strconv.Itoa(int(position))]
		if attemptID == "" {
			response.Duplicate = true
			return nil
		}
		if state.Busy[position-1] != (d.BusyState{Player: int64(a.PlayerID), Type: 2}) {
			return fmt.Errorf("%w: the position was not started by this player", d.ErrRefused)
		}
		attested, err := s.Combat.AttestSummaryTx(c, sc.Tx, cb.SummaryRequest{Locator: defenseLocator(*room, position),
			GenerationRef: defenseGeneration(*room, position), TerminalKind: "ADVENTURE_DEFENSE_RESULT", At: at, Policy: defenseSummaryPolicy,
			Summary: cd.Summary{Star: request.Star, Win: d.IsWin(request.Star), Damage: request.Damage, Formation: request.Formation}})
		if err != nil {
			return err
		}
		if attested.Drained || attested.Attestation.Verdict == cd.VerdictRejected {
			response.Duplicate = true
			return nil
		}
		star, _ := d.ClampDefense(request.Star, request.Damage)
		state.Busy[position-1] = d.BusyState{}
		delete(state.Attempts, strconv.Itoa(int(position)))
		killer := ""
		if d.IsWin(star) {
			profile, found, err := s.Directory.ProfileTx(c, sc.Tx, a.PlayerID)
			if err != nil {
				return err
			}
			if !found {
				return d.ErrRefused
			}
			killer = profile.Name
			state.Monsters[position-1] = d.MonsterState{Killer: killer, Solved: true}
		}
		state.AddPush(7, int64(a.PlayerID), true, map[string]any{"room_id": room.ID, "monster_pos": position,
			"pos_status": map[string]any{"player_id": int64(0), "busy_type": int64(0)}, "monster_status": monsterKillers(state)})
		return s.restoreRoom(sc, room, state)
	}}, op)
	if err != nil {
		return Response{}, err
	}
	state, err := s.roomState(room)
	if err != nil {
		return Response{}, err
	}
	detail, err := s.defenseDetail(c, s.Fresh, room, state, a.PlayerID)
	if err != nil {
		return Response{}, err
	}
	body := map[string]any{"favor": map[string]any{}, "exps": []any{}, "tutorCoin": int64(0), "star_crystal": int64(0),
		"awards": map[string]any{"awards": []any{}}, "room_info": detail["room_info"]}
	return Response{Body: body, Duplicate: response.Duplicate}, nil
}

func monsterKillers(state d.RoomState) []any {
	killers := make([]any, d.DefenseMonsterCount)
	for position := 0; position < d.DefenseMonsterCount; position++ {
		killers[position] = state.Monsters[position].Killer
	}
	return killers
}

func (s Mode) InviteDefense(c context.Context, a identity.ActorContext, target identity.PlayerID, op operation.Context) (map[string]any, error) {
	if !target.Valid() || target == a.PlayerID {
		return nil, d.ErrInvalid
	}
	_, err := s.Rooms.Update(c, a, sr.UpdateRequest{Family: DefenseFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		if room.Owner != a.PlayerID {
			return fmt.Errorf("%w: only the owner invites", d.ErrRefused)
		}
		state, err := s.roomState(*room)
		if err != nil {
			return err
		}
		profile, found, err := s.Directory.ProfileTx(c, sc.Tx, target)
		if err != nil || !found {
			return d.ErrRefused
		}
		if abs64(profile.Level-state.MasterLevel) > d.LevelBand {
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

func (s Mode) KickDefense(c context.Context, a identity.ActorContext, target identity.PlayerID, op operation.Context) (map[string]any, error) {
	if !target.Valid() {
		return nil, d.ErrInvalid
	}
	if err := s.requireAdmission(c, a, op); err != nil {
		return nil, err
	}
	if _, err := s.Rooms.Kick(c, a, DefenseFamily(), target, op); err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

func (s Mode) ExitDefense(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if err := s.requireAdmission(c, a, op); err != nil {
		return nil, err
	}
	if _, err := s.Rooms.Leave(c, a, DefenseFamily(), op); err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

func (s Mode) QuitDefense(c context.Context, a identity.ActorContext, position int64, op operation.Context) (map[string]any, error) {
	if position < 1 || position > d.DefenseMonsterCount {
		return nil, d.ErrInvalid
	}
	_, err := s.Rooms.Update(c, a, sr.UpdateRequest{Family: DefenseFamily(), Before: s.admissionBefore(a, op), Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
		return s.mutateRoom(sc, room, func(state *d.RoomState) error {
			if state.Busy[position-1].Player != int64(a.PlayerID) {
				return nil
			}
			state.Busy[position-1] = d.BusyState{}
			state.AddPush(8, int64(a.PlayerID), false, map[string]any{"room_id": room.ID, "monster_pos": position})
			return nil
		})
	}}, op)
	if err != nil {
		return nil, err
	}
	return map[string]any{}, nil
}

func defenseLocator(room sharedroom.Room, position int64) cd.Locator {
	return cd.Locator{DomainKind: "ADVENTURE_DEFENSE", AuthorityScope: fmt.Sprintf("server:%d", room.LogicalServerID),
		DomainLocator: fmt.Sprintf("room:%d/pos:%d", room.ID, position)}
}

func defenseGeneration(room sharedroom.Room, position int64) string {
	return fmt.Sprintf("ADVENTURE_DEFENSE/%d/%d", room.ID, position)
}

func seated(room sharedroom.Room, player identity.PlayerID) bool {
	for _, seat := range room.Seats {
		if seat.Player == player && seat.Stage == sharedroom.SeatSeated {
			return true
		}
	}
	return false
}
