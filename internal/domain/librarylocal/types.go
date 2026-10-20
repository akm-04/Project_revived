// Package librarylocal owns relationship, applied feeding and collection facts.
// Hero identity and existence are supplied through the Character owner's ports.
package librarylocal

import (
	"errors"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

const (
	RootLockRank      = 490
	HeroLockRank      = 491
	AxisCount         = 6
	SpecialClaimCount = 23
	FavorLimit        = 2000
	SeedPolicyV1      = "LIBRARY_NEUTRAL_SEED_V1"
	FeedPolicyV1      = "LIBRARY_FEED_RECONSTRUCTION_V1"
)

var (
	ErrInvalidFacts = errors.New("library: invalid canonical facts")
	ErrUnqualified  = errors.New("library: unqualified content or owner observation")
	ErrNotMarried   = errors.New("library: feeding requires marriage")
	ErrAtCap        = errors.New("library: all feeding attributes at cap")
	ErrInvalidGift  = errors.New("library: invalid gift")
	ErrMarriageGate = errors.New("library: marriage requires maximum favor")
)

type FeedAttrs [AxisCount]int64

// Candidate is a paid preview. Applied remains unchanged until SAVE succeeds.
type Candidate struct {
	OperationID     ids.UUID
	Revision        int64
	PolicyVersion   string
	ContentRevision string
	Base            FeedAttrs
	Proposed        FeedAttrs
	Delta           FeedAttrs
	CreatedAt       time.Time
}
type HeroFacts struct {
	Ref          character.HeroRef
	StateVersion int64
	Favor        int64
	Married      bool
	Applied      FeedAttrs
	QualityStage int64
	StarStage    int64
	Pending      *Candidate
	SeedPolicy   string
	CreatedAt    time.Time
	UpdatedAt    time.Time
}
type PlayerFacts struct {
	PlayerID      identity.PlayerID
	StateVersion  int64
	SpecialClaims [SpecialClaimCount]bool
	SeedPolicy    string
	CreatedAt     time.Time
	UpdatedAt     time.Time
	// MarriedHighWater is the most heroes ever married at once; marriage titles keep it.
	MarriedHighWater int64
}

func ValidRevision(revision string) bool {
	if len(revision) != 64 || strings.ToLower(revision) != revision {
		return false
	}
	for _, c := range revision {
		if (c < '0' || c > '9') && (c < 'a' || c > 'f') {
			return false
		}
	}
	return true
}
func NewHeroFacts(ref character.HeroRef, now time.Time) (HeroFacts, error) {
	f := HeroFacts{Ref: ref, StateVersion: 1, SeedPolicy: SeedPolicyV1, CreatedAt: now, UpdatedAt: now}
	return f, f.Validate()
}
func NewPlayerFacts(player identity.PlayerID, now time.Time) (PlayerFacts, error) {
	f := PlayerFacts{PlayerID: player, StateVersion: 1, SeedPolicy: SeedPolicyV1, CreatedAt: now, UpdatedAt: now}
	return f, f.Validate()
}
func (f PlayerFacts) Validate() error {
	if !f.PlayerID.Valid() || f.StateVersion <= 0 || f.SeedPolicy != SeedPolicyV1 || f.CreatedAt.IsZero() || f.UpdatedAt.Before(f.CreatedAt) || f.MarriedHighWater < 0 {
		return ErrInvalidFacts
	}
	return nil
}
func (f HeroFacts) Validate() error {
	if f.Ref.Validate() != nil || f.StateVersion <= 0 || f.Favor < 0 || f.Favor > FavorLimit || (f.Married && f.Favor != FavorLimit) || f.QualityStage < 0 || f.StarStage < 0 || f.SeedPolicy != SeedPolicyV1 || f.CreatedAt.IsZero() || f.UpdatedAt.Before(f.CreatedAt) {
		return ErrInvalidFacts
	}
	for _, x := range f.Applied {
		if x < 0 {
			return ErrInvalidFacts
		}
	}
	if f.Pending != nil {
		p := f.Pending
		if p.OperationID.IsZero() || p.Revision <= 0 || p.Revision > f.StateVersion || p.PolicyVersion != FeedPolicyV1 || !ValidRevision(p.ContentRevision) || p.CreatedAt.IsZero() || !f.Married || p.Base != f.Applied {
			return ErrInvalidFacts
		}
		for i, x := range p.Proposed {
			if x < 0 || p.Delta[i] != x-p.Base[i] {
				return ErrInvalidFacts
			}
		}
	}
	return nil
}

// WithPreview returns a new value; it never mutates an existing paid preview.
func (f HeroFacts) WithPreview(p Candidate, now time.Time) (HeroFacts, error) {
	f.Pending = &p
	f.StateVersion++
	f.UpdatedAt = now
	return f, f.Validate()
}

// SaveCurrent converges after a successful save. Late nonce-less SAVE after a
// paid redo applies the current candidate, as the frozen compatibility policy states.
func (f HeroFacts) SaveCurrent(now time.Time) (HeroFacts, bool, error) {
	if err := f.Validate(); err != nil {
		return HeroFacts{}, false, err
	}
	if f.Pending == nil {
		return f, false, nil
	}
	f.Applied = f.Pending.Proposed
	f.Pending = nil
	f.StateVersion++
	f.UpdatedAt = now
	return f, true, f.Validate()
}
