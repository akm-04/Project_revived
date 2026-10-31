package topfloor

import (
	"encoding/json"
	"errors"
	"os"
	"strings"
	"testing"
	"time"
)

func TestTaskModeRotationSourceBoundaryAndContinuation(t *testing.T) {
	catalog := TaskModeCatalog{Schedule: []TaskModeScheduleEntry{{Date: "20170811", Mode: TaskModeSingle}, {Date: "20170818", Mode: TaskModeTriple}}}
	first := time.Date(2017, 8, 10, 21, 0, 0, 0, time.UTC)
	if _, err := catalog.Rotation(first.Add(-time.Nanosecond)); !errors.Is(err, ErrRefused) {
		t.Fatalf("before source: %v", err)
	}
	checks := []struct {
		at           time.Time
		number, mode int64
	}{{first, 1, TaskModeSingle}, {first.Add(7*24*time.Hour - time.Nanosecond), 1, TaskModeSingle}, {first.Add(7 * 24 * time.Hour), 2, TaskModeTriple}, {first.Add(14 * 24 * time.Hour), 3, TaskModeSingle}}
	for _, check := range checks {
		rotation, err := catalog.Rotation(check.at)
		if err != nil || rotation.Number != check.number || rotation.Mode != check.mode || check.at.Before(rotation.StartsAt) || !check.at.Before(rotation.EndsAt) {
			t.Fatalf("%s: %+v %v", check.at, rotation, err)
		}
	}
}

func TestTaskModeFormationTrustBoundaries(t *testing.T) {
	heroes := []TaskModeHero{{InstanceID: 1001, TableID: 10001001, Camp: 1}, {InstanceID: 1002, TableID: 10001002, Camp: 1}}
	single := TaskModeRule{ID: TaskModeSingle, HeroSlots: 1}
	if single.ValidateFormation(heroes[:1], 0, 0, 0) != nil {
		t.Fatal("single valid refused")
	}
	if single.ValidateFormation(heroes, 0, 0, 0) == nil || single.ValidateFormation(heroes[:1], 7, 0, 0) == nil {
		t.Fatal("single admitted excess actors")
	}
	leader := TaskModeRule{ID: TaskModeLeader, HeroSlots: 5, PetAllowed: true, LeaderAllowed: true}
	if leader.ValidateFormation(heroes, 7, 10001001, 0) == nil {
		t.Fatal("table id mistaken for owned leader")
	}
	if leader.ValidateFormation(heroes, 7, 1001, 0) != nil {
		t.Fatal("valid owned leader refused")
	}
	if leader.ValidateFormation([]TaskModeHero{heroes[0], heroes[0]}, 0, 1001, 0) == nil {
		t.Fatal("duplicate instance admitted")
	}
	banned := TaskModeRule{ID: TaskModeBanned, HeroSlots: 5, BannedTables: []int64{10001002}}
	if banned.ValidateFormation(heroes, 0, 0, 0) == nil {
		t.Fatal("banned template admitted")
	}
	camp := TaskModeRule{ID: TaskModeCamp, HeroSlots: 5, PetAllowed: true, BuffGroups: [][]int64{{11}, {22}, {33}, {44}}}
	if camp.ValidateFormation(heroes, 7, 0, 1) != nil {
		t.Fatal("same-camp formation refused")
	}
	if camp.ValidateFormation(heroes, 7, 0, 2) == nil {
		t.Fatal("wrong rotation camp admitted")
	}
	qun := []TaskModeHero{{InstanceID: 1003, TableID: 10001003, Camp: 4}}
	if camp.ValidateFormation(qun, 0, 0, 10) != nil || camp.ValidateFormation(qun, 0, 0, 4) == nil {
		t.Fatal("selection enum 10 must map to Hero faction 4, selection 4 is ASSIST")
	}
	mixed := append([]TaskModeHero(nil), heroes...)
	mixed[1].Camp = 2
	if camp.ValidateFormation(mixed, 0, 0, 0) == nil {
		t.Fatal("mixed camps admitted")
	}
	buffs, err := camp.Buffs(2)
	if err != nil || len(buffs) != 1 || buffs[0] != 22 {
		t.Fatalf("camp buffs %v %v", buffs, err)
	}
	buffs[0] = 99
	original, _ := camp.Buffs(2)
	if original[0] != 22 {
		t.Fatal("returned buffs mutate pinned rules")
	}
}

func TestTaskModeCatalogValidationAndAdmission(t *testing.T) {
	catalog := TaskModeCatalog{SchemaVersion: 1, ContractID: TaskModeContractID, PolicyID: TaskModePolicyID,
		HeroCamps: map[int64]int64{10001001: 1}, EntryRank: 200, EntryChallenges: 10, ServerLevel: 60,
		AttackingLeaderBuff: 40010694, DefendingLeaderBuff: 40010695,
		Schedule: []TaskModeScheduleEntry{{Date: "20170811", Mode: TaskModeSingle}}, Rewards: []Reward{{Range: 1}}}
	for mode := TaskModeSingle; mode <= TaskModeCamp; mode++ {
		rule := TaskModeRule{ID: mode, Title: "source title", HeroSlots: 1, LeaderAllowed: mode == TaskModeLeader}
		if mode == TaskModeSingle || mode == TaskModeTriple {
			rule.BuffGroups = [][]int64{{1}}
		}
		if mode == TaskModeCamp {
			rule.BuffGroups = [][]int64{{1}, {2}, {3}, {4}}
		}
		catalog.Rules = append(catalog.Rules, rule)
	}
	if err := catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	if catalog.Admit(200, 10, 60) != nil {
		t.Fatal("inclusive admission boundary refused")
	}
	for _, values := range [][3]int64{{201, 10, 60}, {200, 9, 60}, {200, 10, 59}, {0, 10, 60}, {200, -1, 60}} {
		if catalog.Admit(values[0], values[1], values[2]) == nil {
			t.Fatalf("invalid admission %+v", values)
		}
	}
	heroes, err := catalog.Heroes([]int64{11}, []int64{10001001})
	if err != nil || heroes[0].InstanceID != 11 || heroes[0].Camp != 1 {
		t.Fatalf("identity conversion %+v %v", heroes, err)
	}
	if _, err = catalog.Heroes([]int64{11}, []int64{99999}); err == nil {
		t.Fatal("unknown table admitted")
	}
	if _, err = catalog.Heroes([]int64{11}, nil); err == nil {
		t.Fatal("mismatched identity vector admitted")
	}
	catalog.Rules[5].BuffGroups = catalog.Rules[5].BuffGroups[:3]
	if catalog.Validate() == nil {
		t.Fatal("missing camp buffs admitted")
	}
	catalog.Rules[5].BuffGroups = append(catalog.Rules[5].BuffGroups, []int64{4})
	catalog.HeroCamps[10001001] = 10
	if catalog.Validate() == nil {
		t.Fatal("selection enum mistaken for Hero camp")
	}
}

