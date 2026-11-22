package publicprofile

import (
	"context"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type forceByPartner struct {
	forces map[int64]float64
	calls  int
}

func (f *forceByPartner) HeroTx(_ context.Context, _ ca.CoherentReadScope, ref character.HeroRef, _ publicstats.View) (publicstats.Result, error) {
	f.calls++
	return publicstats.Result{Stats: statrules.Result{Force: f.forces[ref.PartnerID]}}, nil
}

func topForceFixture(forces map[int64]float64) (tx.Scope, MetricRequest, *rosterOwner, *forceByPartner) {
	sc, r, _ := metricFixture()
	r.IDs = []int64{1012}
	rows := make([]ca.RosterMetricRow, 0, len(forces))
	for partnerID := range forces {
		rows = append(rows, ca.RosterMetricRow{InstanceID: partnerID, OriginTableID: partnerID, TableID: partnerID, Star: 3, Version: 1, BeforeAwaken: partnerID})
	}
	heroes := ca.RosterMetricPopulation{PlayerID: r.PlayerID, Family: "Hero", Revision: r.ContentRevision, ObservedAt: r.ObservedAt, RootVersion: 7, Rows: rows}
	roster := &rosterOwner{calls: map[string]int{}, populations: map[string]ca.RosterMetricPopulation{"Hero": heroes}}
	force := &forceByPartner{forces: forces}
	return sc, r, roster, force
}

func TestI9_10ETopForceMetricSumsFiveStrongest(t *testing.T) {
	sc, r, roster, force := topForceFixture(map[int64]float64{1: 10, 2: 20, 3: 30, 4: 40, 5: 50, 6: 60})
	p := CanonicalMetricProvider{Roster: roster, Force: force}
	m, e := p.ReadTopForceMetricScopeTx(context.Background(), sc, r)
	if e != nil || m.Value != 200 || m.FieldID != 1012 || m.Owner != "CharacterHero" || m.PrivatePolicy != TopForceMetricPolicy || m.Semantics != TopForceMetricSemantics || m.SourceVersion != 7 || m.PopulationVersion != 7 || force.calls != 6 || roster.calls["Hero"] != 1 {
		t.Fatal(m, e, force.calls, roster.calls)
	}
	if !validRosterDigest(m.PopulationDigest) {
		t.Fatal("missing population witness", m)
	}

	sc, r, roster, force = topForceFixture(map[int64]float64{1: 10, 2: 20, 3: 7})
	m, e = (CanonicalMetricProvider{Roster: roster, Force: force}).ReadTopForceMetricScopeTx(context.Background(), sc, r)
	if e != nil || m.Value != 37 || force.calls != 3 {
		t.Fatal(m, e, force.calls)
	}

	sc, r, roster, force = topForceFixture(map[int64]float64{1: 10})
	stale := roster.populations["Hero"]
	stale.ObservedAt = stale.ObservedAt.Add(time.Second)
	roster.populations["Hero"] = stale
	if _, e = (CanonicalMetricProvider{Roster: roster, Force: force}).ReadTopForceMetricScopeTx(context.Background(), sc, r); e == nil {
		t.Fatal("stale population accepted")
	}
	if _, e = (CanonicalMetricProvider{Roster: roster}).ReadTopForceMetricScopeTx(context.Background(), sc, r); e == nil {
		t.Fatal("missing force owner accepted")
	}
	sc.Operation.Policies, _ = policy.NewSet()
	if _, e = (CanonicalMetricProvider{Roster: roster, Force: force}).ReadTopForceMetricScopeTx(context.Background(), sc, r); e == nil {
		t.Fatal("unpinned content accepted")
	}
}
