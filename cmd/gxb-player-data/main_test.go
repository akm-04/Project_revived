//go:build postgres && linux

package main

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const testPlan = `{"authority":"test","schema_version":1,"tables":[
 {"table":"players","action":"restore","select":"SELECT * FROM players WHERE player_id=$1::bigint","versioned":{"state_version":true,"updated_at":false},"inbound":[]}
]}`

func runWithPlan(t *testing.T, arguments ...string) (int, string, string) {
	t.Helper()
	var stdout, stderr bytes.Buffer
	code := run(arguments, &stdout, &stderr)
	return code, stdout.String(), stderr.String()
}

func writeTestPlan(t *testing.T) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "plan.json")
	if err := os.WriteFile(path, []byte(testPlan), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestRunPrintsValidatedPlan(t *testing.T) {
	code, stdout, stderr := runWithPlan(t, "-mode", "plan", "-plan", writeTestPlan(t))
	if code != 0 || stderr != "" {
		t.Fatalf("code %d stderr %q", code, stderr)
	}
	var plan map[string]any
	if err := json.Unmarshal([]byte(stdout), &plan); err != nil {
		t.Fatalf("plan output is not JSON: %v", err)
	}
	if plan["schema_version"] != float64(1) {
		t.Fatalf("plan output %s", stdout)
	}
}

func TestRunRefusesWithExitThree(t *testing.T) {
	cases := map[string][]string{
		"restore without input":  {"-mode", "restore", "-player", "1"},
		"restore without player": {"-mode", "restore", "-in", filepath.Join(t.TempDir(), "export.json")},
		"missing player":         {"-mode", "export", "-plan", writeTestPlan(t)},
		"unknown mode":           {"-mode", "move"},
		"missing plan":           {"-mode", "plan", "-plan", filepath.Join(t.TempDir(), "absent.json")},
	}
	for name, arguments := range cases {
		t.Run(name, func(t *testing.T) {
			code, _, stderr := runWithPlan(t, arguments...)
			if code != 3 {
				t.Fatalf("exit %d, want 3", code)
			}
			lines := strings.Split(strings.TrimSuffix(stderr, "\n"), "\n")
			if len(lines) != 1 || strings.TrimSpace(lines[0]) == "" {
				t.Fatalf("refusal must be one named line, got %q", stderr)
			}
		})
	}
}
