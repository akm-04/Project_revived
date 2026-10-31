package occult

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"slices"
	"strconv"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	cb "gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/occult"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	// teamCombatCampaignType is the stock CampaignType.OCCULT_COOPERATION.
	teamCombatCampaignType = 56
	teamTerminalKind       = "OCCULT_TEAM_RESULT"
)

// FormationRequest is a 2383 pick: one hero at a position, or the member's pet.
type FormationRequest struct {
	CampaignID int64
	SubID      int64
	PartnerID  int64
	Position   int64
	PetID      int64
}

func (r FormationRequest) valid() bool {
	hero := r.PartnerID > 0 && r.Position >= 1 && r.Position <= d.TeamHeroSlots && r.PetID == 0
	pet := r.PetID > 0 && r.PartnerID == 0 && r.Position == 0
	return hero || pet
}

// teamStage resolves the team fight a command talks about: the room must be a
// started co-op room and the stage the live fight's. A window that ran out has
// already been released by the lookup, which a refusal then rolls back; the next
// invite releases it for good.
func teamStage(view *roomView, campaignID, subID int64) (*d.TeamFight, error) {
	if view.state.CampaignType != d.MultiCampaignType || !view.state.Started() {
		return nil, fmt.Errorf("%w: not a started team room", d.ErrRefused)
	}
	team := view.state.LiveTeam(campaignID, subID, view.at.Unix())
	if team == nil {
		return nil, fmt.Errorf("%w: no team fight on this stage", d.ErrRefused)
	}
	return team, nil
}

func memberIDs(view *roomView) []int64 {
	members := view.room.Members()
	out := make([]int64, 0, len(members))
	for _, member := range members {
		out = append(out, int64(member))
	}
	return out
}

// TeamInvite answers 2374. The stage's event fires once and may pass it; else the
// caller becomes start_player, holds the stage and the other members are asked.
func (s Mode) TeamInvite(c context.Context, a identity.ActorContext, campaignID, subID int64, op operation.Context) (map[string]any, error) {
	return s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		if view.state.CampaignType != d.MultiCampaignType {
			return nil, fmt.Errorf("%w: not a team room", d.ErrRefused)
		}
		campaign, err := reachableCampaign(view, campaignID)
		if err != nil {
			return nil, err
		}
		index, err := stageOf(campaign, subID)
		if err != nil {
			return nil, err
		}
		autoPass, err := s.fireCampaignEvent(c, sc, a, view, campaign)
		if err != nil {
			return nil, err
		}
		body := map[string]any{"is_auto_pass": autoPass}
		if autoPass {
			view.state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: int64(a.PlayerID), CampaignID: campaign.ID})
			return body, s.settleIfCleared(c, sc, a, view, body)
		}
		opened, err := view.state.OpenTeamFight(campaign.ID, index, int64(a.PlayerID), view.at.Unix())
		if err != nil {
			return nil, err
		}
		team := view.state.Team
		if opened {
			team.Accept(int64(a.PlayerID), len(view.room.Members()), view.at.Unix())
			view.state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamInvite, Actor: int64(a.PlayerID), CampaignID: campaign.ID, SubID: subID})
			view.state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: int64(a.PlayerID), CampaignID: campaign.ID})
		}
		info, err := s.subCampaignInfo(c, sc.Tx, view.state)
		if err != nil {
			return nil, err
		}
		body["sub_campaign_info"] = info
		return body, nil
	})
}

// TeamAccept answers 2375. A refusal ends the invite for everyone; the last
// acceptance opens the selection window.
func (s Mode) TeamAccept(c context.Context, a identity.ActorContext, campaignID, subID int64, accept bool, op operation.Context) (map[string]any, error) {
	return s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		team, err := teamStage(view, campaignID, subID)
		if err != nil {
			return nil, err
		}
		if team.Selecting() {
			return s.teamReply(c, sc, view)
		}
		if !accept {
			view.state.AbandonTeam()
			view.state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamQuit, Actor: int64(a.PlayerID), CampaignID: campaignID, SubID: subID})
			view.state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: int64(a.PlayerID), CampaignID: campaignID})
			return map[string]any{}, nil
		}
		team.Accept(int64(a.PlayerID), len(view.room.Members()), view.at.Unix())
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamAccept, Actor: int64(a.PlayerID), CampaignID: campaignID, SubID: subID})
		return s.teamReply(c, sc, view)
	})
}