func TestTaskModeExactCompiledCatalog(t *testing.T) {
	path := os.Getenv("GXB_TOP_FLOOR_TASK_CATALOG")
	if path == "" {
		t.Skip("exact task-mode compiler output not supplied")
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var catalog TaskModeCatalog
	if err = json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	if err = catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	if len(catalog.Rules) != 6 || len(catalog.Schedule) != 91 || len(catalog.Rewards) != 17 || len(catalog.HeroCamps) != 569 {
		t.Fatal("exact source profile changed")
	}
}

func TestTaskModePeriodDailyCutoffAndRetiredPeriod(t *testing.T) {
	catalog := TaskModeCatalog{Schedule: []TaskModeScheduleEntry{{Date: "20170811", Mode: TaskModeSingle}}}
	at := time.Date(2026, 10, 23, 12, 0, 0, 0, time.UTC)
	period, err := catalog.NewPeriod(1, strings.Repeat("a", 64), at)
	if err != nil {
		t.Fatal(err)
	}
	cutoff := time.Date(2026, 10, 23, 12, 30, 0, 0, time.UTC)
	if len(period.Unsettled(cutoff.Add(-time.Nanosecond))) != 0 || len(period.Unsettled(cutoff)) != 1 {
		t.Fatal("special20:30 cutoff boundary")
	}
	if normal := (Catalog{CutoffSeconds: 75600, FreezeEndSeconds: 77400}); normal.Frozen(cutoff) {
		t.Fatal("special cutoff changed normal freeze")
	}
	last := period.Unsettled(period.Rotation.EndsAt.Add(30 * 24 * time.Hour))
	if len(last) != 7 {
		t.Fatalf("retired period accrued %d daily rewards", len(last))
	}
	period.Ladder.CreatedAt = period.Rotation.EndsAt
	if period.Validate() == nil {
		t.Fatal("created outside frozen period")
	}
}

func TestTaskModeRobotFormationUsesEligibleSourceTemplates(t *testing.T) {
	normal := Catalog{Robots: []RobotTeam{{Heroes: []int64{1, 2, 3}}, {Heroes: []int64{3}}},
		RobotHeroes: []RobotHero{{ID: 1, PartnerID: 1001}, {ID: 2, PartnerID: 1002}, {ID: 3, PartnerID: 1003}}}
	catalog := TaskModeCatalog{HeroCamps: map[int64]int64{1001: 1, 1002: 2, 1003: 1}, Rules: []TaskModeRule{
		{ID: TaskModeCamp, HeroSlots: 5, BannedTables: []int64{1003}},
		{ID: TaskModeBanned, HeroSlots: 5, BannedTables: []int64{1003}},
		{ID: TaskModePhantom, HeroSlots: 1}}}
	heroes, err := catalog.RobotFormation(normal, 1, TaskModeRotation{Mode: TaskModeCamp})
	if err != nil || len(heroes) != 1 || heroes[0].ID != 1 {
		t.Fatalf("mixed camp robot %+v %v", heroes, err)
	}
	heroes, err = catalog.RobotFormation(normal, 1, TaskModeRotation{Mode: TaskModeCamp, Submode: 2})
	if err != nil || len(heroes) != 1 || heroes[0].ID != 2 {
		t.Fatalf("selected camp robot %+v %v", heroes, err)
	}
	heroes, err = catalog.RobotFormation(normal, 2, TaskModeRotation{Mode: TaskModeBanned})
	if err != nil || len(heroes) != 1 || heroes[0].ID != 1 {
		t.Fatalf("source fallback %+v %v", heroes, err)
	}
	heroes, err = catalog.RobotFormation(normal, 1, TaskModeRotation{Mode: TaskModePhantom})
	if err != nil || len(heroes) != 1 {
		t.Fatal("phantom must freeze just one source actor", err)
	}
	delete(catalog.HeroCamps, 1001)
	if _, err = catalog.RobotFormation(normal, 1, TaskModeRotation{Mode: TaskModePhantom}); err == nil {
		t.Fatal("unknown source camp accepted")
	}
}

func TestTaskEnemyTableReducesOnlyTheOwnRegion(t *testing.T) {
	for _, row := range []struct{ server, enemy, want int64 }{{1, 100032, 32}, {1, 125001, 25001}, {1, 32, 32}, {2, 100032, 100032}, {2, 225001, 25001}} {
		if got := TaskEnemyTable(row.server, row.enemy); got != row.want {
			t.Fatalf("TaskEnemyTable(%d, %d) = %d, want %d", row.server, row.enemy, got, row.want)
		}
	}
}
