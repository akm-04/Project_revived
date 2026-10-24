package publicprofile

import (
	"context"
	"errors"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type metricTx struct{}
type metricRow struct{}

func (metricRow) Scan(...any) error                              { return errors.New("unexpected SQL") }
func (metricTx) QueryRow(context.Context, string, ...any) tx.Row { return metricRow{} }
func (metricTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return nil, errors.New("unexpected SQL")
}
func (metricTx) Commit(context.Context) error   { return nil }
func (metricTx) Rollback(context.Context) error { return nil }

type metricPopulation struct {
	value lib.CollectionInputs
	err   error
	calls int
}

func (p *metricPopulation) MarriedHeroCountTx(context.Context, tx.Queryer, lib.InputScope) (lib.CollectionInputs, error) {
	p.calls++
	return p.value, p.err
}
func metricFixture() (tx.Scope, MetricRequest, *metricPopulation) {
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	at := time.Unix(100, 0).UTC()
	ps, _ := policy.NewSet(policy.Ref{Name: "content", Version: rev})
	sc := tx.Scope{Tx: metricTx{}, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}, Operation: operation.Context{ID: ids.UUID{1}, StartedAt: at, Policies: ps}}
	r := MetricRequest{PlayerID: 1, IDs: []int64{1010}, ContentRevision: rev, ObservedAt: at}
	return sc, r, &metricPopulation{value: lib.CollectionInputs{Player: 1, PopulationVersion: 7, LibraryRootVersion: 12, ContentRevision: rev, ObservedAt: at, MarriedCount: 0}}
}
func TestI7C4CMetricScopeAndOwnerNegatives(t *testing.T) {
	sc, r, owner := metricFixture()
	p := CanonicalMetricProvider{Library: owner}
	out, e := p.ReadMetricsScopeTx(context.Background(), sc, r)
	if e != nil || len(out) != 1 || out[0].Value != 0 || out[0].PopulationVersion != 7 || out[0].SourceVersion != 12 {
		t.Fatal(out, e)
	}
	if values, e := metricValues(r, out); e != nil || values["1010"] != 0 {
		t.Fatal(values, e)
	}
	for _, mutate := range []func(*tx.Scope, *MetricRequest){func(s *tx.Scope, r *MetricRequest) { s.Options.Isolation = tx.ReadCommitted }, func(s *tx.Scope, r *MetricRequest) { s.Tx = nil }, func(s *tx.Scope, r *MetricRequest) { s.Attempt = 0 }, func(s *tx.Scope, r *MetricRequest) { s.Operation.Policies = policy.Set{} }, func(s *tx.Scope, r *MetricRequest) {
		r.ContentRevision = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	}, func(s *tx.Scope, r *MetricRequest) { r.PlayerID = 0 }, func(s *tx.Scope, r *MetricRequest) { r.ObservedAt = time.Time{} }, func(s *tx.Scope, r *MetricRequest) { r.IDs = []int64{1010, 1010} }, func(s *tx.Scope, r *MetricRequest) { r.IDs = []int64{1004} }, func(s *tx.Scope, r *MetricRequest) { r.IDs = []int64{1012} }} {
		s, q, o := metricFixture()
		mutate(&s, &q)
		if got, e := (CanonicalMetricProvider{Library: o}).ReadMetricsScopeTx(context.Background(), s, q); e == nil || got != nil || o.calls != 0 {
			t.Fatal("invalid scope/request reached owner", got, e, o.calls)
		}
	}
	for _, mutate := range []func(*lib.CollectionInputs){func(v *lib.CollectionInputs) { v.Player = 2 }, func(v *lib.CollectionInputs) { v.PopulationVersion = 0 }, func(v *lib.CollectionInputs) { v.LibraryRootVersion = 0 }, func(v *lib.CollectionInputs) { v.MarriedCount = -1 }, func(v *lib.CollectionInputs) { v.MarriedCount = 9007199254740992 }, func(v *lib.CollectionInputs) { v.ContentRevision = "wrong" }, func(v *lib.CollectionInputs) { v.ObservedAt = v.ObservedAt.Add(time.Second) }} {
		s, q, o := metricFixture()
		mutate(&o.value)
		if got, e := (CanonicalMetricProvider{Library: o}).ReadMetricsScopeTx(context.Background(), s, q); e == nil || got != nil {
			t.Fatal("incoherent owner", got, e)
		}
	}
	owner.err = errors.New("owner unavailable")
	if got, e := p.ReadMetricsScopeTx(context.Background(), sc, r); e == nil || got != nil {
		t.Fatal(got, e)
	}
	if _, e = p.ReadMetricsTx(context.Background(), sc.Tx, r); e == nil {
		t.Fatal("unscoped population activated")
	}
	r.IDs = []int64{}
	p.Library = nil
	out, e = p.ReadMetricsScopeTx(context.Background(), sc, r)
	if e != nil || out == nil || len(out) != 0 {
		t.Fatal(out, e)
	}
}
func TestI7C4CRejectForgedMetricObservations(t *testing.T) {
	sc, r, o := metricFixture()
	out, e := (CanonicalMetricProvider{Library: o}).ReadMetricsScopeTx(context.Background(), sc, r)
	if e != nil {
		t.Fatal(e)
	}
	for _, mutate := range []func(*MetricObservation){func(v *MetricObservation) { v.Owner = "Achievement" }, func(v *MetricObservation) { v.Semantics = CreationMetricSemantics }, func(v *MetricObservation) { v.PlayerID++ }, func(v *MetricObservation) { v.FieldID = 1004 }, func(v *MetricObservation) { v.PopulationVersion = 0 }, func(v *MetricObservation) { v.SourceVersion++ }, func(v *MetricObservation) { v.LibraryRootVersion = 0 }, func(v *MetricObservation) { v.ContentRevision = "wrong" }, func(v *MetricObservation) { v.Value = -1 }, func(v *MetricObservation) { v.Value = 9007199254740992 }, func(v *MetricObservation) { v.ObservedAt = v.ObservedAt.Add(time.Second) }} {
		bad := out[0]
		mutate(&bad)
		if _, e := metricValues(r, []MetricObservation{bad}); e == nil {
			t.Fatal("forged observation accepted", bad)
		}
	}
	if _, e := metricValues(r, append(out, out...)); e == nil {
		t.Fatal("duplicate accepted")
	}
}