func (s Mode) teamReply(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
	info, err := s.subCampaignInfo(c, sc.Tx, view.state)
	if err != nil {
		return nil, err
	}
	return map[string]any{"sub_campaign_info": info}, nil
}

// TeamQuit answers 2376. Quitting a fight that is gone or settled is not an error.
func (s Mode) TeamQuit(c context.Context, a identity.ActorContext, campaignID, subID int64, op operation.Context) (map[string]any, error) {
	return s.update(c, a, op, func(_ context.Context, _ gen.TimedScope, view *roomView) (map[string]any, error) {
		if view.state.LiveTeam(campaignID, subID, view.at.Unix()) == nil {
			return map[string]any{}, nil
		}
		view.state.AbandonTeam()
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamQuit, Actor: int64(a.PlayerID), CampaignID: campaignID, SubID: subID})
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: int64(a.PlayerID), CampaignID: campaignID})
		return map[string]any{}, nil
	})
}

// TeamSelect answers 2383 with the ownership and duplicate refusals; the picked
// roster row is frozen into the room so every member draws the same formation.
func (s Mode) TeamSelect(c context.Context, a identity.ActorContext, request FormationRequest, op operation.Context) (map[string]any, error) {
	if !request.valid() {
		return nil, d.ErrInvalid
	}
	return s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		team, err := teamStage(view, request.CampaignID, request.SubID)
		if err != nil {
			return nil, err
		}
		if !team.Selecting() || team.Fighting() {
			return nil, fmt.Errorf("%w: formation is not open", d.ErrRefused)
		}
		if request.PetID > 0 {
			err = s.pickPet(c, sc.Tx, view, team, a.PlayerID, request.PetID)
		} else {
			err = s.pickHero(c, sc.Tx, view, team, a.PlayerID, request)
		}
		if err != nil {
			return nil, err
		}
		if err = view.room.SetReady(a.PlayerID, false, view.at); err != nil {
			return nil, err
		}
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamSelect, Actor: int64(a.PlayerID), CampaignID: request.CampaignID, SubID: request.SubID})
		return map[string]any{}, nil
	})
}

func (s Mode) pickHero(c context.Context, q tx.Queryer, view *roomView, team *d.TeamFight, player identity.PlayerID, request FormationRequest) error {
	roster, err := s.rosterRows(c, q, s.Heroes, player, view.at, "49", "heros")
	if err != nil {
		return err
	}
	row, owned := roster[strconv.FormatInt(request.PartnerID, 10)]
	if !owned {
		return fmt.Errorf("%w: hero %d not owned", d.ErrRefused, request.PartnerID)
	}
	used, err := fieldedTableIDs(view, team, player, int(request.Position))
	if err != nil {
		return err
	}
	if used[tableIDOf(row, request.PartnerID)] {
		return fmt.Errorf("%w: duplicate hero", d.ErrRefused)
	}
	raw, err := json.Marshal(row)
	if err != nil {
		return err
	}
	team.SetHero(int64(player), int(request.Position), request.PartnerID, raw)
	return nil
}

// fieldedTableIDs are the hero table ids already in the team, leaving out the
// position being replaced.
func fieldedTableIDs(view *roomView, team *d.TeamFight, player identity.PlayerID, replacing int) (map[int64]bool, error) {
	used := map[int64]bool{}
	for _, member := range view.room.Members() {
		pick := team.Pick(int64(member))
		for index, row := range pick.Rows {
			if member == player && index+1 == replacing || pick.Heroes[index] == 0 {
				continue
			}
			var fielded map[string]any
			if err := json.Unmarshal(row, &fielded); err != nil {
				return nil, err
			}
			used[tableIDOf(fielded, pick.Heroes[index])] = true
		}
	}
	return used, nil
}

