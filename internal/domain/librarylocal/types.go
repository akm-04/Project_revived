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
	ActCount          = 4
	FavorLimit        = 2000
	DefaultBgMain     = 1
	DefaultBgRoom     = 2
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
	ErrDialogClosed = errors.New("library: dialog not opened")
	ErrActLocked    = errors.New("library: act not unlocked")
	ErrActAwarded   = errors.New("library: act award already claimed")
	ErrTalkClaimed  = errors.New("library: school story reward already claimed")
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
	// Board selection: board_partner 0 means a cleared board, where card and model are 0.
	BoardPartner int64
	BoardCard    int64
	BoardModelID int64
	BgMain       int64
	BgRoom       int64
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
	f := PlayerFacts{PlayerID: player, StateVersion: 1, SeedPolicy: SeedPolicyV1, CreatedAt: now, UpdatedAt: now, BgMain: DefaultBgMain, BgRoom: DefaultBgRoom}
	return f, f.Validate()
}
func (f PlayerFacts) Validate() error {
	if !f.PlayerID.Valid() || f.StateVersion <= 0 || f.SeedPolicy != SeedPolicyV1 || f.CreatedAt.IsZero() || f.UpdatedAt.Before(f.CreatedAt) || f.MarriedHighWater < 0 {
		return ErrInvalidFacts
	}
	if !f.validBoard() || f.BgMain <= 0 || f.BgRoom <= 0 {
		return ErrInvalidFacts
	}
	return nil
}

func (f PlayerFacts) validBoard() bool {
	if f.BoardPartner < 0 || f.BoardModelID < 0 || f.BoardCard < 0 || f.BoardCard > 3 {
		return false
	}
	if f.BoardPartner == 0 {
		return f.BoardCard == 0 && f.BoardModelID == 0
	}
	return f.BoardCard >= 1
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

// DialogFact is one opened dialog of one partner hero. select_id 0 means no choice recorded.
type DialogFact struct {
	PlayerID  identity.PlayerID `json:"player_id"`
	PartnerID int64             `json:"partner_id"`
	DialogID  int64             `json:"dialog_id"`
	IsRead    bool              `json:"is_read"`
	IsAwarded bool              `json:"is_awarded"`
	SelectID  int64             `json:"select_id"`
	UpdatedAt time.Time         `json:"updated_at"`
}

func (f DialogFact) Validate() error {
	if !f.PlayerID.Valid() || f.PartnerID <= 0 || f.DialogID <= 0 || f.SelectID < 0 || f.UpdatedAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

// MissionFact is one materialized partner mission, state 1..4.
type MissionFact struct {
	PlayerID     identity.PlayerID `json:"player_id"`
	PartnerID    int64             `json:"partner_id"`
	MissionID    int64             `json:"mission_id"`
	Process      int64             `json:"process"`
	MissionState int64             `json:"mission_state"`
	UpdatedAt    time.Time         `json:"updated_at"`
}

func (f MissionFact) Validate() error {
	if !f.PlayerID.Valid() || f.PartnerID <= 0 || f.MissionID <= 0 || f.Process < 0 || f.MissionState < 1 || f.MissionState > 4 || f.UpdatedAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

// ActAwardFact is a once-per-hero/act award.
type ActAwardFact struct {
	PlayerID  identity.PlayerID `json:"player_id"`
	PartnerID int64             `json:"partner_id"`
	ActID     int64             `json:"act_id"`
	AwardedAt time.Time         `json:"awarded_at"`
}

func (f ActAwardFact) Validate() error {
	if !f.PlayerID.Valid() || f.PartnerID <= 0 || f.ActID < 1 || f.ActID > ActCount || f.AwardedAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

// TalkClaimFact is a once-per-player school story claim.
type TalkClaimFact struct {
	PlayerID  identity.PlayerID `json:"player_id"`
	TalkID    int64             `json:"talk_id"`
	ClaimedAt time.Time         `json:"claimed_at"`
}

func (f TalkClaimFact) Validate() error {
	if !f.PlayerID.Valid() || f.TalkID <= 0 || f.ClaimedAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

// CGClaimFact is a once-per-player memory CG claim.
type CGClaimFact struct {
	PlayerID  identity.PlayerID `json:"player_id"`
	CGID      int64             `json:"cg_id"`
	ClaimedAt time.Time         `json:"claimed_at"`
}

func (f CGClaimFact) Validate() error {
	if !f.PlayerID.Valid() || f.CGID <= 0 || f.ClaimedAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}

// BackgroundFact is a paid background ownership row; free rows are not stored.
type BackgroundFact struct {
	PlayerID   identity.PlayerID `json:"player_id"`
	BgID       int64             `json:"bg_id"`
	UnlockedAt time.Time         `json:"unlocked_at"`
}

func (f BackgroundFact) Validate() error {
	if !f.PlayerID.Valid() || f.BgID <= 0 || f.UnlockedAt.IsZero() {
		return ErrInvalidFacts
	}
	return nil
}
