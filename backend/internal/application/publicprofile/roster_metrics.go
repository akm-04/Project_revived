package publicprofile

import (
	"context"
	"encoding/hex"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
)

// Retain this version when later policies are introduced: historical receipts
// must continue to validate against the rule that produced them.
const RosterMetricPolicy = "C4C_PRIVATE_CURRENT_ROSTER_V1"
const RosterMetricSemantics = "CURRENT_DISTINCT_ORIGIN_HERO_PET_STARS_BEFORE_AWAKEN_V1"

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
		origins, instances := map[int64]bool{}, map[int64]bool{}
		var count, stars, awaken int64
		for _, row := range pop.Rows {
			maxStar := int64(character.MaxHeroStar)
			if family == "Pet" {
				maxStar = character.MaxPetStar
			}
			if row.InstanceID <= 0 || row.OriginTableID <= 0 || row.TableID <= 0 || row.Version <= 0 || row.Star < 1 || row.Star > maxStar || row.BeforeAwaken < 0 || (family == "Pet" && row.BeforeAwaken != 0) || origins[row.OriginTableID] || instances[row.InstanceID] {
				return nil, ErrContent
			}
			origins[row.OriginTableID] = true
			instances[row.InstanceID] = true
			if count >= 9007199254740991 || stars > 9007199254740991-row.Star {
				return nil, ErrContent
			}
			count++
			stars += row.Star
			if row.BeforeAwaken > 0 {
				awaken++
			}
		}
		values := map[int64]int64{1001: count, 1008: stars, 1009: awaken}
		if family == "Pet" {
			values = map[int64]int64{1002: count}
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
