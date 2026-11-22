package eventcentre

import (
	"crypto/sha256"
	"encoding/binary"
	"slices"
	"sort"
	"strconv"

	"gxb.local/backend/v2/internal/domain/identity"
)

// PRIVATE_POLICY I9-10A notice board: unrecovered original-server laws adopted
// as named values, tunable in docs/i9/I9_10A_NOTICEBOARD_POLICY.json.
const (
	BoardPolicyVersion        = "I9_10A_NOTICE_BOARD_V1"
	BoardBuilding             = int64(6)
	BoardTaskTypeNormal       = int64(1)
	BoardTaskTypeDeposit      = int64(2)
	BoardMaxPartners          = 5
	BoardHistoryLimit         = 50
	BlessingCrystalItemID     = int64(50001136)
	BoardDepositResourceKey   = "mana"
	BoardRefreshPolicy        = "DAILY_AT_GAME_DAY_0500_GMT8"
	BoardOfferPolicy          = "OWNED_HERO_ROWS_SORTED_BY_ID_TO_TASK_LIMIT"
	BoardAwardPolicy          = "MISSION_TIER_GRADE_DETERMINISTIC_BY_PLAYER_DAY_MISSION"
	BoardDepositAwardPolicy   = "DEPOSIT_TASKS_USE_GRADE_TWO_AWARD"
	BoardWishPolicy           = "WISH_DOUBLES_EVERY_AWARD_LINE"
	BoardDepositResultPolicy  = "WIN_CONSUMES_DEPOSIT_LOSS_REFUNDS_IT"
	BoardPowerCapPolicy       = "SUM_OF_DISPLAYED_HERO_FORCE_AT_MOST_UPPER_LIMIT_FIGHTING"
	BoardSettlementPolicy     = "SERVER_REPORT_RESOLVED_AT_DUE_OBSERVATION"
	BoardMissingOfferPolicy   = "NO_OFFER_ROW_REFUSES_START"
	BoardCampaignType         = int64(96)
	BoardTerminalKind         = "EVENT_CENTRE_BOARD_RESULT"
	BoardClosedKind           = "EVENT_CENTRE_BOARD_CLOSED"
	BoardReportContentPolicy  = "STORED_COMBAT_REPORT_JSON_STRING"
	BoardAwardLogPolicy       = "GRANTED_AWARDS_UNTIL_CONFIRM"
	BoardMinPlayerLevelByTier = "1,10,20"
)

var boardTierMinLevels = [...]int64{1, 10, 20}

type BoardRule struct {
	Level, TaskLimit, GoldTask int64
}

type MissionRule struct {
	ID               int64
	HeroID           int64
	FightID          int64
	Fighting         int64
	Duration         int64
	Deposit          int64
	EnemyIDs         []int64
	MonsterStars     []int64
	MonsterQualities []int64
	MonsterLevels    []int64
}

type HeroProfileRule struct {
	HeroID          int64
	MissionIDs      []int64
	ForceThresholds []int64
}

type AwardRule struct {
	ID              int64
	Grade           int64
	ItemID          int64
	ItemCount       int64
	MaterialIDs     []int64
	MaterialAmounts []int64
	Gold            int64
}

type BoardOffer struct {
	MissionID int64 `json:"mission_id"`
	Type      int64 `json:"type"`
	AwardID   int64 `json:"award_id"`
}

type BoardMission struct {
	MissionID   int64   `json:"mission_id"`
	Leader      int64   `json:"leader"`
	Partners    []int64 `json:"partners"`
	StartAt     int64   `json:"start_time"`
	Type        int64   `json:"type"`
	AwardID     int64   `json:"award_id"`
	WishCrystal bool    `json:"wish_crystal"`
	Attempt     string  `json:"attempt,omitempty"`
}

type BoardRun struct {
	MissionID int64 `json:"mission_id"`
	Win       bool  `json:"is_win"`
	ReportID  int64 `json:"battle_id"`
}

type BoardAward struct {
	MissionID   int64 `json:"mission_id"`
	Type        int64 `json:"type"`
	AwardID     int64 `json:"award_id"`
	WishCrystal int64 `json:"wish_crystal"`
}

type BoardState struct {
	RefreshDay   int64        `json:"refresh_day"`
	Offers       []BoardOffer `json:"offers"`
	Doing        []BoardMission
	History      []BoardRun   `json:"history"`
	AwardLog     []BoardAward `json:"award_log"`
	NextReportID int64        `json:"next_report_id"`
}

