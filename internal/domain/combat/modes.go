package combat

import (
	"fmt"
	"time"
)

// ModeKey names one registered combat mode family; it cannot be the Locator
// domain_kind because several modes share one kind with different tuples.
type ModeKey string

const (
	ModeAdventureDefense    ModeKey = "ADVENTURE_DEFENSE"
	ModeAdventureIllusion   ModeKey = "ADVENTURE_ILLUSION"
	ModeAdventurePVP        ModeKey = "ADVENTURE_PVP"
	ModeAdventureCoop       ModeKey = "ADVENTURE_COOP"
	ModeArena               ModeKey = "ARENA"
	ModeArenaPlayoffs       ModeKey = "ARENA_PLAYOFFS"
	ModeArenaFriendFight    ModeKey = "ARENA_FRIEND_FIGHT"
	ModeAwakeningBlood      ModeKey = "AWAKENING_BLOOD"
	ModeCampaign            ModeKey = "CAMPAIGN"
	ModeChampionsLeague     ModeKey = "CHAMPIONS_LEAGUE"
	ModeConquerSchool       ModeKey = "CONQUER_SCHOOL"
	ModeDodgeball           ModeKey = "DODGEBALL"
	ModeEventCentreBoard    ModeKey = "EVENT_CENTRE_BOARD"
	ModeGodsTrial           ModeKey = "GODS_TRIAL"
	ModeGuildCampaign       ModeKey = "GUILD_CAMPAIGN"
	ModeIllusionSolo        ModeKey = "ILLUSION_SOLO"
	ModeIllusionTeam        ModeKey = "ILLUSION_TEAM"
	ModeMarch               ModeKey = "MARCH"
	ModeMemoirBattle        ModeKey = "MEMOIR_BATTLE"
	ModeMemoirPlayer        ModeKey = "MEMOIR_PLAYER"
	ModeOccultSolo          ModeKey = "OCCULT_SOLO"
	ModeOccultTeam          ModeKey = "OCCULT_TEAM"
	ModeOneOnOne            ModeKey = "ONE_ON_ONE"
	ModePetCampaign         ModeKey = "PET_CAMPAIGN"
	ModePetCampaignPractice ModeKey = "PET_CAMPAIGN_PRACTICE"
	ModeTopFloor            ModeKey = "TOP_FLOOR"
	ModeTopFloorTask        ModeKey = "TOP_FLOOR_TASK"
	ModeWorkplace           ModeKey = "WORKPLACE"
	ModeWorldBoss           ModeKey = "WORLD_BOSS"
)

// ChoiceChangeRule is a mode's registered answer to a same-stage START whose
// player choices differ from the open attempt's (I8 generation_supersede rule 2).
type ChoiceChangeRule string

const (
	ChoiceReplaysFrozen    ChoiceChangeRule = "REPLAYS_FROZEN"
	ChoiceSupersedes       ChoiceChangeRule = "SUPERSEDES"
	ChoiceRefusedWhileOpen ChoiceChangeRule = "REFUSED_WHILE_OPEN"
)

// ModeRegistration is the frozen tuple an I8-4 mode registers: its Locator
// family, trust profile, choice-change rule, duplicate-terminal answer, resolver
// transform, snapshot producer profile and replay retention (nil = no replay read).
type ModeRegistration struct {
	Key            ModeKey
	Family         string
	Trust          TrustProfile
	OnChoiceChange ChoiceChangeRule
	Replay         ReplaySpec
	Transform      string
	Producer       string
	Retention      *Retention
}

