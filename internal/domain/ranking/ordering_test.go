package ranking

import (
	"reflect"
	"testing"
	"time"
)

func fixture() (Profile, []Entry) {
	p := Profile{ID: CurrentFirstReach, PolicyVersion: "private-v1", Generation: "snapshot-1", TieBreak: StableID, Scope: Scope{Kind: "SERVER", ServerID: 1, Cohort: "girls"}, ObservedAt: time.Unix(200, 0)}
	f := func(id, score, at int64) Entry {
		return Entry{SubjectID: id, Score: score, ScoreSince: time.Unix(at, 0), Basis: p.ID, PolicyVersion: p.PolicyVersion, Generation: p.Generation, Scope: p.Scope}
	}
	return p, []Entry{f(4, 20, 100), f(3, 20, 90), f(2, 20, 90), f(1, 19, 70), f(5, 21, 190)}
}
func TestFirstReachAndPersistedLottery(t *testing.T) {
	p, rows := fixture()
	original := append([]Entry{}, rows...)
	for _, profile := range []string{CurrentFirstReach, CurrentObserved, MonotonicFirstReach} {
		p.ID = profile
		for i := range rows {
			rows[i].Basis = profile
		}
		got, e := Order(p, rows)
		if e != nil {
			t.Fatal(e)
		}
		ids := []int64{}
		for _, r := range got {
			ids = append(ids, r.SubjectID)
		}
		if !reflect.DeepEqual(ids, []int64{5, 2, 3, 4, 1}) {
			t.Fatal(ids)
		}
	}
	p, rows = fixture()
	p.TieBreak = PersistedLottery
	for i := range rows {
		n := uint64(100 - rows[i].SubjectID)
		rows[i].LotteryPriority = &n
	}
	got, e := Order(p, rows)
	if e != nil || got[1].SubjectID != 3 || got[2].SubjectID != 2 {
		t.Fatal(got, e)
	}
	again, e := Order(p, rows)
	if e != nil || !reflect.DeepEqual(got, again) {
		t.Fatal("refresh changed lottery", e)
	}
	_, plain := fixture()
	if !reflect.DeepEqual(plain, original) {
		t.Fatal("input mutated")
	}
}
func TestRejectMixedScopeTimeProvenanceAndGeneration(t *testing.T) {
	for _, change := range []func(*Profile, []Entry){
		func(p *Profile, r []Entry) { p.Scope = Scope{} },
		func(p *Profile, r []Entry) { p.Scope.ServerID = 0 },
		func(p *Profile, r []Entry) { p.ID = "PVP_AUTHORITATIVE_POSITION" },
		func(p *Profile, r []Entry) { p.TieBreak = "COIN_FLIP_EACH_READ" },
		func(p *Profile, r []Entry) { p.TieBreak = PersistedLottery },
		func(p *Profile, r []Entry) { r[0].Scope.ServerID = 2 },
		func(p *Profile, r []Entry) { r[0].Basis = CurrentObserved },
		func(p *Profile, r []Entry) { r[0].Generation = "old" },
		func(p *Profile, r []Entry) { r[0].PolicyVersion = "old" },
		func(p *Profile, r []Entry) { r[0].ScoreSince = time.Time{} },
		func(p *Profile, r []Entry) { r[0].ScoreSince = p.ObservedAt.Add(time.Second) },
		func(p *Profile, r []Entry) { r[0].Score = -1 },
		func(p *Profile, r []Entry) { r[0].SubjectID = r[1].SubjectID },
	} {
		p, r := fixture()
		change(&p, r)
		if got, e := Order(p, r); e == nil || got != nil {
			t.Fatal("invalid ordering accepted", p, r)
		}
	}
	p, r := fixture()
	p.Scope = Scope{Kind: "GLOBAL", Cohort: "global-girls"}
	for i := range r {
		r[i].Scope = p.Scope
	}
	if _, e := Order(p, r); e != nil {
		t.Fatal(e)
	}
	p.Scope.ServerID = 1
	if _, e := Order(p, r); e == nil {
		t.Fatal("global with serverID")
	}
}
