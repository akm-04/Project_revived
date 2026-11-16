// Package playerdata is the I11A operator capability that exports one player's
// rows. The plan it consumes is generated and reviewed by tools/player_restore_plan.py.
package playerdata

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
)

const PlanFormat = 1

const (
	ActionRestore = "restore"
	ActionKeep    = "keep"
	ActionSkip    = "skip"
)

// PlayersTable is the plan member that supplies the exported header's logical server.
const PlayersTable = "players"

// MediaHistoryTable is the only player table whose rows reference profile media blobs.
const MediaHistoryTable = "player_public_profile_media_history"

var (
	ErrInvalidPlan    = errors.New("invalid player restore plan")
	ErrPlayerNotFound = errors.New("player not found")
)

type Plan struct {
	Authority     string      `json:"authority"`
	SchemaVersion int         `json:"schema_version"`
	Tables        []PlanTable `json:"tables"`
}

type PlanTable struct {
	Table     string             `json:"table"`
	Action    string             `json:"action"`
	Select    string             `json:"select"`
	Versioned Versioned          `json:"versioned"`
	Inbound   []InboundReference `json:"inbound"`
}

// InboundReference is a foreign key from a row the restore does not delete
// (another owner's or a kept table's row) to this table's rows.
type InboundReference struct {
	Constraint string   `json:"constraint"`
	Table      string   `json:"table"`
	Columns    []string `json:"columns"`
	References []string `json:"references"`
}

type Versioned struct {
	StateVersion bool `json:"state_version"`
	UpdatedAt    bool `json:"updated_at"`
}

// LoadPlan validates the generated plan and returns the sha256 of its file bytes,
// which the export header pins and the restore compares.
func LoadPlan(path string) (Plan, string, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return Plan{}, "", err
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	var plan Plan
	if err := decoder.Decode(&plan); err != nil {
		return Plan{}, "", fmt.Errorf("%w: %v", ErrInvalidPlan, err)
	}
	if err := decoder.Decode(new(any)); !errors.Is(err, io.EOF) {
		return Plan{}, "", fmt.Errorf("%w: trailing data", ErrInvalidPlan)
	}
	if err := plan.Validate(); err != nil {
		return Plan{}, "", err
	}
	digest := sha256.Sum256(raw)
	return plan, hex.EncodeToString(digest[:]), nil
}

func (plan Plan) Validate() error {
	if plan.SchemaVersion != PlanFormat {
		return fmt.Errorf("%w: unsupported schema version %d", ErrInvalidPlan, plan.SchemaVersion)
	}
	if len(plan.Tables) == 0 {
		return fmt.Errorf("%w: no tables", ErrInvalidPlan)
	}
	seen := make(map[string]bool, len(plan.Tables))
	hasPlayers := false
	for _, table := range plan.Tables {
		if table.Table == "" || seen[table.Table] {
			return fmt.Errorf("%w: missing or duplicate table %q", ErrInvalidPlan, table.Table)
		}
		seen[table.Table] = true
		switch table.Action {
		case ActionRestore, ActionKeep, ActionSkip:
		default:
			return fmt.Errorf("%w: table %s has action %q", ErrInvalidPlan, table.Table, table.Action)
		}
		if strings.TrimSpace(table.Select) == "" {
			return fmt.Errorf("%w: table %s has no select", ErrInvalidPlan, table.Table)
		}
		for _, inbound := range table.Inbound {
			if inbound.Table == "" || len(inbound.Columns) == 0 || len(inbound.Columns) != len(inbound.References) {
				return fmt.Errorf("%w: table %s has a malformed inbound key", ErrInvalidPlan, table.Table)
			}
		}
		if table.Table != PlayersTable {
			continue
		}
		hasPlayers = true
		if table.Action != ActionRestore {
			return fmt.Errorf("%w: players must be restored, not %q", ErrInvalidPlan, table.Action)
		}
	}
	if !hasPlayers {
		return fmt.Errorf("%w: no players table", ErrInvalidPlan)
	}
	return nil
}
