package objective

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

type StockFamily int64

const (
	Daily     StockFamily = 1
	GrowMain  StockFamily = 2
	Weekly    StockFamily = 3
	Story     StockFamily = 4
	Awake     StockFamily = 5
	Partner   StockFamily = 6
	Challenge StockFamily = 7
)

type Strategy uint8

const (
	HighWaterFromCanonicalState Strategy = iota + 1
	CommittedDeltaFact
	TemporalEntitlement
	DomainSpecificValidatedFact
)

type Fact struct {
	PlayerID          identity.PlayerID
	SourceDomain      string
	SourceBusinessKey string
	Kind              string
	Delta             int64
	Value             int64
}

func (f Fact) Validate() error {
	if !f.PlayerID.Valid() || strings.TrimSpace(f.SourceDomain) == "" || strings.TrimSpace(f.SourceBusinessKey) == "" || strings.TrimSpace(f.Kind) == "" {
		return errors.New("invalid objective fact")
	}
	return nil
}
func (f Fact) Key() (string, error) {
	if err := f.Validate(); err != nil {
		return "", err
	}
	h := sha256.Sum256([]byte(f.SourceDomain + "\x00" + f.SourceBusinessKey + "\x00" + f.Kind + "\x00" + strconv.FormatInt(int64(f.PlayerID), 10)))
	return hex.EncodeToString(h[:]), nil
}

type Definition struct {
	ProgramID          string
	ObjectiveID        int64
	DefinitionRevision string
	Strategy           Strategy
	AcceptedFactKind   string
	Target             int64
}

func (d Definition) Validate() error {
	if d.ProgramID == "" || d.ObjectiveID <= 0 || d.DefinitionRevision == "" || d.Strategy < HighWaterFromCanonicalState || d.Strategy > DomainSpecificValidatedFact || d.AcceptedFactKind == "" || d.Target <= 0 {
		return errors.New("invalid objective definition")
	}
	return nil
}

type ClaimState uint8

const (
	Unclaimed ClaimState = iota + 1
	Claimed
)

type Instance struct {
	PlayerID           identity.PlayerID
	ProgramID          string
	ObjectiveID        int64
	GenerationID       string
	DefinitionRevision string
	ContentRevision    string
	Progress           int64
	CompletedAt        *time.Time
	ClaimState         ClaimState
	ClaimedAt          *time.Time
	StateVersion       int64
}

func (i Instance) Validate() error {
	if !i.PlayerID.Valid() || i.ProgramID == "" || i.ObjectiveID <= 0 || i.DefinitionRevision == "" || i.Progress < 0 || i.StateVersion <= 0 {
		return errors.New("invalid objective instance")
	}
	if i.ClaimState != Unclaimed && i.ClaimState != Claimed {
		return errors.New("invalid objective claim state")
	}
	if (i.ClaimState == Claimed) != (i.ClaimedAt != nil) {
		return errors.New("objective claimed state/time mismatch")
	}
	return nil
}

// ApplyFact is a pure reducer for one already-deduplicated committed semantic
// fact. Persistence must use a family-specific semantic receipt/fact key so this
// reducer is never invoked twice for the same fact.
func ApplyFact(i Instance, d Definition, f Fact, now time.Time) (Instance, bool, error) {
	if err := i.Validate(); err != nil {
		return Instance{}, false, err
	}
	if err := d.Validate(); err != nil {
		return Instance{}, false, err
	}
	if err := f.Validate(); err != nil {
		return Instance{}, false, err
	}
	if now.IsZero() {
		return Instance{}, false, errors.New("authoritative time required")
	}
	if i.PlayerID != f.PlayerID || i.ProgramID != d.ProgramID || i.ObjectiveID != d.ObjectiveID || i.DefinitionRevision != d.DefinitionRevision {
		return Instance{}, false, errors.New("objective owner/definition mismatch")
	}
	if f.Kind != d.AcceptedFactKind {
		return i, false, nil
	}
	old := i.Progress
	switch d.Strategy {
	case CommittedDeltaFact:
		if f.Delta <= 0 {
			return Instance{}, false, errors.New("delta objective requires positive committed delta")
		}
		i.Progress += f.Delta
	case HighWaterFromCanonicalState:
		if f.Value > i.Progress {
			i.Progress = f.Value
		}
	case TemporalEntitlement, DomainSpecificValidatedFact:
		if f.Value > i.Progress {
			i.Progress = f.Value
		}
	}
	if i.Progress < 0 {
		return Instance{}, false, errors.New("objective progress overflow")
	}
	if i.Progress >= d.Target && i.CompletedAt == nil {
		t := now.UTC()
		i.CompletedAt = &t
	}
	changed := i.Progress != old || (old < d.Target && i.CompletedAt != nil)
	if changed {
		i.StateVersion++
	}
	return i, changed, nil
}

func Claim(i Instance, now time.Time) (Instance, error) {
	if err := i.Validate(); err != nil {
		return Instance{}, err
	}
	if i.CompletedAt == nil {
		return Instance{}, errors.New("objective not complete")
	}
	if i.ClaimState == Claimed {
		return i, nil
	}
	if now.IsZero() {
		return Instance{}, errors.New("authoritative time required")
	}
	t := now.UTC()
	i.ClaimState = Claimed
	i.ClaimedAt = &t
	i.StateVersion++
	return i, nil
}
