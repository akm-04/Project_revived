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
	// ResolverNotRequired marks a client-run attempt; it never runs the resolver.
	ResolverNotRequired ResolverStatus = "NOT_REQUIRED"
)

// SupersededKind ends a client-run attempt replaced by a different-stage START.
const SupersededKind = "SUPERSEDED"

// PracticeKind ends a no-value attempt; it carries no verdict.
const PracticeKind = "PRACTICE"

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
	TrustProfile      TrustProfile
	Replay            ReplaySpec
	// SupersedesAttemptID links the generation chain of one locator.
	SupersedesAttemptID ids.UUID
	SnapshotHash        string
	EntropyKeyVersion   string
	RulesCorpusID       string
	ResolverStatus      ResolverStatus
	ResolverFailure     string
	State               AttemptState
	StartedAt           time.Time
	ResultDeadline      time.Time
	StateVersion        int64
	ResolutionHash      string
	TerminalKind        string
	TerminalAt          *time.Time
	SemanticReceiptID   string
}

func (a Attempt) Validate() error {
	if a.ID.IsZero() || !a.Locator.Valid() || a.ActorPlayer <= 0 || a.GameplayContextID == "" || len(a.StartFingerprint) != 64 || len(a.SnapshotHash) != 64 || a.EntropyKeyVersion == "" || len(a.RulesCorpusID) != 64 || a.StartedAt.IsZero() || !a.ResultDeadline.After(a.StartedAt) || a.StateVersion <= 0 {
		return ErrInvalid
	}
	if !a.TrustProfile.Registered() || a.TrustProfile.ServerResolution() == (a.ResolverStatus == ResolverNotRequired) || !a.Replay.valid(a.ResolverStatus) {
		return ErrInvalid
	}
	chained := !a.SupersedesAttemptID.IsZero()
	practice := a.TerminalKind == PracticeKind && a.TrustProfile.SettlesValue()
	if chained && (a.SupersedesAttemptID == a.ID || !a.TrustProfile.Supersedes()) || a.TerminalKind == SupersededKind && !a.TrustProfile.Supersedes() || practice {
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
		// A closed attempt may end unresolved (Pass418: resolution is optional).
		if a.TerminalKind == "" || a.TerminalAt == nil || a.SemanticReceiptID == "" || resolved != (a.ResolverStatus == ResolverReady) {
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
	if !a.Runnable() || reason == "" {
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
	return a.State == Staged && a.ResolverStatus != ResolverPermanentFailed && a.ResolverStatus != ResolverNotRequired
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
	if a.State != ResolutionReady {
		return a, ErrStale
	}
	return a.finish(kind, semanticReceiptID, at)
}

// Closable reports whether the owning mode may end the attempt without
// settlement: its resolution failed permanently, its result deadline passed,
// or it is a staged client-run attempt the mode withdraws (D21b).
func (a Attempt) Closable(at time.Time) bool {
	expired := !at.Before(a.ResultDeadline)
	withdrawable := a.ResolverStatus == ResolverNotRequired
	return a.State == Staged && (a.ResolverStatus == ResolverPermanentFailed || expired || withdrawable) || a.State == ResolutionReady && expired
}

// Close frees the locator slot under the mode's expiry or supersession rule.
func (a Attempt) Close(kind, semanticReceiptID string, at time.Time) (Attempt, error) {
	if !a.Closable(at) {
		return a, ErrStale
	}
	return a.finish(kind, semanticReceiptID, at)
}

// Supersede ends an open client-run attempt replaced by successor's START.
func (a Attempt) Supersede(successor ids.UUID, at time.Time) (Attempt, error) {
	if a.State != Staged || !a.TrustProfile.Supersedes() || successor.IsZero() || successor == a.ID {
		return a, ErrStale
	}
	return a.finish(SupersededKind, "superseded-by:"+successor.String(), at)
}

// Attest ends a value-bearing client-run attempt on the mode's validated
// RESULT within its result deadline.
func (a Attempt) Attest(kind, semanticReceiptID string, at time.Time) (Attempt, error) {
	if a.State != Staged || a.ResolverStatus != ResolverNotRequired || !a.TrustProfile.SettlesValue() || kind == SupersededKind || kind == PracticeKind || !at.Before(a.ResultDeadline) {
		return a, ErrStale
	}
	return a.finish(kind, semanticReceiptID, at)
}

// EndPractice ends a no-value attempt on its RESULT within its deadline.
func (a Attempt) EndPractice(at time.Time) (Attempt, error) {
	if a.State != Staged || a.TrustProfile.SettlesValue() || !at.Before(a.ResultDeadline) {
		return a, ErrStale
	}
	return a.finish(PracticeKind, "practice:"+a.ID.String(), at)
}

func (a Attempt) finish(kind, semanticReceiptID string, at time.Time) (Attempt, error) {
	if kind == "" || semanticReceiptID == "" || at.IsZero() {
		return a, ErrStale
	}
	at = at.UTC()
	a.State, a.TerminalKind, a.TerminalAt, a.SemanticReceiptID = Terminal, kind, &at, semanticReceiptID
	a.StateVersion++
	return a, a.Validate()
}
