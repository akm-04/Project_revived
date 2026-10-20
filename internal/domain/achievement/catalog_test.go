package achievement

import (
	"reflect"
	"strings"
	"testing"
	"time"
)

func levelCatalog() Catalog {
	c := catalog()
	c.SchemaVersion = 2
	c.Levels = []Level{{ID: 1}}
	for id := int64(2); id <= 10; id++ {
		c.Levels = append(c.Levels, Level{ID: id, PointCondition: (id - 1) * 1000, Items: [][2]int64{{50000000 + id, 1}}})
	}
	return c
}

func TestPointsLevelsAndClaims(t *testing.T) {
	c := levelCatalog()
	if c.Validate() != nil || catalog().Validate() != nil {
		t.Fatal("schema 1 and 2 must both validate")
	}
	broken := levelCatalog()
	broken.Levels = broken.Levels[:9]
	if broken.Validate() == nil {
		t.Fatal("schema 2 without ten levels accepted")
	}
	early, late := time.Unix(100, 0), time.Unix(200, 0)
	total, reached := c.Points(Tiers{SelectedID: {&early, nil, nil}, PetsID: {&early, &late, nil}})
	if total != 2000 || !reached.Equal(late) {
		t.Fatal(total, reached)
	}
	if c.PointLevel(0) != 1 || c.PointLevel(2000) != 3 || c.PointLevel(99000) != 10 {
		t.Fatal("point level")
	}
	claimed := map[int64]bool{}
	if got := c.AwardStatus(2000, claimed); !reflect.DeepEqual(got, []int64{-1, 1, 1, 0, 0, 0, 0, 0, 0, 0}) {
		t.Fatal(got)
	}
	level, ok := c.NextClaim(2000, claimed)
	if !ok || level.ID != 2 {
		t.Fatal(level, ok)
	}
	claimed[2], claimed[3] = true, true
	if _, ok = c.NextClaim(2000, claimed); ok {
		t.Fatal("claimed twice")
	}
}

func TestStatusAndOwnedStateCounts(t *testing.T) {
	if StatusOf(100014) != Qualified || StatusOf(PetsID) != Qualified || StatusOf(100005) != ModeNotLive || StatusOf(100031) != OwnerUnknown || StatusOf(100016) != StageC {
		t.Fatal("status")
	}
	qualified := 0
	for id := int64(100001); id <= 100033; id++ {
		if StatusOf(id) == Qualified {
			qualified++
		}
	}
	if qualified != 15 {
		t.Fatal(qualified)
	}
	c := catalog()
	c.Rows[PetsID-100001].Thresholds = [3]int64{2, 8, 15}
	at := time.Unix(100, 0)
	s, e := NewStreak(7, PetsID, strings.Repeat("a", 64), at)
	if e != nil {
		t.Fatal(e)
	}
	s, _, e = s.ObserveCount(c, 9, at.Add(time.Second))
	if e != nil || s.CompleteTimes[1] == nil || s.CompleteTimes[2] != nil {
		t.Fatal(s, e)
	}
	s, changed, e := s.ObserveCount(c, 1, at.Add(2*time.Second))
	if e != nil || !changed || s.Current != 1 || s.CompleteTimes[1] == nil {
		t.Fatal("owned-state tiers must never be revoked", s, e)
	}
}
