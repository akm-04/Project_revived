package topfloor

import (
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/modes"
)

const (
	TaskModeContractID         = "I9_TOP_FLOOR_TASK_MODE_V1"
	TaskModePolicyID           = "I9_TOP_FLOOR_TASK_POLICY_V1"
	TaskModeSingle       int64 = 1
	TaskModeTriple       int64 = 2
	TaskModeLeader       int64 = 3
	TaskModeBanned       int64 = 4
	TaskModePhantom      int64 = 5
	TaskModeCamp         int64 = 6
	TaskModeCampaignType int64 = 57
	taskModeDays               = 7
)

type TaskModeRule struct {
	ID            int64     `json:"id"`
	Title         string    `json:"title"`
	Description   string    `json:"description"`
	RuleText      string    `json:"rule_text"`
	HeroSlots     int       `json:"hero_slots"`
	PetAllowed    bool      `json:"pet_allowed"`
	LeaderAllowed bool      `json:"leader_allowed"`
	BannedTables  []int64   `json:"banned_tables"`
	BuffGroups    [][]int64 `json:"buff_groups"`
	ResetDefense  bool      `json:"reset_defense"`
}

type TaskModeScheduleEntry struct {
	Date    string `json:"date"`
	Mode    int64  `json:"mode"`
	Submode int64  `json:"submode"`
}

type TaskModeCatalog struct {
	MailTitle           string                  `json:"mail_title"`
	MailText            string                  `json:"mail_text"`
	MailSender          string                  `json:"mail_sender"`
	HeroCamps           map[int64]int64         `json:"hero_camps"`
	SchemaVersion       int                     `json:"schema_version"`
	ContractID          string                  `json:"contract_id"`
	PolicyID            string                  `json:"policy_id"`
	Rules               []TaskModeRule          `json:"rules"`
	Schedule            []TaskModeScheduleEntry `json:"schedule"`
	Rewards             []Reward                `json:"rewards"`
	EntryRank           int64                   `json:"entry_rank"`
	EntryChallenges     int64                   `json:"entry_challenges"`
	ServerLevel         int64                   `json:"server_level"`
	AttackingLeaderBuff int64                   `json:"attacking_leader_buff"`
	DefendingLeaderBuff int64                   `json:"defending_leader_buff"`
}

func (catalog TaskModeCatalog) Rule(mode int64) (TaskModeRule, bool) {
	for _, rule := range catalog.Rules {
		if rule.ID == mode {
			return rule, true
		}
	}
	return TaskModeRule{}, false
}

func taskModeSourceDay(date string) (int64, error) {
	parsed, err := time.Parse("20060102", date)
	if err != nil {
		return 0, ErrInvalid
	}
	return modes.Day(parsed.Add(time.Duration(ticketReset-zoneOffset) * time.Second)), nil
}

func (catalog TaskModeCatalog) Validate() error {
	if catalog.SchemaVersion != 1 || catalog.ContractID != TaskModeContractID || catalog.PolicyID != TaskModePolicyID || len(catalog.Rules) != int(TaskModeCamp) || len(catalog.Schedule) == 0 || len(catalog.Rewards) == 0 {
		return ErrInvalid
	}
	if len(catalog.HeroCamps) == 0 {
		return ErrInvalid
	}
	for tableID, camp := range catalog.HeroCamps {
		if tableID <= 0 || camp < 1 || camp > 4 {
			return ErrInvalid
		}
	}
	if catalog.EntryRank <= 0 || catalog.EntryChallenges <= 0 || catalog.ServerLevel <= 0 || catalog.AttackingLeaderBuff <= 0 || catalog.DefendingLeaderBuff <= 0 {
		return ErrInvalid
	}
	seen := map[int64]bool{}
	for _, rule := range catalog.Rules {
		if rule.ID < TaskModeSingle || rule.ID > TaskModeCamp || seen[rule.ID] || rule.Title == "" || rule.HeroSlots < 1 || rule.HeroSlots > DefenseSlots {
			return ErrInvalid
		}
		seen[rule.ID] = true
		if rule.LeaderAllowed != (rule.ID == TaskModeLeader) {
			return ErrInvalid
		}
		expectedGroups := 0
		if rule.ID == TaskModeSingle || rule.ID == TaskModeTriple {
			expectedGroups = 1
		}
		if rule.ID == TaskModeCamp {
			expectedGroups = 4
		}
		if len(rule.BuffGroups) != expectedGroups {
			return ErrInvalid
		}
		for _, group := range rule.BuffGroups {
			if len(group) == 0 {
				return ErrInvalid
			}
			for _, buff := range group {
				if buff <= 0 {
					return ErrInvalid
				}
			}
		}
	}
	var previousDay int64
	for index, entry := range catalog.Schedule {
		day, err := taskModeSourceDay(entry.Date)
		if err != nil {
			return err
		}
		if index > 0 && day != previousDay+taskModeDays {
			return ErrInvalid
		}
		_, validCamp := taskModeSelectedCamp(entry.Submode)
		if _, found := catalog.Rule(entry.Mode); !found || !validCamp || entry.Mode != TaskModeCamp && entry.Submode != 0 {
			return ErrInvalid
		}
		previousDay = day
	}
	var previousRange int64
	for _, reward := range catalog.Rewards {
		if reward.Range <= previousRange || reward.DailyCrystal < 0 || reward.DailyMana < 0 || reward.DailyArenaCoin < 0 {
			return ErrInvalid
		}
		for _, item := range reward.Items {
			if item[0] <= 0 || item[1] <= 0 {
				return ErrInvalid
			}
		}
		previousRange = reward.Range
	}
	return nil
}

