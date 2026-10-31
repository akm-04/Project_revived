package illusion

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"math"
	"strings"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	sr "gxb.local/backend/v2/internal/application/sharedroom"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// StartTeam answers 1358: the master starts one server-report attempt with the
// seated roster, convener first. A replayed start reuses the frozen attempt,
// never admits again, and returns the stored report.
func (s Mode) StartTeam(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	if err := s.roomReady(); err != nil {
		return nil, err
	}
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	var attemptID string
	var report []byte
	var occurrence d.Occurrence
	var catalog d.Catalog
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(),
		Before: func(c context.Context, t tx.Tx, room sharedroom.Room, at time.Time) error {
			var err error
			occurrence, catalog, err = s.lockOccurrence(c, t, room.LogicalServerID, at)
			return err
		},
		Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
			at := sc.Operation.DecisionAt()
			state, err := d.LoadRoomState(room.Payload)
			if err != nil {
				return err
			}
			if state.ReportID != "" {
				raw, found, err := s.Store.ReadReportTx(c, sc.Tx, state.ReportID, at)
				if err != nil {
					return err
				}
				if found {
					report = []byte(raw)
					attemptID = state.AttemptID
				}
				return nil
			}
			if room.Owner != a.PlayerID {
				return fmt.Errorf("%w: only the master starts", d.ErrRefused)
			}
			if state.AttemptID != "" {
				attemptID = state.AttemptID
				return nil
			}
			if len(room.Members()) != int(d.TeamSeats) || !allReady(*room) {
				return fmt.Errorf("%w: team is not ready", d.ErrRefused)
			}
			if state.ParadiseID != occurrence.CampaignID || !occurrence.CanStart(at) {
				return fmt.Errorf("%w: bound boss is not open", d.ErrRefused)
			}
			campaign, found := catalog.Campaign(state.ParadiseID)
			if !found {
				return d.ErrUnavailable
			}
			team, err := s.teamFromRoom(c, sc.Tx, *room, state, at)
			if err != nil {
				return err
			}
			started, err := s.startTeamAttempt(c, sc, a, *room, team, occurrence, campaign, at)
			if err != nil {
				return err
			}
			attemptID = started.Attempt.ID.String()
			state.AttemptID = attemptID
			info, err := s.teamInfo(c, sc.Tx, *room, state, at)
			if err != nil {
				return err
			}
			return s.storeTeamInfo(sc, room, state, info)
		}}, op)
	if err != nil {
		return nil, err
	}
	if len(report) > 0 {
		return reportArray(report), nil
	}
	if attemptID == "" {
		return nil, d.ErrUnavailable
	}
	attemptUUID, err := ids.ParseUUID(attemptID)
	if err != nil {
		return nil, d.ErrInvalid
	}
	if _, err = s.Combat.Resolve(c, op, attemptUUID); err != nil {
		return nil, err
	}
	_, err = s.Rooms.Update(c, a, sr.UpdateRequest{Family: RoomFamilyRef(),
		Before: func(c context.Context, t tx.Tx, room sharedroom.Room, at time.Time) error {
			var err error
			occurrence, _, err = s.lockOccurrence(c, t, room.LogicalServerID, at)
			if err != nil {
				return err
			}
			for _, member := range room.Members() {
				if _, err := s.Store.LockPlayerTx(c, t, int64(room.LogicalServerID), member, at); err != nil {
					return err
				}
			}
			return nil
		},
		Apply: func(c context.Context, sc gen.TimedScope, room *sharedroom.Room) error {
			at := sc.Operation.DecisionAt()
			state, err := d.LoadRoomState(room.Payload)
			if err != nil {
				return err
			}
			if state.ReportID != "" {
				raw, found, err := s.Store.ReadReportTx(c, sc.Tx, state.ReportID, at)
				if err != nil {
					return err
				}
				if found {
					report = []byte(raw)
				}
				return nil
			}
			terminal, err := s.Combat.TerminalTx(c, sc.Tx, cb.TerminalRequest{Locator: teamLocator(*room), GenerationRef: teamGeneration(*room, occurrence),
				TerminalKind: TeamTerminalKind, SemanticReceiptID: teamReceipt(attemptID), At: at})
			if err != nil {
				return err
			}
			report = terminal.Report
			damage, err := reportDamage(report)
			if err != nil {
				return err
			}
			accepted := occurrence.Accept(damage)
			if err := s.Store.SaveOccurrenceTx(c, sc.Tx, occurrence, at); err != nil {
				return err
			}
			if err := s.Store.InsertReportTx(c, sc.Tx, attemptID, int64(room.LogicalServerID), occurrence.OpenDay, occurrence.CampaignID, string(report), at); err != nil {
				return err
			}
			costTime := terminal.Resolution.Outcome.Frames
			members := room.Members()
			for _, member := range members {
				if _, err := s.Combat.SettleMemberTx(c, sc.Tx, cb.MemberSettleRequest{Locator: teamLocator(*room), AttemptID: attemptUUID,
					Member: member, SemanticReceiptID: teamMemberReceipt(attemptID, member), At: at}); err != nil {
					return err
				}
				if err := s.creditMember(c, sc, *room, occurrence, member, attemptID, accepted, costTime, at); err != nil {
					return err
				}
			}
			state.ReportID = attemptID
			state.DamageResults = map[string]json.RawMessage{}
			for _, member := range members {
				attempt := d.Attempt{ID: attemptID, PlayerID: int64(member), LogicalServerID: int64(room.LogicalServerID), OpenDay: occurrence.OpenDay, CampaignID: occurrence.CampaignID}
				body, err := s.terminalBody(c, sc.Tx, attempt, member, accepted)
				if err != nil {
					return err
				}
				raw, err := json.Marshal(body)
				if err != nil {
					return err
				}
				state.DamageResults[fmt.Sprint(int64(member))] = raw
			}
			info, err := s.teamInfo(c, sc.Tx, *room, state, at)
			if err != nil {
				return err
			}
			return s.storeTeamInfo(sc, room, state, info)
		}}, op)
	if err != nil {
		return nil, err
	}
	return reportArray(report), nil
}