// A server-resolved mode replays the frozen START whatever the chosen team; a
// client-attested result supersedes. Dodgeball refuses a changed mark while its
// occurrence is open; memoir battle sends no team choice.
var modeRegistrations = []ModeRegistration{
	{Key: ModeAdventureDefense, Family: "ADVENTURE_DEFENSE", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeAdventureIllusion, Family: "ADVENTURE_ILLUSION", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeAdventurePVP, Family: "ADVENTURE_PVP", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Transform: "REGION_ARENA_SEASON_AWARDS_V1", Producer: ProducerProfileID},
	{Key: ModeAdventureCoop, Family: "ADVENTURE_ILLUSION", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Producer: ProducerProfileID},
	{Key: ModeArena, Family: "ARENA", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Transform: "REGION_ARENA_SEASON_AWARDS_V1", Producer: ProducerProfileID,
		Retention: &Retention{ID: "C5D_ARENA_REPORT_RETENTION_V1", Version: 1, Window: RetentionCeiling}},
	{Key: ModeArenaPlayoffs, Family: "ARENA_PLAYOFFS", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Transform: "REGION_ARENA_PLAYOFFS_AWAKE_V1", Producer: ProducerProfileID,
		Retention: &Retention{ID: "I9_ARENA_TOURNAMENT_REPORT_RETENTION_V1", Version: 1, Window: RetentionCeiling}},
	{Key: ModeArenaFriendFight, Family: "FRIEND_FIGHT", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Transform: "REGION_ARENA_PLAYOFFS_AWAKE_V1", Producer: ProducerProfileID,
		Retention: &Retention{ID: "I9_ARENA_TOURNAMENT_REPORT_RETENTION_V1", Version: 1, Window: RetentionCeiling}},
	{Key: ModeAwakeningBlood, Family: "AWAKENING_BLOOD", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeCampaign, Family: "CAMPAIGN", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeChampionsLeague, Family: "ACADEMY_LEAGUE", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Producer: ProducerProfileID,
		Retention: &Retention{ID: "C5F_LEAGUE_REPORT_RETENTION_V1", Version: 1, Window: 5 * 24 * time.Hour}},
	{Key: ModeConquerSchool, Family: "CONQUER_SCHOOL", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeDodgeball, Family: "dodgeball", Trust: ServerEntropyClientDerived, OnChoiceChange: ChoiceRefusedWhileOpen, Replay: ReplaySpec{Response: ReplayFightExist, ErrorCode: FightExistCode}},
	{Key: ModeEventCentreBoard, Family: "EVENT_CENTRE_BOARD", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Producer: ProducerProfileID},
	{Key: ModeGodsTrial, Family: "godstrial", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayFightExist, ErrorCode: FightExistCode}, Producer: ProducerProfileID},
	{Key: ModeGuildCampaign, Family: "GUILD_CAMPAIGN", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeIllusionSolo, Family: "ILLUSION", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeIllusionTeam, Family: "ILLUSION", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Producer: ProducerProfileID},
	{Key: ModeMarch, Family: "CHAMPION_MARCH", Trust: ClientFullReportAttested, OnChoiceChange: ChoiceRefusedWhileOpen, Replay: ReplaySpec{Response: ReplayFightExist, ErrorCode: FightExistCode}, Producer: ProducerProfileID},
	{Key: ModeMemoirBattle, Family: "MEMOIR", Trust: ClientFullReportAttested, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayFightExist, ErrorCode: FightExistCode}, Transform: "MEMOIR_CARRY_V1", Producer: ProducerProfileID},
	{Key: ModeMemoirPlayer, Family: "MEMOIR", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Transform: "MEMOIR_CARRY_V1", Producer: ProducerProfileID},
	{Key: ModeOccultSolo, Family: "OCCULT", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeOccultTeam, Family: "OCCULT", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Transform: "MEMOIR_CARRY_V1", Producer: ProducerProfileID},
	{Key: ModeOneOnOne, Family: "ONE_ON_ONE", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Transform: "SUPER_ARENA_ROUND_V1", Producer: ProducerProfileID,
		Retention: &Retention{ID: "C5C_ONE_ON_ONE_REPORT_RETENTION_V1", Version: 1, Window: RetentionCeiling}},
	{Key: ModePetCampaign, Family: "petcampaign", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModePetCampaignPractice, Family: "petcampaign-practice", Trust: PracticeNoValue, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
	{Key: ModeTopFloor, Family: "TOP_FLOOR", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Producer: ProducerProfileID,
		Retention: &Retention{ID: "C5B_TOP_FLOOR_REPORT_RETENTION_V1", Version: 1, Window: RetentionCeiling}},
	{Key: ModeTopFloorTask, Family: "TOP_FLOOR_TASK", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Transform: "TOP_FLOOR_TASK_V1", Producer: ProducerProfileID,
		Retention: &Retention{ID: "C5B_TOP_FLOOR_REPORT_RETENTION_V1", Version: 1, Window: RetentionCeiling}},
	{Key: ModeWorkplace, Family: "WORKPLACE_JOB_RIVAL", Trust: ServerReport, OnChoiceChange: ChoiceReplaysFrozen, Replay: ReplaySpec{Response: ReplayStoredReport}, Producer: ProducerProfileID},
	{Key: ModeWorldBoss, Family: "WORLD_BOSS", Trust: ClientSummaryAttested, OnChoiceChange: ChoiceSupersedes, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID},
}

var modes = func() map[ModeKey]ModeRegistration {
	registered := make(map[ModeKey]ModeRegistration, len(modeRegistrations))
	for _, registration := range modeRegistrations {
		registered[registration.Key] = registration
	}
	return registered
}()

func init() {
	if err := validateModeRegistrations(modeRegistrations); err != nil {
		panic(err)
	}
}

// validateModeRegistrations refuses a table that could never be looked up
// safely; it is split out so a test can copy and corrupt the live table.
func validateModeRegistrations(rows []ModeRegistration) error {
	seen := make(map[ModeKey]bool, len(rows))
	for _, registration := range rows {
		if registration.Key == "" || seen[registration.Key] {
			return fmt.Errorf("combat: duplicate or empty mode key %q", registration.Key)
		}
		seen[registration.Key] = true
		if !registration.Trust.Registered() {
			return fmt.Errorf("combat: mode %s names an unregistered trust profile", registration.Key)
		}
		if registration.OnChoiceChange != ChoiceReplaysFrozen && registration.OnChoiceChange != ChoiceSupersedes && registration.OnChoiceChange != ChoiceRefusedWhileOpen {
			return fmt.Errorf("combat: mode %s names an unregistered choice-change rule %q", registration.Key, registration.OnChoiceChange)
		}
		if registration.Trust == ServerReport && registration.OnChoiceChange != ChoiceReplaysFrozen {
			return fmt.Errorf("combat: server-report mode %s must replay the frozen START on a choice change", registration.Key)
		}
		if registration.Trust == ClientSummaryAttested && registration.OnChoiceChange != ChoiceSupersedes {
			return fmt.Errorf("combat: client-attested mode %s must supersede on a choice change", registration.Key)
		}
		if registration.Producer != ProducerProfileID && registration.Producer != "" {
			return fmt.Errorf("combat: mode %s names an unregistered producer profile %q", registration.Key, registration.Producer)
		}
		if registration.Retention != nil && !registration.Retention.Valid() {
			return fmt.Errorf("combat: mode %s names an invalid retention", registration.Key)
		}
	}
	return nil
}

// LookupMode returns the registered tuple for key.
func LookupMode(key ModeKey) (ModeRegistration, bool) {
	registration, ok := modes[key]
	return registration, ok
}

// MustMode is LookupMode for callers that own a statically registered mode.
func MustMode(key ModeKey) ModeRegistration {
	registration, ok := LookupMode(key)
	if !ok {
		panic("combat: unregistered mode " + string(key))
	}
	return registration
}
