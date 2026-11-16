package i5store_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestPayloadGoldenI5StoreBatch18(t *testing.T) {
	const displayTable = "player_display_admissions"
	displayDirectory := filepath.Join("testdata", "payloads", displayTable+".payload")
	displayRaw, err := os.ReadFile(filepath.Join(displayDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var admission app.Admission
	if err := payload.Decode(displayTable, 0, displayRaw, &admission); err != nil {
		t.Fatalf("%s v0: %v", displayTable, err)
	}
	assertBatch18Golden(t, displayTable, displayDirectory, admission)

	const rewardTable = "redeem_reward_bundle_revisions"
	rewardDirectory := filepath.Join("testdata", "payloads", rewardTable+".grant_plan")
	rewardRaw, err := os.ReadFile(filepath.Join(rewardDirectory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var plan grant.Plan
	if err := payload.Decode(rewardTable, 0, rewardRaw, &plan); err != nil {
		t.Fatalf("%s v0: %v", rewardTable, err)
	}
	assertBatch18Golden(t, rewardTable, rewardDirectory, plan)
}

func assertBatch18Golden(t *testing.T, table, directory string, value any) {
	t.Helper()
	got, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("%s v0 decoded value:\n%s\nwant:\n%s", table, got, want)
	}
}