func (s Mode) pickPet(c context.Context, q tx.Queryer, view *roomView, team *d.TeamFight, player identity.PlayerID, petID int64) error {
	if s.Pets == nil {
		return d.ErrUnavailable
	}
	pets, err := s.rosterRows(c, q, s.Pets, player, view.at, "780", "pets")
	if err != nil {
		return err
	}
	row, owned := pets[strconv.FormatInt(petID, 10)]
	if !owned {
		return fmt.Errorf("%w: pet %d not owned", d.ErrRefused, petID)
	}
	raw, err := json.Marshal(row)
	if err != nil {
		return err
	}
	team.SetPet(int64(player), petID, raw)
	return nil
}

// rosterRows reads one stock roster key as rows by partner or pet id; heroes
// arrive as a map and pets as a list.
func (s Mode) rosterRows(c context.Context, q tx.Queryer, source Heroes, player identity.PlayerID, at time.Time, key, field string) (map[string]map[string]any, error) {
	detail := map[string]any{}
	if err := source.OverlayMID1(c, q, identity.ActorContext{PlayerID: player}, false, at, detail); err != nil {
		return nil, err
	}
	body, _ := detail[key].(map[string]any)
	rows := map[string]map[string]any{}
	switch listed := body[field].(type) {
	case map[string]any:
		for id, raw := range listed {
			if row, ok := raw.(map[string]any); ok {
				rows[id] = row
			}
		}
	case []any:
		for _, raw := range listed {
			if row, ok := raw.(map[string]any); ok {
				rows[fmt.Sprint(row["pet_id"])] = row
			}
		}
	}
	return rows, nil
}

func tableIDOf(row map[string]any, fallback int64) int64 {
	switch id := row["table_id"].(type) {
	case int64:
		return id
	case float64:
		return int64(id)
	}
	return fallback
}

// TeamPrepare answers 2378: it toggles the caller's readiness, which the room
// core keeps as the seat's ready flag the Combat admission checks.
func (s Mode) TeamPrepare(c context.Context, a identity.ActorContext, campaignID, subID int64, op operation.Context) (map[string]any, error) {
	return s.update(c, a, op, func(_ context.Context, _ gen.TimedScope, view *roomView) (map[string]any, error) {
		team, err := teamStage(view, campaignID, subID)
		if err != nil {
			return nil, err
		}
		if !team.Selecting() || team.Fighting() {
			return nil, fmt.Errorf("%w: formation is not open", d.ErrRefused)
		}
		if len(team.Pick(int64(a.PlayerID)).Fielded()) < 1 {
			return nil, fmt.Errorf("%w: no hero picked", d.ErrRefused)
		}
		ready := team.Toggle(int64(a.PlayerID))
		if err = view.room.SetReady(a.PlayerID, ready, view.at); err != nil {
			return nil, err
		}
		view.state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamPrepare, Actor: int64(a.PlayerID), CampaignID: campaignID, SubID: subID})
		return map[string]any{}, nil
	})
}

// StartTeamFight answers 2377: the start player starts one Combat attempt with
// every member fielded, convener first, resolves it outside the locks and
// settles every member once. A repeat returns the stored report and never
// admits again.
func (s Mode) StartTeamFight(c context.Context, a identity.ActorContext, campaignID, subID int64, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	var attemptID string
	var replay map[string]any
	_, err = s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		stored, err := s.storedFight(c, sc.Tx, a, view, campaignID, subID)
		if err != nil || stored != nil {
			replay = stored
			return nil, err
		}
		attemptID, err = s.startAttempt(c, sc, a, view, campaignID, subID)
		return nil, err
	})
	if err != nil || replay != nil {
		return replay, err
	}
	attempt, err := ids.ParseUUID(attemptID)
	if err != nil {
		return nil, d.ErrInvalid
	}
	if _, err = s.Combat.Resolve(c, op, attempt); err != nil {
		return nil, err
	}
	return s.update(c, a, op, func(c context.Context, sc gen.TimedScope, view *roomView) (map[string]any, error) {
		stored, err := s.storedFight(c, sc.Tx, a, view, campaignID, subID)
		if err != nil || stored != nil {
			return stored, err
		}
		return s.settleAttempt(c, sc, a, view, attempt)
	})
}

