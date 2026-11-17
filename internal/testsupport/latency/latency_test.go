package latency

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestDeferredOnlyOutsideTheSection(t *testing.T) {
	t.Setenv(SectionEnvironment, "")
	if !deferred(Dedicated) {
		t.Fatal("a dedicated budget must defer outside the latency section")
	}
	if deferred(Incidental) {
		t.Fatal("an incidental budget must stay in the general section")
	}
	if DeferredReason != "latency: deferred to latency section" {
		t.Fatalf("fixed skip reason changed: %q", DeferredReason)
	}
	t.Setenv(SectionEnvironment, "1")
	if deferred(Dedicated) || deferred(Incidental) {
		t.Fatal("nothing defers inside the latency section")
	}
}

func TestIncidentalBudgetUsesTheGeneralCeiling(t *testing.T) {
	t.Setenv(SectionEnvironment, "")
	t.Setenv(ceilingEnvironment, "10")
	if got := effectiveBudget(Incidental, time.Second); got != 10*time.Second {
		t.Fatalf("incidental general budget %s, want 10s", got)
	}
	if got := effectiveBudget(Dedicated, time.Second); got != time.Second {
		t.Fatalf("dedicated general budget %s, want the unchanged 1s", got)
	}
	t.Setenv(ceilingEnvironment, "4")
	if got := effectiveBudget(Incidental, 250*time.Millisecond); got != time.Second {
		t.Fatalf("tunable ceiling ignored: %s", got)
	}
	t.Setenv(SectionEnvironment, "1")
	if got := effectiveBudget(Incidental, time.Second); got != time.Second {
		t.Fatalf("incidental section budget %s, want the unchanged 1s", got)
	}
}

func TestWithinHonoursTheCeilingAndTheSection(t *testing.T) {
	t.Setenv(RecordEnvironment, "")
	t.Setenv(SectionEnvironment, "")
	t.Setenv(ceilingEnvironment, "10")
	if !Within(t, Incidental, 5*time.Second, time.Second) {
		t.Fatal("an incidental miss below the general ceiling must stay green")
	}
	if Within(t, Incidental, 11*time.Second, time.Second) {
		t.Fatal("an incidental miss above the general ceiling must fail")
	}
	t.Setenv(SectionEnvironment, "1")
	if Within(t, Incidental, 5*time.Second, time.Second) {
		t.Fatal("the latency section enforces the unchanged budget")
	}
}

func readRecordLines(t *testing.T, path string) []string {
	t.Helper()
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return strings.Split(strings.TrimSpace(string(raw)), "\n")
}

// GATE_LATENCY_SECTION_V1 section 6: every helper call records "<import path> <root test name>" once.
func TestRecordNamesTheCallingPackageAndRootTest(t *testing.T) {
	path := filepath.Join(t.TempDir(), "record.txt")
	t.Setenv(RecordEnvironment, path)
	t.Setenv(SectionEnvironment, "1")
	Require(t, Dedicated)
	Enforce(t, Dedicated, 0, time.Second)
	EnforceRate(t, Dedicated, 1, 1)
	if !Within(t, Dedicated, 0, time.Second) {
		t.Fatal("zero is within a one-second budget")
	}
	want := "gxb.local/backend/v2/internal/testsupport/latency TestRecordNamesTheCallingPackageAndRootTest"
	lines := readRecordLines(t, path)
	if len(lines) != 4 {
		t.Fatalf("recorded %d lines, want one per helper call: %v", len(lines), lines)
	}
	for _, line := range lines {
		if line != want {
			t.Fatalf("record line %q, want %q", line, want)
		}
	}
}

func TestRecordUsesTheRootTestNameForSubtests(t *testing.T) {
	path := filepath.Join(t.TempDir(), "record.txt")
	t.Setenv(RecordEnvironment, path)
	t.Setenv(SectionEnvironment, "1")
	t.Run("child", func(t *testing.T) {
		Enforce(t, Dedicated, 0, time.Second)
	})
	want := "gxb.local/backend/v2/internal/testsupport/latency TestRecordUsesTheRootTestNameForSubtests"
	lines := readRecordLines(t, path)
	if len(lines) != 1 || lines[0] != want {
		t.Fatalf("record lines %v, want [%q]", lines, want)
	}
}
