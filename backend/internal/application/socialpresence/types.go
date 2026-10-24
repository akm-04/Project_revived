package socialpresence

import (
	"errors"
	"math"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/ids"
)

var (
	ErrInvalidLease         = errors.New("social presence: invalid lease")
	ErrStaleLeaseGeneration = errors.New("social presence: stale lease generation")
	ErrStaleRealtimeOwner   = errors.New("social presence: stale realtime owner")
	ErrInvalidObservation   = errors.New("social presence: invalid observation")
)

// LeaseRef is the exact derived realtime lease identity. Context+role is the
// durable primary identity; process+generation fences stale writers/closers.
type LeaseRef struct {
	PlayerID             identity.PlayerID
	ContextID            identity.ContextID
	Role                 domainrt.PhysicalRole
	RealtimeOwnerFence   int64
	RealtimeInstanceID   ids.UUID
	ConnectionGeneration uint64
}

func (r LeaseRef) Validate() error {
	if !r.PlayerID.Valid() || r.ContextID.UUID().IsZero() || !r.Role.Valid() || r.RealtimeOwnerFence <= 0 || r.RealtimeInstanceID.IsZero() || r.ConnectionGeneration == 0 || r.ConnectionGeneration > math.MaxInt64 {
		return ErrInvalidLease
	}
	return nil
}

func (r LeaseRef) GenerationInt64() (int64, error) {
	if err := r.Validate(); err != nil {
		return 0, err
	}
	return int64(r.ConnectionGeneration), nil
}

// Observation is a read-only SocialPresence projection at one authoritative
// database observation instant. LatestConnectedAt exists only while online.
type Observation struct {
	PlayerID          identity.PlayerID
	IsOnline          bool
	LastSeenAt        *time.Time
	LatestConnectedAt *time.Time
}

func (o Observation) Validate() error {
	if !o.PlayerID.Valid() {
		return ErrInvalidObservation
	}
	if o.LastSeenAt != nil && o.LastSeenAt.IsZero() {
		return ErrInvalidObservation
	}
	if o.LatestConnectedAt != nil && o.LatestConnectedAt.IsZero() {
		return ErrInvalidObservation
	}
	if o.IsOnline != (o.LatestConnectedAt != nil) {
		return ErrInvalidObservation
	}
	return nil
}

// ExpiredSummary is produced while the Presence root is locked.
type ExpiredSummary struct {
	MaxExpiredAt *time.Time
	HasLiveLease bool
}
