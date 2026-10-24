package publicprofile

import (
	"context"
	"math"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
)

// C4F_ALL_GIRLS_AP_V1 (private, user Q3): 1007 is the sum over every currently
// owned Hero of the qualified I7C-3B public force in the owner's Self view.
const ForceMetricPolicy = "C4F_ALL_GIRLS_AP_V1"
const ForceMetricSemantics = "CURRENT_SUM_OWNED_HERO_PUBLIC_FORCE_SELF_V1"

type ForceReader interface {
	HeroTx(context.Context, ca.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error)
}

// Any unavailable Hero rejects the observation; it is never zero-filled.
func (p CanonicalMetricProvider) forceMetric(c context.Context, sc ca.CoherentReadScope, r MetricRequest) (MetricObservation, error) {
	if p.Roster == nil || p.Force == nil {
		return MetricObservation{}, ErrContent
	}
	pop, e := p.Roster.ReadRosterMetricsTx(c, sc, r.PlayerID, "Hero")
	if e != nil {
		return MetricObservation{}, e
	}
	if pop.PlayerID != r.PlayerID || pop.Revision != r.ContentRevision || !pop.ObservedAt.Equal(r.ObservedAt) || pop.RootVersion <= 0 {
		return MetricObservation{}, ErrContent
	}
	total := int64(0)
	for _, row := range pop.Rows {
		v, e := p.Force.HeroTx(c, sc, character.HeroRef{PlayerID: r.PlayerID, PartnerID: row.InstanceID}, publicstats.View{Kind: publicstats.Self, Viewer: r.PlayerID})
		if e != nil {
			return MetricObservation{}, e
		}
		force := math.Round(v.Stats.Force)
		if force < 0 || force > 9007199254740991 || total > 9007199254740991-int64(force) {
			return MetricObservation{}, ErrContent
		}
		total += int64(force)
	}
	return MetricObservation{Owner: "CharacterHero", PlayerID: r.PlayerID, FieldID: 1007, Value: total, Semantics: ForceMetricSemantics, SourceVersion: pop.RootVersion, PopulationVersion: pop.RootVersion, PopulationDigest: pop.Digest(), PrivatePolicy: ForceMetricPolicy, ContentRevision: r.ContentRevision, ObservedAt: r.ObservedAt.UTC()}, nil
}
