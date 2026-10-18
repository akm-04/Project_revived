//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	profile "gxb.local/backend/v2/internal/application/publicprofile"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

// Interleave real owner commands after the first actual metric observation.
// This wrapper never substitutes an observation or opens a read transaction.
type rankingInterleavedMetrics struct {
	Inner      profile.ScopedMetricReader
	AfterFirst func()
	Called     bool
	Attempts   []int
}

func (m *rankingInterleavedMetrics) ReadMetricsScopeTx(c context.Context, sc tx.Scope, r profile.MetricRequest) ([]profile.MetricObservation, error) {
	m.Attempts = append(m.Attempts, sc.Attempt)
	out, e := m.Inner.ReadMetricsScopeTx(c, sc, r)
	if e == nil && !m.Called {
		m.Called = true
		m.AfterFirst()
	}
	return out, e
}
func TestI7C4CRankingActualAcquisitionBetweenParticipantsUsesOneSnapshot(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	b := rankingActor(t, p, server, true)
	rankingSummon(t, p, a, rev, 10001001)
	rankingSummon(t, p, b, rev, 10001001)
	s := rankingService(p, p)
	// Create the Ranking root before interleaving so concurrent owner changes do
	// not depend on first-root insertion behavior.
	if _, e := s.RefreshGirls(ctx, a, op()); e != nil {
		t.Fatal(e)
	}
	entered, done := make(chan struct{}), make(chan struct{})
	wrapper := &rankingInterleavedMetrics{Inner: s.Metrics, AfterFirst: func() {
		close(entered)
		select {
		case <-done:
		case <-time.After(10 * time.Second):
			t.Error("real acquisition interleave timeout")
		}
	}}
	s.Metrics = wrapper
	go func() {
		defer close(done)
		<-entered
		rankingSummon(t, p, a, rev, 10001002)
		rankingSummon(t, p, b, rev, 10001002)
	}()

	snap, e := s.RefreshGirls(ctx, a, op())
	value := int64(-1)
	if e != nil {
		if !errors.Is(e, ca.ErrInvalidCoherentReadScope) && !errors.Is(e, d.ErrStale) {
			t.Fatal("unexpected concurrent error", e)
		}
		if rankingCount(t, p, server, "ranking_girls_snapshots") != 1 {
			t.Fatal("failed attempt published partial snapshot")
		}
	} else {
		if len(snap.Entries) != 2 || snap.Entries[0].Metric.Value != snap.Entries[1].Metric.Value {
			t.Fatal("mixed before/after roster population", snap)
		}
		value = snap.Entries[0].Metric.Value
		if value != 1 && value != 2 {
			t.Fatal("invented population", value)
		}
	}
	t.Log("interleaved result", value, "error", e, "metric caller attempts", wrapper.Attempts)
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("owner command not completed")
	}
	next, e := rankingService(p, p).RefreshGirls(ctx, a, op())
	if e != nil {
		t.Fatal(e)
	}
	if next.Entries[0].Metric.Value != 2 || next.Entries[1].Metric.Value != 2 {
		t.Fatal("next request did not observe real acquisitions", next)
	}
	t.Log("ACTUAL_PG_SERIALIZABLE_METRIC_INTERLEAVE real Hero commands committed between participants; consistent published population or safe refusal; new operation sees both", value)
}