// BoardFacts narrows a State to the notice board section so callers cannot
// accidentally write another building's facts.
type BoardFacts = BoardState

func (s BoardState) Clone() BoardState {
	out := BoardState{RefreshDay: s.RefreshDay, NextReportID: s.NextReportID}
	out.Offers = append([]BoardOffer(nil), s.Offers...)
	for _, mission := range s.Doing {
		copyMission := mission
		copyMission.Partners = append([]int64(nil), mission.Partners...)
		out.Doing = append(out.Doing, copyMission)
	}
	out.History = append([]BoardRun(nil), s.History...)
	out.AwardLog = append([]BoardAward(nil), s.AwardLog...)
	return out
}

func (s BoardState) Validate() error {
	if s.RefreshDay < 0 || s.NextReportID < 1 || len(s.Offers) > 11 || len(s.Doing) > 11 || len(s.History) > BoardHistoryLimit || len(s.AwardLog) > 11 {
		return ErrUnqualified
	}
	offers := map[int64]bool{}
	for _, offer := range s.Offers {
		if offer.MissionID <= 0 || offer.AwardID <= 0 || !validBoardTaskType(offer.Type) || offers[offer.MissionID] {
			return ErrUnqualified
		}
		offers[offer.MissionID] = true
	}
	busy := map[int64]bool{}
	for _, mission := range s.Doing {
		if mission.MissionID <= 0 || mission.Leader <= 0 || mission.StartAt <= 0 || !validBoardTaskType(mission.Type) || mission.AwardID <= 0 || len(mission.Partners) > BoardMaxPartners {
			return ErrUnqualified
		}
		for _, hero := range append([]int64{mission.Leader}, mission.Partners...) {
			if hero <= 0 || busy[hero] {
				return ErrUnqualified
			}
			busy[hero] = true
		}
	}
	for _, run := range s.History {
		if run.MissionID <= 0 || run.ReportID < 0 {
			return ErrUnqualified
		}
	}
	for _, award := range s.AwardLog {
		if award.MissionID <= 0 || award.AwardID <= 0 || !validBoardTaskType(award.Type) || award.WishCrystal < 0 || award.WishCrystal > 1 {
			return ErrUnqualified
		}
	}
	return nil
}

func validBoardTaskType(kind int64) bool {
	return kind == BoardTaskTypeNormal || kind == BoardTaskTypeDeposit
}

func (c Catalog) validateBoard() error {
	for level := int64(1); level <= 5; level++ {
		rule, ok := c.Board[level]
		if !ok || rule.Level != level || rule.TaskLimit <= 0 || rule.GoldTask < 0 || rule.GoldTask > rule.TaskLimit {
			return ErrUnqualified
		}
	}
	for id, mission := range c.Missions {
		if id <= 0 || mission.ID != id || mission.HeroID <= 0 || mission.FightID <= 0 || mission.Duration <= 0 || mission.Deposit < 0 {
			return ErrUnqualified
		}
		if len(mission.EnemyIDs) != 5 || len(mission.MonsterStars) != 5 || len(mission.MonsterQualities) != 5 || len(mission.MonsterLevels) != 5 {
			return ErrUnqualified
		}
	}
	for id, profile := range c.HeroProfiles {
		if id <= 0 || profile.HeroID != id || len(profile.MissionIDs) != 3 || len(profile.ForceThresholds) != 3 {
			return ErrUnqualified
		}
		for _, threshold := range profile.ForceThresholds {
			if threshold <= 0 {
				return ErrUnqualified
			}
		}
	}
	for id, award := range c.Awards {
		if id <= 0 || award.ID != id || award.Grade < 1 || award.Grade > 3 || award.ItemCount < 0 || award.Gold <= 0 || len(award.MaterialIDs) != len(award.MaterialAmounts) {
			return ErrUnqualified
		}
		if award.ItemID == 0 && award.ItemCount != 0 || award.ItemID > 0 && award.ItemCount <= 0 {
			return ErrUnqualified
		}
	}
	return nil
}

func (c Catalog) BoardRule(level int64) (BoardRule, error) {
	if level < 1 {
		level = 1
	}
	rule, ok := c.Board[level]
	if !ok {
		return BoardRule{}, ErrUnqualified
	}
	return rule, nil
}

func (c Catalog) Mission(missionID int64) (MissionRule, bool) {
	rule, ok := c.Missions[missionID]
	return rule, ok
}

