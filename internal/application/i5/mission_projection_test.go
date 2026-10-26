package i5

import (
	"gxb.local/backend/v2/internal/domain/objective"
	"testing"
	"time"
)

func TestMissionPartnerReadAndCommonHookHaveTheirOwnSourceShapes(t *testing.T) {
	at := time.Unix(100000, 0).UTC()
	root, err := objective.NewMissionRoot(100001, at)
	if err != nil {
		t.Fatal(err)
	}
	view := MissionView{Root: root, Instances: []objective.Instance{{ProgramID: "mission:6", ObjectiveID: 70001, GenerationID: "hero:123", CompletedAt: &at}}}
	read := MissionProjection(view, at, objective.Partner)
	if rows := read["mission_list"].(map[string]any)["123"].([]any); len(rows) != 1 || rows[0].(map[string]any)["table_id"] != int64(70001) {
		t.Fatal(read)
	}
	hook := MissionProjection(view, at, 0)
	if rows := hook["partner_mission_"].([]any); len(rows) != 1 || rows[0].(map[string]any)["123"].(map[string]any)["table_id"] != int64(70001) {
		t.Fatal(hook)
	}
	if marks := hook["redmarks_"].(map[string]any)["27"].(map[string]any)["redmark_list"].([]int64); len(marks) != 1 || marks[0] != 2706 {
		t.Fatal(hook)
	}
}

func TestActivityFlagsAndReadyChestRedmark(t *testing.T) {
	at := time.Unix(100000, 0).UTC()
	root, err := objective.NewMissionRoot(100001, at)
	if err != nil {
		t.Fatal(err)
	}
	root.DayHuoyue = 30
	root.WeekHuoyue = 500
	view := MissionView{Root: root, Activity: &objective.ActivityCatalog{Rules: []objective.ActivityRule{{Period: "DAY", Index: 1, Medal: 30}, {Period: "WEEK", Index: 1, Medal: 500}}}}
	marked := func() bool {
		body := MissionProjection(view, at, 0)
		marks := body["redmarks_"].(map[string]any)["27"].(map[string]any)["redmark_list"].([]int64)
		return len(marks) == 1 && marks[0] == 2701
	}
	if !marked() {
		t.Fatal("ready chest missing daily redmark")
	}
	view.Root.DayAward = []int64{1}
	if !marked() {
		t.Fatal("weekly chest missing daily redmark")
	}
	view.Root.WeekAward = []int64{1}
	if marked() {
		t.Fatal("claimed chest still marked")
	}
	info := MissionProjection(view, at, objective.Daily)["extra_info"].(map[string]any)["huoyue_info"].(map[string]any)
	flags := info["day_award"].([]int64)
	if len(flags) != 5 || flags[0] != 1 || flags[1] != 0 {
		t.Fatalf("stock flags %v", flags)
	}
}

func TestInscriptionDailyRowCarriesInscriptID(t *testing.T) {
	at := time.Unix(100000, 0).UTC()
	root, err := objective.NewMissionRoot(100001, at)
	if err != nil {
		t.Fatal(err)
	}
	definition := objective.MissionDefinition{ObjectiveID: 10031, Presentation: objective.MissionPresentation{InscriptionPool: []objective.InscriptionChoice{{ItemID: 160400101, Weight: 8}}}}
	view := MissionView{Root: root, Definitions: []objective.MissionDefinition{definition}, Instances: []objective.Instance{
		{PlayerID: 100001, ProgramID: "mission:1", ObjectiveID: 10031, GenerationID: "day:1"},
		{PlayerID: 100001, ProgramID: "mission:1", ObjectiveID: 10002, GenerationID: "day:1"}}}
	rows := MissionProjection(view, at, objective.Daily)["mission_list"].([]any)
	if rows[0].(map[string]any)["inscript_id"] != int64(160400101) {
		t.Fatal(rows)
	}
	if _, ok := rows[1].(map[string]any)["inscript_id"]; ok {
		t.Fatal(rows)
	}
}

func TestAwakeningBadgeComposesWithOtherTaskBadges(t *testing.T) {
	at := time.Unix(100000, 0).UTC()
	view := MissionView{AwakeningReady: true, Instances: []objective.Instance{{ProgramID: "mission:6", ObjectiveID: 70001, GenerationID: "hero:123", CompletedAt: &at}}}
	marks := MissionProjection(view, at, 0)["redmarks_"].(map[string]any)["27"].(map[string]any)["redmark_list"].([]int64)
	if len(marks) != 2 || marks[0] != 2705 || marks[1] != 2706 {
		t.Fatal(marks)
	}
	view.AwakeningReady = false
	marks = MissionProjection(view, at, 0)["redmarks_"].(map[string]any)["27"].(map[string]any)["redmark_list"].([]int64)
	if len(marks) != 1 || marks[0] != 2706 {
		t.Fatal("unrelated badge cleared", marks)
	}
}