// GetReport answers 1362 from the stored team report.
func (s Mode) GetReport(c context.Context, reportID string, _ operation.Context) (map[string]any, error) {
	if s.Store == nil || s.Timed.Binder.Time == nil || reportID == "" {
		return nil, d.ErrUnavailable
	}
	at, err := s.Timed.Binder.Time.Now(c)
	if err != nil {
		return nil, err
	}
	raw, found, err := s.Store.ReadReportTx(c, s.Fresh, reportID, at)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, d.ErrRefused
	}
	return reportArray([]byte(raw)), nil
}

func (s Mode) lockOccurrence(c context.Context, t tx.Tx, server identity.LogicalServerID, at time.Time) (d.Occurrence, d.Catalog, error) {
	revision, err := s.Content.ActiveRevision(c, t)
	if err != nil {
		return d.Occurrence{}, d.Catalog{}, err
	}
	catalog, err := s.Content.IllusionCatalogTx(c, t, revision)
	if err != nil {
		return d.Occurrence{}, d.Catalog{}, err
	}
	occurrence, err := s.Store.LockOccurrenceTx(c, t, int64(server), at)
	if err != nil {
		return d.Occurrence{}, d.Catalog{}, err
	}
	if occurrence.Roll(catalog, at) {
		if err := s.Store.SaveOccurrenceTx(c, t, occurrence, at); err != nil {
			return d.Occurrence{}, d.Catalog{}, err
		}
	}
	return occurrence, catalog, nil
}

// teamFromRoom freezes the three seats' picks into the C5 validated team.
func (s Mode) teamFromRoom(c context.Context, q tx.Queryer, room sharedroom.Room, state d.RoomState, at time.Time) (d.Team, error) {
	seats := room.Members()
	if len(seats) != int(d.TeamSeats) {
		return d.Team{}, fmt.Errorf("%w: three seats", d.ErrRefused)
	}
	team := d.Team{Members: make([]d.TeamMember, 0, len(seats))}
	for index, player := range seats {
		profile, found, err := s.Directory.ProfileTx(c, q, player)
		if err != nil {
			return d.Team{}, err
		}
		if !found {
			return d.Team{}, d.ErrRefused
		}
		pick := state.Pick(int64(player))
		expected := d.MasterHeroes
		if index > 0 {
			expected = d.MateHeroes
		}
		if len(pick.Heroes) != expected || pick.PetID < 0 {
			return d.Team{}, fmt.Errorf("%w: member pick incomplete", d.ErrRefused)
		}
		roster, err := s.heroRows(c, q, player, at)
		if err != nil {
			return d.Team{}, err
		}
		member := d.TeamMember{PlayerID: int64(player), Level: profile.Level, Force: pick.Force, PetID: pick.PetID}
		for _, id := range pick.Heroes {
			if _, owned := roster[fmt.Sprint(id)]; !owned {
				return d.Team{}, fmt.Errorf("%w: hero %d not owned", d.ErrRefused, id)
			}
			member.Heroes = append(member.Heroes, d.Hero{TableID: tableIDOf(roster, id), PartnerID: id, Power: pick.Force})
		}
		team.Members = append(team.Members, member)
	}
	if err := team.Validate(); err != nil {
		return d.Team{}, err
	}
	return team, nil
}

