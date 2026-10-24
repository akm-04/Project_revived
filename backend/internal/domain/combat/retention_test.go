package combat

import (
	"testing"
	"time"
)

func TestRetentionWindowAndVersions(t *testing.T) {
	terminal := time.Date(2026, 10, 1, 12, 0, 0, 0, time.UTC)
	attempt := Attempt{State: Terminal, ResolutionHash: "resolved", TerminalAt: &terminal}
	week := Retention{ID: "FIXTURE_REPORT_RETENTION_V1", Version: 1, Window: RetentionCeiling}
	short := Retention{ID: "FIXTURE_REPORT_RETENTION_V2", Version: 2, Window: 48 * time.Hour}
	for name, r := range map[string]Retention{
		"unversioned id":  {ID: "fixture", Version: 1, Window: time.Hour},
		"zero version":    {ID: "FIXTURE_REPORT_RETENTION_V1", Window: time.Hour},
		"zero window":     {ID: "FIXTURE_REPORT_RETENTION_V1", Version: 1},
		"above ceiling":   {ID: "FIXTURE_REPORT_RETENTION_V1", Version: 1, Window: RetentionCeiling + time.Second},
		"negative window": {ID: "FIXTURE_REPORT_RETENTION_V1", Version: 1, Window: -time.Hour},
	} {
		if r.Valid() {
			t.Fatal("retention accepted", name)
		}
	}
	if !week.Valid() || !short.Valid() {
		t.Fatal("valid retention refused")
	}
	threeDays := terminal.Add(72 * time.Hour)
	if !week.Retains(attempt, threeDays) || short.Retains(attempt, threeDays) {
		t.Fatal("the version must decide availability at the same instant")
	}
	if !week.Retains(attempt, terminal.Add(RetentionCeiling-time.Nanosecond)) || week.Retains(attempt, terminal.Add(RetentionCeiling)) {
		t.Fatal("the window end is exclusive")
	}
	for name, a := range map[string]Attempt{
		"unresolved terminal": {State: Terminal, TerminalAt: &terminal},
		"resolution ready":    {State: ResolutionReady, ResolutionHash: "resolved"},
	} {
		if week.Retains(a, terminal) {
			t.Fatal("retained", name)
		}
	}
}
