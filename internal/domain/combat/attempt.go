package combat

import (
	"time"

	"gxb.local/backend/v2/internal/foundation/ids"
)

type AttemptState string

const (
	Staged          AttemptState = "STAGED"
	ResolutionReady AttemptState = "RESOLUTION_READY"
	Terminal        AttemptState = "TERMINAL"
)

type ResolverStatus string

const (
	ResolverPending         ResolverStatus = "PENDING"
	ResolverReady           ResolverStatus = "READY"
	ResolverRetryableFailed ResolverStatus = "RETRYABLE_FAILED"
	ResolverPermanentFailed ResolverStatus = "PERMANENT_FAILED"
)

// Locator is the mode's source-shaped identity of one START/RESULT family slot.
// At most one unresolved attempt exists per locator.
type Locator struct {
	DomainKind     string `json:"domain_kind"`
	AuthorityScope string `json:"authority_scope"`
	DomainLocator  string `json:"domain_locator"`
}

func (l Locator) Valid() bool {
	return l.DomainKind != "" && l.AuthorityScope != "" && l.DomainLocator != "" && len(l.DomainKind) <= 128 && len(l.AuthorityScope) <= 256 && len(l.DomainLocator) <= 512
}

// Attempt is the Pass418 shared envelope; mode phases stay with the mode.
type Attempt struct {
	ID                ids.UUID
	Locator           Locator
	ActorPlayer       int64
	GameplayContextID string
	GenerationRef     string
	StartFingerprint  string
	SnapshotHash      string
	EntropyKeyVersion string
	RulesCorpusID     string
	ResolverStatus    ResolverStatus
	ResolverFailure   string
	State             AttemptState
	StartedAt         time.Time
	ResultDeadline    time.Time
	StateVersion      int64
	ResolutionHash    string
	TerminalKind      string
	TerminalAt        *time.Time
	SemanticReceiptID string
}

func (a Attempt) Validate() error {
	if a.ID.IsZero() || !a.Locator.Valid() || a.ActorPlayer <= 0 || a.GameplayContextID == "" || len(a.StartFingerprint) != 64 || len(a.SnapshotHash) != 64 || a.EntropyKeyVersion == "" || len(a.RulesCorpusID) != 64 || a.StartedAt.IsZero() || !a.ResultDeadline.After(a.StartedAt) || a.StateVersion <= 0 {
		return ErrInvalid
	}
	resolved := a.ResolutionHash != ""
	terminal := a.TerminalKind != "" || a.TerminalAt != nil || a.SemanticReceiptID != ""
	switch a.State {
	case Staged:
		if resolved || terminal || a.ResolverStatus == ResolverReady {
			return ErrInvalid
		}
	case ResolutionReady:
		if !resolved || terminal || a.ResolverStatus != ResolverReady {
			return ErrInvalid
		}
	case Terminal:
		if !resolved || a.TerminalKind == "" || a.TerminalAt == nil || a.SemanticReceiptID == "" || a.ResolverStatus != ResolverReady {
			return ErrInvalid
		}
	default:
		return ErrInvalid
	}
	return nil
}

// Unresolved attempts own their locator slot.
func (a Attempt) Unresolved() bool { return a.State != Terminal }

// FailResolution records a classified worker failure; only RETRYABLE stays runnable.
func (a Attempt) FailResolution(permanent bool, reason string) (Attempt, error) {
	if a.State != Staged || a.ResolverStatus == ResolverPermanentFailed || reason == "" {
		return a, ErrStale
	}
	a.ResolverStatus = ResolverRetryableFailed
	if permanent {
		a.ResolverStatus = ResolverPermanentFailed
	}
	a.ResolverFailure = reason
	a.StateVersion++
	return a, nil
}

func (a Attempt) Runnable() bool {
	return a.State == Staged && a.ResolverStatus != ResolverPermanentFailed
}

func (a Attempt) Resolve(resolutionHash string) (Attempt, error) {
	if !a.Runnable() || len(resolutionHash) != 64 {
		return a, ErrStale
	}
	a.State, a.ResolverStatus, a.ResolverFailure, a.ResolutionHash = ResolutionReady, ResolverReady, "", resolutionHash
	a.StateVersion++
	return a, a.Validate()
}

func (a Attempt) Terminate(kind, semanticReceiptID string, at time.Time) (Attempt, error) {
	if a.State != ResolutionReady || kind == "" || semanticReceiptID == "" || at.IsZero() {
		return a, ErrStale
	}
	at = at.UTC()
	a.State, a.TerminalKind, a.TerminalAt, a.SemanticReceiptID = Terminal, kind, &at, semanticReceiptID
	a.StateVersion++
	return a, a.Validate()
}
