package ranking

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrUnavailable = errors.New("ranking: unavailable provider or unqualified history")
var ErrConflict = errors.New("ranking: conflicting scope or immutable proof")

// boardReceipt keeps each board's receipt names stable so stored receipts replay.
type boardReceipt struct{ metricPin, settlementClass string }

var boardReceipts = map[string]boardReceipt{
	d.GirlsPolicy:            {metricPin: "roster-metrics", settlementClass: "I7C4C_GIRLS_RANKING_WEEKLY_TITLES"},
	d.AchievementPointPolicy: {metricPin: "force-metric", settlementClass: "I7C4FA_AP_RANKING_WEEKLY_TITLES"},
	d.SkinsPolicy:            {metricPin: "skin-metric", settlementClass: "I7C4FC_SKINS_RANKING_WEEKLY_TITLES"},
	d.DormComfortPolicy:      {metricPin: "comfort-metric", settlementClass: "I9_10C_DORM_COMFORT_RANKING_WEEKLY_TITLES"},
	d.StarCountPolicy:        {metricPin: "roster-metrics", settlementClass: "I9_10D_STAR_COUNT_RANKING_WEEKLY_TITLES"},
	d.AwakenCountPolicy:      {metricPin: "roster-metrics", settlementClass: "I9_10D_AWAKEN_COUNT_RANKING_WEEKLY_TITLES"},
	d.TopForcePolicy:         {metricPin: "top-force-metric", settlementClass: "I9_10E_TOP_FIVE_FORCE_RANKING_WEEKLY_TITLES"},
}

func Profile() tx.Profile {
	return tx.Profile{Name: "I7C4C_GIRLS_RANKING", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 20 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 30 * time.Second}
}

func boardMetricOf(m publicprofile.MetricObservation) d.BoardMetric {
	return d.BoardMetric{Player: m.PlayerID, Owner: m.Owner, Policy: m.PrivatePolicy, Semantics: m.Semantics, Revision: m.ContentRevision, PopulationDigest: m.PopulationDigest, FieldID: m.FieldID, Value: m.Value, SourceVersion: m.SourceVersion, PopulationVersion: m.PopulationVersion, ObservedAt: m.ObservedAt}
}

// boardMetric reads one score from its owner. Zero Player marks a subject with
// no owned fact, which is skipped rather than ranked as an invented zero.
func (s Service) boardMetric(c context.Context, b d.Board, scope tx.Scope, player identity.PlayerID, rev string, at time.Time) (d.BoardMetric, error) {
	if b.Policy == d.TopForcePolicy {
		if s.TopForce == nil {
			return d.BoardMetric{}, ErrUnavailable
		}
		m, e := s.TopForce.ReadTopForceMetricScopeTx(c, scope, publicprofile.MetricRequest{PlayerID: player, IDs: []int64{b.FieldID}, ContentRevision: rev, ObservedAt: at})
		if e != nil {
			return d.BoardMetric{}, e
		}
		return boardMetricOf(m), nil
	}
	if b.Policy != d.DormComfortPolicy {
		ms, e := s.Metrics.ReadMetricsScopeTx(c, scope, publicprofile.MetricRequest{PlayerID: player, IDs: []int64{b.FieldID}, ContentRevision: rev, ObservedAt: at})
		if e != nil {
			return d.BoardMetric{}, e
		}
		if len(ms) != 1 {
			return d.BoardMetric{}, ErrUnavailable
		}
		return boardMetricOf(ms[0]), nil
	}
	if s.Comfort == nil {
		return d.BoardMetric{}, ErrUnavailable
	}
	fact, found, e := s.Comfort.ComfortFactTx(c, scope.Tx, player, rev, at)
	if e != nil {
		return d.BoardMetric{}, e
	}
	if !found {
		return d.BoardMetric{}, nil
	}
	if fact.Validate(at) != nil || fact.Player != player {
		return d.BoardMetric{}, ErrConflict
	}
	return d.BoardMetric{Player: fact.Player, Owner: b.SourceOwner, Policy: b.SourcePolicy, Semantics: b.SourceSemantics, Revision: fact.Revision, PopulationDigest: fact.RoomsDigest, FieldID: b.FieldID, Value: fact.Value, SourceVersion: fact.RootVersion, PopulationVersion: fact.RootVersion, ObservedAt: fact.ObservedAt}, nil
}
func bind(o operation.Context, name, value string) (operation.Context, error) {
	if got, ok := o.Policies.Get(name); ok {
		if got != value {
			return o, ErrConflict
		}
		return o, nil
	}
	refs := append(o.Policies.Refs(), policy.Ref{Name: name, Version: value})
	var e error
	o.Policies, e = policy.NewSet(refs...)
	return o, e
}
func (s Service) bindRefresh(c context.Context, b d.Board, o operation.Context) (operation.Context, string, error) {
	rev, ok := o.Policies.Get("content")
	var e error
	if !ok {
		rev, e = s.Content.ActiveRevision(c, s.Fresh)
		if e != nil {
			return o, "", e
		}
	}
	o, e = bind(o, "content", rev)
	if e != nil {
		return o, "", e
	}
	o, e = bind(o, boardReceipts[b.Policy].metricPin, b.SourcePolicy)
	if e != nil {
		return o, "", e
	}
	o, e = bind(o, "ranking", b.Policy)
	return o, rev, e
}

func strictDecode(raw []byte, out any) error {
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if e := dec.Decode(out); e != nil {
		return e
	}
	var extra any
	if dec.Decode(&extra) != io.EOF {
		return ErrConflict
	}
	return nil
}

// The generic Kernel resolver uses its immutable receipt identity/fingerprint;
// it intentionally treats absence as unresolved. TimedRunner keeps one bound
// decision instant through retries and this positive-proof reconciliation.
type timedReceiptResolver struct{ receipt.Resolver }

func (r timedReceiptResolver) ResolveTimed(c context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	return r.Resolver.Resolve(c, tx.ResolutionRequest{})
}