func (s Mode) startTeamAttempt(c context.Context, sc gen.TimedScope, actor identity.ActorContext, room sharedroom.Room, team d.Team, occurrence d.Occurrence, campaign d.Campaign, at time.Time) (cb.Started, error) {
	waves, err := s.Combat.MonsterWaves(campaign.FightID)
	if err != nil {
		return cb.Started{}, err
	}
	battle := cb.BattleRequest{CampaignType: campaign.CampaignType, BattleID: campaign.FightID, WavesB: waves}
	for index, member := range team.Members {
		origin := cd.OwnedSelf
		if index > 0 {
			origin = cd.OwnedMember
		}
		for _, hero := range member.Heroes {
			battle.TeamA = append(battle.TeamA, cb.Participant{Origin: origin, Kind: cd.HeroActor, Player: identity.PlayerID(member.PlayerID), Identity: hero.PartnerID})
		}
		if member.PetID > 0 {
			battle.PetsA = append(battle.PetsA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: identity.PlayerID(member.PlayerID), Identity: member.PetID})
		}
	}
	op := sc.Operation.Operation()
	revision, _ := op.Policies.Get("content")
	if revision == "" {
		var err error
		if revision, err = s.Content.ActiveRevision(c, sc.Tx); err != nil {
			return cb.Started{}, err
		}
	}
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: op, Attempt: sc.Attempt, Options: sc.Options}, revision, at)
	if err != nil {
		return cb.Started{}, err
	}
	members := room.Members()
	return s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: actor, Locator: teamLocator(room), GenerationRef: teamGeneration(room, occurrence),
		StartFingerprint: teamFingerprint(room, team, occurrence), ResultDeadline: at.Add(attemptLimit), Battle: battle,
		TrustProfile: cd.ServerReport, Members: members})
}

func (s Mode) creditMember(c context.Context, sc gen.TimedScope, room sharedroom.Room, occurrence d.Occurrence, member identity.PlayerID, attemptID string, damage, costTime int64, at time.Time) error {
	result, err := s.Store.LockResultTx(c, sc.Tx, int64(room.LogicalServerID), occurrence.OpenDay, occurrence.CampaignID, member, at)
	if err != nil {
		return err
	}
	if damage > result.Hurt || damage == result.Hurt && costTime < result.CostTime {
		result.Hurt, result.CostTime = damage, costTime
	}
	if err := s.Store.SaveResultTx(c, sc.Tx, int64(room.LogicalServerID), occurrence.OpenDay, occurrence.CampaignID, result, at); err != nil {
		return err
	}
	player, err := s.Store.LockPlayerTx(c, sc.Tx, int64(room.LogicalServerID), member, at)
	if err != nil {
		return err
	}
	player.Reset(modes.Day(at))
	player.RecordHit(damage, costTime)
	if err := s.Store.SavePlayerTx(c, sc.Tx, player, at); err != nil {
		return err
	}
	return s.recordFantasy(c, sc, identity.ActorContext{PlayerID: member, LogicalServerID: room.LogicalServerID}, fmt.Sprintf("%s:%d", attemptID, member))
}

func allReady(room sharedroom.Room) bool {
	for _, seat := range room.Seats {
		if seat.Stage == sharedroom.SeatSeated && !seat.Ready {
			return false
		}
	}
	return true
}

func reportArray(raw []byte) map[string]any {
	return map[string]any{"report": []map[string]any{{"content": string(raw)}}}
}

func teamLocator(room sharedroom.Room) cd.Locator {
	return cd.Locator{DomainKind: "ILLUSION", AuthorityScope: fmt.Sprintf("server:%d", room.LogicalServerID), DomainLocator: fmt.Sprintf("room:%d", room.ID)}
}

func teamGeneration(room sharedroom.Room, occurrence d.Occurrence) string {
	return fmt.Sprintf("ILLUSION_TEAM/%d/%d/%d", room.ID, occurrence.OpenDay, occurrence.CampaignID)
}

func teamReceipt(attemptID string) string {
	return "illusion-team:" + attemptID
}

func teamMemberReceipt(attemptID string, member identity.PlayerID) string {
	return fmt.Sprintf("illusion-team:%s:%d", attemptID, member)
}

// teamFingerprint is deterministic so a replayed 1358 is a Combat replay, not a
// new attempt: it never names the request operation.
func teamFingerprint(room sharedroom.Room, team d.Team, occurrence d.Occurrence) string {
	raw, _ := json.Marshal(struct {
		Room       int64
		OpenDay    int64
		CampaignID int64
		Team       d.Team
	}{room.ID, occurrence.OpenDay, occurrence.CampaignID, team})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

// reportDamage sums the A-side harms of the stock fighter report.
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
	if total > float64(d.DamageCap) {
		total = float64(d.DamageCap)
	}
	return int64(total), nil
}
