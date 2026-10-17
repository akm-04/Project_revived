// Package privilege holds Commerce-owned qualifying charge facts. Manual
// preservation provenance is explicit and never means provider payment verified.
package privilege

import (
	"encoding/hex"
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"strings"
	"time"
)

const CatalogPolicy = "C4A_SRC64_VIP_THRESHOLDS_V1"
const ManualPolicy = "C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1"
const ManualClass = "MANUAL_PRESERVATION"
const MonthlyAbsent = "QUALIFIED_ABSENT"
const ManualCapability = "commerce.entitlement.manual_preservation"

var ErrUnavailable = errors.New("canonical privilege unavailable")
var ErrConflict = errors.New("canonical privilege conflict")

type Threshold struct {
	Level    int64 `json:"level"`
	Charge   int64 `json:"charge"`
	SkillCap int64 `json:"skill_cap"`
}
type Catalog struct {
	SchemaVersion int         `json:"schema_version"`
	PolicyID      string      `json:"policy_id"`
	Rows          []Threshold `json:"rows"`
}

func (c Catalog) Validate() error {
	if c.SchemaVersion != 1 || c.PolicyID != CatalogPolicy || len(c.Rows) != 16 {
		return ErrUnavailable
	}
	for i, r := range c.Rows {
		if r.Level != int64(i) || r.Charge < 0 || r.SkillCap < 0 || i > 0 && r.Charge <= c.Rows[i-1].Charge {
			return ErrUnavailable
		}
	}
	if c.Rows[0].Charge != 0 || c.Rows[0].SkillCap != 10 {
		return ErrUnavailable
	}
	return nil
}
func (c Catalog) Derive(charge int64) (int64, error) {
	if c.Validate() != nil || charge < 0 || charge > 9007199254740991 {
		return 0, ErrUnavailable
	}
	var level int64
	for _, r := range c.Rows {
		if charge < r.Charge {
			break
		}
		level = r.Level
	}
	return level, nil
}
func (c Catalog) SkillCap(level int64) (int64, error) {
	if c.Validate() != nil || level < 0 || level > 15 {
		return 0, ErrUnavailable
	}
	return c.Rows[level].SkillCap, nil
}
func RevisionValid(s string) bool {
	if len(s) != 64 {
		return false
	}
	_, e := hex.DecodeString(s)
	return e == nil && strings.ToLower(s) == s
}

type State struct {
	PlayerID        identity.PlayerID        `json:"player_id"`
	LogicalServerID identity.LogicalServerID `json:"logical_server_id"`
	Charge          int64                    `json:"charge"`
	VIPLevel        int64                    `json:"vip_level"`
	MonthlyState    string                   `json:"monthly_state"`
	ContentRevision string                   `json:"content_revision"`
	PolicyVersion   string                   `json:"policy_version"`
	OriginClass     string                   `json:"origin_class"`
	Issuer          string                   `json:"issuer"`
	Reason          string                   `json:"reason"`
	StateVersion    int64                    `json:"state_version"`
	CreatedAt       time.Time                `json:"created_at"`
	UpdatedAt       time.Time                `json:"updated_at"`
}

func (s State) Validate() error {
	if !s.PlayerID.Valid() || !s.LogicalServerID.Valid() || s.Charge < 0 || s.Charge > 9007199254740991 || s.VIPLevel < 0 || s.VIPLevel > 15 || s.MonthlyState != MonthlyAbsent || !RevisionValid(s.ContentRevision) || s.PolicyVersion != ManualPolicy || s.OriginClass != ManualClass || strings.TrimSpace(s.Issuer) == "" || strings.TrimSpace(s.Reason) == "" || s.StateVersion < 1 || s.CreatedAt.IsZero() || s.UpdatedAt.Before(s.CreatedAt) {
		return ErrConflict
	}
	return nil
}
func (s State) ValidateCatalog(c Catalog) error {
	if s.Validate() != nil {
		return ErrConflict
	}
	level, e := c.Derive(s.Charge)
	if e != nil || level != s.VIPLevel {
		return ErrConflict
	}
	return nil
}

// Snapshot pins both observation content and the canonical settlement's original
// content. A new active revision cannot silently reinterpret old VIP facts.
type Snapshot struct {
	State               State
	ObservationRevision string
	ObservedAt          time.Time
	SkillPointCap       int64
	ProviderRevision    string
}

func (s Snapshot) Validate(pid identity.PlayerID, revision string, at time.Time) error {
	if s.State.Validate() != nil || s.State.PlayerID != pid || s.ObservationRevision != revision || !RevisionValid(revision) || at.IsZero() || !s.ObservedAt.Equal(at) || s.State.UpdatedAt.After(at) || s.SkillPointCap < 0 || s.ProviderRevision != ManualPolicy+"/"+s.State.ContentRevision {
		return ErrUnavailable
	}
	return nil
}
