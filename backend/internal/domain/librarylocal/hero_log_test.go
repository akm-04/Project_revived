package librarylocal

import (
	"reflect"
	"testing"
	"time"
)

func TestHeroLogThresholds(t *testing.T) {
	if got := FavorLogIDsCrossed(0, 99); len(got) != 0 {
		t.Fatalf("below first threshold %v", got)
	}
	if got := FavorLogIDsCrossed(0, 100); !reflect.DeepEqual(got, []int64{80001}) {
		t.Fatalf("cross 100 %v", got)
	}
	if got := FavorLogIDsCrossed(100, 300); !reflect.DeepEqual(got, []int64{80006, 80002}) {
		t.Fatalf("cross 200,300 %v", got)
	}
	if got := FavorLogIDsCrossed(0, 2000); len(got) != 9 || got[0] != 80001 || got[8] != 80005 {
		t.Fatalf("cross all %v", got)
	}
	if got := DialogueLogIDsReached(0, 1); !reflect.DeepEqual(got, []int64{70001}) {
		t.Fatalf("dialogue 1 %v", got)
	}
	if got := DialogueLogIDsReached(9, 30); !reflect.DeepEqual(got, []int64{70002, 70003}) {
		t.Fatalf("dialogue 10,30 %v", got)
	}
	if got := DialogueLogIDsReached(0, 0); len(got) != 0 {
		t.Fatalf("dialogue zero %v", got)
	}
}

func TestHoldTimeLogsReached(t *testing.T) {
	acquired := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)
	cases := []struct {
		name string
		at   time.Time
		want []int64
	}{
		{"29 days", acquired.AddDate(0, 0, 29), []int64{}},
		{"30 days", acquired.AddDate(0, 0, 30), []int64{50001}},
		{"89 days", acquired.AddDate(0, 0, 89), []int64{50001}},
		{"90 days", acquired.AddDate(0, 0, 90), []int64{50001, 50002}},
		{"179 days", acquired.AddDate(0, 0, 179), []int64{50001, 50002}},
		{"180 days", acquired.AddDate(0, 0, 180), []int64{50001, 50002, 50003}},
		{"364 days", acquired.AddDate(0, 0, 364), []int64{50001, 50002, 50003}},
		{"365 days", acquired.AddDate(0, 0, 365), []int64{50001, 50002, 50003, 50004}},
		{"before acquisition", acquired.AddDate(0, 0, -1), []int64{}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got := HoldTimeLogsReached(acquired, c.at)
			ids := make([]int64, len(got))
			for i, milestone := range got {
				ids[i] = milestone.LogID
			}
			if !reflect.DeepEqual(ids, c.want) {
				t.Fatalf("milestones %v, want %v", ids, c.want)
			}
		})
	}

	got := HoldTimeLogsReached(acquired, acquired.AddDate(0, 0, 365))
	if want := acquired.AddDate(0, 0, 30); !got[0].OccurredAt.Equal(want) {
		t.Fatalf("50001 time %v, want %v", got[0].OccurredAt, want)
	}
	if want := acquired.AddDate(0, 0, 365); !got[3].OccurredAt.Equal(want) {
		t.Fatalf("50004 time %v, want %v", got[3].OccurredAt, want)
	}
}

func TestBattleLogIDsCrossed(t *testing.T) {
	cases := []struct {
		name     string
		from, to int64
		want     []int64
	}{
		{"first battle", 0, 1, []int64{60001}},
		{"fiftieth", 49, 50, []int64{60002}},
		{"hundredth", 99, 100, []int64{60003}},
		{"thousandth", 999, 1000, []int64{60004}},
		{"one step over all", 49, 1000, []int64{60002, 60003, 60004}},
		{"above fifty to thousand", 99, 1000, []int64{60003, 60004}},
		{"past thousand", 1000, 1001, []int64{}},
		{"no step", 42, 42, []int64{}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := BattleLogIDsCrossed(c.from, c.to); !reflect.DeepEqual(got, c.want) {
				t.Fatalf("battle (%d,%d] = %v, want %v", c.from, c.to, got, c.want)
			}
		})
	}
}

func TestAcquisitionLogSources(t *testing.T) {
	for _, logID := range []int64{10001, 10004, 10008} {
		if !IsAcquisitionLog(logID) {
			t.Fatalf("source %d not an acquisition row", logID)
		}
	}
	for _, logID := range []int64{10000, 10009, 20001, 90001} {
		if IsAcquisitionLog(logID) {
			t.Fatalf("log %d wrongly an acquisition row", logID)
		}
	}
	if LogAcquiredSoulStone != 10004 {
		t.Fatalf("soul-stone source %d", LogAcquiredSoulStone)
	}
}

func TestHeroLogColorAndStarIDs(t *testing.T) {
	if id, ok := ColorLogID(2); !ok || id != 20001 {
		t.Fatalf("color 2 %d %v", id, ok)
	}
	if id, ok := ColorLogID(14); !ok || id != 20013 {
		t.Fatalf("color 14 %d %v", id, ok)
	}
	if _, ok := ColorLogID(1); ok {
		t.Fatal("color 1 has no promotion entry")
	}
	if _, ok := ColorLogID(15); ok {
		t.Fatal("color 15 has no promotion entry")
	}
	if id, ok := StarLogID(2); !ok || id != 40001 {
		t.Fatalf("star 2 %d %v", id, ok)
	}
	if id, ok := StarLogID(10); !ok || id != 40009 {
		t.Fatalf("star 10 %d %v", id, ok)
	}
	if _, ok := StarLogID(1); ok {
		t.Fatal("star 1 has no star-up entry")
	}
	if _, ok := StarLogID(11); ok {
		t.Fatal("star 11 has no star-up entry")
	}
}
