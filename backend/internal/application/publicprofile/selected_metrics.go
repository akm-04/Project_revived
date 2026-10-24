package publicprofile

import (
	"context"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	d "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const MarriageMetricSemantics = "I7C_METRIC_CURRENT_CANONICAL_LIBRARY_MARRIED_HERO_POPULATION_V1"

// ScopedMetricReader extends the existing component port without granting an
// arbitrary Queryer enough authority to read a multi-owner population.
type ScopedMetricReader interface {
	ReadMetricsScopeTx(context.Context, tx.Scope, MetricRequest) ([]MetricObservation, error)
}
type MarriedPopulationReader interface {
	MarriedHeroCountTx(context.Context, tx.Queryer, lib.InputScope) (lib.CollectionInputs, error)
}
type CanonicalMetricProvider struct {
	Creation CanonicalCreationMetricProvider
	Roster   ca.RosterMetricReader
	Library  MarriedPopulationReader
	Force    ForceReader
	Display  DisplayCounts
	Trophies TrophyCounts
}

// Unscoped consumers retain only the historically qualified creation metric.
func (p CanonicalMetricProvider) ReadMetricsTx(c context.Context, q tx.Queryer, r MetricRequest) ([]MetricObservation, error) {
	return p.Creation.ReadMetricsTx(c, q, r)
}
func readMetricsScopeTx(c context.Context, p MetricReader, sc tx.Scope, r MetricRequest) ([]MetricObservation, error) {
	if p == nil {
		return nil, ErrContent
	}
	if scoped, ok := p.(ScopedMetricReader); ok {
		return scoped.ReadMetricsScopeTx(c, sc, r)
	}
	return p.ReadMetricsTx(c, sc.Tx, r)
}
func (p CanonicalMetricProvider) ReadMetricsScopeTx(c context.Context, sc tx.Scope, r MetricRequest) ([]MetricObservation, error) {
	coherent, e := ca.NewCoherentReadScope(sc, r.ContentRevision, r.ObservedAt)
	pin, ok := sc.Operation.Policies.Get("content")
	if e != nil || !ok || pin != r.ContentRevision || !r.PlayerID.Valid() {
		return nil, ErrContent
	}
	seen := map[int64]bool{}
	for _, id := range r.IDs {
		if seen[id] || id < 1001 || id > 1011 {
			return nil, ErrContent
		}
		seen[id] = true
	}
	out := make([]MetricObservation, 0, len(r.IDs))
	// Read each owner at most once in the caller snapshot. Neither provider opens
	// transactions, samples time, locks mutation roots or persists a second count.
	var married MetricObservation
	if seen[1010] {
		if p.Library == nil {
			return nil, ErrContent
		}
		v, e := p.Library.MarriedHeroCountTx(c, coherent.Queryer(), lib.InputScope{Player: r.PlayerID, ContentRevision: r.ContentRevision, ObservedAt: r.ObservedAt})
		if e != nil {
			return nil, e
		}
		if v.Player != r.PlayerID || v.ContentRevision != r.ContentRevision || !v.ObservedAt.Equal(r.ObservedAt) || v.MarriedCount < 0 || v.MarriedCount > 9007199254740991 || v.PopulationVersion <= 0 || v.LibraryRootVersion <= 0 || !d.ValidRevision(v.ContentRevision) {
			return nil, ErrContent
		}
		married = MetricObservation{Owner: "Library", PlayerID: r.PlayerID, FieldID: 1010, Value: v.MarriedCount, Semantics: MarriageMetricSemantics, SourceVersion: v.LibraryRootVersion, PopulationVersion: v.PopulationVersion, LibraryRootVersion: v.LibraryRootVersion, ContentRevision: r.ContentRevision, ObservedAt: r.ObservedAt.UTC()}
	}
	var created MetricObservation
	if seen[1011] {
		q := r
		q.IDs = []int64{1011}
		values, e := p.Creation.ReadMetricsTx(c, sc.Tx, q)
		if e != nil {
			return nil, e
		}
		if len(values) != 1 {
			return nil, ErrContent
		}
		created = values[0]
	}
	roster := map[int64]MetricObservation{}
	if seen[1001] || seen[1002] || seen[1008] || seen[1009] {
		roster, e = p.rosterMetrics(c, coherent, r, seen[1001] || seen[1008] || seen[1009], seen[1002])
		if e != nil {
			return nil, e
		}
	}
	var force MetricObservation
	if seen[1007] {
		if force, e = p.forceMetric(c, coherent, r); e != nil {
			return nil, e
		}
	}
	for _, id := range r.IDs {
		if isCosmeticMetric(id) {
			v, e := p.cosmeticMetric(c, coherent, r, id)
			if e != nil {
				return nil, e
			}
			out = append(out, v)
		} else if id == 1004 {
			v, e := p.trophyMetric(c, coherent, r)
			if e != nil {
				return nil, e
			}
			out = append(out, v)
		} else if isRosterMetric(id) {
			out = append(out, roster[id])
		} else if id == 1007 {
			out = append(out, force)
		} else if id == 1010 {
			out = append(out, married)
		} else {
			out = append(out, created)
		}
	}
	return out, nil
}
func validMetricBasis(v MetricObservation) bool {
	if isCosmeticMetric(v.FieldID) || v.FieldID == 1004 {
		return validCosmeticBasis(v)
	}
	if v.FieldID == 1007 {
		return v.Owner == "CharacterHero" && v.PrivatePolicy == ForceMetricPolicy && v.Semantics == ForceMetricSemantics && validRosterDigest(v.PopulationDigest) && v.Value >= 0 && v.PopulationVersion > 0 && v.SourceVersion == v.PopulationVersion && v.PetRootVersion == 0 && v.LibraryRootVersion == 0
	}
	if isRosterMetric(v.FieldID) {
		if v.PrivatePolicy != RosterMetricPolicy || v.Semantics != RosterMetricSemantics || !validRosterDigest(v.PopulationDigest) || v.LibraryRootVersion != 0 || v.Value < 0 {
			return false
		}
		if v.FieldID == 1002 {
			return v.Owner == "CharacterPet" && v.PopulationVersion == 0 && v.PetRootVersion > 0 && v.SourceVersion == v.PetRootVersion
		}
		return v.Owner == "CharacterHero" && v.PetRootVersion == 0 && v.PopulationVersion > 0 && v.SourceVersion == v.PopulationVersion
	}
	if v.PrivatePolicy != "" || v.PopulationDigest != "" || v.PetRootVersion != 0 {
		return false
	}
	switch v.FieldID {
	case 1011:
		return v.Owner == "I5.Player" && v.Semantics == CreationMetricSemantics && v.PopulationVersion == 0 && v.LibraryRootVersion == 0
	case 1010:
		return v.Owner == "Library" && v.Semantics == MarriageMetricSemantics && v.Value >= 0 && v.PopulationVersion > 0 && v.LibraryRootVersion > 0 && v.SourceVersion == v.LibraryRootVersion
	}
	return false
}
