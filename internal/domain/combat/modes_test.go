package combat

import (
	"testing"
	"time"
)

func TestModeRegistryRows(t *testing.T) {
	keys := []ModeKey{
		ModeAdventureDefense, ModeAdventureIllusion, ModeAdventurePVP, ModeAdventureCoop,
		ModeArena, ModeArenaPlayoffs, ModeArenaFriendFight,
		ModeAwakeningBlood, ModeCampaign, ModeChampionsLeague, ModeConquerSchool, ModeDodgeball,
		ModeEventCentreBoard, ModeGodsTrial, ModeGuildCampaign, ModeIllusionSolo, ModeIllusionTeam,
		ModeMarch, ModeMemoirBattle, ModeMemoirPlayer, ModeOccultSolo, ModeOccultTeam, ModeOneOnOne,
		ModePetCampaign, ModePetCampaignPractice, ModeTopFloor, ModeTopFloorTask, ModeWorkplace, ModeWorldBoss,
	}
	if len(modeRegistrations) != len(keys) {
		t.Fatalf("registry has %d rows, want %d", len(modeRegistrations), len(keys))
	}
	seen := map[ModeKey]bool{}
	for _, registration := range modeRegistrations {
		if registration.Key == "" || seen[registration.Key] {
			t.Fatalf("duplicate or empty key %q", registration.Key)
		}
		if !registration.Trust.Registered() {
			t.Fatalf("%s names an unregistered trust profile", registration.Key)
		}
		if registration.Producer != ProducerProfileID && registration.Producer != "" {
			t.Fatalf("%s names an unregistered producer %q", registration.Key, registration.Producer)
		}
		seen[registration.Key] = true
	}
	for _, key := range keys {
		if !seen[key] {
			t.Fatalf("key %q is not registered", key)
		}
	}
	retentions := map[ModeKey]struct {
		id     string
		window time.Duration
	}{
		ModeArena:            {"C5D_ARENA_REPORT_RETENTION_V1", RetentionCeiling},
		ModeArenaPlayoffs:    {"I9_ARENA_TOURNAMENT_REPORT_RETENTION_V1", RetentionCeiling},
		ModeArenaFriendFight: {"I9_ARENA_TOURNAMENT_REPORT_RETENTION_V1", RetentionCeiling},
		ModeChampionsLeague:  {"C5F_LEAGUE_REPORT_RETENTION_V1", 5 * 24 * time.Hour},
		ModeOneOnOne:         {"C5C_ONE_ON_ONE_REPORT_RETENTION_V1", RetentionCeiling},
		ModeTopFloor:         {"C5B_TOP_FLOOR_REPORT_RETENTION_V1", RetentionCeiling},
		ModeTopFloorTask:     {"C5B_TOP_FLOOR_REPORT_RETENTION_V1", RetentionCeiling},
	}
	for key, want := range retentions {
		registration, ok := LookupMode(key)
		if !ok || registration.Retention == nil || registration.Retention.ID != want.id || registration.Retention.Window != want.window {
			t.Fatalf("%s retention = %+v", key, registration.Retention)
		}
	}
	for _, registration := range modeRegistrations {
		if _, replayed := retentions[registration.Key]; replayed == (registration.Retention == nil) {
			t.Fatalf("%s retention presence is wrong", registration.Key)
		}
	}
}

func TestModeRegistrationGuards(t *testing.T) {
	duplicate := append([]ModeRegistration{}, modeRegistrations...)
	duplicate = append(duplicate, modeRegistrations[0])
	if err := validateModeRegistrations(duplicate); err == nil {
		t.Fatal("duplicate key accepted")
	}
	unregistered := ModeRegistration{Key: "FIXTURE_MODE", Family: "FIXTURE", Trust: TrustProfile{"NO_SUCH_PROFILE_V1", 1}, Replay: ReplaySpec{Response: ReplayOK}, Producer: ProducerProfileID}
	if err := validateModeRegistrations([]ModeRegistration{unregistered}); err == nil {
		t.Fatal("unregistered trust profile accepted")
	}
	badProducer := modeRegistrations[0]
	badProducer.Key = ModeKey("FIXTURE_MODE")
	badProducer.Producer = "NO_SUCH_PRODUCER_V1"
	if err := validateModeRegistrations([]ModeRegistration{badProducer}); err == nil {
		t.Fatal("unregistered producer accepted")
	}
	if _, ok := LookupMode("NO_SUCH_MODE"); ok {
		t.Fatal("unknown mode looked up")
	}
	defer func() {
		if recover() == nil {
			t.Fatal("MustMode accepted an unknown mode")
		}
	}()
	MustMode("NO_SUCH_MODE")
}
