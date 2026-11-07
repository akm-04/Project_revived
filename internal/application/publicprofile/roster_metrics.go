package publicprofile

import (
	"context"
	"encoding/hex"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

// Retain this version when later policies are introduced: historical receipts
// must continue to validate against the rule that produced them.
const RosterMetricPolicy = ca.RosterMetricPolicy
const RosterMetricSemantics = ca.RosterMetricSemantics

func isRosterMetric(id int64) bool { return id == 1001 || id == 1002 || id == 1008 || id == 1009 }
func bindRosterPolicy(o operation.Context) (operation.Context, error) {
	if v, ok := o.Policies.Get("roster-metrics"); ok {
		if v != RosterMetricPolicy {
			return o, ErrConflict
		}
		return o, nil
	}
	refs := append(o.Policies.Refs(), policy.Ref{Name: "roster-metrics", Version: RosterMetricPolicy})
	var e error
	o.Policies, e = policy.NewSet(refs...)
	return o, e
}
func validRosterDigest(s string) bool {
	b, e := hex.DecodeString(s)
	return e == nil && len(b) == 32 && hex.EncodeToString(b) == s
}
func (p CanonicalMetricProvider) rosterMetrics(c context.Context, sc ca.CoherentReadScope, r MetricRequest, hero, pet bool) (map[int64]MetricObservation, error) {
	out := map[int64]MetricObservation{}
	pin, ok := sc.Operation.Policies.Get("roster-metrics")
	if p.Roster == nil || !ok || pin != RosterMetricPolicy {
		return nil, ErrContent
	}
	for _, family := range []string{"Hero", "Pet"} {
		if (family == "Hero" && !hero) || (family == "Pet" && !pet) {
			continue
		}
		pop, e := p.Roster.ReadRosterMetricsTx(c, sc, r.PlayerID, family)
		if e != nil {
			return nil, e
		}
		if pop.PlayerID != r.PlayerID || pop.Family != family || pop.Revision != r.ContentRevision || !pop.ObservedAt.Equal(r.ObservedAt) || pop.RootVersion <= 0 {
			return nil, ErrContent
		}
		summary, err := pop.Summary()
		if err != nil {
			return nil, ErrContent
		}
		values := map[int64]int64{1001: summary.OwnedCount, 1008: summary.StarCount, 1009: summary.AwakenedCount}
		if family == "Pet" {
			values = map[int64]int64{1002: summary.OwnedCount}
		}
		for id, value := range values {
			v := MetricObservation{Owner: "Character" + family, PlayerID: r.PlayerID, FieldID: id, Value: value, Semantics: RosterMetricSemantics, SourceVersion: pop.RootVersion, PopulationDigest: pop.Digest(), PrivatePolicy: RosterMetricPolicy, ContentRevision: r.ContentRevision, ObservedAt: r.ObservedAt.UTC()}
			if family == "Hero" {
				v.PopulationVersion = pop.RootVersion
			} else {
				v.PetRootVersion = pop.RootVersion
			}
			out[id] = v
		}
	}
	return out, nil
}