func (c Catalog) MissionTier(missionID int64) (HeroProfileRule, int64, bool) {
	for _, profile := range c.HeroProfiles {
		for index, candidate := range profile.MissionIDs {
			if candidate == missionID && index < len(profile.ForceThresholds) {
				return profile, int64(index + 1), true
			}
		}
	}
	return HeroProfileRule{}, 0, false
}

func (c Catalog) Award(awardID int64) (AwardRule, bool) {
	rule, ok := c.Awards[awardID]
	return rule, ok
}

func (c Catalog) awardIDs(grade int64) []int64 {
	out := make([]int64, 0, len(c.Awards))
	for id, rule := range c.Awards {
		if rule.Grade == grade {
			out = append(out, id)
		}
	}
	slices.Sort(out)
	return out
}

// chooseAward deterministically selects an award of the grade from the
// player, refresh day and mission id, so one refresh always shows one award.
func (c Catalog) chooseAward(grade int64, player identity.PlayerID, day, missionID int64) (int64, bool) {
	candidates := c.awardIDs(grade)
	if len(candidates) == 0 {
		return 0, false
	}
	sum := sha256.Sum256([]byte(strconv.FormatInt(int64(player), 10) + ":" + strconv.FormatInt(day, 10) + ":" + strconv.FormatInt(missionID, 10)))
	index := binary.BigEndian.Uint64(sum[:8]) % uint64(len(candidates))
	return candidates[index], true
}

// BoardOffers builds the day's offers from the mission rows whose required
// hero the player owns, sorted by mission id and capped by the board level's
// task limit. The first gold_task offerings, by deposit, are deposit tasks.
func (c Catalog) BoardOffers(level, playerLevel int64, ownedHeroIDs map[int64]bool, day int64, player identity.PlayerID) []BoardOffer {
	rule, err := c.BoardRule(level)
	if err != nil || rule.TaskLimit <= 0 {
		return nil
	}
	candidates := make([]MissionRule, 0, len(c.Missions))
	for _, mission := range c.Missions {
		if !ownedHeroIDs[mission.HeroID] {
			continue
		}
		_, tier, ok := c.MissionTier(mission.ID)
		if !ok || playerLevel < boardTierMinLevels[tier-1] {
			continue
		}
		candidates = append(candidates, mission)
	}
	sort.Slice(candidates, func(left, right int) bool { return candidates[left].ID < candidates[right].ID })
	if len(candidates) > 0 {
		rotation := sha256.Sum256([]byte(strconv.FormatInt(int64(player), 10) + "/" + strconv.FormatInt(day, 10)))
		offset := int(binary.BigEndian.Uint64(rotation[:8]) % uint64(len(candidates)))
		candidates = append(candidates[offset:], candidates[:offset]...)
	}
	if int64(len(candidates)) > rule.TaskLimit {
		candidates = candidates[:rule.TaskLimit]
	}
	gold := append([]MissionRule(nil), candidates...)
	sort.SliceStable(gold, func(left, right int) bool {
		if gold[left].Deposit != gold[right].Deposit {
			return gold[left].Deposit > gold[right].Deposit
		}
		return gold[left].ID < gold[right].ID
	})
	depositMissions := map[int64]bool{}
	for index := 0; index < len(gold) && int64(index) < rule.GoldTask; index++ {
		depositMissions[gold[index].ID] = true
	}
	offers := make([]BoardOffer, 0, len(candidates))
	for _, mission := range candidates {
		_, tier, _ := c.MissionTier(mission.ID)
		grade := tier
		kind := BoardTaskTypeNormal
		if depositMissions[mission.ID] {
			grade, kind = 2, BoardTaskTypeDeposit
		}
		awardID, ok := c.chooseAward(grade, player, day, mission.ID)
		if !ok {
			continue
		}
		offers = append(offers, BoardOffer{MissionID: mission.ID, Type: kind, AwardID: awardID})
	}
	return offers
}

func (s BoardState) Offer(missionID int64) (BoardOffer, bool) {
	for _, offer := range s.Offers {
		if offer.MissionID == missionID {
			return offer, true
		}
	}
	return BoardOffer{}, false
}

func (s BoardState) IsDoing(missionID int64) bool {
	for _, mission := range s.Doing {
		if mission.MissionID == missionID {
			return true
		}
	}
	return false
}

func (s BoardState) BusyHeroes() map[int64]bool {
	busy := map[int64]bool{}
	for _, mission := range s.Doing {
		busy[mission.Leader] = true
		for _, partner := range mission.Partners {
			busy[partner] = true
		}
	}
	return busy
}

