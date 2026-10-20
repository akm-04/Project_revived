package publicprofile

import (
	"context"

	"gxb.local/backend/v2/internal/application/achievement"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
)

const CosmeticMetricSemantics = "CURRENT_SKIN_FRAME_AVATAR_COLLECTION_V1"
const TrophyMetricSemantics = "RECORDED_ACHIEVEMENT_TIERS_V1"

type DisplayCounts interface {
	SkinCollectionTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (display.CosmeticCount, error)
	CosmeticCountTx(context.Context, ca.CoherentReadScope, identity.PlayerID, string) (display.CosmeticCount, error)
}
type TrophyCounts interface {
	TrophyCountTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (achievement.TrophyCount, error)
}

func isCosmeticMetric(id int64) bool { return id == 1003 || id == 1005 || id == 1006 }

func (p CanonicalMetricProvider) cosmeticMetric(c context.Context, sc ca.CoherentReadScope, r MetricRequest, id int64) (MetricObservation, error) {
	if p.Display == nil {
		return MetricObservation{}, ErrContent
	}
	var v display.CosmeticCount
	var e error
	switch id {
	case 1003:
		v, e = p.Display.SkinCollectionTx(c, sc, r.PlayerID)
	case 1005:
		v, e = p.Display.CosmeticCountTx(c, sc, r.PlayerID, "frame")
	default:
		v, e = p.Display.CosmeticCountTx(c, sc, r.PlayerID, "avatar")
	}
	if e != nil {
		return MetricObservation{}, e
	}
	return MetricObservation{Owner: "PlayerDisplay", PlayerID: r.PlayerID, FieldID: id, Value: v.Value, Semantics: CosmeticMetricSemantics, SourceVersion: v.SourceVersion, PopulationVersion: v.SourceVersion, PopulationDigest: v.PopulationDigest, PrivatePolicy: v.Policy, ContentRevision: r.ContentRevision, ObservedAt: r.ObservedAt.UTC()}, nil
}

func (p CanonicalMetricProvider) trophyMetric(c context.Context, sc ca.CoherentReadScope, r MetricRequest) (MetricObservation, error) {
	if p.Trophies == nil {
		return MetricObservation{}, ErrContent
	}
	v, e := p.Trophies.TrophyCountTx(c, sc, r.PlayerID)
	if e != nil {
		return MetricObservation{}, e
	}
	return MetricObservation{Owner: "Achievement", PlayerID: r.PlayerID, FieldID: 1004, Value: v.Value, Semantics: TrophyMetricSemantics, SourceVersion: v.RootVersion, PopulationVersion: v.RootVersion, PopulationDigest: v.TiersDigest, PrivatePolicy: achievement.TrophyCountPolicy, ContentRevision: r.ContentRevision, ObservedAt: r.ObservedAt.UTC()}, nil
}

func validCosmeticBasis(v MetricObservation) bool {
	if v.Value < 0 || v.SourceVersion != v.PopulationVersion || !validRosterDigest(v.PopulationDigest) || v.PetRootVersion != 0 || v.LibraryRootVersion != 0 {
		return false
	}
	switch v.FieldID {
	case 1003:
		return v.Owner == "PlayerDisplay" && v.Semantics == CosmeticMetricSemantics && v.PrivatePolicy == display.SkinCollectionPolicy && v.PopulationVersion > 0
	case 1005, 1006:
		return v.Owner == "PlayerDisplay" && v.Semantics == CosmeticMetricSemantics && v.PrivatePolicy == display.CosmeticCountPolicy && v.PopulationVersion > 0
	case 1004:
		unobserved := v.PopulationVersion == 0 && v.Value == 0
		return v.Owner == "Achievement" && v.Semantics == TrophyMetricSemantics && v.PrivatePolicy == achievement.TrophyCountPolicy && (v.PopulationVersion > 0 || unobserved)
	}
	return false
}
