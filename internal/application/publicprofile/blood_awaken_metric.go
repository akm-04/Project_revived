package publicprofile

import (
	"context"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// I9_12_PRIVATE_BLOOD_AWAKEN_COUNT_V1 (private): field 1013 counts the current
// owned heroes whose raw awakening reached xyd.AwakeTwiceStage.COMPLETE. It sits
// outside ReadMetricsScopeTx because public-profile show IDs stop at 1011.
const BloodAwakenMetricPolicy = "I9_12_PRIVATE_BLOOD_AWAKEN_COUNT_V1"
const BloodAwakenMetricSemantics = "CURRENT_COUNT_OWNED_HEROES_RAW_AWAKENING_COMPLETE_V1"
const BloodAwakenMetricFieldID int64 = 1013
const bloodAwakenMetricMaximum int64 = 9007199254740991

// RawAwakeningReader is CharacterHero's typed raw-awakening facet read port.
type RawAwakeningReader interface {
	ListRawAwakeningsTx(context.Context, tx.Queryer, identity.PlayerID, []int64) (map[int64]character.RawAwakeningBirth, error)
}

// ReadBloodAwakenMetricScopeTx is the ranking board's read port, a sibling of
// the top-five-force metric. Missing legacy facets read as stage 0.
func (p CanonicalMetricProvider) ReadBloodAwakenMetricScopeTx(c context.Context, sc tx.Scope, r MetricRequest) (MetricObservation, error) {
	coherent, e := ca.NewCoherentReadScope(sc, r.ContentRevision, r.ObservedAt)
	if e != nil || p.Roster == nil || p.Awakenings == nil || !r.PlayerID.Valid() {
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
	partners := make([]int64, 0, len(population.Rows))
	for _, row := range population.Rows {
		partners = append(partners, row.InstanceID)
	}
	births, e := p.Awakenings.ListRawAwakeningsTx(c, sc.Tx, r.PlayerID, partners)
	if e != nil {
		return MetricObservation{}, e
	}
	count := int64(0)
	for _, partner := range partners {
		birth, found := births[partner]
		if !found {
			continue
		}
		if birth.Ref.PlayerID != r.PlayerID || birth.Ref.PartnerID != partner || birth.Validate() != nil {
			return MetricObservation{}, ErrContent
		}
		if birth.RawStage != character.RawAwakeningCompleteStage {
			continue
		}
		if count >= bloodAwakenMetricMaximum {
			return MetricObservation{}, ErrContent
		}
		count++
	}
	return MetricObservation{Owner: "CharacterHero", PlayerID: r.PlayerID, FieldID: BloodAwakenMetricFieldID, Value: count, Semantics: BloodAwakenMetricSemantics, SourceVersion: population.RootVersion, PopulationVersion: population.RootVersion, PopulationDigest: population.Digest(), PrivatePolicy: BloodAwakenMetricPolicy, ContentRevision: r.ContentRevision, ObservedAt: coherent.ObservedAt}, nil
}
