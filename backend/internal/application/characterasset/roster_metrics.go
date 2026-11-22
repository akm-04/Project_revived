package characterasset

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"sort"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

// RosterMetricRow exposes identity and progression facts only. It deliberately
// carries no equipment, skin entitlement, cached force or display eligibility.
type RosterMetricRow struct {
	InstanceID, OriginTableID, TableID, Star, Version int64
	BeforeAwaken                                      int64
}
type RosterMetricPopulation struct {
	PlayerID    identity.PlayerID
	Family      string
	Revision    string
	ObservedAt  time.Time
	RootVersion int64
	Rows        []RosterMetricRow
}
type RosterMetricReader interface {
	ReadRosterMetricsTx(context.Context, CoherentReadScope, identity.PlayerID, string) (RosterMetricPopulation, error)
}

// Digest includes records as well as the root: evolving a girl need not change
// the root allocator version. Sorting makes the witness independent of SQL order.
func (p RosterMetricPopulation) Digest() string {
	rows := append([]RosterMetricRow{}, p.Rows...)
	sort.Slice(rows, func(i, j int) bool { return rows[i].InstanceID < rows[j].InstanceID })
	b, _ := json.Marshal(struct {
		Player           identity.PlayerID
		Family, Revision string
		Root             int64
		Rows             []RosterMetricRow
	}{p.PlayerID, p.Family, p.Revision, p.RootVersion, rows})
	d := sha256.Sum256(b)
	return hex.EncodeToString(d[:])
}

const RosterMetricPolicy = "C4C_PRIVATE_CURRENT_ROSTER_V1"
const RosterMetricSemantics = "CURRENT_DISTINCT_ORIGIN_HERO_PET_STARS_BEFORE_AWAKEN_V1"
const maxRosterMetricInteger int64 = 9007199254740991

var ErrInvalidRosterPopulation = errors.New("character: invalid current roster population")

type RosterMetricSummary struct {
	OwnedCount    int64
	StarCount     int64
	AwakenedCount int64
}

// Summary validates rows; callers still qualify the coherent scope and population witness.
func (population RosterMetricPopulation) Summary() (RosterMetricSummary, error) {
	var summary RosterMetricSummary
	maximumStar := int64(character.MaxHeroStar)
	if population.Family == "Pet" {
		maximumStar = character.MaxPetStar
	} else if population.Family != "Hero" {
		return summary, ErrInvalidRosterPopulation
	}
	origins, instances := map[int64]bool{}, map[int64]bool{}
	for _, row := range population.Rows {
		if row.InstanceID <= 0 || row.OriginTableID <= 0 || row.TableID <= 0 || row.Version <= 0 || row.Star < 1 || row.Star > maximumStar || row.BeforeAwaken < 0 || (population.Family == "Pet" && row.BeforeAwaken != 0) || origins[row.OriginTableID] || instances[row.InstanceID] {
			return RosterMetricSummary{}, ErrInvalidRosterPopulation
		}
		origins[row.OriginTableID] = true
		instances[row.InstanceID] = true
		if summary.OwnedCount >= maxRosterMetricInteger || summary.StarCount > maxRosterMetricInteger-row.Star {
			return RosterMetricSummary{}, ErrInvalidRosterPopulation
		}
		summary.OwnedCount++
		summary.StarCount += row.Star
		if row.BeforeAwaken > 0 {
			summary.AwakenedCount++
		}
	}
	return summary, nil
}