type TaskModeRotation struct {
	Number   int64
	Mode     int64
	Submode  int64
	StartsAt time.Time
	EndsAt   time.Time
}

func (catalog TaskModeCatalog) Rotation(at time.Time) (TaskModeRotation, error) {
	if at.IsZero() || len(catalog.Schedule) == 0 {
		return TaskModeRotation{}, ErrInvalid
	}
	firstDay, err := taskModeSourceDay(catalog.Schedule[0].Date)
	if err != nil {
		return TaskModeRotation{}, err
	}
	elapsed := modes.Day(at) - firstDay
	if elapsed < 0 {
		return TaskModeRotation{}, ErrRefused
	}
	index := elapsed / taskModeDays
	entry := catalog.Schedule[index%int64(len(catalog.Schedule))]
	startDay := firstDay + index*taskModeDays
	return TaskModeRotation{Number: index + 1, Mode: entry.Mode, Submode: entry.Submode, StartsAt: modes.DayBegins(startDay), EndsAt: modes.DayBegins(startDay + taskModeDays)}, nil
}

type TaskModeHero struct {
	InstanceID int64
	TableID    int64
	Camp       int64
}

func (rule TaskModeRule) ValidateFormation(heroes []TaskModeHero, pet, leader, submode int64) error {
	selectedCamp, validCamp := taskModeSelectedCamp(submode)
	if rule.ID < TaskModeSingle || rule.ID > TaskModeCamp || len(heroes) == 0 || len(heroes) > rule.HeroSlots || pet < 0 || leader < 0 || !validCamp || rule.ID != TaskModeCamp && submode != 0 {
		return ErrInvalid
	}
	if pet > 0 && !rule.PetAllowed {
		return ErrRefused
	}
	if !rule.LeaderAllowed && leader != 0 {
		return ErrRefused
	}
	seen := map[int64]bool{}
	leaderFound := false
	for _, hero := range heroes {
		if hero.InstanceID <= 0 || hero.TableID <= 0 || seen[hero.InstanceID] {
			return ErrInvalid
		}
		seen[hero.InstanceID] = true
		if slices.Contains(rule.BannedTables, hero.TableID) {
			return ErrRefused
		}
		leaderFound = leaderFound || hero.InstanceID == leader
		if rule.ID != TaskModeCamp {
			continue
		}
		if hero.Camp < 1 || hero.Camp > 4 || hero.Camp != heroes[0].Camp {
			return ErrRefused
		}
		if selectedCamp > 0 && hero.Camp != selectedCamp {
			return ErrRefused
		}
	}
	if rule.LeaderAllowed && !leaderFound {
		return ErrRefused
	}
	return nil
}

func taskModeSelectedCamp(submode int64) (int64, bool) {
	switch submode {
	case 0, 1, 2, 3:
		return submode, true
	case 10:
		return 4, true
	default:
		return 0, false
	}
}

func (rule TaskModeRule) Buffs(camp int64) ([]int64, error) {
	if len(rule.BuffGroups) == 0 {
		return []int64{}, nil
	}
	if rule.ID != TaskModeCamp {
		return slices.Clone(rule.BuffGroups[0]), nil
	}
	if camp < 1 || camp > int64(len(rule.BuffGroups)) {
		return nil, ErrInvalid
	}
	return slices.Clone(rule.BuffGroups[camp-1]), nil
}

// TaskEnemyTable reduces the enemy id of stock MID 286: ArenaWindow adds region*stride to the table id for a
// challenge, while an avenge from ArenaRecordPlayerInfoWindow sends the plain table id.
func TaskEnemyTable(server, enemy int64) int64 {
	if enemy/RegionStride == server {
		return enemy % RegionStride
	}
	return enemy
}

func (catalog TaskModeCatalog) Admit(rank, weeklyChallenges, serverLevel int64) error {
	if rank < 1 || weeklyChallenges < 0 || serverLevel < 1 {
		return ErrInvalid
	}
	if rank > catalog.EntryRank || weeklyChallenges < catalog.EntryChallenges || serverLevel < catalog.ServerLevel {
		return ErrRefused
	}
	return nil
}

func (catalog TaskModeCatalog) Heroes(identities, tables []int64) ([]TaskModeHero, error) {
	if len(identities) != len(tables) || len(identities) == 0 {
		return nil, ErrInvalid
	}
	heroes := make([]TaskModeHero, 0, len(identities))
	for index, tableID := range tables {
		camp, found := catalog.HeroCamps[tableID]
		if !found || identities[index] <= 0 {
			return nil, ErrInvalid
		}
		heroes = append(heroes, TaskModeHero{InstanceID: identities[index], TableID: tableID, Camp: camp})
	}
	return heroes, nil
}
