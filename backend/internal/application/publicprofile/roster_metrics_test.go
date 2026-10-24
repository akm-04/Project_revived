package publicprofile

import (
	"context"
	"errors"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/policy"
	"testing"
	"time"
)

type rosterOwner struct {
	populations map[string]ca.RosterMetricPopulation
	calls       map[string]int
	err         error
}

func (o *rosterOwner) ReadRosterMetricsTx(_ context.Context, _ ca.CoherentReadScope, _ identity.PlayerID, f string) (ca.RosterMetricPopulation, error) {
	o.calls[f]++
	return o.populations[f], o.err
}
func rosterFixture(t *testing.T) (CanonicalMetricProvider, *rosterOwner) {
	t.Helper()
	_, r, _ := metricFixture()
	f := func(family string, rows []ca.RosterMetricRow) ca.RosterMetricPopulation {
		return ca.RosterMetricPopulation{PlayerID: r.PlayerID, Family: family, Revision: r.ContentRevision, ObservedAt: r.ObservedAt, RootVersion: 7, Rows: rows}
	}
	o := &rosterOwner{calls: map[string]int{}, populations: map[string]ca.RosterMetricPopulation{"Hero": f("Hero", []ca.RosterMetricRow{{InstanceID: 1, OriginTableID: 1001, TableID: 1001, Star: 4, Version: 3}, {InstanceID: 2, OriginTableID: 11001, TableID: 11001001, Star: 6, Version: 8, BeforeAwaken: 11001}}), "Pet": f("Pet", []ca.RosterMetricRow{{InstanceID: 1, OriginTableID: 2001, TableID: 2001, Star: 2, Version: 1}})}}
	return CanonicalMetricProvider{Roster: o}, o
}
func TestPrivateRosterCountsStableOriginAndVersionedBasis(t *testing.T) {
	p, o := rosterFixture(t)
	sc, r, _ := metricFixture()
	sc.Operation, _ = bindRosterPolicy(sc.Operation)
	r.IDs = []int64{1009, 1001, 1008, 1002}
	obs, e := p.ReadMetricsScopeTx(context.Background(), sc, r)
	if e != nil {
		t.Fatal(e)
	}
	got, e := metricValues(r, obs)
	if e != nil || got["1001"] != 2 || got["1002"] != 1 || got["1008"] != 10 || got["1009"] != 1 || o.calls["Hero"] != 1 || o.calls["Pet"] != 1 {
		t.Fatal(got, e, o.calls)
	}
	heroes := o.populations["Hero"]
	old := heroes.Digest()
	heroes.Rows[0], heroes.Rows[1] = heroes.Rows[1], heroes.Rows[0]
	if heroes.Digest() != old {
		t.Fatal("order-dependent witness")
	}
	heroes.Rows[0].Star++
	heroes.Rows[0].Version++
	o.populations["Hero"] = heroes
	if heroes.Digest() == old {
		t.Fatal("star evolution missed by root-only basis")
	}
	obs, e = p.ReadMetricsScopeTx(context.Background(), sc, r)
	got, _ = metricValues(r, obs)
	if e != nil || got["1001"] != 2 || got["1008"] != 11 {
		t.Fatal(got, e)
	}
	for _, field := range []int64{1001, 1002, 1008, 1009} {
		p, o = rosterFixture(t)
		r.IDs = []int64{field}
		if _, e = p.ReadMetricsScopeTx(context.Background(), sc, r); e != nil {
			t.Fatal(e)
		}
		other := "Pet"
		if field == 1002 {
			other = "Hero"
		}
		if o.calls[other] != 0 {
			t.Fatal("unrequested owner read", o.calls)
		}
	}
}
func TestPrivateRosterRejectsCorruptOrUnpinnedPopulation(t *testing.T) {
	for _, mutate := range []func(*ca.RosterMetricPopulation){
		func(v *ca.RosterMetricPopulation) { v.PlayerID++ }, func(v *ca.RosterMetricPopulation) { v.RootVersion = 0 }, func(v *ca.RosterMetricPopulation) { v.Revision = "wrong" }, func(v *ca.RosterMetricPopulation) { v.Family = "Pet" }, func(v *ca.RosterMetricPopulation) { v.ObservedAt = v.ObservedAt.Add(time.Second) }, func(v *ca.RosterMetricPopulation) { v.Rows[1].OriginTableID = v.Rows[0].OriginTableID }, func(v *ca.RosterMetricPopulation) { v.Rows[1].InstanceID = v.Rows[0].InstanceID }, func(v *ca.RosterMetricPopulation) { v.Rows[0].Star = 0 }, func(v *ca.RosterMetricPopulation) { v.Rows[0].Version = 0 }, func(v *ca.RosterMetricPopulation) { v.Rows[0].BeforeAwaken = -1 },
	} {
		p, o := rosterFixture(t)
		sc, r, _ := metricFixture()
		sc.Operation, _ = bindRosterPolicy(sc.Operation)
		r.IDs = []int64{1001}
		pop := o.populations["Hero"]
		mutate(&pop)
		o.populations["Hero"] = pop
		if got, e := p.ReadMetricsScopeTx(context.Background(), sc, r); e == nil || got != nil {
			t.Fatal("corruption accepted", got, e)
		}
	}
	p, o := rosterFixture(t)
	sc, r, _ := metricFixture()
	r.IDs = []int64{1001}
	if _, e := p.ReadMetricsScopeTx(context.Background(), sc, r); e == nil || len(o.calls) != 0 {
		t.Fatal("unbound policy reached owner")
	}
	sc.Operation, _ = bindRosterPolicy(sc.Operation)
	obs, e := p.ReadMetricsScopeTx(context.Background(), sc, r)
	if e != nil {
		t.Fatal(e)
	}
	for _, mutate := range []func(*MetricObservation){func(v *MetricObservation) { v.PrivatePolicy = "future" }, func(v *MetricObservation) { v.PopulationDigest = "bad" }, func(v *MetricObservation) { v.Owner = "CharacterPet" }, func(v *MetricObservation) { v.PetRootVersion = 1 }, func(v *MetricObservation) { v.PopulationVersion = 0 }, func(v *MetricObservation) { v.SourceVersion++ }, func(v *MetricObservation) { v.LibraryRootVersion = 1 }} {
		bad := obs[0]
		mutate(&bad)
		if _, e := metricValues(r, []MetricObservation{bad}); e == nil {
			t.Fatal("forged roster basis")
		}
	}
	o.err = errors.New("owner unavailable")
	if _, e = p.ReadMetricsScopeTx(context.Background(), sc, r); e == nil {
		t.Fatal("owner error swallowed")
	}
	sc.Operation.Policies, _ = policy.NewSet(policy.Ref{Name: "roster-metrics", Version: "future"})
	if _, e = bindRosterPolicy(sc.Operation); e == nil {
		t.Fatal("conflicting policy accepted")
	}
}