// storedFight answers a repeated 2377 of a settled stage from its stored report.
func (s Mode) storedFight(c context.Context, q tx.Queryer, a identity.ActorContext, view *roomView, campaignID, subID int64) (map[string]any, error) {
	team := view.state.Team
	if team == nil || !team.Settled() || team.CampaignID != campaignID || team.SubID != subID {
		return nil, nil
	}
	if team.StartPlayer != int64(a.PlayerID) {
		return nil, fmt.Errorf("%w: only the start player replays", d.ErrRefused)
	}
	return s.storedReport(c, q, a, team.ReportKey, view.at)
}

func (s Mode) startAttempt(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView, campaignID, subID int64) (string, error) {
	team, err := teamStage(view, campaignID, subID)
	if err != nil {
		return "", err
	}
	if team.StartPlayer != int64(a.PlayerID) {
		return "", fmt.Errorf("%w: only the start player starts", d.ErrRefused)
	}
	if team.AttemptID != "" {
		return team.AttemptID, nil
	}
	members := memberIDs(view)
	if !team.Selecting() || len(team.Accepted) != len(members) || !team.AllPrepared(members) {
		return "", fmt.Errorf("%w: team is not ready", d.ErrRefused)
	}
	campaign, ok := view.catalog.Campaign(team.CampaignID)
	if !ok {
		return "", d.ErrUnavailable
	}
	started, err := s.startTeamAttempt(c, sc, a, view, *team, campaign)
	if err != nil {
		return "", err
	}
	team.AttemptID = started.Attempt.ID.String()
	team.FightStartedAt = view.at.Unix()
	return team.AttemptID, nil
}

// teamRoster is the start player first, then the others in seat order.
func teamRoster(view *roomView, startPlayer int64) []identity.PlayerID {
	roster := []identity.PlayerID{identity.PlayerID(startPlayer)}
	for _, member := range view.room.Members() {
		if int64(member) != startPlayer {
			roster = append(roster, member)
		}
	}
	return roster
}

func (s Mode) startTeamAttempt(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView, team d.TeamFight, campaign d.Campaign) (cb.Started, error) {
	index, err := stageOf(campaign, team.SubID)
	if err != nil {
		return cb.Started{}, err
	}
	waves, err := s.Combat.MonsterWaves(campaign.FightIDs[index])
	if err != nil {
		return cb.Started{}, err
	}
	battle := cb.BattleRequest{CampaignType: teamCombatCampaignType, BattleID: campaign.FightIDs[index], WavesB: waves}
	roster := teamRoster(view, team.StartPlayer)
	for position, member := range roster {
		origin := cd.OwnedSelf
		if position > 0 {
			origin = cd.OwnedMember
		}
		pick := team.Pick(int64(member))
		for _, heroID := range pick.Fielded() {
			battle.TeamA = append(battle.TeamA, cb.Participant{Origin: origin, Kind: cd.HeroActor, Player: member, Identity: heroID})
		}
		if pick.PetID > 0 {
			battle.PetsA = append(battle.PetsA, cb.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: member, Identity: pick.PetID})
		}
	}
	op := sc.Operation.Operation()
	revision, _ := op.Policies.Get("content")
	scope, err := ca.NewCoherentReadScope(tx.Scope{Tx: sc.Tx, Operation: op, Attempt: sc.Attempt, Options: sc.Options}, revision, view.at)
	if err != nil {
		return cb.Started{}, err
	}
	return s.Combat.StartTx(c, sc.Tx, scope, cb.StartRequest{Actor: a, Locator: teamLocator(view.room.ID, view.room.LogicalServerID), GenerationRef: teamGeneration(view.room.ID, team),
		StartFingerprint: teamFingerprint(view.room.ID, team, roster), ResultDeadline: view.at.Add(d.FightSeconds * time.Second), Battle: battle,
		TrustProfile: cd.ServerReport, Members: roster})
}

