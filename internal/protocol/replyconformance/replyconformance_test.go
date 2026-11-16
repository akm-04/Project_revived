package replyconformance

import (
	"sort"
	"strings"
	"testing"
)

type regionRow struct {
	RegionID *int64 `json:"region_id"`
	Name     string `json:"name"`
}

func int64Pointer(value int64) *int64 { return &value }

func TestCheckerFlagsMissingAndNullRequiredPaths(t *testing.T) {
	cases := []struct {
		name string
		body any
		want []string
	}{
		{"complete", map[string]any{"regions": []any{map[string]any{"region_id": int64(1), "name": "Server 1"}}}, nil},
		{"missing leaf", map[string]any{"regions": []any{map[string]any{"name": "Server 1"}}}, []string{"regions[].region_id"}},
		{"null leaf", map[string]any{"regions": []any{map[string]any{"region_id": nil, "name": "Server 1"}}}, []string{"regions[].region_id"}},
		{"typed rows", map[string]any{"regions": []map[string]any{{"region_id": int64(1), "name": "Server 1"}}}, nil},
		{"struct rows", map[string]any{"regions": []regionRow{{RegionID: int64Pointer(1), Name: "Server 1"}}}, nil},
		{"struct null", map[string]any{"regions": []regionRow{{Name: "Server 1"}}}, []string{"regions[].region_id"}},
		{"missing list", map[string]any{}, []string{"regions", "regions[]", "regions[].name", "regions[].region_id"}},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			got := (Checker{}).Check(18, testCase.body)
			sort.Strings(got)
			if strings.Join(got, ",") != strings.Join(testCase.want, ",") {
				t.Fatalf("violations %#v, want %#v", got, testCase.want)
			}
		})
	}
}

func TestCheckerFollowsAnAbsentListParentsRequirement(t *testing.T) {
	base := map[string]any{
		"sub_type":          int64(1),
		"newyear_boss_rank": map[string]any{"infos": []any{}, "my_hurt": int64(0)},
	}
	if violations := (Checker{}).Check(276, base); len(violations) != 0 {
		t.Fatalf("optional absent boss_rank produced %#v", violations)
	}
	base["boss_rank"] = []any{map[string]any{}}
	got := (Checker{}).Check(276, base)
	sort.Strings(got)
	want := []string{"boss_rank[].infos", "boss_rank[].my_hurt"}
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Fatalf("violations %#v, want %#v", got, want)
	}
}

func TestCheckerIgnoresMIDsWithoutObligations(t *testing.T) {
	if violations := (Checker{}).Check(20480, nil); len(violations) != 0 {
		t.Fatalf("violations %#v", violations)
	}
}

type recordingReporter struct {
	helperCalled bool
	failures     []string
}

func (r *recordingReporter) Helper() { r.helperCalled = true }

func (r *recordingReporter) Fatalf(format string, args ...any) {
	r.failures = append(r.failures, format)
}

func TestCheckFailsOnAMissingRequiredPath(t *testing.T) {
	reporter := &recordingReporter{}
	Check(reporter, 18, map[string]any{"regions": []any{map[string]any{"name": "Server 1"}}})
	if !reporter.helperCalled || len(reporter.failures) != 1 {
		t.Fatalf("helper=%v failures=%#v", reporter.helperCalled, reporter.failures)
	}
}
