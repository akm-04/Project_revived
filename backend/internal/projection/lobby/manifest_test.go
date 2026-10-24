package lobby

import (
	"testing"
	"time"
)

func TestQuiescenceDetectsRequestStormWithinCorrelatedRun(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	dir := t.TempDir()
	api := newCapturedForTest(t, dir, "run-storm", ProcessAPI, "api-1", base, 1000, 1000)
	rt := newCapturedForTest(t, dir, "run-storm", ProcessRealtime, "rt-1", base, 1000, 1000)
	recordServerS0(t, api, rt, base)
	for i := 0; i < 10; i++ {
		if err := api.Record(corr(api, BootEvent{MID: 192, Kind: BootDiscovery, Phase: PhaseClientRequestObserved, At: base.Add(time.Duration(i+20) * time.Second), Key: "WORLD"})); err != nil {
			t.Fatal(err)
		}
	}
	_ = api.RecordHealth(base.Add(60 * time.Second))
	_ = rt.RecordHealth(base.Add(60 * time.Second))
	combined, err := LoadBootTrackerJSONL(testEvidencePath(dir, "run-storm", ProcessAPI), testEvidencePath(dir, "run-storm", ProcessRealtime))
	if err != nil {
		t.Fatal(err)
	}
	q := combined.Quiescence(base.Add(61*time.Second), 60*time.Second)
	if q.Stable || len(q.Storms) == 0 {
		t.Fatalf("request storm incorrectly quiescent: %+v", q)
	}
}

func TestTimerHeavySixtySecondsStaysMemoryBounded(t *testing.T) {
	base := time.Unix(1_700_000_000, 0).UTC()
	tr := newCapturedForTest(t, t.TempDir(), "run-timers", ProcessAPI, "api-1", base, 1000, 16)
	for i := 1; i <= 600; i++ {
		if err := tr.Record(corr(tr, BootEvent{MID: 1056, Kind: BootLegitTimer, Phase: PhaseClientRequestObserved, At: base.Add(time.Duration(i) * 100 * time.Millisecond), Key: "building"})); err != nil {
			t.Fatal(err)
		}
	}
	if got := len(tr.Events()); got > 16 {
		t.Fatalf("timer-heavy ring=%d", got)
	}
	if tr.Health().TotalEvents != 601 { // capture start + 600 timer events
		t.Fatalf("health=%+v", tr.Health())
	}
}