func (s Mode) settleAttempt(c context.Context, sc gen.TimedScope, a identity.ActorContext, view *roomView, attempt ids.UUID) (map[string]any, error) {
	team := view.state.Team
	if team == nil || team.AttemptID != attempt.String() {
		return nil, fmt.Errorf("%w: the team fight is gone", d.ErrRefused)
	}
	locator := teamLocator(view.room.ID, view.room.LogicalServerID)
	terminal, err := s.Combat.TerminalTx(c, sc.Tx, cb.TerminalRequest{Locator: locator, GenerationRef: teamGeneration(view.room.ID, *team), TerminalKind: teamTerminalKind,
		SemanticReceiptID: teamReceipt(attempt.String()), At: view.at})
	if err != nil {
		return nil, err
	}
	for _, member := range teamRoster(view, team.StartPlayer) {
		if _, err = s.Combat.SettleMemberTx(c, sc.Tx, cb.MemberSettleRequest{Locator: locator, AttemptID: attempt, Member: member,
			SemanticReceiptID: teamMemberReceipt(attempt.String(), member), At: view.at}); err != nil {
			return nil, err
		}
	}
	// shortcut: the server holds no monster stats, so a lost fight leaves the stage
	// HP and the hero status untouched; only a win empties the stage.
	result, err := view.state.ApplyTeamResult(terminal.Resolution.Outcome.Star)
	if err != nil {
		return nil, err
	}
	awards := map[identity.PlayerID][]d.Reward{}
	if result.Won {
		if awards, err = s.settleCleared(c, sc, a, view); err != nil {
			return nil, err
		}
	}
	report, err := withStar(terminal.Report, terminal.Resolution.Outcome.Star)
	if err != nil {
		return nil, err
	}
	reportKey := attempt.String()
	if err = s.storeReport(c, sc.Tx, view, reportKey, report, awards); err != nil {
		return nil, err
	}
	entry := logEntry(view.at, battleLogType, team.CampaignID, view.room.Members()...)
	if err = s.Store.InsertLogTx(c, sc.Tx, int64(view.room.LogicalServerID), view.room.ID, battleLogType, a.PlayerID, mustJSON(entry), view.at); err != nil {
		return nil, err
	}
	campaignID, subID := team.CampaignID, team.SubID
	view.state.Conclude(reportKey)
	view.state.AddNotice(d.NoticeRecord{Function: d.NoticeTeamFight, Actor: int64(a.PlayerID), CampaignID: campaignID, SubID: subID, ReportKey: reportKey})
	view.state.AddNotice(d.NoticeRecord{Function: d.NoticeFightStatus, Actor: int64(a.PlayerID), CampaignID: campaignID})
	if err = s.unreadyAll(view); err != nil {
		return nil, err
	}
	body := map[string]any{"battle_report": string(report), "award_info": map[string]any{"awards": rewardRows(awards[a.PlayerID])}}
	return body, s.fillState(c, sc, a, view, body, result.Score)
}

func (s Mode) unreadyAll(view *roomView) error {
	for _, member := range view.room.Members() {
		if err := view.room.SetReady(member, false, view.at); err != nil {
			return err
		}
	}
	return nil
}

