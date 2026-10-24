package socialrelation

import (
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

var ErrInvalidState = errors.New("invalid social relation state")

type Root struct {
	PlayerID     identity.PlayerID
	StateVersion int64
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

func (r Root) Validate() error {
	if !r.PlayerID.Valid() || r.StateVersion < 1 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return ErrInvalidState
	}
	return nil
}

type Friendship struct {
	PlayerLowID  identity.PlayerID
	PlayerHighID identity.PlayerID
	Generation   int64
	Active       bool
	ActivatedAt  time.Time
	EndedAt      *time.Time
	StateVersion int64
	UpdatedAt    time.Time
}

func (f Friendship) Validate() error {
	if !f.PlayerLowID.Valid() || !f.PlayerHighID.Valid() || f.PlayerLowID >= f.PlayerHighID || f.Generation < 1 || f.StateVersion < 1 || f.ActivatedAt.IsZero() || f.UpdatedAt.Before(f.ActivatedAt) {
		return ErrInvalidState
	}
	if f.Active != (f.EndedAt == nil) {
		return ErrInvalidState
	}
	if f.EndedAt != nil && f.EndedAt.Before(f.ActivatedAt) {
		return ErrInvalidState
	}
	return nil
}

type RequestStatus string

const (
	RequestPending  RequestStatus = "PENDING"
	RequestAccepted RequestStatus = "ACCEPTED"
	RequestDenied   RequestStatus = "DENIED"
	RequestIgnored  RequestStatus = "IGNORED"
)

func (s RequestStatus) Valid() bool {
	return s == RequestPending || s == RequestAccepted || s == RequestDenied || s == RequestIgnored
}

type FriendRequest struct {
	RequesterPlayerID identity.PlayerID
	TargetPlayerID    identity.PlayerID
	Generation        int64
	Status            RequestStatus
	Message           string
	RequestedAt       time.Time
	TerminalAt        *time.Time
	StateVersion      int64
	UpdatedAt         time.Time
}

func (r FriendRequest) Validate() error {
	if !r.RequesterPlayerID.Valid() || !r.TargetPlayerID.Valid() || r.RequesterPlayerID == r.TargetPlayerID || r.Generation < 1 || !r.Status.Valid() || r.StateVersion < 1 || r.RequestedAt.IsZero() || r.UpdatedAt.Before(r.RequestedAt) {
		return ErrInvalidState
	}
	if len([]rune(r.Message)) > 26 {
		return ErrInvalidState
	}
	if (r.Status == RequestPending) != (r.TerminalAt == nil) {
		return ErrInvalidState
	}
	if r.TerminalAt != nil && r.TerminalAt.Before(r.RequestedAt) {
		return ErrInvalidState
	}
	return nil
}

type Block struct {
	BlockerPlayerID identity.PlayerID
	BlockedPlayerID identity.PlayerID
	Generation      int64
	Active          bool
	ActivatedAt     time.Time
	RemovedAt       *time.Time
	StateVersion    int64
	UpdatedAt       time.Time
}

func (b Block) Validate() error {
	if !b.BlockerPlayerID.Valid() || !b.BlockedPlayerID.Valid() || b.BlockerPlayerID == b.BlockedPlayerID || b.Generation < 1 || b.StateVersion < 1 || b.ActivatedAt.IsZero() || b.UpdatedAt.Before(b.ActivatedAt) {
		return ErrInvalidState
	}
	if b.Active != (b.RemovedAt == nil) {
		return ErrInvalidState
	}
	if b.RemovedAt != nil && b.RemovedAt.Before(b.ActivatedAt) {
		return ErrInvalidState
	}
	return nil
}

type RequestEpoch struct {
	PlayerID              identity.PlayerID
	PolicyID              string
	EpochGeneration       int64
	EpochStartedAt        time.Time
	SuccessfulNewRequests int64
	StateVersion          int64
	UpdatedAt             time.Time
}

func (e RequestEpoch) Validate() error {
	if !e.PlayerID.Valid() || e.PolicyID == "" || e.EpochGeneration < 0 || e.SuccessfulNewRequests < 0 || e.StateVersion < 1 || e.EpochStartedAt.IsZero() || e.UpdatedAt.Before(e.EpochStartedAt) {
		return ErrInvalidState
	}
	return nil
}
