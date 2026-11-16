package replyconformance

import (
	"encoding/json"
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

// provenRepeatedPaths are the only generated paths allowed to repeat a segment;
// each is read as a nested key at the client line cited in the extractor test.
var provenRepeatedPaths = map[string]bool{
	"301:rank_list[].rank_info.rank_info":      true,
	"1362:report.report":                       true,
	"2411:hero_stat[].hero_stat.stay_pos":      true,
	"2411:info.hero_stat[].hero_stat":          true,
	"2411:info.hero_stat[].hero_stat.stay_pos": true,
}

func repeatedSegment(path string) string {
	seen := map[string]bool{}
	for _, part := range strings.Split(strings.ReplaceAll(path, "[]", ""), ".") {
		if part == "" {
			continue
		}
		if seen[part] {
			return part
		}
		seen[part] = true
	}
	return ""
}

// TestGeneratedObligationsHaveNoUnprovenRepeatedPath is the completeness check
// for the extractor's storage-binding repair: it fails when the live embedded
// population grows a repeated path outside the proven table, or when a proven
// entry disappears.
func TestGeneratedObligationsHaveNoUnprovenRepeatedPath(t *testing.T) {
	var document struct {
		MIDs map[string]struct {
			Paths []json.RawMessage `json:"paths"`
		} `json:"mids"`
	}
	if err := json.Unmarshal(generated, &document); err != nil {
		t.Fatalf("embedded obligations: %v", err)
	}
	found := map[string]bool{}
	for mid, record := range document.MIDs {
		for _, raw := range record.Paths {
			var entry []json.RawMessage
			if err := json.Unmarshal(raw, &entry); err != nil || len(entry) < 2 {
				continue
			}
			var path string
			if json.Unmarshal(entry[0], &path) != nil {
				continue
			}
			if repeatedSegment(path) == "" {
				continue
			}
			found[mid+":"+path] = true
		}
	}
	for key := range found {
		if !provenRepeatedPaths[key] {
			t.Fatalf("MID/path %s repeats a segment without client proof", key)
		}
	}
	for key := range provenRepeatedPaths {
		if !found[key] {
			t.Fatalf("proven repeated path %s is no longer generated; update the table", key)
		}
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
