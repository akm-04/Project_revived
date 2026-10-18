package achievement

import (
	"encoding/hex"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"time"
)

const Policy = "C4B_MARRIED_POPULATION_TIER_FACTS_V1"
const SelectedID int64 = 100014

var ErrUnavailable = errors.New("achievement: unavailable history or producer")
var ErrConflict = errors.New("achievement: conflicting fact or coherent scope")

func RevisionValid(s string) bool {
	b, e := hex.DecodeString(s)
	return e == nil && len(b) == 32 && hex.EncodeToString(b) == s
}

type Root struct {
	PlayerID             identity.PlayerID
	ContentRevision      string
	PolicyID             string
	Progress             int64
	CompleteTimes        [3]*time.Time
	StateVersion         int64
	CreatedAt, UpdatedAt time.Time
}

func NewRoot(pid identity.PlayerID, rev string, at time.Time) (Root, error) {
	r := Root{PlayerID: pid, ContentRevision: rev, PolicyID: Policy, StateVersion: 1, CreatedAt: at.UTC(), UpdatedAt: at.UTC()}
	return r, r.Validate()
}
func (r Root) Validate() error {
	if !r.PlayerID.Valid() || !RevisionValid(r.ContentRevision) || r.PolicyID != Policy || r.Progress < 0 || r.Progress > 9007199254740991 || r.StateVersion < 1 || r.CreatedAt.Unix() <= 0 || r.UpdatedAt.Before(r.CreatedAt) {
		return ErrConflict
	}
	for i, n := range [3]int64{1, 10, 20} {
		t := r.CompleteTimes[i]
		if (t != nil) != (r.Progress >= n) {
			return ErrConflict
		}
		if t != nil && (t.Unix() <= 0 || t.Before(r.CreatedAt) || t.After(r.UpdatedAt) || i > 0 && r.CompleteTimes[i-1].After(*t)) {
			return ErrConflict
		}
	}
	return nil
}

// ObservePopulation reuses I5's pure objective reducer; Achievement remains the
// sole persistence owner. No I5 stock-family rows or award claims are created.
func (r Root) ObservePopulation(c Catalog, n int64, at time.Time) (Root, bool, error) {
	if r.Validate() != nil || c.Validate() != nil || n < 1 || n > 9007199254740991 || at.Before(r.UpdatedAt) {
		return Root{}, false, ErrConflict
	}
	old := r.Progress
	times := r.CompleteTimes
	for j, target := range c.Rows[13].Thresholds {
		inst := objective.Instance{PlayerID: r.PlayerID, ProgramID: Policy, ObjectiveID: int64(j + 1), DefinitionRevision: Policy, ContentRevision: r.ContentRevision, Progress: r.Progress, CompletedAt: times[j], ClaimState: objective.Unclaimed, StateVersion: r.StateVersion}
		def := objective.Definition{ProgramID: Policy, ObjectiveID: int64(j + 1), DefinitionRevision: Policy, Strategy: objective.HighWaterFromCanonicalState, AcceptedFactKind: "MARRIED_HERO_POPULATION", Target: target}
		fact := objective.Fact{PlayerID: r.PlayerID, SourceDomain: "Library", SourceBusinessKey: "validated-prepared-source-transition", Kind: def.AcceptedFactKind, Value: n}
		v, _, e := objective.ApplyFact(inst, def, fact, at)
		if e != nil {
			return Root{}, false, e
		}
		r.CompleteTimes[j] = v.CompletedAt
	}
	if n > old {
		r.Progress = n
		r.StateVersion++
		r.UpdatedAt = at.UTC()
	}
	return r, n > old, r.Validate()
}

type Definition struct {
	ID         int64    `json:"id"`
	Thresholds [3]int64 `json:"thresholds"`
	Points     [3]int64 `json:"points"`
	Daily      int      `json:"daily"`
	Hidden     int      `json:"hidden"`
	Stamp      int      `json:"stamp"`
}
type Catalog struct {
	SchemaVersion int          `json:"schema_version"`
	PolicyID      string       `json:"policy_id"`
	SelectedID    int64        `json:"selected_id"`
	Rows          []Definition `json:"rows"`
}

func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != "C4B_MARRIED_POPULATION_TIER_FACTS_V1" || c.SelectedID != 100014 || len(c.Rows) != 33 {
		return errors.New("achievement catalog profile")
	}
	for i, r := range c.Rows {
		if r.ID != 100001+int64(i) || r.Daily < 0 || r.Daily > 1 || r.Hidden < 0 || r.Hidden > 1 || r.Stamp < 0 || r.Stamp > 1 {
			return errors.New("achievement source row")
		}
		for j, v := range r.Thresholds {
			if v < 1 || j > 0 && v <= r.Thresholds[j-1] || r.Points[j] <= 0 {
				return errors.New("achievement tier")
			}
		}
	}
	if c.Rows[13].Thresholds != [3]int64{1, 10, 20} || c.Rows[13].Daily != 0 {
		return errors.New("achievement selected profile")
	}
	return nil
}
