package profilefeedback

import (
	"errors"
	"gxb.local/backend/v2/internal/domain/identity"
	"time"
)

const PolicyVersion = "I7B_PROFILE_PRAISE_V1"

var ErrInvalid = errors.New("invalid ProfileFeedback state")

type Root struct {
	PlayerID             identity.PlayerID
	StateVersion         int64
	CreatedAt, UpdatedAt time.Time
}

func (r Root) Validate() error {
	if !r.PlayerID.Valid() || r.StateVersion <= 0 || r.CreatedAt.IsZero() || r.UpdatedAt.Before(r.CreatedAt) {
		return ErrInvalid
	}
	return nil
}

type Praise struct {
	Target, Actor identity.PlayerID
	FirstAt       time.Time
	RootVersion   int64
}

func (p Praise) Validate() error {
	if !p.Target.Valid() || !p.Actor.Valid() || p.Target == p.Actor || p.FirstAt.IsZero() || p.RootVersion <= 0 {
		return ErrInvalid
	}
	return nil
}

// Observation is a current coherent read, separate from any private terminal result.
type Observation struct {
	Target, Actor      identity.PlayerID
	Count, RootVersion int64
	HasPraised         bool
	ContentRevision    string
	ObservedAt         time.Time
}
