package course_test

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/content/builtin"
	c "gxb.local/backend/v2/internal/domain/course"
	"strings"
	"testing"
	"time"
)

func catalog(t testing.TB) c.Catalog {
	t.Helper()
	raw, e := builtin.GeneratedFile("course_input_catalog.json")
	if e != nil {
		t.Fatal(e)
	}
	var x c.Catalog
	if e = json.Unmarshal(raw, &x); e != nil || x.Validate() != nil {
		t.Fatal(e)
	}
	return x
}
func TestFiniteSessionDueOnceNoAutoRepeat(t *testing.T) {
	cat := catalog(t)
	at := time.Date(2026, 10, 14, 10, 0, 0, 0, time.UTC)
	h := c.SeedHero()
	h.Courses = append(h.Courses, c.Record{ID: 100101, Quality: 1})
	s := c.Seed()
	s.Attendance[1] = c.Attendance{PartnerID: 1, EnterAt: at, Job: &c.Job{CourseID: 100101, Occurrence: "occ", Revision: strings.Repeat("a", 64), StartedAt: at, Duration: cat.Duration}}
	if _, e := s.Settle(cat, 1, &h, at.Add(8*time.Hour-time.Nanosecond)); e != nil || h.Courses[0].Progress != 0 {
		t.Fatal("early", e)
	}
	if due, e := s.Settle(cat, 1, &h, at.Add(100*time.Hour)); !due || e != nil || h.Courses[0].Progress != 20 || len(s.Attendance) != 0 || len(s.Logs) != 1 {
		t.Fatal("finite", e, h, s)
	}
	if due, e := s.Settle(cat, 1, &h, at.Add(200*time.Hour)); due || e != nil || h.Courses[0].Progress != 20 {
		t.Fatal("double", e)
	}
	if s.Logs[0].At != at.Add(8*time.Hour).Unix() {
		t.Fatal("deadlineevent")
	}
}
func TestRawSpecialMetadataAndQualityBoundaries(t *testing.T) {
	cat := catalog(t)
	if cat.Metadata(100101)["number"] != "-2" || cat.Metadata(100101)["step_up"] != "25.5" {
		t.Fatal("narrowed rawdecimal")
	}
	for i, n := range cat.Thresholds {
		if cat.Quality(n) != int64(i+1) {
			t.Fatal("threshold")
		}
		if i > 0 && cat.Quality(n-1) != int64(i) {
			t.Fatal("belowthreshold")
		}
	}
	h := c.SeedHero()
	h.Courses = []c.Record{{ID: 100101, Progress: 100, Quality: 1, Skill: 1}, {ID: 100102, Progress: 100, Quality: 1, Skill: 1}}
	if h.Validate(cat) == nil {
		t.Fatal("duplicatebinding")
	}
	h.Courses[1].Skill = 5
	if h.Validate(cat) == nil {
		t.Fatal("closed source slot")
	}
}
func FuzzFiniteRemaining(f *testing.F) {
	for _, n := range []int64{-1, 0, 1, 28799, 28800, 28801, 1000000} {
		f.Add(n)
	}
	f.Fuzz(func(t *testing.T, seconds int64) {
		seconds %= 10000000
		at := time.Unix(1800000000, 0)
		j := &c.Job{StartedAt: at, Duration: 28800}
		left, e := c.Remaining(j, at.Add(time.Duration(seconds)*time.Second))
		if seconds < 0 {
			if e == nil {
				t.Fatal("backward clock")
			}
			return
		}
		if e != nil || left < 0 || left > 28800 || seconds >= 28800 && left != 0 {
			t.Fatal(left, e)
		}
	})
}