func (s BoardState) DueMissions(at int64, catalog Catalog) []BoardMission {
	out := make([]BoardMission, 0, len(s.Doing))
	for _, mission := range s.Doing {
		rule, ok := catalog.Missions[mission.MissionID]
		if !ok || rule.Duration <= 0 {
			continue
		}
		if mission.StartAt+rule.Duration <= at {
			out = append(out, mission)
		}
	}
	return out
}

// CapFor returns the upper_limit_fighting cap of the mission's tier.
func (c Catalog) CapFor(missionID int64) (int64, bool) {
	profile, tier, ok := c.MissionTier(missionID)
	if !ok || tier < 1 || int(tier) > len(profile.ForceThresholds) {
		return 0, false
	}
	return profile.ForceThresholds[tier-1], true
}

// AwardSettlement is the win award after the wish multiplier is applied.
type AwardSettlement struct {
	ItemID    int64
	ItemCount int64
	Materials []ResourceAmount
	Gold      int64
}

func (c Catalog) WinAward(awardID int64, wish bool) (AwardSettlement, bool) {
	award, ok := c.Awards[awardID]
	if !ok {
		return AwardSettlement{}, false
	}
	multiplier := int64(1)
	if wish {
		multiplier = 2
	}
	out := AwardSettlement{ItemID: award.ItemID, ItemCount: award.ItemCount * multiplier, Gold: award.Gold * multiplier}
	for index, identifier := range award.MaterialIDs {
		if index >= len(award.MaterialAmounts) {
			return AwardSettlement{}, false
		}
		out.Materials = append(out.Materials, ResourceAmount{ID: identifier, Amount: award.MaterialAmounts[index] * multiplier})
	}
	return out, true
}

func (s *BoardState) AppendHistory(run BoardRun) {
	s.History = append([]BoardRun{run}, s.History...)
	if len(s.History) > BoardHistoryLimit {
		s.History = s.History[:BoardHistoryLimit]
	}
}

func (s *BoardState) AppendAward(award BoardAward) {
	s.AwardLog = append([]BoardAward{award}, s.AwardLog...)
	if len(s.AwardLog) > 11 {
		s.AwardLog = s.AwardLog[:11]
	}
}

func (s *BoardState) RemoveDoing(missionID int64) {
	kept := s.Doing[:0]
	for _, mission := range s.Doing {
		if mission.MissionID != missionID {
			kept = append(kept, mission)
		}
	}
	s.Doing = kept
}

// BoardWire projects the 1083 reply. The client indexes these field paths:
// mission_list[].mission_id/type/award_id (BoardMainWindow.lua:240,272,
// BoardMissionItem.lua:29,106), doing_mission_list[].mission_id/leader/
// partners/start_time (BoardAttackTaskItem.lua:40,74-84), finish_mission_list[]
// .mission_id/is_win/battle_id (BoardHistoryItem.lua:19,28) and award_log[]
// .mission_id/type/award_id/wish_crystal (BoardTaskBonusItem.lua:23-49).
func BoardWire(state BoardState) map[string]any {
	offers := make([]any, 0, len(state.Offers))
	for _, offer := range state.Offers {
		offers = append(offers, map[string]any{"mission_id": offer.MissionID, "type": offer.Type, "award_id": offer.AwardID})
	}
	doing := make([]any, 0, len(state.Doing))
	for _, mission := range state.Doing {
		partners := make([]any, 0, len(mission.Partners))
		for _, partner := range mission.Partners {
			partners = append(partners, partner)
		}
		doing = append(doing, map[string]any{"mission_id": mission.MissionID, "leader": mission.Leader, "partners": partners, "start_time": mission.StartAt})
	}
	finish := make([]any, 0, len(state.History))
	for _, run := range state.History {
		isWin := int64(0)
		if run.Win {
			isWin = 1
		}
		finish = append(finish, map[string]any{"mission_id": run.MissionID, "is_win": isWin, "battle_id": run.ReportID})
	}
	awards := make([]any, 0, len(state.AwardLog))
	for _, award := range state.AwardLog {
		awards = append(awards, map[string]any{"mission_id": award.MissionID, "type": award.Type, "award_id": award.AwardID, "wish_crystal": award.WishCrystal})
	}
	return map[string]any{"mission_list": offers, "doing_mission_list": doing, "finish_mission_list": finish, "award_log": awards}
}
