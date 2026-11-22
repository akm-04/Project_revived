package publicprofile

import (
	"context"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/heroforce"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// I9_10E_PRIVATE_TOP_FIVE_FORCE_V1 (private): field 1012 is the sum of the
// five strongest current heroes' qualified public force in the owner's Self
// view, as stock row 2002 "Total AP of top 5 BGs" describes.
const TopForceMetricPolicy = "I9_10E_PRIVATE_TOP_FIVE_FORCE_V1"
const TopForceMetricSemantics = "CURRENT_SUM_TOP_FIVE_OWNED_HERO_PUBLIC_FORCE_SELF_V1"
const TopForceMetricCount = 5

// ReadTopForceMetricScopeTx is the ranking board's read port. It stays outside
// ReadMetricsScopeTx because public-profile show IDs stop at 1011.
func (p CanonicalMetricProvider) ReadTopForceMetricScopeTx(c context.Context, sc tx.Scope, r MetricRequest) (MetricObservation, error) {
	coherent, e := ca.NewCoherentReadScope(sc, r.ContentRevision, r.ObservedAt)
	if e != nil || p.Roster == nil || p.Force == nil || !r.PlayerID.Valid() {
		return MetricObservation{}, ErrContent
	}
	pin, ok := sc.Operation.Policies.Get("content")
	if !ok || pin != r.ContentRevision {
		return MetricObservation{}, ErrContent
	}
	population, e := p.Roster.ReadRosterMetricsTx(c, coherent, r.PlayerID, "Hero")
	if e != nil {
		return MetricObservation{}, e
	}
	if population.PlayerID != r.PlayerID || population.Revision != r.ContentRevision || !population.ObservedAt.Equal(coherent.ObservedAt) || population.RootVersion <= 0 {
		return MetricObservation{}, ErrContent
	}
	timed, e := gen.NewTimedOperation(sc.Operation, coherent.ObservedAt)
	if e != nil {
		return MetricObservation{}, ErrContent
	}
	partners := make([]int64, 0, len(population.Rows))
	for _, row := range population.Rows {
		partners = append(partners, row.InstanceID)
	}
	value, e := heroforce.Best(c, TopForceMetricCount, gen.TimedScope{Tx: sc.Tx, Operation: timed, Attempt: sc.Attempt, Options: sc.Options}, p.Force, r.PlayerID, r.ContentRevision, coherent.ObservedAt, partners)
	if e != nil {
		return MetricObservation{}, e
	}
	return MetricObservation{Owner: "CharacterHero", PlayerID: r.PlayerID, FieldID: 1012, Value: value, Semantics: TopForceMetricSemantics, SourceVersion: population.RootVersion, PopulationVersion: population.RootVersion, PopulationDigest: population.Digest(), PrivatePolicy: TopForceMetricPolicy, ContentRevision: r.ContentRevision, ObservedAt: coherent.ObservedAt}, nil
}