// withStar makes sure the report carries the star the replay window reads.
func withStar(report []byte, star int64) ([]byte, error) {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(report, &fields); err != nil {
		return nil, fmt.Errorf("%w: team report", d.ErrUnavailable)
	}
	if _, present := fields["star"]; !present {
		fields["star"] = json.RawMessage(strconv.FormatInt(star, 10))
	}
	return json.Marshal(fields)
}

type storedContent struct {
	BattleReport string                      `json:"battle_report"`
	Awards       map[string][]map[string]any `json:"awards"`
}

func (s Mode) storeReport(c context.Context, t tx.Tx, view *roomView, reportKey string, report []byte, awards map[identity.PlayerID][]d.Reward) error {
	content := storedContent{BattleReport: string(report), Awards: map[string][]map[string]any{}}
	for member, rewards := range awards {
		content.Awards[numberKey(int64(member))] = rewardRows(rewards)
	}
	raw, err := json.Marshal(content)
	if err != nil {
		return err
	}
	return s.Store.InsertReportTx(c, t, reportKey, int64(view.room.LogicalServerID), view.room.ID, memberIDs(view), string(raw), view.at)
}

// storedReport reads a report for a member only; anyone else gets the refusal.
func (s Mode) storedReport(c context.Context, q tx.Queryer, a identity.ActorContext, reportKey string, at time.Time) (map[string]any, error) {
	raw, found, err := s.Store.ReadReportTx(c, q, reportKey, int64(a.LogicalServerID), a.PlayerID, at)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, fmt.Errorf("%w: no such report", d.ErrRefused)
	}
	var content storedContent
	if err = json.Unmarshal([]byte(raw), &content); err != nil {
		return nil, d.ErrUnavailable
	}
	awards := content.Awards[numberKey(int64(a.PlayerID))]
	if awards == nil {
		awards = []map[string]any{}
	}
	return map[string]any{"battle_report": content.BattleReport, "award_info": map[string]any{"awards": awards}}, nil
}

// TeamReport answers 2382: the stored report of a fight the caller was in, in the
// shape the replay window reads (battle_report[1].report).
func (s Mode) TeamReport(c context.Context, a identity.ActorContext, reportKey string, op operation.Context) (map[string]any, error) {
	if reportKey == "" {
		return nil, d.ErrInvalid
	}
	loaded, err := s.read(c, a, op)
	if err != nil {
		return nil, err
	}
	stored, err := s.storedReport(c, s.Fresh, a, reportKey, loaded.at)
	if err != nil {
		return nil, err
	}
	body, err := s.body(c, a, loaded)
	if err != nil {
		return nil, err
	}
	body["battle_report"] = []map[string]any{{"report": stored["battle_report"]}}
	body["award_info"] = stored["award_info"]
	return body, nil
}

func teamLocator(roomID int64, server identity.LogicalServerID) cd.Locator {
	return cd.Locator{DomainKind: "OCCULT", AuthorityScope: fmt.Sprintf("server:%d", server), DomainLocator: fmt.Sprintf("room:%d", roomID)}
}

func teamGeneration(roomID int64, team d.TeamFight) string {
	return fmt.Sprintf("OCCULT_TEAM/%d/%d/%d/%d", roomID, team.CampaignID, team.SubID, team.Round)
}

func teamReceipt(attemptID string) string { return "occult-team:" + attemptID }

func teamMemberReceipt(attemptID string, member identity.PlayerID) string {
	return fmt.Sprintf("occult-team:%s:%d", attemptID, member)
}

// teamFingerprint is deterministic so a replayed start is a Combat replay, not a
// new attempt: it never names the request operation.
func teamFingerprint(roomID int64, team d.TeamFight, roster []identity.PlayerID) string {
	picks := make([]d.TeamPick, 0, len(roster))
	for _, member := range roster {
		picks = append(picks, team.Pick(int64(member)))
	}
	raw, _ := json.Marshal(struct {
		Room   int64
		Team   string
		Roster []identity.PlayerID
		Picks  []d.TeamPick
	}{roomID, teamGeneration(roomID, team), slices.Clone(roster), picks})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}
