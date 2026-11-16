package playerdata

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

const validPlan = `{
 "authority": "test",
 "schema_version": 1,
 "tables": [
  {"table": "players", "action": "restore", "select": "SELECT * FROM \"players\" WHERE \"player_id\" = $1::bigint", "versioned": {"state_version": true, "updated_at": false}, "inbound": []},
  {"table": "achievement_award_claims", "action": "keep", "select": "SELECT * FROM \"achievement_award_claims\" WHERE \"player_id\" = $1::bigint", "versioned": {"state_version": false, "updated_at": false}, "inbound": []}
 ]
}`

func writePlan(t *testing.T, content string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "plan.json")
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestLoadPlanPinsFileDigest(t *testing.T) {
	path := writePlan(t, validPlan)
	plan, digest, err := LoadPlan(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(plan.Tables) != 2 || plan.Tables[1].Action != ActionKeep {
		t.Fatalf("unexpected plan %#v", plan.Tables)
	}
	sum := sha256.Sum256([]byte(validPlan))
	if digest != hex.EncodeToString(sum[:]) {
		t.Fatalf("digest %s does not pin the file bytes", digest)
	}
}

func TestLoadPlanRefusesInvalidPlans(t *testing.T) {
	cases := map[string]string{
		"unknown field":   strings.Replace(validPlan, `"authority"`, `"authority_extra": 1, "authority"`, 1),
		"trailing data":   validPlan + `{}`,
		"missing players": `{"authority":"test","schema_version":1,"tables":[{"table":"x","action":"restore","select":"SELECT 1","versioned":{},"inbound":[]}]}`,
		"duplicate table": strings.Replace(validPlan, `"achievement_award_claims"`, `"players"`, 1),
		"unknown action":  strings.Replace(validPlan, `"keep"`, `"delete"`, 1),
		"empty select":    strings.Replace(validPlan, `SELECT * FROM \"achievement_award_claims\" WHERE \"player_id\" = $1::bigint`, ` `, 1),
	}
	for name, content := range cases {
		t.Run(name, func(t *testing.T) {
			if _, _, err := LoadPlan(writePlan(t, content)); !errors.Is(err, ErrInvalidPlan) {
				t.Fatalf("want ErrInvalidPlan, got %v", err)
			}
		})
	}
}

func TestEncodeDiffersOnlyInExportedAt(t *testing.T) {
	document := Document{
		Format:          ExportFormat,
		SchemaVersion:   165,
		PlayerID:        100001,
		LogicalServerID: 1,
		PlanSHA256:      "digest",
		BlobKeys:        []string{"abc.png"},
		Tables: []TableRows{{
			Table:  "players",
			Action: ActionRestore,
			Rows:   []json.RawMessage{json.RawMessage(`{"player_id":100001,"payload_version":1}`)},
		}},
	}
	document.ExportedAt = time.Date(2026, 11, 16, 1, 2, 3, 4, time.UTC)
	first, err := encode(t, document)
	if err != nil {
		t.Fatal(err)
	}
	document.ExportedAt = time.Date(2026, 11, 16, 5, 6, 7, 8, time.UTC)
	second, err := encode(t, document)
	if err != nil {
		t.Fatal(err)
	}
	if first == second {
		t.Fatal("exported_at did not reach the document")
	}
	document.ExportedAt = time.Date(2026, 11, 16, 1, 2, 3, 4, time.UTC)
	again, err := encode(t, document)
	if err != nil {
		t.Fatal(err)
	}
	if first != again {
		t.Fatal("encoding is not deterministic")
	}
	if !strings.Contains(first, `"payload_version":1`) {
		t.Fatal("row payload_version missing from the encoded export")
	}
}

func encode(t *testing.T, document Document) (string, error) {
	t.Helper()
	var buffer bytes.Buffer
	if err := Encode(&buffer, document); err != nil {
		return "", err
	}
	return buffer.String(), nil
}

func TestReferencedBlobKeys(t *testing.T) {
	rows := []json.RawMessage{
		json.RawMessage(`{"operation":"00000000-0000-4000-8000-000000000001","reference":{"asset":{"sha256":"aa"},"url":"http://h/profile-media/x/aa.png"}}`),
	}
	keys, err := referencedBlobKeys(rows)
	if err != nil {
		t.Fatal(err)
	}
	if len(keys) != 1 || keys[0] != "aa.png" {
		t.Fatalf("keys %v", keys)
	}
	if _, err := referencedBlobKeys([]json.RawMessage{json.RawMessage(`{"reference":{"asset":{}}}`)}); err == nil {
		t.Fatal("row without an asset digest was accepted")
	}
}
