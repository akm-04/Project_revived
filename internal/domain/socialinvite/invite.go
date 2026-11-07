// Package socialinvite owns the pure invitation binding and mission-progress
// rules. Codes, accounts, levels, thresholds and mission configuration are
// supplied by their existing owners; this package performs no I/O or award.
package socialinvite

import (
	"errors"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
)

// PRIVATE_POLICY (D493 item 4): the source misc invite level gate is below
// academy level 50; this reconstruction keeps that literal policy limit.
const InviteAcademyLevelLimit int64 = 50

// PRIVATE_POLICY (D493 item 4): no original-server code spelling exists. The
// code is a canonical, non-secret, unique base36 spelling of the inviter's
// player id, so every existing character has exactly one valid code.
const InviteCodePolicy = "I9_10E_INVITE_CODE_BASE36_V1"

const maxInviteCodeLength = 13

func EncodeCode(player identity.PlayerID) (string, error) {
	if !player.Valid() {
		return "", ErrInvalid
	}
	return strings.ToUpper(strconv.FormatInt(int64(player), 36)), nil
}

// DecodeCode accepts the canonical code and its case-insensitive spelling.
func DecodeCode(raw string) (identity.PlayerID, error) {
	code := strings.ToUpper(strings.TrimSpace(raw))
	if code == "" || len(code) > maxInviteCodeLength {
		return 0, ErrInvalid
	}
	value, err := strconv.ParseInt(code, 36, 64)
	if err != nil || value <= 0 {
		return 0, ErrInvalid
	}
	player := identity.PlayerID(value)
	canonical, err := EncodeCode(player)
	if err != nil || canonical != code {
		return 0, ErrInvalid
	}
	return player, nil
}

var (
	ErrInvalid        = errors.New("social invite: invalid binding")
	ErrSelfInvite     = errors.New("social invite: inviter cannot invite self")
	ErrSameAccount    = errors.New("social invite: inviter and invitee share an account")
	ErrServerMismatch = errors.New("social invite: players outside logical server")
	ErrIneligible     = errors.New("social invite: invitee academy level is not eligible")
	ErrAlreadyBound   = errors.New("social invite: invitee is already bound")
	ErrMission        = errors.New("social invite: invalid mission")
	ErrFacts          = errors.New("social invite: invalid invitee facts")
	ErrDuplicate      = errors.New("social invite: duplicate invitee")
)

type Candidate struct {
	Inviter             identity.PlayerID
	Invitee             identity.PlayerID
	LogicalServerID     identity.LogicalServerID
	InviterAccount      identity.AccountID
	InviteeAccount      identity.AccountID
	InviteeAcademyLevel int64
}

type Binding struct {
	Inviter             identity.PlayerID
	Invitee             identity.PlayerID
	LogicalServerID     identity.LogicalServerID
	InviterAccount      identity.AccountID
	InviteeAccount      identity.AccountID
	InviteeAcademyLevel int64
	BoundAt             time.Time
}

func Bind(existing *Binding, candidate Candidate, academyLevelLimit int64, at time.Time) (Binding, error) {
	if existing != nil {
		if err := existing.Validate(); err != nil {
			return Binding{}, err
		}
		return Binding{}, ErrAlreadyBound
	}
	if academyLevelLimit <= 0 || at.IsZero() {
		return Binding{}, ErrInvalid
	}
	binding := Binding{
		Inviter:             candidate.Inviter,
		Invitee:             candidate.Invitee,
		LogicalServerID:     candidate.LogicalServerID,
		InviterAccount:      candidate.InviterAccount,
		InviteeAccount:      candidate.InviteeAccount,
		InviteeAcademyLevel: candidate.InviteeAcademyLevel,
		BoundAt:             at.UTC(),
	}
	if err := binding.Validate(); err != nil {
		return Binding{}, err
	}
	if binding.InviteeAcademyLevel >= academyLevelLimit {
		return Binding{}, ErrIneligible
	}
	return binding, nil
}

func (b Binding) Validate() error {
	if !b.Inviter.Valid() || !b.Invitee.Valid() {
		return ErrInvalid
	}
	if b.Inviter == b.Invitee {
		return ErrSelfInvite
	}
	if !b.LogicalServerID.Valid() {
		return ErrInvalid
	}
	if logicalserver.PlayerRegion(b.Inviter) != b.LogicalServerID || logicalserver.PlayerRegion(b.Invitee) != b.LogicalServerID {
		return ErrServerMismatch
	}
	if !validAccount(b.InviterAccount) || !validAccount(b.InviteeAccount) {
		return ErrInvalid
	}
	if b.InviterAccount == b.InviteeAccount {
		return ErrSameAccount
	}
	if b.InviteeAcademyLevel < 0 || !validTime(b.BoundAt) {
		return ErrInvalid
	}
	return nil
}

type MissionType int64

const (
	MissionInvitedCount          MissionType = 1
	MissionOwnedHeroCount        MissionType = 2
	MissionHighestOwnedHeroLevel MissionType = 3
	MissionCharge                MissionType = 4
)

type Mission struct {
	ID        int64
	Type      MissionType
	Threshold int64
}

func (m Mission) Validate() error {
	if m.ID <= 0 || m.Threshold < 0 {
		return ErrMission
	}
	switch m.Type {
	case MissionInvitedCount, MissionOwnedHeroCount, MissionHighestOwnedHeroLevel, MissionCharge:
		return nil
	default:
		return ErrMission
	}
}

type InviteeFacts struct {
	Player                identity.PlayerID
	AcademyLevel          int64
	OwnedHeroCount        int64
	HighestOwnedHeroLevel int64
	ChargeTotal           int64
}

func (f InviteeFacts) Validate() error {
	if !f.Player.Valid() || f.AcademyLevel < 0 || f.OwnedHeroCount < 0 || f.HighestOwnedHeroLevel < 0 || f.ChargeTotal < 0 {
		return ErrFacts
	}
	return nil
}

func Progress(mission Mission, invitees []InviteeFacts) (int64, error) {
	if err := mission.Validate(); err != nil {
		return 0, err
	}
	seen := make(map[identity.PlayerID]struct{}, len(invitees))
	var progress int64
	for _, facts := range invitees {
		if err := facts.Validate(); err != nil {
			return 0, err
		}
		if _, duplicate := seen[facts.Player]; duplicate {
			return 0, ErrDuplicate
		}
		seen[facts.Player] = struct{}{}
		switch mission.Type {
		case MissionInvitedCount:
			progress++
		case MissionOwnedHeroCount:
			if facts.OwnedHeroCount >= mission.Threshold {
				progress++
			}
		case MissionHighestOwnedHeroLevel:
			if facts.HighestOwnedHeroLevel >= mission.Threshold {
				progress++
			}
		case MissionCharge:
			if facts.ChargeTotal >= mission.Threshold {
				progress++
			}
		}
	}
	return progress, nil
}

func validAccount(account identity.AccountID) bool {
	return !account.UUID().IsZero()
}

func validTime(value time.Time) bool {
	return !value.IsZero() && value.Location() == time.UTC
}
