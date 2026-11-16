package profilefeedbackstore_test

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/foundation/payload"
)

const commentOperationTable = "player_profile_comment_operations"
const commentAdmissionColumn = "admission_payload"

func TestPayloadGoldenProfileFeedbackStore(t *testing.T) {
	directory := filepath.Join("testdata", "payloads", commentOperationTable+"."+commentAdmissionColumn)
	raw, err := os.ReadFile(filepath.Join(directory, "v0.json"))
	if err != nil {
		t.Fatal(err)
	}
	var admission app.CommentAdmission
	if err := payload.Decode(commentOperationTable, 0, raw, &admission); err != nil {
		t.Fatalf("%s v0: %v", commentOperationTable, err)
	}
	got, err := json.MarshalIndent(admission, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	want, err := os.ReadFile(filepath.Join(directory, "v0.expected.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.TrimSpace(string(got)) != strings.TrimSpace(string(want)) {
		t.Fatalf("%s v0 decoded value:\n%s\nwant:\n%s", commentOperationTable, got, want)
	}
}
