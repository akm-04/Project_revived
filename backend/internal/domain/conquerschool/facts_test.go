package conquerschool_test

import (
	"gxb.local/backend/v2/internal/content/builtin"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/foundation/ids"
	"reflect"
	"strings"
	"testing"
	"time"
)

func catalog(t testing.TB) d.Catalog {
	t.Helper()
	b, e := builtin.Load()
	if e != nil {
		t.Fatal(e)
	}
	v, e := d.NewCatalog(b.ConquerInputs.SchemaVersion, b.ConquerInputs.PolicyID, b.ConquerInputs.Tables)
	if e != nil {
		t.Fatal(e)
	}
	return v
}
func TestExactConquerRegionalBoundaryAndLoopVectors(t *testing.T) {
	c := catalog(t)
	all := map[int64]int64{5: 100, 6: 200, 9: 48, 10: 48, 4: 2500, 7: 30, 8: 20, 14: 15, 15: 10}
	for _, x := range []struct {
		level int64
		want  map[int64]int64
	}{{0, map[int64]int64{}}, {19, map[int64]int64{}}, {20, map[int64]int64{5: 100, 6: 200}}, {39, map[int64]int64{5: 100, 6: 200}}, {40, map[int64]int64{5: 100, 6: 200, 9: 48, 10: 48}}, {49, map[int64]int64{5: 100, 6: 200, 9: 48, 10: 48}}, {50, map[int64]int64{5: 100, 6: 200, 9: 48, 10: 48, 4: 2500}}, {54, map[int64]int64{5: 100, 6: 200, 9: 48, 10: 48, 4: 2500}}, {55, map[int64]int64{5: 100, 6: 200, 9: 48, 10: 48, 4: 2500, 7: 30, 8: 20}}, {56, all}} {
		got, e := c.Evaluate(d.Progress{Level: x.level, Loop: 1})
		if e != nil || !reflect.DeepEqual(got, x.want) {
			t.Fatal(x.level, got, e, x.want)
		}
	}
	for loop := int64(2); loop <= 9; loop++ {
		got, e := c.Evaluate(d.Progress{Level: 1, Loop: loop})
		if e != nil || !reflect.DeepEqual(got, all) {
			t.Fatal(loop, got, e)
		}
		zero, e := c.Evaluate(d.Progress{Loop: loop})
		if e != nil || len(zero) != 0 {
			t.Fatal(zero, e)
		}
	}
	for _, p := range []d.Progress{{Level: 57, Loop: 1}, {Level: -1, Loop: 1}, {Level: 20, Loop: 0}, {Level: 20, Loop: 10}} {
		if _, e := c.Evaluate(p); e == nil {
			t.Fatal("bad progress", p)
		}
	}
	got, _ := c.Evaluate(d.Progress{Level: 56, Loop: 1})
	got[15] = 999
	again, _ := c.Evaluate(d.Progress{Level: 56, Loop: 1})
	if again[15] != 10 {
		t.Fatal("mutable/translation value leaked")
	}
}
func TestRunObservationDistinctFromStatProgressAndUnknown(t *testing.T) {
	c := catalog(t)
	for _, r := range []struct {
		run      d.Run
		complete bool
	}{{d.Run{Loop: 1, CurrentID: 10002, PassedID: 10001, Generation: "test-run"}, false}, {d.Run{Loop: 1, CurrentID: 10056, PassedID: 10056, Generation: "test-run"}, true}, {d.Run{Loop: 1, CurrentID: 0, PassedID: 10056, Generation: "test-run"}, true}, {d.Run{Loop: 9, CurrentID: 10001, Generation: "test-run"}, true}} {
		v, e := c.Complete(r.run)
		if e != nil || v != r.complete {
			t.Fatal(r, v, e)
		}
	}
	for _, r := range []d.Run{{Loop: 1, CurrentID: 999, Generation: "x"}, {Loop: 1, CurrentID: 10001}, {Loop: 10, Generation: "x"}} {
		if _, e := c.Complete(r); e == nil {
			t.Fatal(r)
		}
	}
	id, e := ids.NewUUID()
	if e != nil {
		t.Fatal(e)
	}
	f := d.Facts{Player: 100001, Version: 1, ContentRevision: strings.Repeat("a", 64), Payload: d.Payload{Kind: d.Unknown, Policy: d.Policy, OriginOperation: id, OriginRef: "explicit-test"}, CreatedAt: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC), UpdatedAt: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)}
	if e = f.Validate(c); e != nil || f.Known() {
		t.Fatal(f, e)
	}
	f.Payload.Progress = &d.Progress{Loop: 1}
	if f.Validate(c) == nil {
		t.Fatal("unknown default became proof")
	}
	f.Payload.Kind = d.Initial
	if f.Validate(c) != nil || !f.Known() {
		t.Fatal(f)
	}
	cp := f.Payload.Clone()
	cp.Progress.Level = 20
	if f.Payload.Progress.Level != 0 {
		t.Fatal("raw alias")
	}
}
func FuzzConquerProgressNoMutationOrUnboundedOutput(f *testing.F) {
	c := catalog(f)
	f.Add(int64(20), int64(1))
	f.Add(int64(1), int64(2))
	f.Fuzz(func(t *testing.T, level, loop int64) {
		p := d.Progress{Level: level, Loop: loop}
		copy := p
		got, e := c.Evaluate(p)
		if p != copy {
			t.Fatal("mutation")
		}
		if e == nil {
			for id, v := range got {
				if id < 1 || v < 0 || v > 2500 {
					t.Fatal(id, v)
				}
			}
			if level == 0 && len(got) != 0 {
				t.Fatal("nonzero initial")
			}
		}
	})
}
