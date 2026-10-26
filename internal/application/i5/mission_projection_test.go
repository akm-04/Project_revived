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
